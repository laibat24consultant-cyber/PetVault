import { z } from 'zod';
import { HttpError, asyncRoute } from '../errors.js';
import { requireVerifiedSupplyRole } from '../security.js';
import { createNotification, writeAuditEvent } from '../notifications.js';
import { inTransaction } from '../database.js';

const uuid = z.string().uuid();
const listingSchema = z.object({
  title: z.string().trim().min(4).max(160),
  species: z.string().trim().min(2).max(80),
  breed: z.string().trim().min(1).max(120),
  city: z.string().trim().min(2).max(120),
  price: z.number().positive().max(1_000_000),
  age: z.string().trim().min(1).max(80),
  imageUrl: z.string().trim().max(2000).default(''),
  healthNotes: z.string().trim().max(4000).default(''),
}).strict();
const favoriteSchema = z.object({ favorite: z.boolean() }).strict();
const reportSchema = z.object({ reason: z.string().trim().min(5).max(1000) }).strict();
const visitSchema = z.object({
  scheduledAt: z.string().datetime({ offset: true }),
  message: z.string().trim().max(2000).default(''),
}).strict();
const visitStatusSchema = z.object({
  status: z.enum(['confirmed', 'declined', 'cancelled']),
}).strict();
const messageSchema = z.object({
  body: z.string().trim().min(1).max(5000),
}).strict();
const conversationSchema = z.object({
  listingId: z.string().uuid(),
  body: z.string().trim().min(1).max(5000),
}).strict();
const allowedSpecies = new Set([
  'dog', 'cat', 'rabbit', 'bird', 'fish', 'guinea pig', 'hamster',
  'turtle', 'tortoise',
]);
const prohibitedSpecies = new Set([
  'monkey', 'primate', 'wolf', 'wolfdog', 'fox', 'wild cat', 'big cat',
  'lion', 'tiger', 'bear', 'crocodile', 'alligator', 'venomous snake',
  'raccoon', 'skunk', 'otter', 'bat',
]);

export function registerMarketplaceRoutes(publicRouter, router, { pool, requireRole }) {
  publicRouter.get('/listings', asyncRoute(async (req, res) => {
    const query = listingFilters(req.query);
    const values = [];
    const where = ["l.status = 'active'"];
    if (query.search) {
      values.push(`%${query.search}%`);
      where.push(`(l.title ILIKE $${values.length} OR l.species ILIKE $${values.length}
                   OR l.breed ILIKE $${values.length} OR l.city ILIKE $${values.length})`);
    }
    if (query.species) {
      values.push(query.species);
      where.push(`lower(l.species) = $${values.length}`);
    }
    if (query.city) {
      values.push(`%${query.city}%`);
      where.push(`l.city ILIKE $${values.length}`);
    }
    if (query.minPrice !== undefined) {
      values.push(query.minPrice);
      where.push(`l.price >= $${values.length}`);
    }
    if (query.maxPrice !== undefined) {
      values.push(query.maxPrice);
      where.push(`l.price <= $${values.length}`);
    }
    values.push(query.limit);
    const result = await pool.query(
      `SELECT l.id, l.seller_id, u.display_name AS seller_name,
              l.title, l.species, l.breed, l.city, l.price, l.age,
              l.image_url, l.health_notes, l.status, l.created_at, l.updated_at
         FROM listings l
         JOIN users u ON u.id = l.seller_id
        WHERE ${where.join(' AND ')}
          AND u.deleted_at IS NULL
        ORDER BY l.created_at DESC
        LIMIT $${values.length}`,
      values,
    );
    res.json({ listings: mapListings(result.rows) });
  }));

  publicRouter.get('/providers', asyncRoute(async (req, res) => {
    const role = z.enum(['sitter', 'veterinarian']).parse(req.query.role);
    const result = await pool.query(
      `SELECT u.id, u.display_name, r.role,
              k.status AS verification_status
         FROM users u
         JOIN user_roles r ON r.user_id = u.id AND r.role = $1
         JOIN kyc_submissions k ON k.user_id = u.id AND k.role = r.role
        WHERE u.deleted_at IS NULL
          AND u.email_verified_at IS NOT NULL
          AND k.status = 'verified'
        ORDER BY u.display_name`,
      [role],
    );
    res.json({
      providers: result.rows.map((row) => ({
        id: row.id,
        displayName: row.display_name,
        role: row.role,
        verified: row.verification_status === 'verified',
      })),
    });
  }));

  router.get('/listings/mine', requireRole('seller'), asyncRoute(async (req, res) => {
    await requireVerifiedSupplyRole(req, pool);
    const result = await pool.query(
      `SELECT l.id, l.seller_id, u.display_name AS seller_name,
              l.title, l.species, l.breed, l.city, l.price, l.age,
              l.image_url, l.health_notes, l.status, l.created_at, l.updated_at
         FROM listings l JOIN users u ON u.id = l.seller_id
        WHERE l.seller_id = $1
        ORDER BY l.created_at DESC`,
      [req.user.id],
    );
    res.json({ listings: mapListings(result.rows) });
  }));

  router.post('/listings', requireRole('seller'), asyncRoute(async (req, res) => {
    await requireVerifiedSupplyRole(req, pool);
    const body = listingSchema.parse(req.body);
    const species = body.species.toLowerCase();
    if (prohibitedSpecies.has(species)) {
      throw new HttpError(400, 'This species is not allowed on the marketplace.');
    }
    if (!allowedSpecies.has(species)) {
      throw new HttpError(400, 'Select an allowed domestic companion species.');
    }
    const result = await pool.query(
      `INSERT INTO listings
         (seller_id, title, species, breed, city, price, age, image_url,
          health_notes, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'pending_review')
       RETURNING id, seller_id, title, species, breed, city, price, age,
                 image_url, health_notes, status, created_at, updated_at`,
      [
        req.user.id,
        body.title,
        species,
        body.breed,
        body.city,
        body.price,
        body.age,
        body.imageUrl,
        body.healthNotes,
      ],
    );
    await writeAuditEvent(pool, {
      actorId: req.user.id,
      action: 'listing.submitted',
      resourceType: 'listing',
      resourceId: result.rows[0].id,
    });
    res.status(201).json({ listing: mapListing(result.rows[0], req.user.display_name) });
  }));

  router.patch('/listings/:id', requireRole('seller'), asyncRoute(async (req, res) => {
    await requireVerifiedSupplyRole(req, pool);
    const id = uuid.parse(req.params.id);
    const body = listingSchema.parse(req.body);
    const species = body.species.toLowerCase();
    if (prohibitedSpecies.has(species) || !allowedSpecies.has(species)) {
      throw new HttpError(400, 'This species is not allowed on the marketplace.');
    }
    const result = await pool.query(
      `UPDATE listings
          SET title = $3, species = $4, breed = $5, city = $6, price = $7,
              age = $8, image_url = $9, health_notes = $10,
              status = 'pending_review', updated_at = now()
        WHERE id = $1 AND seller_id = $2 AND status <> 'sold'
        RETURNING id, seller_id, title, species, breed, city, price, age,
                  image_url, health_notes, status, created_at, updated_at`,
      [
        id,
        req.user.id,
        body.title,
        species,
        body.breed,
        body.city,
        body.price,
        body.age,
        body.imageUrl,
        body.healthNotes,
      ],
    );
    if (!result.rows[0]) throw new HttpError(404, 'Editable listing was not found.');
    res.json({ listing: mapListing(result.rows[0], req.user.display_name) });
  }));

  router.get('/admin/listings/moderation', requireRole('admin'), asyncRoute(async (req, res) => {
    const result = await pool.query(
      `SELECT l.id, l.seller_id, u.display_name AS seller_name,
              l.title, l.species, l.breed, l.city, l.price, l.age,
              l.image_url, l.health_notes, l.status, l.created_at, l.updated_at,
              (SELECT count(*) FROM listing_reports r
                WHERE r.listing_id = l.id AND r.status = 'open') AS open_reports,
              (SELECT count(*) FROM listings own
                WHERE own.seller_id = l.seller_id
                  AND own.created_at > now() - interval '30 days') AS seller_volume,
              (SELECT count(*) FROM listings duplicate
                WHERE lower(regexp_replace(duplicate.title, '[^a-z0-9]', '', 'g'))
                    = lower(regexp_replace(l.title, '[^a-z0-9]', '', 'g'))
                  AND duplicate.id <> l.id) AS duplicate_titles,
              (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY comparable.price)
                 FROM listings comparable
                WHERE comparable.status = 'active'
                  AND lower(comparable.species) = lower(l.species)) AS comparable_median
         FROM listings l
         JOIN users u ON u.id = l.seller_id
        WHERE l.status = 'pending_review'
        ORDER BY l.created_at ASC`,
    );
    res.json({
      listings: result.rows.map((row) => mapListing(row, row.seller_name, {
        openReports: Number(row.open_reports),
        sellerVolume: Number(row.seller_volume),
        duplicateTitles: Number(row.duplicate_titles),
        comparableMedian: row.comparable_median == null
          ? null
          : Number(row.comparable_median),
      })),
    });
  }));

  router.patch('/admin/listings/:id/moderation', requireRole('admin'), asyncRoute(async (req, res) => {
    const id = uuid.parse(req.params.id);
    const body = z.object({
      status: z.enum(['active', 'rejected']),
      reviewNote: z.string().trim().max(1000).default(''),
    }).strict().parse(req.body);
    const result = await pool.query(
      `UPDATE listings
          SET status = $2, moderation_note = NULLIF($4, ''),
              reviewed_by = $3, reviewed_at = now(), updated_at = now()
        WHERE id = $1 AND status = 'pending_review'
        RETURNING id, seller_id, title, species, breed, city, price, age,
                  image_url, health_notes, status, moderation_note,
                  reviewed_by, reviewed_at, created_at, updated_at`,
      [id, body.status, req.user.id, body.reviewNote],
    );
    const listing = result.rows[0];
    if (!listing) throw new HttpError(404, 'Pending listing was not found.');
    await createNotification(
      pool,
      listing.seller_id,
      body.status === 'active' ? 'Listing approved' : 'Listing not approved',
      body.reviewNote || (body.status === 'active'
        ? 'Your listing is now visible in the marketplace.'
        : 'Your listing was not approved. Review the marketplace rules.'),
    );
    await writeAuditEvent(pool, {
      actorId: req.user.id,
      action: `listing.moderated.${body.status}`,
      resourceType: 'listing',
      resourceId: id,
      metadata: { reviewNote: body.reviewNote },
    });
    res.json({ listing: mapListing(listing) });
  }));

  router.get('/admin/listing-reports', requireRole('admin'), asyncRoute(async (req, res) => {
    const result = await pool.query(
      `SELECT r.id, r.listing_id, r.reporter_id, r.reason, r.status,
              r.created_at, r.reviewed_at, r.reviewed_by,
              l.title AS listing_title, reporter.display_name AS reporter_name
         FROM listing_reports r
         JOIN listings l ON l.id = r.listing_id
         JOIN users reporter ON reporter.id = r.reporter_id
        ORDER BY CASE WHEN r.status = 'open' THEN 0 ELSE 1 END, r.created_at DESC
        LIMIT 500`,
    );
    res.json({
      reports: result.rows.map((row) => ({
        ...mapRow(row),
        listingTitle: row.listing_title,
        reporterName: row.reporter_name,
      })),
    });
  }));

  router.patch('/admin/listing-reports/:id', requireRole('admin'), asyncRoute(async (req, res) => {
    const id = uuid.parse(req.params.id);
    const { status } = z.object({
      status: z.enum(['reviewed', 'dismissed']),
    }).strict().parse(req.body);
    const result = await pool.query(
      `UPDATE listing_reports
          SET status = $2, reviewed_by = $3, reviewed_at = now()
        WHERE id = $1 AND status = 'open'
        RETURNING id, listing_id, reporter_id, reason, status,
                  created_at, reviewed_at, reviewed_by`,
      [id, status, req.user.id],
    );
    if (!result.rows[0]) throw new HttpError(404, 'Open listing report was not found.');
    await writeAuditEvent(pool, {
      actorId: req.user.id,
      action: `listing_report.${status}`,
      resourceType: 'listing_report',
      resourceId: id,
    });
    res.json({ report: mapRow(result.rows[0]) });
  }));

  router.get('/listings/favorites', requireRole('owner'), asyncRoute(async (req, res) => {
    const result = await pool.query(
      `SELECT l.id, l.seller_id, u.display_name AS seller_name,
              l.title, l.species, l.breed, l.city, l.price, l.age,
              l.image_url, l.health_notes, l.status, l.created_at, l.updated_at
         FROM listing_favorites f
         JOIN listings l ON l.id = f.listing_id
         JOIN users u ON u.id = l.seller_id
        WHERE f.user_id = $1 AND l.status = 'active'
        ORDER BY f.created_at DESC`,
      [req.user.id],
    );
    res.json({ listings: mapListings(result.rows) });
  }));

  router.put('/listings/:id/favorite', requireRole('owner'), asyncRoute(async (req, res) => {
    const id = uuid.parse(req.params.id);
    const { favorite } = favoriteSchema.parse(req.body);
    if (favorite) {
      const listing = await pool.query(
        `INSERT INTO listing_favorites (listing_id, user_id)
         SELECT id, $2 FROM listings WHERE id = $1 AND status = 'active'
         ON CONFLICT DO NOTHING
         RETURNING listing_id`,
        [id, req.user.id],
      );
      if (listing.rowCount === 0) {
        const exists = await pool.query(
          "SELECT 1 FROM listings WHERE id = $1 AND status = 'active'",
          [id],
        );
        if (exists.rowCount === 0) throw new HttpError(404, 'Active listing was not found.');
      }
    } else {
      await pool.query(
        'DELETE FROM listing_favorites WHERE listing_id = $1 AND user_id = $2',
        [id, req.user.id],
      );
    }
    res.json({ favorite });
  }));

  router.post('/listings/:id/reports', requireRole('owner'), asyncRoute(async (req, res) => {
    const id = uuid.parse(req.params.id);
    const body = reportSchema.parse(req.body);
    const result = await pool.query(
      `INSERT INTO listing_reports (listing_id, reporter_id, reason)
       SELECT id, $2, $3 FROM listings WHERE id = $1 AND status = 'active'
       ON CONFLICT (listing_id, reporter_id) WHERE status = 'open' DO NOTHING
       RETURNING id, listing_id, reporter_id, reason, status, created_at`,
      [id, req.user.id, body.reason],
    );
    if (!result.rows[0]) {
      const listing = await pool.query(
        "SELECT 1 FROM listings WHERE id = $1 AND status = 'active'",
        [id],
      );
      if (!listing.rowCount) throw new HttpError(404, 'Active listing was not found.');
      throw new HttpError(409, 'You have already reported this listing.');
    }
    await writeAuditEvent(pool, {
      actorId: req.user.id,
      action: 'listing.reported',
      resourceType: 'listing',
      resourceId: id,
    });
    res.status(201).json({ report: mapRow(result.rows[0]) });
  }));

  router.post('/listings/:id/visit-requests', requireRole('owner'), asyncRoute(async (req, res) => {
    const listingId = uuid.parse(req.params.id);
    const body = visitSchema.parse(req.body);
    const scheduledAt = new Date(body.scheduledAt);
    if (scheduledAt <= new Date()) {
      throw new HttpError(400, 'Choose a future visit time.');
    }
    const result = await pool.query(
      `INSERT INTO visit_requests (listing_id, buyer_id, scheduled_at, message)
       SELECT id, $2, $3, $4
         FROM listings
        WHERE id = $1 AND status = 'active' AND seller_id <> $2
       RETURNING id, listing_id, buyer_id, scheduled_at, message, status,
                 created_at, updated_at`,
      [listingId, req.user.id, scheduledAt, body.message],
    );
    const visit = result.rows[0];
    if (!visit) throw new HttpError(404, 'Available listing was not found.');
    const seller = await pool.query('SELECT seller_id FROM listings WHERE id = $1', [listingId]);
    await createNotification(
      pool,
      seller.rows[0].seller_id,
      'Pet visit requested',
      'A buyer requested a visit for your listing.',
    );
    res.status(201).json({ visitRequest: mapRow(visit) });
  }));

  router.get('/visit-requests', requireRole('owner', 'seller'), asyncRoute(async (req, res) => {
    if (req.user.activeRole === 'seller') await requireVerifiedSupplyRole(req, pool);
    const ownerFilter = req.user.activeRole === 'owner'
      ? 'v.buyer_id = $1'
      : 'l.seller_id = $1';
    const result = await pool.query(
      `SELECT v.id, v.listing_id, v.buyer_id, v.scheduled_at, v.message,
              v.status, v.created_at, v.updated_at,
              l.title, l.species, l.breed, l.city, l.seller_id,
              buyer.display_name AS buyer_name,
              seller.display_name AS seller_name
         FROM visit_requests v
         JOIN listings l ON l.id = v.listing_id
         JOIN users buyer ON buyer.id = v.buyer_id
         JOIN users seller ON seller.id = l.seller_id
        WHERE ${ownerFilter}
        ORDER BY v.scheduled_at DESC`,
      [req.user.id],
    );
    res.json({ visitRequests: mapRows(result.rows) });
  }));

  router.patch('/visit-requests/:id/status', requireRole('owner', 'seller'), asyncRoute(async (req, res) => {
    const id = uuid.parse(req.params.id);
    const { status } = visitStatusSchema.parse(req.body);
    if (req.user.activeRole === 'seller') {
      await requireVerifiedSupplyRole(req, pool);
    }
    const allowed = req.user.activeRole === 'owner'
      ? status === 'cancelled'
      : status === 'confirmed' || status === 'declined';
    if (!allowed) throw new HttpError(403, 'This role cannot set that visit-request status.');
    const result = await pool.query(
      `UPDATE visit_requests v
          SET status = $2, updated_at = now()
         FROM listings l
        WHERE v.id = $1 AND v.listing_id = l.id
          AND ${
            req.user.activeRole === 'owner'
              ? "v.status IN ('requested', 'confirmed')"
              : "v.status = 'requested'"
          }
          AND ${req.user.activeRole === 'owner' ? 'v.buyer_id' : 'l.seller_id'} = $3
        RETURNING v.id, v.listing_id, v.buyer_id, v.scheduled_at, v.message,
                  v.status, v.created_at, v.updated_at`,
      [id, status, req.user.id],
    );
    if (!result.rows[0]) throw new HttpError(404, 'Pending visit request was not found.');
    const notifyUser = req.user.activeRole === 'owner'
      ? (await pool.query(
          'SELECT seller_id FROM listings WHERE id = $1',
          [result.rows[0].listing_id],
        )).rows[0].seller_id
      : result.rows[0].buyer_id;
    await createNotification(
      pool,
      notifyUser,
      'Visit request updated',
      `Your visit request was ${status}.`,
    );
    res.json({ visitRequest: mapRow(result.rows[0]) });
  }));

  router.post('/conversations', requireRole('owner'), asyncRoute(async (req, res) => {
    const { listingId, body } = conversationSchema.parse(req.body);
    const conversation = await inTransaction(pool, async (client) => {
      const listing = await client.query(
        `SELECT id, seller_id, title FROM listings
          WHERE id = $1 AND status = 'active'
          FOR SHARE`,
        [listingId],
      );
      if (!listing.rows[0] || listing.rows[0].seller_id === req.user.id) {
        throw new HttpError(404, 'Available listing was not found.');
      }
      const created = await client.query(
        `INSERT INTO conversations (listing_id)
         VALUES ($1) RETURNING id, listing_id, created_at`,
        [listingId],
      );
      const row = created.rows[0];
      await client.query(
        `INSERT INTO conversation_members (conversation_id, user_id)
         VALUES ($1, $2), ($1, $3)`,
        [row.id, req.user.id, listing.rows[0].seller_id],
      );
      const message = await client.query(
        `INSERT INTO messages (conversation_id, sender_id, body)
         VALUES ($1, $2, $3)
         RETURNING id, conversation_id, sender_id, body, created_at, read_at`,
        [row.id, req.user.id, body],
      );
      return {
        ...row,
        title: listing.rows[0].title,
        sellerId: listing.rows[0].seller_id,
        message: message.rows[0],
      };
    });
    await createNotification(
      pool,
      conversation.sellerId,
      'New marketplace message',
      'A buyer sent you a message about a listing.',
    );
    res.status(201).json({
      conversation: mapRow(conversation),
      message: mapRow(conversation.message),
    });
  }));

  router.get('/conversations', asyncRoute(async (req, res) => {
    const result = await pool.query(
      `SELECT c.id, c.listing_id, l.title,
              c.created_at,
              max(m.created_at) AS last_message_at,
              (SELECT m.body FROM messages m
                WHERE m.conversation_id = c.id
                ORDER BY m.created_at DESC LIMIT 1) AS last_message
         FROM conversations c
         JOIN conversation_members mine
           ON mine.conversation_id = c.id AND mine.user_id = $1
         LEFT JOIN listings l ON l.id = c.listing_id
         LEFT JOIN messages m ON m.conversation_id = c.id
        GROUP BY c.id, l.title
        ORDER BY max(m.created_at) DESC NULLS LAST, c.created_at DESC`,
      [req.user.id],
    );
    res.json({ conversations: mapRows(result.rows) });
  }));

  router.get('/conversations/:id/messages', asyncRoute(async (req, res) => {
    const id = uuid.parse(req.params.id);
    const membership = await pool.query(
      `SELECT 1 FROM conversation_members
        WHERE conversation_id = $1 AND user_id = $2`,
      [id, req.user.id],
    );
    if (!membership.rowCount) throw new HttpError(404, 'Conversation was not found.');
    await pool.query(
      `UPDATE messages SET read_at = now()
        WHERE conversation_id = $1 AND sender_id <> $2 AND read_at IS NULL`,
      [id, req.user.id],
    );
    const result = await pool.query(
      `SELECT id, conversation_id, sender_id, body, created_at, read_at
         FROM messages
        WHERE conversation_id = $1
        ORDER BY created_at`,
      [id],
    );
    res.json({ messages: mapRows(result.rows) });
  }));

  router.post('/conversations/:id/messages', asyncRoute(async (req, res) => {
    const id = uuid.parse(req.params.id);
    const { body } = messageSchema.parse(req.body);
    const membership = await pool.query(
      `SELECT user_id FROM conversation_members
        WHERE conversation_id = $1`,
      [id],
    );
    if (!membership.rows.some((member) => member.user_id === req.user.id)) {
      throw new HttpError(404, 'Conversation was not found.');
    }
    const result = await pool.query(
      `INSERT INTO messages (conversation_id, sender_id, body)
       VALUES ($1, $2, $3)
       RETURNING id, conversation_id, sender_id, body, created_at, read_at`,
      [id, req.user.id, body],
    );
    await Promise.all(
      membership.rows
        .filter((member) => member.user_id !== req.user.id)
        .map((member) => createNotification(
          pool,
          member.user_id,
          'New marketplace message',
          'You have a new message.',
        )),
    );
    res.status(201).json({ message: mapRow(result.rows[0]) });
  }));
}

function listingFilters(query) {
  const search = typeof query.q === 'string' ? query.q.trim().slice(0, 120) : '';
  const species = typeof query.species === 'string'
    ? query.species.trim().toLowerCase().slice(0, 80)
    : '';
  const city = typeof query.city === 'string' ? query.city.trim().slice(0, 120) : '';
  const minPrice = query.minPrice === undefined ? undefined : Number(query.minPrice);
  const maxPrice = query.maxPrice === undefined ? undefined : Number(query.maxPrice);
  if ((minPrice !== undefined && (!Number.isFinite(minPrice) || minPrice < 0)) ||
      (maxPrice !== undefined && (!Number.isFinite(maxPrice) || maxPrice < 0))) {
    throw new HttpError(400, 'Price filters must be non-negative numbers.');
  }
  return {
    search,
    species,
    city,
    minPrice,
    maxPrice,
    limit: Math.min(100, Math.max(1, Number.parseInt(query.limit ?? '50', 10) || 50)),
  };
}

function mapListing(row, sellerName = row.seller_name, risk = {}) {
  const riskInputs = { ...risk, price: risk.price ?? Number(row.price) };
  return {
    ...mapRow(row),
    sellerName,
    ...risk,
    openReportCount: risk.openReports ?? Number(row.open_reports ?? 0),
    riskScore: computeRiskScore(riskInputs),
    riskFactors: riskFactorLabels(riskInputs),
  };
}

function mapListings(rows) {
  return rows.map((row) => mapListing(row));
}

function computeRiskScore(risk) {
  let score = 0;
  if (risk.openReports > 0) score += Math.min(35, 15 + risk.openReports * 5);
  if (risk.duplicateTitles > 0) score += 20;
  if (risk.sellerVolume > 20) score += 15;
  if (risk.comparableMedian > 0 && risk.price < risk.comparableMedian * 0.5) score += 20;
  return Math.min(100, score);
}

function riskFactorLabels(risk) {
  const factors = [];
  if (risk.openReports > 0) factors.push('open_reports');
  if (risk.duplicateTitles > 0) factors.push('duplicate_title');
  if (risk.sellerVolume > 20) factors.push('high_seller_volume');
  if (risk.comparableMedian > 0 && risk.price < risk.comparableMedian * 0.5) {
    factors.push('unusually_low_price');
  }
  return factors;
}

function mapRow(row) {
  const numeric = new Set([
    'price', 'open_reports', 'seller_volume', 'duplicate_titles',
  ]);
  return Object.fromEntries(
    Object.entries(row).map(([key, value]) => {
      const target = key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
      if (value instanceof Date) return [target, value.toISOString()];
      return [target, numeric.has(key) && value !== null ? Number(value) : value];
    }),
  );
}

function mapRows(rows) {
  return rows.map(mapRow);
}
