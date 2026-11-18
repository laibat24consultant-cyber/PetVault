import { z } from 'zod';
import { HttpError, asyncRoute } from '../errors.js';
import { SUPPLY_ROLES } from '../security.js';
import { createNotification, writeAuditEvent } from '../notifications.js';
import { inTransaction } from '../database.js';

const uuid = z.string().uuid();
const submitSchema = z.object({
  role: z.enum([...SUPPLY_ROLES]),
  documentReference: z.string().trim().min(3).max(500),
}).strict();
const reviewSchema = z.object({
  status: z.enum(['verified', 'rejected']),
  reviewNote: z.string().trim().max(1000).default(''),
}).strict();

export function registerKycRoutes(router, { pool, requireRole }) {
  router.get('/kyc', asyncRoute(async (req, res) => {
    const result = await pool.query(
      `SELECT id, user_id, role, status, document_reference,
              review_note, created_at, reviewed_at
         FROM kyc_submissions
        WHERE user_id = $1
        ORDER BY created_at DESC`,
      [req.user.id],
    );
    res.json({ submissions: result.rows.map((row) => ({
      id: row.id,
      userId: row.user_id,
      role: row.role,
      status: row.status,
      documentReference: row.document_reference,
      reviewNote: row.review_note,
      createdAt: row.created_at,
      reviewedAt: row.reviewed_at,
    })) });
  }));

  router.post('/kyc', asyncRoute(async (req, res) => {
    const requestedRole = req.body?.role;
    if (typeof requestedRole === 'string' && !SUPPLY_ROLES.has(requestedRole)) {
      await writeAuditEvent(pool, {
        actorId: req.user.id,
        action: 'authorization.role_assignment_denied',
        resourceType: 'user',
        resourceId: req.user.id,
        metadata: { attemptedRole: requestedRole.slice(0, 64) },
      });
      throw new HttpError(403, 'Choose an available supply role.');
    }
    const body = submitSchema.parse(req.body);
    if (!SUPPLY_ROLES.has(body.role)) {
      throw new HttpError(403, 'Choose an available supply role.');
    }
    const outcome = await inTransaction(pool, async (client) => {
      let roleAdded = false;
      if (body.role === 'seller' &&
          req.user.roles.includes('owner') &&
          !req.user.roles.includes('seller')) {
        const conflictingSupplyRole = req.user.roles.some(
          (role) => SUPPLY_ROLES.has(role) && role !== 'seller',
        );
        if (conflictingSupplyRole) {
          throw new HttpError(
            403,
            'Only owner and seller roles can share one account. Use a separate account for other supply roles.',
          );
        }
        await client.query(
          `INSERT INTO user_roles (user_id, role)
           VALUES ($1, 'seller')
           ON CONFLICT (user_id, role) DO NOTHING`,
          [req.user.id],
        );
        roleAdded = true;
      } else if (!req.user.roles.includes(body.role)) {
        throw new HttpError(403, 'Only an assigned supply role can submit verification.');
      }

      const result = await client.query(
        `INSERT INTO kyc_submissions
           (user_id, role, document_reference, status)
         VALUES ($1, $2, $3, 'pending')
         ON CONFLICT (user_id, role)
         DO UPDATE SET document_reference = EXCLUDED.document_reference,
                       status = 'pending',
                       reviewer_id = NULL,
                       review_note = NULL,
                       reviewed_at = NULL
         WHERE kyc_submissions.status = 'rejected'
         RETURNING id, user_id, role, status, document_reference,
                   review_note, created_at, reviewed_at`,
        [req.user.id, body.role, body.documentReference],
      );
      if (result.rowCount) {
        return { row: result.rows[0], roleAdded };
      }
      const current = await client.query(
        `SELECT id, user_id, role, status, document_reference,
                review_note, created_at, reviewed_at
           FROM kyc_submissions
          WHERE user_id = $1 AND role = $2`,
        [req.user.id, body.role],
      );
      if (current.rows[0]?.status === 'verified') {
        return { row: current.rows[0], alreadyVerified: true, roleAdded };
      }
      throw new HttpError(409, 'A verification request is already awaiting review.');
    });
    const submission = mapSubmission(outcome.row);
    if (outcome.roleAdded) {
      await writeAuditEvent(pool, {
        actorId: req.user.id,
        action: 'account.seller_role_requested',
        resourceType: 'user',
        resourceId: req.user.id,
      });
    }
    if (outcome.alreadyVerified) {
      return res.status(200).json({ submission });
    }
    await writeAuditEvent(pool, {
      actorId: req.user.id,
      action: 'kyc.submitted',
      resourceType: 'kyc_submission',
      resourceId: submission.id,
      metadata: { role: body.role },
    });
    res.status(201).json({ submission });
  }));

  router.get('/admin/kyc', requireRole('admin'), asyncRoute(async (req, res) => {
    const result = await pool.query(
      `SELECT k.id, k.user_id, k.role, k.status, k.document_reference,
              k.review_note, k.created_at, k.reviewed_at,
              u.email, u.display_name
         FROM kyc_submissions k
         JOIN users u ON u.id = k.user_id
        WHERE u.deleted_at IS NULL
        ORDER BY CASE WHEN k.status = 'pending' THEN 0 ELSE 1 END,
                 k.created_at`,
    );
    res.json({
      submissions: result.rows.map((row) => ({
        ...mapSubmission(row),
        email: row.email,
        displayName: row.display_name,
      })),
    });
  }));

  router.patch('/admin/kyc/:id', requireRole('admin'), asyncRoute(async (req, res) => {
    const id = uuid.parse(req.params.id);
    const body = reviewSchema.parse(req.body);
    const submission = await pool.query(
      `UPDATE kyc_submissions
          SET status = $2,
              reviewer_id = $3,
              review_note = NULLIF($4, ''),
              reviewed_at = now()
        WHERE id = $1 AND status = 'pending'
        RETURNING id, user_id, role, status, document_reference,
                  review_note, created_at, reviewed_at`,
      [id, body.status, req.user.id, body.reviewNote],
    );
    if (submission.rowCount === 0) {
      throw new HttpError(404, 'Pending verification submission was not found.');
    }
    const row = submission.rows[0];
    if (body.status === 'verified') {
      await pool.query(
        `INSERT INTO user_roles (user_id, role)
         VALUES ($1, $2)
         ON CONFLICT (user_id, role) DO NOTHING`,
        [row.user_id, row.role],
      );
    }
    await createNotification(
      pool,
      row.user_id,
      body.status === 'verified' ? 'Verification approved' : 'Verification needs attention',
      body.reviewNote || (body.status === 'verified'
        ? 'Your supply-role verification is approved.'
        : 'Your verification was not approved. Review the note and resubmit.'),
    );
    await writeAuditEvent(pool, {
      actorId: req.user.id,
      action: `kyc.${body.status}`,
      resourceType: 'kyc_submission',
      resourceId: id,
      metadata: { role: row.role },
    });
    res.json({ submission: mapSubmission(row) });
  }));
}

function mapSubmission(row) {
  return {
    id: row.id,
    userId: row.user_id,
    role: row.role,
    status: row.status,
    documentReference: row.document_reference,
    reviewNote: row.review_note,
    createdAt: row.created_at,
    reviewedAt: row.reviewed_at,
  };
}
