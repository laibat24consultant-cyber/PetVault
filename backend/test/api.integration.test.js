import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import { after, before, test } from 'node:test';
import pg from 'pg';
import { createApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import { provisionAdmin } from '../src/provision-admin.js';
import { runMigrations } from '../src/migrate.js';

const { Pool } = pg;
const databaseUrl = process.env.TEST_DATABASE_URL;
const enabled = Boolean(databaseUrl);
let adminPool;
let pool;
let server;
let baseUrl;
let testSchema;

if (enabled) {
  const parsed = new URL(databaseUrl);
  const database = parsed.pathname.slice(1);
  if (!['localhost', '127.0.0.1', '::1'].includes(parsed.hostname) ||
      parsed.port === '5432' ||
      !database.startsWith('petvault_test')) {
    throw new Error(
      'TEST_DATABASE_URL must target a local, disposable petvault_test database on a port other than 5432.',
    );
  }
}

before(async () => {
  if (!enabled) return;
  adminPool = new Pool({ connectionString: databaseUrl });
  testSchema = `petvault_test_${crypto.randomUUID().replace(/-/g, '')}`;
  await adminPool.query(`CREATE SCHEMA "${testSchema}"`);
  const scopedUrl = new URL(databaseUrl);
  scopedUrl.searchParams.set('options', `-c search_path=${testSchema},public`);
  pool = new Pool({ connectionString: scopedUrl.toString() });
  await runMigrations(pool);

  const config = loadConfig({
    ...process.env,
    NODE_ENV: 'test',
    DATABASE_URL: scopedUrl.toString(),
    JWT_SECRET: 'test-only-jwt-secret-at-least-32-characters',
    DEV_AUTH_CODES: 'true',
    PAYMENT_PROVIDER: 'mock',
    ALLOWED_ORIGINS: 'http://localhost:8765',
  });
  const app = createApp({
    pool,
    config,
    emailSender: async () => {},
  });
  server = await new Promise((resolve) => {
    const listening = app.listen(0, '127.0.0.1', () => resolve(listening));
  });
  baseUrl = `http://127.0.0.1:${server.address().port}/api`;
});

after(async () => {
  if (!enabled) return;
  if (server) {
    await new Promise((resolve, reject) => {
      server.close((error) => error ? reject(error) : resolve());
    });
  }
  if (pool) await pool.end();
  if (adminPool && testSchema) {
    await adminPool.query(`DROP SCHEMA "${testSchema}" CASCADE`);
    await adminPool.end();
  }
});

test('authentication, role authorization, marketplace and commerce workflows', {
  skip: enabled ? false : 'Set TEST_DATABASE_URL to an isolated local test database.',
}, async () => {
  const health = await request('/health');
  assert.equal(health.status, 200);

  const adminSignup = await request('/auth/register', 'POST', {
    displayName: 'Untrusted Admin',
    email: 'untrusted-admin@example.test',
    phone: '+12025550999',
    password: 'a-strong-password',
    role: 'admin',
  });
  assert.equal(adminSignup.status, 403);

  const owner = await registerAndVerify('owner@example.test', 'owner');
  const seller = await registerAndVerify('seller@example.test', 'owner');
  const sitter = await registerAndVerify('sitter@example.test', 'sitter');
  const veterinarian = await registerAndVerify(
    'veterinarian@example.test',
    'veterinarian',
  );
  const vendor = await registerAndVerify('vendor@example.test', 'vendor');
  const vendorTwo = await registerAndVerify('vendor-two@example.test', 'vendor');
  const admin = await provisionAdmin({
    pool,
    email: 'admin@example.test',
    displayName: 'Test Admin',
    phone: '+12025550199',
    password: 'a-very-strong-admin-password',
  });
  const adminToken = await login(admin.email, 'a-very-strong-admin-password');
  const outsider = await registerAndVerify('outsider@example.test', 'owner');

  assert.equal((await request('/pets', 'GET', undefined, null)).status, 401);
  assert.equal((await request('/pets', 'GET', undefined, 'not-a-valid-token')).status, 401);
  assert.equal((await request('/auth/roles', 'POST', { role: 'owner' }, owner.token)).status, 200);
  assert.equal((await request('/auth/roles', 'POST', { role: 'seller' }, owner.token)).status, 403);
  assert.equal((await request('/admin/kyc', 'GET', undefined, owner.token)).status, 403);
  assert.equal((await request('/products', 'POST', {
    name: 'Unauthorized product',
    price: 5,
    stock: 1,
  }, owner.token, 'seller')).status, 403);

  const kyc = await request('/kyc', 'POST', {
    role: 'seller',
    documentReference: 'test-verification-document',
  }, seller.token);
  assert.equal(kyc.status, 201);
  assert.equal((await request(`/admin/kyc/${kyc.body.submission.id}`, 'PATCH', {
    status: 'verified',
    reviewNote: 'Approved for integration testing.',
  }, adminToken, 'admin')).status, 200);
  assert.equal((await request('/auth/roles', 'POST', {
    role: 'seller',
  }, seller.token)).status, 200);
  assert.equal((await request('/kyc', 'POST', {
    role: 'vendor',
    documentReference: 'unsupported-second-supply-role',
  }, seller.token, 'seller')).status, 403);

  const product = await request('/products', 'POST', {
    name: 'Healthy pet food',
    price: 12.5,
    stock: 3,
    imageUrl: '',
  }, vendor.token, 'vendor');
  assert.equal(product.status, 403);
  const vendorKyc = await request('/kyc', 'POST', {
    role: 'vendor',
    documentReference: 'test-vendor-verification',
  }, vendor.token, 'vendor');
  assert.equal(vendorKyc.status, 201);
  assert.equal((await request(`/admin/kyc/${vendorKyc.body.submission.id}`, 'PATCH', {
    status: 'verified',
  }, adminToken, 'admin')).status, 200);
  const vendorTwoKyc = await request('/kyc', 'POST', {
    role: 'vendor',
    documentReference: 'test-second-vendor-verification',
  }, vendorTwo.token, 'vendor');
  assert.equal(vendorTwoKyc.status, 201);
  assert.equal((await request(`/admin/kyc/${vendorTwoKyc.body.submission.id}`, 'PATCH', {
    status: 'verified',
  }, adminToken, 'admin')).status, 200);
  const createdProduct = await request('/products', 'POST', {
    name: 'Healthy pet food',
    price: 12.5,
    stock: 3,
    imageUrl: '',
  }, vendor.token, 'vendor');
  assert.equal(createdProduct.status, 201, JSON.stringify(createdProduct));
  const secondProduct = await request('/products', 'POST', {
    name: 'Pet travel bowl',
    price: 7.25,
    stock: 5,
    imageUrl: '',
  }, vendorTwo.token, 'vendor');
  assert.equal(secondProduct.status, 201);
  const outOfStockProduct = await request('/products', 'POST', {
    name: 'Out of stock treat',
    price: 3,
    stock: 0,
    imageUrl: '',
  }, vendor.token, 'vendor');
  assert.equal(outOfStockProduct.status, 201);
  const publicCatalog = await request('/products');
  assert.equal(publicCatalog.body.products.find(
    (item) => item.id === outOfStockProduct.body.product.id,
  ).stock, 0);
  assert.equal((await request('/orders', 'POST', {
    items: [{ productId: outOfStockProduct.body.product.id, quantity: 1 }],
  }, owner.token)).status, 409);

  const order = await request('/orders', 'POST', {
    items: [
      { productId: createdProduct.body.product.id, quantity: 1 },
      { productId: secondProduct.body.product.id, quantity: 1 },
    ],
  }, owner.token);
  assert.equal(order.status, 201);
  assert.equal(order.body.order.total, 19.75);
  const paid = await request(`/orders/${order.body.order.id}/pay`, 'POST', {
    simulateUnavailable: false,
  }, owner.token);
  assert.equal(paid.status, 200);
  assert.equal(paid.body.order.paymentStatus, 'paid');
  const noticesBeforeRepeatPay = await pool.query(
    `SELECT count(*)::int AS total FROM notifications
      WHERE user_id = $1 AND title = 'New paid order'`,
    [vendor.user.id],
  );
  const auditsBeforeRepeatPay = await pool.query(
    `SELECT count(*)::int AS total FROM audit_events
      WHERE resource_id = $1 AND action = 'order.payment_succeeded'`,
    [order.body.order.id],
  );
  const repeatedPayment = await request(
    `/orders/${order.body.order.id}/pay`,
    'POST',
    { simulateUnavailable: false },
    owner.token,
  );
  assert.equal(repeatedPayment.status, 200);
  const noticesAfterRepeatPay = await pool.query(
    `SELECT count(*)::int AS total FROM notifications
      WHERE user_id = $1 AND title = 'New paid order'`,
    [vendor.user.id],
  );
  const auditsAfterRepeatPay = await pool.query(
    `SELECT count(*)::int AS total FROM audit_events
      WHERE resource_id = $1 AND action = 'order.payment_succeeded'`,
    [order.body.order.id],
  );
  assert.equal(noticesAfterRepeatPay.rows[0].total, noticesBeforeRepeatPay.rows[0].total);
  assert.equal(auditsAfterRepeatPay.rows[0].total, auditsBeforeRepeatPay.rows[0].total);
  const orderDeletionCheck = await request(
    '/account/deletion-eligibility',
    'GET',
    undefined,
    owner.token,
  );
  assert.equal(orderDeletionCheck.body.canDelete, false);
  assert.equal((await request('/account', 'DELETE', { confirm: true }, owner.token)).status, 409);
  const products = await request('/products');
  assert.equal(products.body.products.find((item) =>
    item.id === createdProduct.body.product.id).stock, 2);
  assert.equal((await request('/orders', 'GET', undefined, owner.token)).body.orders.length, 1);
  assert.equal((await request(`/orders/${order.body.order.id}/status`, 'PATCH', {
    status: 'Shipped',
  }, vendor.token, 'vendor')).status, 200);
  const vendorOrders = await request('/orders', 'GET', undefined, vendor.token, 'vendor');
  assert.equal(vendorOrders.body.orders[0].status, 'Shipped');
  assert.equal(vendorOrders.body.orders[0].items.length, 1);
  assert.equal(vendorOrders.body.orders[0].total, 12.5);
  assert.equal((await request('/orders', 'GET', undefined, owner.token))
    .body.orders[0].status, 'Processing');
  assert.equal((await request(`/orders/${order.body.order.id}/status`, 'PATCH', {
    status: 'Shipped',
  }, vendorTwo.token, 'vendor')).status, 200);
  assert.equal((await request('/orders', 'GET', undefined, owner.token))
    .body.orders[0].status, 'Shipped');
  assert.equal((await request(`/orders/${order.body.order.id}/status`, 'PATCH', {
    status: 'Delivered',
  }, vendor.token, 'vendor')).status, 200);
  assert.equal((await request('/orders', 'GET', undefined, owner.token))
    .body.orders[0].status, 'Shipped');
  assert.equal((await request(`/orders/${order.body.order.id}/status`, 'PATCH', {
    status: 'Delivered',
  }, vendorTwo.token, 'vendor')).status, 200);
  assert.equal((await request('/orders', 'GET', undefined, owner.token))
    .body.orders[0].status, 'Delivered');

  const listing = await request('/listings', 'POST', {
    title: 'Family-friendly dog listing',
    species: 'dog',
    breed: 'Mixed breed',
    city: 'Test City',
    price: 250,
    age: '2 years',
    imageUrl: '',
    healthNotes: 'Vaccinated',
  }, seller.token, 'seller');
  assert.equal(listing.status, 201);
  const moderation = await request('/admin/listings/moderation', 'GET', undefined, adminToken, 'admin');
  assert.equal(moderation.status, 200);
  assert.ok(moderation.body.listings.some((item) => item.id === listing.body.listing.id));
  assert.equal((await request(
    `/admin/listings/${listing.body.listing.id}/moderation`,
    'PATCH',
    { status: 'active', reviewNote: '' },
    adminToken,
    'admin',
  )).status, 200);
  assert.ok((await request('/listings')).body.listings.some(
    (item) => item.id === listing.body.listing.id,
  ));
  assert.equal((await request(`/listings/${listing.body.listing.id}/favorite`, 'PUT', {
    favorite: true,
  }, owner.token)).status, 200);
  assert.equal((await request('/listings/favorites', 'GET', undefined, owner.token))
    .body.listings.length, 1);
  assert.equal((await request(`/listings/${listing.body.listing.id}/reports`, 'POST', {
    reason: 'Potentially misleading information.',
  }, owner.token)).status, 201);
  assert.equal((await request(`/listings/${listing.body.listing.id}/reports`, 'POST', {
    reason: 'Second report from same user.',
  }, owner.token)).status, 409);
  const reports = await request('/admin/listing-reports', 'GET', undefined, adminToken, 'admin');
  assert.equal(reports.status, 200);
  assert.equal((await request(
    `/admin/listing-reports/${reports.body.reports[0].id}`,
    'PATCH',
    { status: 'reviewed' },
    adminToken,
    'admin',
  )).status, 200);

  const adminDashboard = await request(
    '/admin/dashboard',
    'GET',
    undefined,
    adminToken,
    'admin',
  );
  assert.equal(adminDashboard.status, 200, JSON.stringify(adminDashboard));
  assert.ok(adminDashboard.body.stats.totalUsers >= 1);
  const adminListPaths = [
    '/admin/users?role=seller&verified=true',
    '/admin/listings?status=active',
    '/admin/bookings',
    '/admin/appointments',
    '/admin/orders?paymentStatus=paid',
    '/admin/disputes',
    '/admin/reviews',
    '/admin/notifications',
    '/admin/audit-events',
    '/admin/support/requests',
  ];
  for (const path of adminListPaths) {
    const response = await request(path, 'GET', undefined, adminToken, 'admin');
    assert.equal(response.status, 200, `${path}: ${JSON.stringify(response)}`);
    assert.ok(Array.isArray(response.body.items), path);
  }
  const adminUsers = await request(
    '/admin/users?role=seller&verified=true',
    'GET',
    undefined,
    adminToken,
    'admin',
  );
  const sellerAccount = adminUsers.body.items.find(
    (item) => item.id === seller.user.id,
  );
  assert.deepEqual(sellerAccount.kycStatuses, { seller: 'verified' });
  assert.equal((await request(
    '/admin/dashboard',
    'GET',
    undefined,
    owner.token,
  )).status, 403);

  const dispute = await request(
    '/disputes',
    'POST',
    {
      targetType: 'order',
      targetId: order.body.order.id,
      reason: 'Test order delivery dispute.',
    },
    owner.token,
  );
  assert.equal(dispute.status, 201, JSON.stringify(dispute));
  const disputeId = dispute.body.dispute.id;
  assert.equal((await request(
    '/disputes',
    'POST',
    {
      targetType: 'order',
      targetId: order.body.order.id,
      reason: 'Duplicate order dispute.',
    },
    owner.token,
  )).status, 409);
  assert.equal((await request(
    '/disputes',
    'POST',
    {
      targetType: 'order',
      targetId: order.body.order.id,
      reason: 'Unauthorized order dispute.',
    },
    outsider.token,
  )).status, 404);
  assert.equal((await request(
    `/admin/disputes/${disputeId}`,
    'PATCH',
    { status: 'in_review' },
    adminToken,
    'admin',
  )).status, 200);
  const resolvedDispute = await request(
    `/admin/disputes/${disputeId}`,
    'PATCH',
    { status: 'resolved', resolution: 'Resolved for integration testing.' },
    adminToken,
    'admin',
  );
  assert.equal(resolvedDispute.status, 200, JSON.stringify(resolvedDispute));
  assert.equal(resolvedDispute.body.dispute.status, 'resolved');
  assert.equal((await request('/orders', 'GET', undefined, owner.token))
    .body.orders[0].paymentStatus, 'paid');

  const conversation = await request('/conversations', 'POST', {
    listingId: listing.body.listing.id,
    body: 'Is this listing still available?',
  }, owner.token);
  assert.equal(conversation.status, 201);
  assert.equal((await request(
    `/conversations/${conversation.body.conversation.id}/messages`,
    'GET',
    undefined,
    outsider.token,
  )).status, 404);
  const message = await request(
    `/conversations/${conversation.body.conversation.id}/messages`,
    'POST',
    { body: 'Yes, please share your availability.' },
    seller.token,
    'seller',
  );
  assert.equal(message.status, 201);
  assert.equal((await request(
    `/conversations/${conversation.body.conversation.id}/messages`,
    'GET',
    undefined,
    owner.token,
  )).body.messages.length, 2);

  const visit = await request(`/listings/${listing.body.listing.id}/visit-requests`, 'POST', {
    scheduledAt: new Date(Date.now() + 86_400_000).toISOString(),
    message: 'Please let me know when a visit works.',
  }, owner.token);
  assert.equal(visit.status, 201);
  assert.equal((await request(`/visit-requests/${visit.body.visitRequest.id}/status`, 'PATCH', {
    status: 'confirmed',
  }, seller.token, 'seller')).status, 200);
  assert.equal((await request('/visit-requests', 'GET', undefined, owner.token))
    .body.visitRequests[0].status, 'confirmed');
  assert.equal((await request('/account', 'DELETE', { confirm: true }, owner.token)).status, 409);
  assert.equal((await request(
    `/visit-requests/${visit.body.visitRequest.id}/status`,
    'PATCH',
    { status: 'cancelled' },
    owner.token,
  )).status, 200);

  const pet = await request('/pets', 'POST', {
    name: 'Milo',
    species: 'dog',
    breed: 'Mixed breed',
    age: '3 years',
    sex: 'Unknown',
    weightKg: 12.5,
  }, owner.token);
  assert.equal(pet.status, 201);
  const dueDate = new Date(Date.now() + 14 * 86_400_000).toISOString().slice(0, 10);
  const healthRecord = await request(`/pets/${pet.body.pet.id}/health-records`, 'POST', {
    title: 'Rabies vaccination',
    type: 'vaccination',
    provider: 'Test Clinic',
    date: new Date().toISOString().slice(0, 10),
    nextDueAt: dueDate,
    attachmentName: 'vaccination-record.pdf',
  }, owner.token);
  assert.equal(healthRecord.status, 201);
  const healthRecords = await request(
    `/pets/${pet.body.pet.id}/health-records`,
    'GET',
    undefined,
    owner.token,
  );
  assert.equal(healthRecords.body.records[0].vaccinationStatus, 'due_soon');
  const sitterKyc = await request('/kyc', 'POST', {
    role: 'sitter',
    documentReference: 'test-sitter-verification',
  }, sitter.token, 'sitter');
  assert.equal(sitterKyc.status, 201);
  assert.equal((await request(`/admin/kyc/${sitterKyc.body.submission.id}`, 'PATCH', {
    status: 'verified',
  }, adminToken, 'admin')).status, 200);
  const sitterBooking = await request('/sitting/bookings', 'POST', {
    sitterId: sitter.user.id,
    petId: pet.body.pet.id,
    startsAt: new Date(Date.now() + 86_400_000).toISOString(),
    endsAt: new Date(Date.now() + 2 * 86_400_000).toISOString(),
    arrangement: 'Care at the owner home',
    instructions: 'Feed the pet twice daily.',
    emergencyName: 'Trusted Contact',
    emergencyPhone: '+12025550123',
  }, owner.token);
  assert.equal(sitterBooking.status, 201, JSON.stringify(sitterBooking));
  const sitterViewBeforeStart = await request(
    '/sitting/bookings',
    'GET',
    undefined,
    sitter.token,
    'sitter',
  );
  assert.equal(sitterViewBeforeStart.body.bookings[0].emergencyName, null);
  assert.equal(sitterViewBeforeStart.body.bookings[0].emergencyPhone, null);
  assert.equal((await request(
    '/sitting/bookings',
    'GET',
    undefined,
    owner.token,
  )).body.bookings[0].emergencyName, 'Trusted Contact');
  assert.equal((await request(
    `/sitting/bookings/${sitterBooking.body.booking.id}/status`,
    'PATCH',
    { status: 'confirmed' },
    sitter.token,
    'sitter',
  )).status, 200);
  await pool.query(
    `UPDATE sitter_bookings
        SET starts_at = now() - interval '1 minute',
            ends_at = now() + interval '1 hour'
      WHERE id = $1`,
    [sitterBooking.body.booking.id],
  );
  const sitterViewDuringBooking = await request(
    '/sitting/bookings',
    'GET',
    undefined,
    sitter.token,
    'sitter',
  );
  assert.equal(sitterViewDuringBooking.body.bookings[0].emergencyName, 'Trusted Contact');
  assert.equal((await request(
    `/sitting/bookings/${sitterBooking.body.booking.id}/check-ins`,
    'POST',
    { note: 'Rosco ate dinner and is resting comfortably.' },
    owner.token,
  )).status, 403);
  const checkIn = await request(
    `/sitting/bookings/${sitterBooking.body.booking.id}/check-ins`,
    'POST',
    { note: 'Rosco ate dinner and is resting comfortably.' },
    sitter.token,
    'sitter',
  );
  assert.equal(checkIn.status, 201, JSON.stringify(checkIn));
  assert.equal(checkIn.body.checkIn.note, 'Rosco ate dinner and is resting comfortably.');
  const ownerBookingUpdates = await request(
    '/sitting/bookings',
    'GET',
    undefined,
    owner.token,
  );
  assert.equal(ownerBookingUpdates.body.bookings[0].updates.length, 1);
  assert.equal(ownerBookingUpdates.body.bookings[0].updates[0].note, checkIn.body.checkIn.note);
  await pool.query(
    `UPDATE sitter_bookings
        SET starts_at = now() - interval '2 hours',
            ends_at = now() - interval '1 hour'
      WHERE id = $1`,
    [sitterBooking.body.booking.id],
  );
  const sitterViewAfterBooking = await request(
    '/sitting/bookings',
    'GET',
    undefined,
    sitter.token,
    'sitter',
  );
  assert.equal(sitterViewAfterBooking.body.bookings[0].emergencyName, null);
  assert.equal((await request(
    `/sitting/bookings/${sitterBooking.body.booking.id}/check-ins`,
    'POST',
    { note: 'Late update should not be accepted.' },
    sitter.token,
    'sitter',
  )).status, 404);
  assert.equal((await request(
    `/sitting/bookings/${sitterBooking.body.booking.id}/status`,
    'PATCH',
    { status: 'complete' },
    sitter.token,
    'sitter',
  )).status, 200);

  const veterinarianKyc = await request('/kyc', 'POST', {
    role: 'veterinarian',
    documentReference: 'test-vet-identity-verification',
  }, veterinarian.token, 'veterinarian');
  assert.equal(veterinarianKyc.status, 201);
  assert.equal((await request(
    `/admin/kyc/${veterinarianKyc.body.submission.id}`,
    'PATCH',
    { status: 'verified' },
    adminToken,
    'admin',
  )).status, 200);
  const vetStartsAt = new Date(Date.now() + 3 * 86_400_000);
  const vetSlot = await request('/veterinary/availability', 'POST', {
    startsAt: vetStartsAt.toISOString(),
    endsAt: new Date(vetStartsAt.getTime() + 60 * 60_000).toISOString(),
  }, veterinarian.token, 'veterinarian');
  assert.equal(vetSlot.status, 201, JSON.stringify(vetSlot));
  const appointment = await request('/veterinary/appointments', 'POST', {
    availabilityId: vetSlot.body.availability.id,
    petId: pet.body.pet.id,
    type: 'Routine checkup',
  }, owner.token);
  assert.equal(appointment.status, 201, JSON.stringify(appointment));
  const deniedVetNotes = await request(
    `/veterinary/appointments/${appointment.body.appointment.id}/notes`,
    'POST',
    { notes: 'Consultation notes without owner access.' },
    veterinarian.token,
    'veterinarian',
  );
  assert.equal(deniedVetNotes.status, 403);
  assert.equal((await request('/veterinary/appointments', 'POST', {
    availabilityId: vetSlot.body.availability.id,
    petId: pet.body.pet.id,
    type: 'Duplicate booking',
  }, owner.token)).status, 404);
  const vetGrant = await request(`/pets/${pet.body.pet.id}/access-grants`, 'POST', {
    recipientId: veterinarian.user.id,
    sections: ['health'],
  }, owner.token);
  assert.equal(vetGrant.status, 201);
  const followUpDate = new Date(Date.now() + 30 * 86_400_000)
    .toISOString()
    .slice(0, 10);
  const consultation = await request(
    `/veterinary/appointments/${appointment.body.appointment.id}/notes`,
    'POST',
    { notes: 'Routine consultation notes.', followUp: followUpDate },
    veterinarian.token,
    'veterinarian',
  );
  assert.equal(consultation.status, 200, JSON.stringify(consultation));
  const vetHealthRecords = await request(
    `/pets/${pet.body.pet.id}/health-records`,
    'GET',
    undefined,
    veterinarian.token,
    'veterinarian',
  );
  const persistedConsultation = vetHealthRecords.body.records.find(
    (record) => record.recordType === 'consultation',
  );
  assert.ok(persistedConsultation);
  assert.equal(persistedConsultation.createdBy, veterinarian.user.id);
  assert.equal(persistedConsultation.nextDueAt, followUpDate);
  const ownerAppointments = await request(
    '/veterinary/appointments',
    'GET',
    undefined,
    owner.token,
  );
  assert.equal(
    ownerAppointments.body.appointments[0].consultationNotes,
    'Routine consultation notes.',
  );
  const grantBody = { recipientId: sitter.user.id, sections: ['health'] };
  assert.equal((await request(`/pets/${pet.body.pet.id}/access-grants`, 'POST', grantBody, owner.token))
    .status, 201);
  assert.equal((await request(
    `/pets/${pet.body.pet.id}/health-records`,
    'GET',
    undefined,
    sitter.token,
    'sitter',
  )).status, 200);
  assert.equal((await request(
    `/pets/${pet.body.pet.id}/access-grants/${sitter.user.id}`,
    'DELETE',
    undefined,
    owner.token,
  )).status, 204);
  assert.equal((await request(
    `/pets/${pet.body.pet.id}/health-records`,
    'GET',
    undefined,
    sitter.token,
    'sitter',
  )).status, 403);
  assert.equal((await request(`/pets/${pet.body.pet.id}/access-grants`, 'POST', grantBody, owner.token))
    .status, 201);
  const deniedHealth = await request(
    `/pets/${pet.body.pet.id}/health-records`,
    'GET',
    undefined,
    outsider.token,
  );
  assert.equal(deniedHealth.status, 403);

  const suspended = await request(
    `/admin/users/${outsider.user.id}/status`,
    'PATCH',
    { status: 'suspended', reason: 'Integration test suspension.' },
    adminToken,
    'admin',
  );
  assert.equal(suspended.status, 200, JSON.stringify(suspended));
  assert.equal((await request('/pets', 'GET', undefined, outsider.token)).status, 401);
  assert.equal((await request('/auth/login', 'POST', {
    email: 'outsider@example.test',
    password: 'test-user-password',
  })).status, 403);
  const reactivated = await request(
    `/admin/users/${outsider.user.id}/status`,
    'PATCH',
    { status: 'active', reason: 'Integration test reactivation.' },
    adminToken,
    'admin',
  );
  assert.equal(reactivated.status, 200, JSON.stringify(reactivated));
  const reactivatedToken = await login(
    'outsider@example.test',
    'test-user-password',
  );
  assert.equal((await request('/pets', 'GET', undefined, reactivatedToken)).status, 200);
  assert.equal((await request(
    `/admin/users/${admin.id}/status`,
    'PATCH',
    { status: 'suspended', reason: 'Cannot suspend last admin.' },
    adminToken,
    'admin',
  )).status, 409);

  const denialAudit = await pool.query(
    `SELECT count(*)::int AS total
       FROM audit_events
      WHERE actor_id = $1 AND action = 'authorization.denied'`,
    [owner.user.id],
  );
  assert.ok(denialAudit.rows[0].total >= 1);

  const pending = await request('/auth/register', 'POST', {
    displayName: 'Expired Code User',
    email: 'expired-code@example.test',
    phone: '+12025550988',
    password: 'test-user-password',
    role: 'owner',
  });
  assert.equal(pending.status, 201);
  await pool.query(
    `UPDATE verification_codes SET expires_at = now() - interval '1 minute'
      WHERE user_id = (SELECT id FROM users WHERE email = $1)`,
    ['expired-code@example.test'],
  );
  assert.equal((await request('/auth/verify', 'POST', {
    email: 'expired-code@example.test',
    code: pending.body.devCode,
  })).status, 400);

  const failedPayment = await request(`/orders/${order.body.order.id}/pay`, 'POST', {
    simulateUnavailable: true,
  }, owner.token);
  assert.equal(failedPayment.status, 503);

  const reset = await request('/auth/password-reset', 'POST', {
    email: 'owner@example.test',
  });
  assert.equal(reset.status, 200);
  const changed = await request('/auth/password-reset/confirm', 'POST', {
    email: 'owner@example.test',
    code: reset.body.devCode,
    newPassword: 'new-test-user-password',
  });
  assert.equal(changed.status, 200);
  assert.equal((await request('/pets', 'GET', undefined, owner.token)).status, 401);
  const renewedOwnerToken = await login('owner@example.test', 'new-test-user-password');

  for (let attempt = 1; attempt <= 5; attempt++) {
    const failedLogin = await request('/auth/login', 'POST', {
      email: 'owner@example.test',
      password: 'wrong-password',
    });
    assert.equal(failedLogin.status, attempt === 5 ? 423 : 401);
  }
  assert.equal((await request('/auth/login', 'POST', {
    email: 'owner@example.test',
    password: 'new-test-user-password',
  })).status, 423);
  const failedAttempts = await pool.query(
    `SELECT count(*)::integer AS count FROM audit_events
      WHERE actor_id = (SELECT id FROM users WHERE email = $1)
        AND action = 'auth.login_failed'`,
    ['owner@example.test'],
  );
  assert.equal(failedAttempts.rows[0].count, 6);
  const finalEligibility = await request(
    '/account/deletion-eligibility',
    'GET',
    undefined,
    renewedOwnerToken,
  );
  assert.equal(finalEligibility.body.canDelete, true);
  const deleted = await request(
    '/account',
    'DELETE',
    { confirm: true },
    renewedOwnerToken,
  );
  assert.equal(deleted.status, 200);
  assert.equal((await request('/pets', 'GET', undefined, renewedOwnerToken)).status, 401);
  const privacyCheck = await pool.query(
    `SELECT u.email, u.display_name, u.deleted_at,
            (SELECT count(*)::integer FROM user_roles r WHERE r.user_id = u.id) AS role_count,
            (SELECT count(*)::integer FROM health_records h
              JOIN pets p ON p.id = h.pet_id WHERE p.owner_id = u.id) AS health_count,
            (SELECT count(*)::integer FROM pet_access_grants g
              WHERE g.owner_id = u.id AND g.revoked_at IS NULL) AS active_grants,
            (SELECT name FROM pets p WHERE p.owner_id = u.id LIMIT 1) AS pet_name
       FROM users u WHERE u.id = $1`,
    [owner.user.id],
  );
  assert.match(privacyCheck.rows[0].email, /^deleted\+/);
  assert.equal(privacyCheck.rows[0].display_name, 'Deleted user');
  assert.ok(privacyCheck.rows[0].deleted_at);
  assert.equal(privacyCheck.rows[0].role_count, 0);
  assert.equal(privacyCheck.rows[0].health_count, 0);
  assert.equal(privacyCheck.rows[0].active_grants, 0);
  assert.equal(privacyCheck.rows[0].pet_name, 'Deleted pet');
});

async function registerAndVerify(email, role) {
  const registered = await request('/auth/register', 'POST', {
    displayName: email.split('@')[0],
    email,
    phone: `+1202555${Math.floor(1000 + Math.random() * 8999)}`,
    password: 'test-user-password',
    role,
  });
  assert.equal(registered.status, 201);
  const verified = await request('/auth/verify', 'POST', {
    email,
    code: registered.body.devCode,
  });
  assert.equal(verified.status, 200);
  return { token: verified.body.token, user: verified.body.user };
}

async function login(email, password) {
  const result = await request('/auth/login', 'POST', { email, password });
  assert.equal(result.status, 200);
  return result.body.token;
}

async function request(path, method = 'GET', body, token, activeRole = 'owner') {
  const headers = {};
  if (body !== undefined) headers['content-type'] = 'application/json';
  if (token) {
    headers.authorization = `Bearer ${token}`;
    headers['x-active-role'] = activeRole;
  }
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  return {
    status: response.status,
    body: text ? JSON.parse(text) : null,
  };
}
