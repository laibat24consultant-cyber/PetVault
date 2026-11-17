import { z } from 'zod';
import { HttpError, asyncRoute } from '../errors.js';
import { inTransaction } from '../database.js';
import { createNotification, writeAuditEvent } from '../notifications.js';

const uuid = z.string().uuid();
const pageFields = {
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(25),
  q: z.string().trim().max(120).default(''),
};

function mapRow(row) {
  return Object.fromEntries(
    Object.entries(row).map(([key, value]) => [
      key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase()),
      value instanceof Date ? value.toISOString() : value,
    ]),
  );
}

function paged(items, total, page, pageSize) {
  return {
    items: items.map(mapRow),
    page,
    pageSize,
    total,
    pages: Math.ceil(total / pageSize),
  };
}

function appendSearch(where, values, expression, search) {
  if (!search) return;
  const placeholderCount = (expression.match(/\?/g) ?? []).length;
  const firstPlaceholder = values.length + 1;
  let placeholder = 0;
  values.push(...Array(placeholderCount).fill(`%${search}%`));
  where.push(expression.replace(/\?/g, () => `$${firstPlaceholder + placeholder++}`));
}

function appendFilter(where, values, expression, value) {
  if (value === undefined) return;
  values.push(value);
  where.push(expression.replaceAll('?', `$${values.length}`));
}

function queryParts(schema, query) {
  return schema.parse(query);
}

export function registerAdminRoutes(router, { pool, requireRole }) {
  router.get('/admin/dashboard', requireRole('admin'), asyncRoute(async (req, res) => {
    const result = await pool.query(
      `SELECT
         (SELECT count(*)::int FROM users WHERE deleted_at IS NULL) AS total_users,
         (SELECT count(*)::int FROM users
           WHERE deleted_at IS NULL AND email_verified_at IS NOT NULL) AS verified_users,
         (SELECT count(*)::int FROM users
           WHERE deleted_at IS NULL AND email_verified_at IS NULL) AS unverified_users,
         (SELECT count(*)::int FROM users
           WHERE deleted_at IS NULL AND account_status = 'suspended') AS suspended_users,
         (SELECT count(*)::int FROM user_roles r JOIN users u ON u.id = r.user_id
           WHERE r.role = 'seller' AND u.deleted_at IS NULL) AS sellers,
         (SELECT count(*)::int FROM user_roles r JOIN users u ON u.id = r.user_id
           WHERE r.role = 'sitter' AND u.deleted_at IS NULL) AS sitters,
         (SELECT count(*)::int FROM user_roles r JOIN users u ON u.id = r.user_id
           WHERE r.role = 'veterinarian' AND u.deleted_at IS NULL) AS veterinarians,
         (SELECT count(*)::int FROM user_roles r JOIN users u ON u.id = r.user_id
           WHERE r.role = 'vendor' AND u.deleted_at IS NULL) AS vendors,
         (SELECT count(*)::int FROM listings) AS total_listings,
         (SELECT count(*)::int FROM listings WHERE status = 'pending_review') AS pending_listings,
         (SELECT count(*)::int FROM listings WHERE status = 'active') AS approved_listings,
         (SELECT count(*)::int FROM listing_reports WHERE status = 'open') AS open_reports,
         (SELECT count(*)::int FROM sitter_bookings) AS total_bookings,
         (SELECT count(*)::int FROM sitter_bookings
           WHERE status IN ('requested', 'confirmed')) AS open_bookings,
         (SELECT count(*)::int FROM vet_appointments) AS total_appointments,
         (SELECT count(*)::int FROM orders) AS total_orders,
         (SELECT count(*)::int FROM orders
           WHERE payment_status IN ('pending', 'failed', 'refund_pending')) AS attention_orders,
         (SELECT count(*)::int FROM disputes
           WHERE status IN ('open', 'in_review')) AS open_disputes,
         (SELECT count(*)::int FROM disputes
           WHERE status IN ('resolved', 'dismissed')) AS resolved_disputes,
         (SELECT count(*)::int FROM kyc_submissions k JOIN users u ON u.id = k.user_id
           WHERE k.status = 'pending' AND u.deleted_at IS NULL) AS pending_kyc`,
    );
    res.json({ stats: mapRow(result.rows[0]) });
  }));

  router.get('/admin/users', requireRole('admin'), asyncRoute(async (req, res) => {
    const query = queryParts(z.object({
      ...pageFields,
      role: z.enum(['owner', 'seller', 'sitter', 'veterinarian', 'vendor', 'admin']).optional(),
      status: z.enum(['active', 'suspended', 'deleted']).optional(),
      verified: z.enum(['true', 'false']).optional(),
    }).strict(), req.query);
    const where = [];
    const values = [];
    if (query.status === 'deleted') {
      where.push('u.deleted_at IS NOT NULL');
    } else {
      where.push('u.deleted_at IS NULL');
      appendFilter(where, values, 'u.account_status = ?', query.status);
    }
    if (query.role) {
      values.push(query.role);
      where.push(`EXISTS (
        SELECT 1 FROM user_roles role_filter
         WHERE role_filter.user_id = u.id AND role_filter.role = $${values.length}
      )`);
    }
    if (query.verified !== undefined) {
      where.push(query.verified === 'true'
        ? 'u.email_verified_at IS NOT NULL'
        : 'u.email_verified_at IS NULL');
    }
    appendSearch(
      where,
      values,
      `(u.display_name ILIKE ? OR u.email ILIKE ? OR u.phone ILIKE ? OR u.id::text ILIKE ?)`,
      query.q,
    );
    const predicate = where.join(' AND ');
    const count = await pool.query(
      `SELECT count(*)::int AS total FROM users u WHERE ${predicate}`,
      values,
    );
    const page = query.page;
    const pageSize = query.pageSize;
    const result = await pool.query(
      `SELECT u.id, u.display_name, u.email, u.phone,
              u.email_verified_at, u.account_status, u.deleted_at,
              u.created_at, u.updated_at,
              COALESCE(array_agg(DISTINCT r.role)
                FILTER (WHERE r.role IS NOT NULL), ARRAY[]::text[]) AS roles,
              COALESCE((
                SELECT jsonb_object_agg(k.role, k.status)
                  FROM kyc_submissions k
                 WHERE k.user_id = u.id
              ), '{}'::jsonb) AS kyc_statuses
         FROM users u
         LEFT JOIN user_roles r ON r.user_id = u.id
        WHERE ${predicate}
        GROUP BY u.id
        ORDER BY u.created_at DESC, u.id
        LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, (page - 1) * pageSize],
    );
    const items = result.rows.map((row) => ({
      ...row,
      status: row.deleted_at ? 'deleted' : row.account_status,
      verified: row.email_verified_at !== null,
    }));
    res.json(paged(items, count.rows[0].total, page, pageSize));
  }));

  router.patch('/admin/users/:id/status', requireRole('admin'), asyncRoute(async (req, res) => {
    const id = uuid.parse(req.params.id);
    const body = z.object({
      status: z.enum(['active', 'suspended']),
      reason: z.string().trim().min(5).max(1000),
    }).strict().parse(req.body);
    if (id === req.user.id && body.status === 'suspended') {
      throw new HttpError(409, 'Administrators cannot suspend their own account.');
    }
    const user = await inTransaction(pool, async (client) => {
      await client.query('SELECT pg_advisory_xact_lock($1)', [7_914_032]);
      const current = await client.query(
        `SELECT u.id, u.display_name, u.email, u.account_status,
                u.deleted_at,
                ARRAY(
                  SELECT r.role FROM user_roles r WHERE r.user_id = u.id
                ) AS roles
           FROM users u
          WHERE u.id = $1
          FOR UPDATE OF u`,
        [id],
      );
      const row = current.rows[0];
      if (!row || row.deleted_at) {
        throw new HttpError(404, 'User was not found.');
      }
      if (row.account_status === body.status) return { ...row, changed: false };
      if (body.status === 'suspended' && row.roles.includes('admin')) {
        const admins = await client.query(
          `SELECT count(*)::int AS total
             FROM users u
             JOIN user_roles r ON r.user_id = u.id AND r.role = 'admin'
            WHERE u.deleted_at IS NULL AND u.account_status = 'active'`,
        );
        if (admins.rows[0].total <= 1) {
          throw new HttpError(409, 'The last active administrator cannot be suspended.');
        }
      }
      const updated = await client.query(
        `UPDATE users
            SET account_status = $2,
                token_version = token_version + 1,
                failed_login_attempts = 0,
                locked_until = NULL,
                updated_at = now()
          WHERE id = $1
          RETURNING id, display_name, email, account_status`,
        [id, body.status],
      );
      return { ...updated.rows[0], roles: row.roles, changed: true };
    });
    if (user.changed) {
      await createNotification(
        pool,
        id,
        body.status === 'suspended' ? 'Account suspended' : 'Account reactivated',
        body.status === 'suspended'
          ? `An administrator suspended this account. Reason: ${body.reason}`
          : `An administrator reactivated this account. Reason: ${body.reason}`,
      );
      await writeAuditEvent(pool, {
        actorId: req.user.id,
        action: `user.${body.status}`,
        resourceType: 'user',
        resourceId: id,
        metadata: { reason: body.reason },
      });
    }
    res.json({ user: mapRow(user), changed: user.changed });
  }));

  router.get('/admin/listings', requireRole('admin'), asyncRoute(async (req, res) => {
    const query = queryParts(z.object({
      ...pageFields,
      status: z.enum(['pending_review', 'active', 'rejected', 'sold']).optional(),
    }).strict(), req.query);
    const where = [];
    const values = [];
    appendFilter(where, values, 'l.status = ?', query.status);
    appendSearch(
      where,
      values,
      `(l.title ILIKE ? OR l.species ILIKE ? OR l.breed ILIKE ? OR l.city ILIKE ? OR u.display_name ILIKE ? OR u.email ILIKE ?)`,
      query.q,
    );
    const predicate = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const count = await pool.query(
      `SELECT count(*)::int AS total
         FROM listings l JOIN users u ON u.id = l.seller_id
         ${predicate}`,
      values,
    );
    const page = query.page;
    const pageSize = query.pageSize;
    const result = await pool.query(
      `SELECT l.id, l.seller_id, u.display_name AS seller_name,
              u.email AS seller_email, l.title, l.species, l.breed,
              l.city, l.price, l.age, l.health_notes, l.status,
              l.moderation_note, l.reviewed_at, l.created_at, l.updated_at
         FROM listings l
         JOIN users u ON u.id = l.seller_id
         ${predicate}
        ORDER BY CASE WHEN l.status = 'pending_review' THEN 0 ELSE 1 END,
                 l.created_at DESC, l.id
        LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, (page - 1) * pageSize],
    );
    res.json(paged(result.rows, count.rows[0].total, page, pageSize));
  }));

  router.get('/admin/bookings', requireRole('admin'), asyncRoute(async (req, res) => {
    const query = queryParts(z.object({
      ...pageFields,
      status: z.enum(['requested', 'confirmed', 'declined', 'cancelled', 'complete']).optional(),
    }).strict(), req.query);
    const where = [];
    const values = [];
    appendFilter(where, values, 'b.status = ?', query.status);
    appendSearch(
      where,
      values,
      `(b.id::text ILIKE ? OR p.name ILIKE ? OR owner.display_name ILIKE ? OR sitter.display_name ILIKE ?)`,
      query.q,
    );
    const joins = `FROM sitter_bookings b
      JOIN pets p ON p.id = b.pet_id
      JOIN users owner ON owner.id = b.owner_id
      JOIN users sitter ON sitter.id = b.sitter_id`;
    const predicate = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const count = await pool.query(
      `SELECT count(*)::int AS total ${joins} ${predicate}`,
      values,
    );
    const page = query.page;
    const pageSize = query.pageSize;
    const result = await pool.query(
      `SELECT b.id, b.owner_id, owner.display_name AS owner_name,
              b.sitter_id, sitter.display_name AS sitter_name,
              b.pet_id, p.name AS pet_name, b.starts_at, b.ends_at,
              b.arrangement, b.status, b.created_at
         ${joins}
         ${predicate}
        ORDER BY b.starts_at DESC, b.id
        LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, (page - 1) * pageSize],
    );
    res.json(paged(result.rows, count.rows[0].total, page, pageSize));
  }));

  router.get('/admin/appointments', requireRole('admin'), asyncRoute(async (req, res) => {
    const query = queryParts(z.object({
      ...pageFields,
      status: z.enum(['Confirmed', 'Complete', 'Cancelled']).optional(),
    }).strict(), req.query);
    const where = [];
    const values = [];
    appendFilter(where, values, 'a.status = ?', query.status);
    appendSearch(
      where,
      values,
      `(a.id::text ILIKE ? OR p.name ILIKE ? OR owner.display_name ILIKE ? OR vet.display_name ILIKE ?)`,
      query.q,
    );
    const joins = `FROM vet_appointments a
      JOIN vet_availability slot ON slot.id = a.availability_id
      JOIN pets p ON p.id = a.pet_id
      JOIN users owner ON owner.id = a.owner_id
      JOIN users vet ON vet.id = a.veterinarian_id`;
    const predicate = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const count = await pool.query(
      `SELECT count(*)::int AS total ${joins} ${predicate}`,
      values,
    );
    const page = query.page;
    const pageSize = query.pageSize;
    const result = await pool.query(
      `SELECT a.id, a.owner_id, owner.display_name AS owner_name,
              a.veterinarian_id, vet.display_name AS veterinarian_name,
              a.pet_id, p.name AS pet_name, a.appointment_type, a.status,
              slot.starts_at, slot.ends_at, a.created_at
         ${joins}
         ${predicate}
        ORDER BY slot.starts_at DESC, a.id
        LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, (page - 1) * pageSize],
    );
    res.json(paged(result.rows, count.rows[0].total, page, pageSize));
  }));

  router.get('/admin/orders', requireRole('admin'), asyncRoute(async (req, res) => {
    const query = queryParts(z.object({
      ...pageFields,
      status: z.enum(['Processing', 'Shipped', 'Delivered', 'Cancelled']).optional(),
      paymentStatus: z.enum(['pending', 'paid', 'failed', 'refund_pending', 'refunded']).optional(),
    }).strict(), req.query);
    const where = [];
    const values = [];
    appendFilter(where, values, 'o.status = ?', query.status);
    appendFilter(where, values, 'o.payment_status = ?', query.paymentStatus);
    appendSearch(
      where,
      values,
      `(o.id::text ILIKE ? OR buyer.display_name ILIKE ? OR buyer.email ILIKE ?
        OR EXISTS (
          SELECT 1 FROM order_items search_item
          JOIN products search_product ON search_product.id = search_item.product_id
          JOIN users search_vendor ON search_vendor.id = search_item.vendor_id
          WHERE search_item.order_id = o.id
            AND (search_product.name ILIKE ? OR search_vendor.display_name ILIKE ?)
        ))`,
      query.q,
    );
    const from = `FROM orders o
      JOIN users buyer ON buyer.id = o.buyer_id`;
    const predicate = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const count = await pool.query(
      `SELECT count(*)::int AS total ${from} ${predicate}`,
      values,
    );
    const page = query.page;
    const pageSize = query.pageSize;
    const orderIds = await pool.query(
      `SELECT o.id
         ${from}
         ${predicate}
        ORDER BY o.created_at DESC, o.id
        LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, (page - 1) * pageSize],
    );
    const ids = orderIds.rows.map((row) => row.id);
    const result = ids.length
      ? await pool.query(
        `SELECT o.id, o.buyer_id, buyer.display_name AS buyer_name,
                buyer.email AS buyer_email, o.status, o.payment_status,
                o.total, o.created_at, o.updated_at,
                i.product_id, p.name AS product_name, i.vendor_id,
                vendor.display_name AS vendor_name, i.quantity, i.unit_price,
                i.vendor_status
           FROM orders o
           JOIN users buyer ON buyer.id = o.buyer_id
           JOIN order_items i ON i.order_id = o.id
           JOIN products p ON p.id = i.product_id
           JOIN users vendor ON vendor.id = i.vendor_id
          WHERE o.id = ANY($1::uuid[])
          ORDER BY o.created_at DESC, o.id, p.name`,
        [ids],
      )
      : { rows: [] };
    const orders = new Map();
    for (const row of result.rows) {
      let order = orders.get(row.id);
      if (!order) {
        order = {
          id: row.id,
          buyerId: row.buyer_id,
          buyerName: row.buyer_name,
          buyerEmail: row.buyer_email,
          status: row.status,
          paymentStatus: row.payment_status,
          total: Number(row.total),
          createdAt: row.created_at,
          updatedAt: row.updated_at,
          items: [],
        };
        orders.set(row.id, order);
      }
      order.items.push({
        productId: row.product_id,
        productName: row.product_name,
        vendorId: row.vendor_id,
        vendorName: row.vendor_name,
        quantity: row.quantity,
        unitPrice: Number(row.unit_price),
        vendorStatus: row.vendor_status,
      });
    }
    res.json(paged([...orders.values()], count.rows[0].total, page, pageSize));
  }));

  router.get('/admin/disputes', requireRole('admin'), asyncRoute(async (req, res) => {
    const query = queryParts(z.object({
      ...pageFields,
      status: z.enum(['open', 'in_review', 'resolved', 'dismissed']).optional(),
    }).strict(), req.query);
    const where = [];
    const values = [];
    appendFilter(where, values, 'd.status = ?', query.status);
    appendSearch(
      where,
      values,
      `(d.id::text ILIKE ? OR d.reason ILIKE ? OR opener.display_name ILIKE ? OR opener.email ILIKE ?)`,
      query.q,
    );
    const joins = `FROM disputes d
      JOIN users opener ON opener.id = d.opened_by
      LEFT JOIN users resolver ON resolver.id = d.resolved_by
      LEFT JOIN listing_transactions lt
        ON d.target_type = 'listing_transaction' AND lt.id = d.target_id
      LEFT JOIN orders o ON d.target_type = 'order' AND o.id = d.target_id
      LEFT JOIN sitter_bookings b ON d.target_type = 'booking' AND b.id = d.target_id
      LEFT JOIN vet_appointments a ON d.target_type = 'appointment' AND a.id = d.target_id`;
    const predicate = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const count = await pool.query(
      `SELECT count(*)::int AS total ${joins} ${predicate}`,
      values,
    );
    const page = query.page;
    const pageSize = query.pageSize;
    const result = await pool.query(
      `SELECT d.id, d.opened_by, opener.display_name AS opener_name,
              opener.email AS opener_email, d.target_type, d.target_id,
              d.reason, d.status, d.resolution, d.resolved_by,
              resolver.display_name AS resolver_name, d.created_at, d.resolved_at,
              COALESCE(lt.amount, o.total) AS target_amount,
              COALESCE(lt.status, o.payment_status, b.status, a.status) AS target_status
         ${joins}
         ${predicate}
        ORDER BY CASE WHEN d.status IN ('open', 'in_review') THEN 0 ELSE 1 END,
                 d.created_at DESC, d.id
        LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, (page - 1) * pageSize],
    );
    res.json(paged(result.rows, count.rows[0].total, page, pageSize));
  }));

  router.patch('/admin/disputes/:id', requireRole('admin'), asyncRoute(async (req, res) => {
    const id = uuid.parse(req.params.id);
    const body = z.object({
      status: z.enum(['in_review', 'resolved', 'dismissed']),
      resolution: z.string().trim().max(2000).default(''),
    }).strict().superRefine((value, context) => {
      if (value.status !== 'in_review' && value.resolution.length < 5) {
        context.addIssue({
          code: 'custom',
          path: ['resolution'],
          message: 'A resolution note is required.',
        });
      }
    }).parse(req.body);
    const result = await pool.query(
      `UPDATE disputes
          SET status = $2,
              resolution = CASE WHEN $2 = 'in_review' THEN resolution ELSE $3 END,
              resolved_by = CASE WHEN $2 = 'in_review' THEN NULL ELSE $4::uuid END,
              resolved_at = CASE WHEN $2 = 'in_review' THEN NULL ELSE now() END
        WHERE id = $1 AND status IN ('open', 'in_review')
        RETURNING id, target_type, target_id, status, resolution, resolved_by,
                  created_at, resolved_at`,
      [id, body.status, body.resolution || null, req.user.id],
    );
    if (!result.rows[0]) {
      throw new HttpError(404, 'Open dispute was not found.');
    }
    await writeAuditEvent(pool, {
      actorId: req.user.id,
      action: `dispute.${body.status}`,
      resourceType: 'dispute',
      resourceId: id,
      metadata: { resolution: body.resolution },
    });
    res.json({ dispute: mapRow(result.rows[0]) });
  }));

  router.get('/admin/reviews', requireRole('admin'), asyncRoute(async (req, res) => {
    const query = queryParts(z.object({
      ...pageFields,
      subjectType: z.enum(['product', 'sitter', 'veterinarian']).optional(),
    }).strict(), req.query);
    const where = [];
    const values = [];
    appendFilter(where, values, 'r.subject_type = ?', query.subjectType);
    appendSearch(
      where,
      values,
      `(r.comment ILIKE ? OR r.subject_id::text ILIKE ? OR author.display_name ILIKE ? OR author.email ILIKE ?)`,
      query.q,
    );
    const joins = 'FROM reviews r JOIN users author ON author.id = r.author_id';
    const predicate = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const count = await pool.query(
      `SELECT count(*)::int AS total ${joins} ${predicate}`,
      values,
    );
    const page = query.page;
    const pageSize = query.pageSize;
    const result = await pool.query(
      `SELECT r.id, r.author_id, author.display_name AS author_name,
              author.email AS author_email, r.subject_type, r.subject_id,
              r.rating, r.comment, r.created_at
         ${joins}
         ${predicate}
        ORDER BY r.created_at DESC, r.id
        LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, (page - 1) * pageSize],
    );
    res.json(paged(result.rows, count.rows[0].total, page, pageSize));
  }));

  router.get('/admin/notifications', requireRole('admin'), asyncRoute(async (req, res) => {
    const query = queryParts(z.object({
      ...pageFields,
      read: z.enum(['true', 'false']).optional(),
    }).strict(), req.query);
    const where = [];
    const values = [];
    if (query.read !== undefined) {
      where.push(query.read === 'true' ? 'n.read_at IS NOT NULL' : 'n.read_at IS NULL');
    }
    appendSearch(
      where,
      values,
      `(n.title ILIKE ? OR recipient.display_name ILIKE ? OR recipient.email ILIKE ?)`,
      query.q,
    );
    const joins = `FROM notifications n
      JOIN users recipient ON recipient.id = n.user_id`;
    const predicate = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const count = await pool.query(
      `SELECT count(*)::int AS total ${joins} ${predicate}`,
      values,
    );
    const page = query.page;
    const pageSize = query.pageSize;
    const result = await pool.query(
      `SELECT n.id, n.user_id, recipient.display_name AS recipient_name,
              recipient.email AS recipient_email, n.title, n.read_at, n.created_at
         ${joins}
         ${predicate}
        ORDER BY n.created_at DESC, n.id
        LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, (page - 1) * pageSize],
    );
    res.json(paged(result.rows, count.rows[0].total, page, pageSize));
  }));

  router.get('/admin/audit-events', requireRole('admin'), asyncRoute(async (req, res) => {
    const query = queryParts(z.object({
      ...pageFields,
      action: z.string().trim().max(120).optional(),
    }).strict(), req.query);
    const where = [];
    const values = [];
    appendFilter(where, values, 'e.action = ?', query.action);
    appendSearch(
      where,
      values,
      `(e.action ILIKE ? OR e.resource_type ILIKE ? OR e.resource_id ILIKE ? OR actor.display_name ILIKE ? OR actor.email ILIKE ?)`,
      query.q,
    );
    const joins = `FROM audit_events e
      LEFT JOIN users actor ON actor.id = e.actor_id`;
    const predicate = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const count = await pool.query(
      `SELECT count(*)::int AS total ${joins} ${predicate}`,
      values,
    );
    const page = query.page;
    const pageSize = query.pageSize;
    const result = await pool.query(
      `SELECT e.id, e.actor_id, actor.display_name AS actor_name,
              e.action, e.resource_type, e.resource_id, e.created_at
         ${joins}
         ${predicate}
        ORDER BY e.created_at DESC, e.id DESC
        LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, (page - 1) * pageSize],
    );
    res.json(paged(result.rows, count.rows[0].total, page, pageSize));
  }));
}
