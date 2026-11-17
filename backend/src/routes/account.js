import crypto from 'node:crypto';
import { z } from 'zod';
import { HttpError, asyncRoute } from '../errors.js';
import { inTransaction } from '../database.js';

export function registerAccountRoutes(router, { pool }) {
  router.get('/account/deletion-eligibility', asyncRoute(async (req, res) => {
    const commitments = await findActiveCommitments(pool, req.user.id);
    res.json({
      canDelete: commitments.length === 0,
      commitments,
    });
  }));

  router.delete('/account', asyncRoute(async (req, res) => {
    const { confirm } = z.object({ confirm: z.literal(true) }).strict().parse(req.body);
    if (!confirm) throw new HttpError(400, 'Confirm account deletion to continue.');
    await inTransaction(pool, async (client) => {
      await client.query('SELECT pg_advisory_xact_lock($1)', [7_914_032]);
      const current = await client.query(
        'SELECT id FROM users WHERE id = $1 AND deleted_at IS NULL FOR UPDATE',
        [req.user.id],
      );
      if (!current.rowCount) throw new HttpError(404, 'Account was not found.');
      const adminRole = await client.query(
        'SELECT 1 FROM user_roles WHERE user_id = $1 AND role = $2',
        [req.user.id, 'admin'],
      );
      if (adminRole.rowCount) {
        const admins = await client.query(
          `SELECT count(*)::int AS total
             FROM users u
             JOIN user_roles r ON r.user_id = u.id AND r.role = 'admin'
            WHERE u.deleted_at IS NULL AND u.account_status = 'active'`,
        );
        if (admins.rows[0].total <= 1) {
          throw new HttpError(409, 'The last active administrator cannot be deleted.');
        }
      }
      const commitments = await findActiveCommitments(client, req.user.id);
      if (commitments.length) {
        throw new HttpError(
          409,
          'Complete active commitments before deleting your account.',
          'ACTIVE_COMMITMENTS',
          commitments,
        );
      }

      const access = await client.query(
        `UPDATE pet_access_grants
            SET revoked_at = COALESCE(revoked_at, now())
          WHERE owner_id = $1 AND revoked_at IS NULL
          RETURNING id, pet_id`,
        [req.user.id],
      );
      for (const grant of access.rows) {
        await client.query(
          `INSERT INTO audit_events
             (actor_id, action, resource_type, resource_id, metadata)
           VALUES ($1, 'pet_access.revoked_by_account_deletion',
                   'pet_access_grant', $2, $3)`,
          [req.user.id, grant.id, { petId: grant.pet_id }],
        );
      }
      await client.query(
        'DELETE FROM pet_access_grants WHERE recipient_id = $1',
        [req.user.id],
      );
      await client.query(
        `DELETE FROM health_records h
          USING pets p
          WHERE h.pet_id = p.id AND p.owner_id = $1`,
        [req.user.id],
      );
      await client.query(
        `UPDATE pets
            SET name = 'Deleted pet', species = 'unknown', breed = 'unknown',
                age = 'unknown', sex = 'unknown', weight_kg = 0.01,
                microchip = '', updated_at = now()
          WHERE owner_id = $1`,
        [req.user.id],
      );
      await client.query(
        `UPDATE listings
            SET status = CASE WHEN status = 'sold' THEN status ELSE 'rejected' END,
                title = CASE WHEN status = 'sold' THEN title ELSE 'Removed listing' END,
                image_url = CASE WHEN status = 'sold' THEN image_url ELSE '' END,
                health_notes = '',
                updated_at = now()
          WHERE seller_id = $1`,
        [req.user.id],
      );
      await client.query(
        `UPDATE products
            SET published = false, stock = 0, updated_at = now()
          WHERE vendor_id = $1`,
        [req.user.id],
      );
      await client.query(
        `DELETE FROM vet_availability
          WHERE veterinarian_id = $1 AND is_booked = false`,
        [req.user.id],
      );
      await client.query(
        'DELETE FROM conversation_members WHERE user_id = $1',
        [req.user.id],
      );
      await client.query(
        `UPDATE messages
            SET body = 'Message removed after account deletion'
          WHERE sender_id = $1`,
        [req.user.id],
      );
      await client.query(
        `UPDATE sitter_check_ins
            SET note = 'Update removed after account deletion'
          WHERE sitter_id = $1`,
        [req.user.id],
      );
      await client.query(
        `UPDATE support_requests
            SET user_id = NULL,
                message = 'Request content removed after account deletion'
          WHERE user_id = $1`,
        [req.user.id],
      );
      await client.query(
        'DELETE FROM notifications WHERE user_id = $1',
        [req.user.id],
      );
      await client.query(
        'DELETE FROM listing_favorites WHERE user_id = $1',
        [req.user.id],
      );
      await client.query(
        'DELETE FROM notification_preferences WHERE user_id = $1',
        [req.user.id],
      );
      await client.query(
        'DELETE FROM listing_search_events WHERE user_id = $1',
        [req.user.id],
      );
      await client.query(
        'DELETE FROM kyc_submissions WHERE user_id = $1',
        [req.user.id],
      );
      await client.query(
        `INSERT INTO audit_events
           (actor_id, action, resource_type, resource_id, metadata)
         VALUES ($1, 'account.deleted', 'user', $2, '{}'::jsonb)`,
        [req.user.id, req.user.id],
      );
      await client.query(
        `UPDATE audit_events SET actor_id = NULL, resource_id = NULL
          WHERE actor_id = $1`,
        [req.user.id],
      );
      await client.query(
        `DELETE FROM user_roles WHERE user_id = $1`,
        [req.user.id],
      );
      await client.query(
        `DELETE FROM verification_codes WHERE user_id = $1`,
        [req.user.id],
      );
      await client.query(
        `UPDATE users
            SET email = 'deleted+' || replace(id::text, '-', '') || '@deleted.petvault.invalid',
                display_name = 'Deleted user',
                phone = 'deleted' || replace(id::text, '-', ''),
                password_hash = $2,
                email_verified_at = NULL,
                deleted_at = now(),
                token_version = token_version + 1,
                updated_at = now()
          WHERE id = $1`,
        [req.user.id, crypto.randomBytes(48).toString('base64url')],
      );
    });
    res.json({
      deleted: true,
      message: 'Your account was anonymized and your session was revoked.',
    });
  }));
}

async function findActiveCommitments(queryable, userId) {
  const bookings = await queryable.query(
    `SELECT id, status FROM sitter_bookings
      WHERE (owner_id = $1 OR sitter_id = $1)
        AND status IN ('requested', 'confirmed')`,
    [userId],
  );
  const orders = await queryable.query(
    `SELECT DISTINCT o.id, o.status FROM orders o
     LEFT JOIN order_items i ON i.order_id = o.id
      WHERE (o.buyer_id = $1 OR i.vendor_id = $1)
        AND o.status IN ('Processing', 'Shipped')`,
    [userId],
  );
  const transactions = await queryable.query(
    `SELECT id, status FROM listing_transactions
      WHERE (buyer_id = $1 OR seller_id = $1)
        AND status IN ('initiated', 'held', 'handover_pending', 'disputed')`,
    [userId],
  );
  const appointments = await queryable.query(
    `SELECT id, status FROM vet_appointments
      WHERE (owner_id = $1 OR veterinarian_id = $1)
        AND status = 'Confirmed'`,
    [userId],
  );
  const visits = await queryable.query(
    `SELECT v.id, v.status FROM visit_requests v
     JOIN listings l ON l.id = v.listing_id
      WHERE (v.buyer_id = $1 OR l.seller_id = $1)
        AND v.status IN ('requested', 'confirmed')`,
    [userId],
  );
  const disputes = await queryable.query(
    `SELECT d.id, d.target_type, d.status FROM disputes d
      WHERE d.status IN ('open', 'in_review')
        AND (
          d.opened_by = $1 OR
          (d.target_type = 'order' AND EXISTS (
            SELECT 1 FROM orders o
            LEFT JOIN order_items i ON i.order_id = o.id
             WHERE o.id = d.target_id
               AND (o.buyer_id = $1 OR i.vendor_id = $1)
          )) OR
          (d.target_type = 'listing_transaction' AND EXISTS (
            SELECT 1 FROM listing_transactions t
             WHERE t.id = d.target_id
               AND (t.buyer_id = $1 OR t.seller_id = $1)
          )) OR
          (d.target_type = 'booking' AND EXISTS (
            SELECT 1 FROM sitter_bookings b
             WHERE b.id = d.target_id
               AND (b.owner_id = $1 OR b.sitter_id = $1)
          )) OR
          (d.target_type = 'appointment' AND EXISTS (
            SELECT 1 FROM vet_appointments a
             WHERE a.id = d.target_id
               AND (a.owner_id = $1 OR a.veterinarian_id = $1)
          ))
        )`,
    [userId],
  );
  return [
    ...bookings.rows.map((row) => ({ type: 'sitting_booking', ...row })),
    ...orders.rows.map((row) => ({ type: 'order', ...row })),
    ...transactions.rows.map((row) => ({ type: 'listing_transaction', ...row })),
    ...appointments.rows.map((row) => ({ type: 'veterinary_appointment', ...row })),
    ...visits.rows.map((row) => ({ type: 'visit_request', ...row })),
    ...disputes.rows.map((row) => ({
      type: 'dispute',
      id: row.id,
      status: row.status,
      targetType: row.target_type,
    })),
  ];
}
