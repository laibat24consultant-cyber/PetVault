import { z } from 'zod';
import { HttpError, asyncRoute } from '../errors.js';
import { inTransaction } from '../database.js';
import { requireVerifiedSupplyRole } from '../security.js';
import { writeAuditEvent } from '../notifications.js';

const uuid = z.string().uuid();
const disputeSchema = z.object({
  targetType: z.enum(['listing_transaction', 'order', 'booking', 'appointment']),
  targetId: uuid,
  reason: z.string().trim().min(5).max(2000),
}).strict();

export function registerDisputeRoutes(router, { pool }) {
  router.post('/disputes', asyncRoute(async (req, res) => {
    const body = disputeSchema.parse(req.body);
    if (body.targetType === 'booking' && req.user.activeRole === 'sitter') {
      await requireVerifiedSupplyRole(req, pool);
    }
    if (body.targetType === 'appointment' &&
        req.user.activeRole === 'veterinarian') {
      await requireVerifiedSupplyRole(req, pool);
    }
    if (body.targetType === 'order' && req.user.activeRole === 'vendor') {
      await requireVerifiedSupplyRole(req, pool);
    }

    const dispute = await inTransaction(pool, async (client) => {
      const target = await findDisputableTarget(client, req, body);
      if (!target) throw new HttpError(404, 'Disputable record was not found.');
      const existing = await client.query(
        `SELECT id FROM disputes
          WHERE target_type = $1 AND target_id = $2
            AND status IN ('open', 'in_review')
          LIMIT 1`,
        [body.targetType, body.targetId],
      );
      if (existing.rowCount) {
        throw new HttpError(409, 'An unresolved dispute already exists for this record.');
      }
      if (body.targetType === 'listing_transaction') {
        await client.query(
          `UPDATE listing_transactions
              SET status = 'disputed', updated_at = now()
            WHERE id = $1`,
          [body.targetId],
        );
      }
      const created = await client.query(
        `INSERT INTO disputes (opened_by, target_type, target_id, reason)
         VALUES ($1, $2, $3, $4)
         RETURNING id, opened_by, target_type, target_id, reason,
                   status, created_at`,
        [req.user.id, body.targetType, body.targetId, body.reason],
      );
      await client.query(
        `INSERT INTO notifications (user_id, title, body)
         SELECT u.id, 'New dispute submitted', 'A case is awaiting administrator review.'
           FROM users u
           JOIN user_roles r ON r.user_id = u.id AND r.role = 'admin'
          WHERE u.deleted_at IS NULL AND u.account_status = 'active'`,
      );
      await writeAuditEvent(client, {
        actorId: req.user.id,
        action: 'dispute.opened',
        resourceType: 'dispute',
        resourceId: created.rows[0].id,
        metadata: { targetType: body.targetType, targetId: body.targetId },
      });
      return created.rows[0];
    });

    res.status(201).json({
      dispute: Object.fromEntries(
        Object.entries(dispute).map(([key, value]) => [
          key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase()),
          value instanceof Date ? value.toISOString() : value,
        ]),
      ),
    });
  }));
}

async function findDisputableTarget(client, req, { targetType, targetId }) {
  const userId = req.user.id;
  switch (targetType) {
    case 'order': {
      if (!['owner', 'vendor'].includes(req.user.activeRole)) return null;
      const result = await client.query(
        `SELECT o.id FROM orders o
          WHERE o.id = $1 AND o.payment_status IN ('paid', 'refund_pending')
            AND (
              ($2 = 'owner' AND o.buyer_id = $3) OR
              ($2 = 'vendor' AND EXISTS (
                SELECT 1 FROM order_items i
                 WHERE i.order_id = o.id AND i.vendor_id = $3
              ))
            )
          FOR UPDATE`,
        [targetId, req.user.activeRole, userId],
      );
      return result.rows[0];
    }
    case 'booking': {
      if (!['owner', 'sitter'].includes(req.user.activeRole)) return null;
      const result = await client.query(
        `SELECT id FROM sitter_bookings
          WHERE id = $1 AND status IN ('requested', 'confirmed', 'complete')
            AND (
              ($2 = 'owner' AND owner_id = $3) OR
              ($2 = 'sitter' AND sitter_id = $3)
            )
          FOR UPDATE`,
        [targetId, req.user.activeRole, userId],
      );
      return result.rows[0];
    }
    case 'appointment': {
      if (!['owner', 'veterinarian'].includes(req.user.activeRole)) return null;
      const result = await client.query(
        `SELECT id FROM vet_appointments
          WHERE id = $1 AND status IN ('Confirmed', 'Complete')
            AND (
              ($2 = 'owner' AND owner_id = $3) OR
              ($2 = 'veterinarian' AND veterinarian_id = $3)
            )
          FOR UPDATE`,
        [targetId, req.user.activeRole, userId],
      );
      return result.rows[0];
    }
    case 'listing_transaction': {
      if (!['owner', 'seller'].includes(req.user.activeRole)) return null;
      const result = await client.query(
        `SELECT id FROM listing_transactions
          WHERE id = $1 AND status IN ('held', 'handover_pending')
            AND (
              ($2 = 'owner' AND buyer_id = $3) OR
              ($2 = 'seller' AND seller_id = $3)
            )
          FOR UPDATE`,
        [targetId, req.user.activeRole, userId],
      );
      return result.rows[0];
    }
  }
  return null;
}
