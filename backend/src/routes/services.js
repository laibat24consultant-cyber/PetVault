import { z } from 'zod';
import { HttpError, asyncRoute } from '../errors.js';
import { inTransaction } from '../database.js';
import { requireVerifiedSupplyRole } from '../security.js';
import { createNotification, writeAuditEvent } from '../notifications.js';
import { assertPetAccess } from '../pet-access.js';

const uuid = z.string().uuid();
const bookingSchema = z.object({
  sitterId: uuid,
  petId: uuid,
  startsAt: z.string().datetime({ offset: true }),
  endsAt: z.string().datetime({ offset: true }),
  arrangement: z.string().trim().min(2).max(500),
  instructions: z.string().trim().max(4000).default(''),
  emergencyName: z.string().trim().min(2).max(120),
  emergencyPhone: z.string().trim().min(7).max(40),
}).strict();
const availabilitySchema = z.object({
  startsAt: z.string().datetime({ offset: true }),
  endsAt: z.string().datetime({ offset: true }),
}).strict();
const appointmentSchema = z.object({
  availabilityId: uuid,
  petId: uuid,
  type: z.string().trim().min(2).max(120),
}).strict();
const sittingUpdateSchema = z.object({
  note: z.string().trim().min(1).max(2000),
}).strict();

export function registerServiceRoutes(publicRouter, router, { pool, requireRole }) {
  publicRouter.get('/veterinary/availability', asyncRoute(async (req, res) => {
    const result = await pool.query(
      `SELECT a.id, a.veterinarian_id, u.display_name AS veterinarian_name,
              a.starts_at, a.ends_at, a.is_booked
         FROM vet_availability a
         JOIN users u ON u.id = a.veterinarian_id
         JOIN kyc_submissions k
           ON k.user_id = u.id AND k.role = 'veterinarian' AND k.status = 'verified'
        WHERE a.is_booked = false AND a.starts_at > now()
          AND u.deleted_at IS NULL
        ORDER BY a.starts_at
        LIMIT 200`,
    );
    res.json({
      availability: result.rows.map((row) => ({
        ...mapRow(row),
        veterinarianName: row.veterinarian_name,
      })),
    });
  }));

  router.get('/sitting/bookings', requireRole('owner', 'sitter'), asyncRoute(async (req, res) => {
    if (req.user.activeRole === 'sitter') await requireVerifiedSupplyRole(req, pool);
    const predicate = req.user.activeRole === 'owner'
      ? 'b.owner_id = $1'
      : 'b.sitter_id = $1';
    const result = await pool.query(
      `SELECT b.id, b.owner_id, b.sitter_id, b.pet_id, b.starts_at, b.ends_at,
              b.arrangement, b.instructions,
              CASE WHEN $2 = 'owner' OR (
                b.status = 'confirmed'
                AND now() >= b.starts_at
                AND now() < b.ends_at
              ) THEN b.emergency_name END AS emergency_name,
              CASE WHEN $2 = 'owner' OR (
                b.status = 'confirmed'
                AND now() >= b.starts_at
                AND now() < b.ends_at
              ) THEN b.emergency_phone END AS emergency_phone,
              b.status, b.created_at, p.name AS pet_name,
              owner.display_name AS owner_name,
                      sitter.display_name AS sitter_name,
                      COALESCE((
                        SELECT json_agg(json_build_object(
                          'id', ci.id, 'note', ci.note, 'created_at', ci.created_at
                        ) ORDER BY ci.created_at)
                          FROM sitter_check_ins ci
                         WHERE ci.booking_id = b.id
                      ), '[]'::json) AS updates
         FROM sitter_bookings b
         JOIN pets p ON p.id = b.pet_id
         JOIN users owner ON owner.id = b.owner_id
         JOIN users sitter ON sitter.id = b.sitter_id
        WHERE ${predicate}
        ORDER BY b.starts_at DESC`,
      [req.user.id, req.user.activeRole],
    );
    res.json({ bookings: result.rows.map((row) => ({
      ...mapRow(row),
      petName: row.pet_name,
      ownerName: row.owner_name,
      sitterName: row.sitter_name,
      updates: row.updates.map(mapRow),
    })) });
  }));

  router.post('/sitting/bookings', requireRole('owner'), asyncRoute(async (req, res) => {
    const body = bookingSchema.parse(req.body);
    const startsAt = new Date(body.startsAt);
    const endsAt = new Date(body.endsAt);
    if (startsAt <= new Date() || endsAt <= startsAt) {
      throw new HttpError(400, 'Choose a future booking interval with a valid end time.');
    }
    const result = await inTransaction(pool, async (client) => {
      const sitter = await client.query(
        `SELECT 1 FROM kyc_submissions
          WHERE user_id = $1 AND role = 'sitter' AND status = 'verified'`,
        [body.sitterId],
      );
      if (!sitter.rowCount) throw new HttpError(404, 'Verified sitter was not found.');
      const pet = await client.query(
        'SELECT 1 FROM pets WHERE id = $1 AND owner_id = $2',
        [body.petId, req.user.id],
      );
      if (!pet.rowCount) throw new HttpError(404, 'Pet was not found.');
      const created = await client.query(
        `INSERT INTO sitter_bookings
           (owner_id, sitter_id, pet_id, starts_at, ends_at, arrangement,
            instructions, emergency_name, emergency_phone)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         RETURNING id, owner_id, sitter_id, pet_id, starts_at, ends_at,
                   arrangement, instructions, emergency_name, emergency_phone,
                   status, created_at`,
        [
          req.user.id,
          body.sitterId,
          body.petId,
          startsAt,
          endsAt,
          body.arrangement,
          body.instructions,
          body.emergencyName,
          body.emergencyPhone,
        ],
      );
      return created.rows[0];
    });
    await createNotification(
      pool,
      body.sitterId,
      'New sitting request',
      'A pet owner requested care during your availability.',
    );
    res.status(201).json({ booking: mapRow(result) });
  }));

  router.patch('/sitting/bookings/:id/status', requireRole('owner', 'sitter'), asyncRoute(async (req, res) => {
    const id = uuid.parse(req.params.id);
    const { status } = z.object({
      status: z.enum(['confirmed', 'declined', 'cancelled', 'complete']),
    }).strict().parse(req.body);
    if (req.user.activeRole === 'sitter') await requireVerifiedSupplyRole(req, pool);
    const owner = req.user.activeRole === 'owner';
    const allowed = owner
      ? status === 'cancelled'
      : status === 'confirmed' || status === 'declined' || status === 'complete';
    if (!allowed) throw new HttpError(403, 'This role cannot set that booking status.');
    const result = await pool.query(
      `UPDATE sitter_bookings
          SET status = $2
        WHERE id = $1 AND ${owner ? 'owner_id' : 'sitter_id'} = $3
          AND (
            (status = 'requested' AND $2 IN ('confirmed', 'declined', 'cancelled'))
            OR (status = 'confirmed' AND $2 IN ('cancelled', 'complete'))
          )
        RETURNING id, owner_id, sitter_id, pet_id, starts_at, ends_at,
                  arrangement, instructions, emergency_name, emergency_phone,
                  status, created_at`,
      [id, status, req.user.id],
    );
    const booking = result.rows[0];
    if (!booking) throw new HttpError(404, 'Booking was not found or cannot be updated.');
    await createNotification(
      pool,
      owner ? booking.sitter_id : booking.owner_id,
      'Sitting booking updated',
      `The booking was ${status}.`,
    );
    res.json({ booking: mapRow(booking) });
  }));

  router.post('/sitting/bookings/:id/check-ins', requireRole('sitter'), asyncRoute(async (req, res) => {
    await requireVerifiedSupplyRole(req, pool);
    const id = uuid.parse(req.params.id);
    const { note } = sittingUpdateSchema.parse(req.body);
    const checkIn = await inTransaction(pool, async (client) => {
      const bookingResult = await client.query(
        `SELECT id, owner_id
           FROM sitter_bookings
          WHERE id = $1 AND sitter_id = $2 AND status = 'confirmed'
            AND now() >= starts_at AND now() < ends_at
          FOR UPDATE`,
        [id, req.user.id],
      );
      const booking = bookingResult.rows[0];
      if (!booking) {
        throw new HttpError(404, 'Active sitting booking was not found.');
      }
      const result = await client.query(
        `INSERT INTO sitter_check_ins (booking_id, sitter_id, note)
         VALUES ($1, $2, $3)
         RETURNING id, booking_id, sitter_id, note, created_at`,
        [id, req.user.id, note],
      );
      return { checkIn: result.rows[0], ownerId: booking.owner_id };
    });
    await createNotification(
      pool,
      checkIn.ownerId,
      'Sitting care update',
      'Your sitter shared an update during the booking.',
    );
    await writeAuditEvent(pool, {
      actorId: req.user.id,
      action: 'sitting.check_in_posted',
      resourceType: 'sitter_booking',
      resourceId: id,
    });
    res.status(201).json({ checkIn: mapRow(checkIn.checkIn) });
  }));

  router.post('/veterinary/availability', requireRole('veterinarian'), asyncRoute(async (req, res) => {
    await requireVerifiedSupplyRole(req, pool);
    const body = availabilitySchema.parse(req.body);
    const startsAt = new Date(body.startsAt);
    const endsAt = new Date(body.endsAt);
    if (startsAt <= new Date() || endsAt <= startsAt ||
        endsAt.getTime() - startsAt.getTime() > 8 * 60 * 60 * 1000) {
      throw new HttpError(400, 'Availability must be a future interval no longer than 8 hours.');
    }
    const result = await pool.query(
      `INSERT INTO vet_availability (veterinarian_id, starts_at, ends_at)
       VALUES ($1, $2, $3)
       RETURNING id, veterinarian_id, starts_at, ends_at, is_booked`,
      [req.user.id, startsAt, endsAt],
    );
    res.status(201).json({ availability: mapRow(result.rows[0]) });
  }));

  router.get('/veterinary/appointments', requireRole('owner', 'veterinarian'), asyncRoute(async (req, res) => {
    if (req.user.activeRole === 'veterinarian') await requireVerifiedSupplyRole(req, pool);
    const predicate = req.user.activeRole === 'owner'
      ? 'a.owner_id = $1'
      : 'a.veterinarian_id = $1';
    const result = await pool.query(
      `SELECT a.id, a.veterinarian_id, a.owner_id, a.pet_id,
              a.availability_id, a.appointment_type, a.status,
              a.consultation_notes, a.created_at,
              v.starts_at, v.ends_at, p.name AS pet_name,
              owner.display_name AS owner_name,
              vet.display_name AS veterinarian_name
         FROM vet_appointments a
         JOIN vet_availability v ON v.id = a.availability_id
         JOIN pets p ON p.id = a.pet_id
         JOIN users owner ON owner.id = a.owner_id
         JOIN users vet ON vet.id = a.veterinarian_id
        WHERE ${predicate}
        ORDER BY v.starts_at DESC`,
      [req.user.id],
    );
    res.json({ appointments: result.rows.map((row) => ({
      ...mapRow(row),
      petName: row.pet_name,
      ownerName: row.owner_name,
      veterinarianName: row.veterinarian_name,
    })) });
  }));

  router.post('/veterinary/appointments', requireRole('owner'), asyncRoute(async (req, res) => {
    const body = appointmentSchema.parse(req.body);
    const appointment = await inTransaction(pool, async (client) => {
      const availability = await client.query(
        `SELECT a.id, a.veterinarian_id, a.starts_at, a.ends_at,
                u.display_name AS veterinarian_name
           FROM vet_availability a
           JOIN users u ON u.id = a.veterinarian_id
           JOIN kyc_submissions k
             ON k.user_id = u.id AND k.role = 'veterinarian' AND k.status = 'verified'
          WHERE a.id = $1 AND a.is_booked = false AND a.starts_at > now()
          FOR UPDATE OF a`,
        [body.availabilityId],
      );
      const slot = availability.rows[0];
      if (!slot) throw new HttpError(404, 'Available veterinarian slot was not found.');
      const pet = await client.query(
        'SELECT 1 FROM pets WHERE id = $1 AND owner_id = $2',
        [body.petId, req.user.id],
      );
      if (!pet.rowCount) throw new HttpError(404, 'Pet was not found.');
      const result = await client.query(
        `INSERT INTO vet_appointments
           (veterinarian_id, owner_id, pet_id, availability_id, appointment_type)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, veterinarian_id, owner_id, pet_id, availability_id,
                   appointment_type, status, consultation_notes, created_at`,
        [slot.veterinarian_id, req.user.id, body.petId, slot.id, body.type],
      );
      await client.query(
        'UPDATE vet_availability SET is_booked = true WHERE id = $1',
        [slot.id],
      );
      return {
        ...result.rows[0],
        starts_at: slot.starts_at,
        ends_at: slot.ends_at,
        veterinarian_name: slot.veterinarian_name,
      };
    });
    await createNotification(
      pool,
      appointment.veterinarian_id,
      'New veterinary appointment',
      'A pet owner booked one of your available appointment times.',
    );
    res.status(201).json({ appointment: mapRow(appointment) });
  }));

  router.post('/veterinary/appointments/:id/notes', requireRole('veterinarian'), asyncRoute(async (req, res) => {
    await requireVerifiedSupplyRole(req, pool);
    const id = uuid.parse(req.params.id);
    const body = z.object({
      notes: z.string().trim().min(1).max(4000),
      followUp: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
    }).strict().parse(req.body);
    const appointment = await inTransaction(pool, async (client) => {
      const current = await client.query(
        `SELECT id, veterinarian_id, owner_id, pet_id, availability_id,
                appointment_type, status
           FROM vet_appointments
          WHERE id = $1 AND veterinarian_id = $2 AND status = 'Confirmed'
          FOR UPDATE`,
        [id, req.user.id],
      );
      const row = current.rows[0];
      if (!row) throw new HttpError(404, 'Active appointment was not found.');
      await assertPetAccess(client, req, row.pet_id, 'health');
      const updated = await client.query(
        `UPDATE vet_appointments
            SET consultation_notes = $2, status = 'Complete'
          WHERE id = $1
          RETURNING id, veterinarian_id, owner_id, pet_id, availability_id,
                    appointment_type, status, consultation_notes, created_at`,
        [id, body.notes],
      );
      await client.query(
        `INSERT INTO health_records
           (pet_id, created_by, title, record_type, provider, record_date,
            next_due_at, vet_name)
         VALUES ($1, $2, 'Consultation notes', 'consultation', $3,
                 CURRENT_DATE, $4, $3)`,
        [row.pet_id, req.user.id, req.user.display_name, body.followUp ?? null],
      );
      return updated.rows[0];
    });
    await createNotification(
      pool,
      appointment.owner_id,
      'Appointment notes are available',
      'Your veterinarian added consultation notes.',
    );
    await writeAuditEvent(pool, {
      actorId: req.user.id,
      action: 'appointment.completed',
      resourceType: 'vet_appointment',
      resourceId: id,
    });
    res.json({ appointment: mapRow(appointment) });
  }));

  router.get('/notifications', asyncRoute(async (req, res) => {
    const result = await pool.query(
      `SELECT id, user_id, title, body, read_at, created_at
         FROM notifications
        WHERE user_id = $1
        ORDER BY created_at DESC
        LIMIT 200`,
      [req.user.id],
    );
    res.json({ notifications: result.rows.map(mapRow) });
  }));

  router.patch('/notifications/:id/read', asyncRoute(async (req, res) => {
    const id = uuid.parse(req.params.id);
    const result = await pool.query(
      `UPDATE notifications SET read_at = COALESCE(read_at, now())
        WHERE id = $1 AND user_id = $2
        RETURNING id, user_id, title, body, read_at, created_at`,
      [id, req.user.id],
    );
    if (!result.rows[0]) throw new HttpError(404, 'Notification was not found.');
    res.json({ notification: mapRow(result.rows[0]) });
  }));

  router.post('/support/requests', asyncRoute(async (req, res) => {
    const body = z.object({
      topic: z.string().trim().min(2).max(160),
      message: z.string().trim().min(5).max(5000),
    }).strict().parse(req.body);
    const result = await pool.query(
      `INSERT INTO support_requests (user_id, topic, message)
       VALUES ($1, $2, $3)
       RETURNING id, user_id, topic, message, status, created_at`,
      [req.user.id, body.topic, body.message],
    );
    res.status(201).json({ request: mapRow(result.rows[0]) });
  }));

  router.get('/admin/support/requests', requireRole('admin'), asyncRoute(async (req, res) => {
    const query = z.object({
      page: z.coerce.number().int().min(1).default(1),
      pageSize: z.coerce.number().int().min(1).max(100).default(25),
      q: z.string().trim().max(120).default(''),
      status: z.enum(['open', 'in_progress', 'resolved']).optional(),
    }).strict().parse(req.query);
    const where = [];
    const values = [];
    if (query.status) {
      values.push(query.status);
      where.push(`s.status = $${values.length}`);
    }
    if (query.q) {
      values.push(`%${query.q}%`);
      const parameter = `$${values.length}`;
      where.push(`(s.topic ILIKE ${parameter}
        OR s.message ILIKE ${parameter}
        OR u.display_name ILIKE ${parameter}
        OR u.email ILIKE ${parameter})`);
    }
    const predicate = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const count = await pool.query(
      `SELECT count(*)::int AS total
         FROM support_requests s
         LEFT JOIN users u ON u.id = s.user_id
         ${predicate}`,
      values,
    );
    const result = await pool.query(
      `SELECT s.id, s.user_id, s.topic, s.message, s.status, s.created_at,
              u.email, u.display_name
         FROM support_requests s
         LEFT JOIN users u ON u.id = s.user_id
         ${predicate}
        ORDER BY s.created_at DESC
        LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, query.pageSize, (query.page - 1) * query.pageSize],
    );
    const requests = result.rows.map((row) => ({
      ...mapRow(row),
      email: row.email,
      displayName: row.display_name,
    }));
    res.json({
      items: requests,
      requests,
      page: query.page,
      pageSize: query.pageSize,
      total: count.rows[0].total,
      pages: Math.ceil(count.rows[0].total / query.pageSize),
    });
  }));

  router.patch('/admin/support/requests/:id', requireRole('admin'), asyncRoute(async (req, res) => {
    const id = uuid.parse(req.params.id);
    const { status } = z.object({
      status: z.enum(['open', 'in_progress', 'resolved']),
    }).strict().parse(req.body);
    const result = await pool.query(
      `UPDATE support_requests SET status = $2
        WHERE id = $1
        RETURNING id, user_id, topic, message, status, created_at`,
      [id, status],
    );
    if (!result.rows[0]) throw new HttpError(404, 'Support request was not found.');
    if (result.rows[0].user_id) {
      await createNotification(
        pool,
        result.rows[0].user_id,
        'Support request updated',
        `Your support request is ${status.replace('_', ' ')}.`,
      );
    }
    await writeAuditEvent(pool, {
      actorId: req.user.id,
      action: 'support_request.updated',
      resourceType: 'support_request',
      resourceId: id,
      metadata: { status },
    });
    res.json({ request: mapRow(result.rows[0]) });
  }));
}

function mapRow(row) {
  return Object.fromEntries(
    Object.entries(row).map(([key, value]) => [
      key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase()),
      value instanceof Date ? value.toISOString() : value,
    ]),
  );
}
