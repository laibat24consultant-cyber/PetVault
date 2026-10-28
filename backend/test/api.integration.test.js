import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import test from 'node:test';

const apiUrl = process.env.PETVAULT_API_URL ?? 'http://127.0.0.1:3000/api';

async function request(path, { method = 'GET', body, token, role } = {}) {
  const response = await fetch(`${apiUrl}${path}`, {
    method,
    headers: {
      ...(body ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(role ? { 'X-Active-Role': role } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const bodyText = response.status === 204 ? '' : await response.text();
  let payload = {};
  if (bodyText) {
    try {
      payload = JSON.parse(bodyText);
    } catch {
      payload = { error: bodyText };
    }
  }
  return { status: response.status, payload };
}

test('registration, pet health records, and owner privacy work end to end', async () => {
  const suffix = randomUUID();
  const password = 'PetVaultIntegration123!';

  async function createVerifiedUser(label) {
    const email = `${label}-${suffix}@petvault.test`;
    const registration = await request('/auth/register', {
      method: 'POST',
      body: {
        displayName: `Integration ${label}`,
        email,
        phone: '5550100200',
        password,
      },
    });
    assert.equal(registration.status, 201);
    assert.match(registration.payload.devCode ?? '', /^\d{6}$/,
      'run integration tests against a development API with DEV_AUTH_CODES enabled');

    const verification = await request('/auth/verify', {
      method: 'POST',
      body: { email, code: registration.payload.devCode },
    });
    assert.equal(verification.status, 200);
    assert.ok(verification.payload.token);
    return verification.payload.token;
  }

  const ownerToken = await createVerifiedUser('owner');
  const otherOwnerToken = await createVerifiedUser('other');

  const petResponse = await request('/pets', {
    method: 'POST',
    token: ownerToken,
    body: {
      name: 'Integration Pet',
      species: 'Dog',
      breed: 'Test mix',
      age: '2 years',
      sex: 'Female',
      weightKg: 12.5,
      microchip: '',
    },
  });
  assert.equal(petResponse.status, 201);
  const petId = petResponse.payload.pet.id;
  assert.ok(petId);

  const recordResponse = await request(`/pets/${petId}/health-records`, {
    method: 'POST',
    token: ownerToken,
    body: {
      title: 'Integration vaccination',
      type: 'Vaccination',
      provider: 'Test clinic',
      date: '2026-10-21',
      nextDueAt: '2027-10-21',
      attachmentName: 'vaccination.pdf',
    },
  });
  assert.equal(recordResponse.status, 201);
  assert.equal(recordResponse.payload.record.attachmentName, 'vaccination.pdf');

  const visibleRecords = await request(`/pets/${petId}/health-records`, {
    token: ownerToken,
  });
  assert.equal(visibleRecords.status, 200);
  assert.ok(visibleRecords.payload.records.some(
    (record) => record.id === recordResponse.payload.record.id,
  ));

  const privateRecords = await request(`/pets/${petId}/health-records`, {
    token: otherOwnerToken,
  });
  assert.equal(privateRecords.status, 403);
});

test('listing risk flags are explainable and admin moderation is enforced', async () => {
  const suffix = randomUUID().slice(0, 8);
  const sellerLogin = await request('/auth/login', {
    method: 'POST',
    body: { email: 'seller@petvault.demo', password: 'demo1234' },
  });

  assert.equal(sellerLogin.status, 200);

  const listingInput = {
    title: `Risk benchmark ${suffix}`,
    species: 'Dog',
    breed: 'Test mix',
    city: 'Test City',
    price: 1000,
    age: '8 weeks',
    imageUrl: '',
    healthNotes: '',
  };
  const originalListing = await request('/listings', {
    method: 'POST',
    token: sellerLogin.payload.token,
    role: 'seller',
    body: listingInput,
  });
  assert.equal(originalListing.status, 201);
  const submitted = await request('/listings', {
    method: 'POST',
    token: sellerLogin.payload.token,
    role: 'seller',
    body: listingInput,
  });
  assert.equal(submitted.status, 201);

  const adminLogin = await request('/auth/login', {
    method: 'POST',
    body: { email: 'admin@petvault.demo', password: 'demo1234' },
  });
  assert.equal(adminLogin.status, 200);

  const queue = await request('/admin/listings/moderation', {
    token: adminLogin.payload.token,
  });
  assert.equal(queue.status, 200);
  const flagged = queue.payload.listings.find(
    (listing) => listing.id === submitted.payload.listing.id,
  );
  assert.ok(flagged, 'the pending listing should appear in the admin queue');
  assert.ok(flagged.riskScore >= 35);
  assert.ok(flagged.riskFactors.some((factor) => factor.includes('same normalized title')));

  const unauthorized = await request('/admin/listings/moderation', {
    token: sellerLogin.payload.token,
    role: 'seller',
  });
  assert.equal(unauthorized.status, 403);

  const decision = await request(
    `/admin/listings/${flagged.id}/moderation`,
    {
      method: 'PATCH',
      token: adminLogin.payload.token,
      body: { status: 'active', reviewNote: 'Human review approved.' },
    },
  );
  assert.equal(decision.status, 200);
  assert.equal(decision.payload.listing.status, 'active');

  const emptyQueue = await request('/admin/listings/moderation', {
    token: adminLogin.payload.token,
  });
  assert.equal(emptyQueue.status, 200);
  assert.ok(
    !emptyQueue.payload.listings.some((listing) => listing.id === flagged.id),
    'an approved listing with no open reports should leave the moderation queue',
  );
});

test('mock checkout charges only on approval and releases stock on provider failure', async () => {
  const login = await request('/auth/login', {
    method: 'POST',
    body: { email: 'owner@petvault.demo', password: 'demo1234' },
  });
  assert.equal(login.status, 200);
  const vendorLogin = await request('/auth/login', {
    method: 'POST',
    body: { email: 'vendor@petvault.demo', password: 'demo1234' },
  });
  assert.equal(vendorLogin.status, 200);
  const productResponse = await request('/products', {
    method: 'POST',
    token: vendorLogin.payload.token,
    role: 'vendor',
    body: {
      name: `Payment integration product ${randomUUID()}`,
      price: 1250,
      stock: 5,
      imageUrl: '',
    },
  });
  assert.equal(productResponse.status, 201);
  const product = productResponse.payload.product;

  const createOrder = async () => request('/orders', {
    method: 'POST',
    token: login.payload.token,
    body: { items: [{ productId: product.id, quantity: 1 }] },
  });

  const approvedOrder = await createOrder();
  assert.equal(approvedOrder.status, 201);
  assert.equal(approvedOrder.payload.order.paymentStatus, 'pending');
  const paid = await request(`/orders/${approvedOrder.payload.order.id}/pay`, {
    method: 'POST',
    token: login.payload.token,
    body: {},
  });
  assert.equal(paid.status, 200);
  assert.equal(paid.payload.order.paymentStatus, 'paid');

  const failedOrder = await createOrder();
  assert.equal(failedOrder.status, 201);
  const failedPayment = await request(
    `/orders/${failedOrder.payload.order.id}/pay`,
    {
      method: 'POST',
      token: login.payload.token,
      body: { simulateUnavailable: true },
    },
  );
  assert.equal(failedPayment.status, 503);

  const orders = await request('/orders', { token: login.payload.token });
  const rejectedOrder = orders.payload.orders.find(
    (order) => order.id === failedOrder.payload.order.id,
  );
  assert.equal(rejectedOrder.status, 'Cancelled');
  assert.equal(rejectedOrder.paymentStatus, 'failed');

  const remainingProducts = await request('/products');
  const refreshedProduct = remainingProducts.payload.products.find(
    (item) => item.id === product.id,
  );
  assert.equal(refreshedProduct.stock, product.stock - 1);
});
