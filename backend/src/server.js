import 'dotenv/config';
import bcrypt from 'bcryptjs';
import cors from 'cors';
import { randomInt } from 'node:crypto';
import express from 'express';
import { rateLimit } from 'express-rate-limit';
import helmet from 'helmet';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { pool, transaction } from './db.js';
import { scoreListingRisk } from './listing-risk.js';
import { createPaymentProvider } from './payment-provider.js';
import { emailIsConfigured, sendOtpEmail } from './email.js';

const app = express();
const port = Number(process.env.PORT ?? 3000);
const jwtSecret = process.env.JWT_SECRET ?? '';
const development = process.env.NODE_ENV !== 'production';
const devAuthCodes = development && process.env.DEV_AUTH_CODES === 'true';
const otpTtlMinutes = Number(process.env.OTP_TTL_MINUTES ?? 10);
if (!Number.isInteger(otpTtlMinutes) || otpTtlMinutes < 1 || otpTtlMinutes > 60) {
  throw new Error('OTP_TTL_MINUTES must be an integer between 1 and 60.');
}
const paymentProvider = createPaymentProvider();
const roles = ['owner', 'seller', 'sitter', 'veterinarian', 'vendor', 'admin'];

if (jwtSecret.length < 32) {
  throw new Error('JWT_SECRET must contain at least 32 characters.');
}
if (process.env.NODE_ENV === 'production' &&
    jwtSecret === 'local-development-secret-change-this-32chars') {
  throw new Error('Production must use a unique JWT_SECRET; the local development secret is unsafe.');
}

const allowedOrigins = (process.env.ALLOWED_ORIGINS ?? '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

app.disable('x-powered-by');
app.use(helmet());
app.use(cors({
  origin(origin, callback) {
    if (!origin || allowedOrigins.includes(origin)) return callback(null, true);
    return callback(new Error('This origin is not allowed by the API CORS policy.'));
  },
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Active-Role'],
}));
app.use(express.json({ limit: '1mb' }));

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: development ? 100 : 20,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
});

const idSchema = z.string().uuid();
const emailSchema = z.string().trim().email().max(254).transform((value) => value.toLowerCase());
const passwordSchema = z.string().min(8).max(128);
const petSchema = z.object({
  name: z.string().trim().min(1).max(100),
  species: z.string().trim().min(1).max(60),
  breed: z.string().trim().min(1).max(100),
  age: z.string().trim().min(1).max(60),
  sex: z.string().trim().min(1).max(30),
  weightKg: z.coerce.number().positive().max(1000),
  microchip: z.string().trim().max(100).default(''),
}).strict();
const listingSchema = z.object({
  title: z.string().trim().min(1).max(160),
  species: z.string().trim().min(1).max(60),
  breed: z.string().trim().min(1).max(100),
  city: z.string().trim().min(1).max(100),
  price: z.coerce.number().positive().max(100_000_000),
  age: z.string().trim().min(1).max(60),
  imageUrl: z.string().trim().max(2048).default(''),
  healthNotes: z.string().trim().max(5000).default(''),
}).strict();

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function fail(status, message) {
  throw new HttpError(status, message);
}

function validate(schema, input) {
  const result = schema.safeParse(input);
  if (!result.success) {
    fail(400, result.error.issues.map((issue) => `${issue.path.join('.')}: ${issue.message}`).join('; '));
  }
  return result.data;
}

function asyncRoute(handler) {
  return (request, response, next) => Promise.resolve(handler(request, response, next)).catch(next);
}

async function audit(client, actorId, action, resourceType, resourceId = null, metadata = {}) {
  await client.query(
    `INSERT INTO audit_events (actor_id, action, resource_type, resource_id, metadata)
     VALUES ($1, $2, $3, $4, $5::jsonb)`,
    [actorId, action, resourceType, resourceId, JSON.stringify(metadata)],
  );
}

async function notify(client, userId, title, body) {
  await client.query(
    'INSERT INTO notifications (user_id, title, body) VALUES ($1, $2, $3)',
    [userId, title, body],
  );
}

async function getUserWithRoles(client, userId) {
  const { rows } = await client.query(
    `SELECT u.id, u.email, u.display_name AS "displayName", u.phone,
            u.email_verified_at IS NOT NULL AS verified,
            COALESCE(array_agg(ur.role) FILTER (WHERE ur.role IS NOT NULL), '{}') AS roles
     FROM users u
     LEFT JOIN user_roles ur ON ur.user_id = u.id
     WHERE u.id = $1 AND u.deleted_at IS NULL
     GROUP BY u.id`,
    [userId],
  );
  return rows[0] ?? null;
}

function issueToken(user) {
  return jwt.sign({ sub: user.id }, jwtSecret, {
    expiresIn: process.env.JWT_EXPIRES_IN ?? '8h',
    issuer: 'petvault-api',
    audience: 'petvault-app',
  });
}

const authenticate = asyncRoute(async (request, _response, next) => {
  const authorization = request.get('authorization') ?? '';
  const [scheme, token] = authorization.split(' ');
  if (scheme !== 'Bearer' || !token) fail(401, 'Sign in to continue.');

  let claims;
  try {
    claims = jwt.verify(token, jwtSecret, {
      issuer: 'petvault-api',
      audience: 'petvault-app',
    });
  } catch {
    fail(401, 'Your session has expired. Sign in again.');
  }

  const user = await getUserWithRoles(pool, claims.sub);
  if (!user) fail(401, 'This account is unavailable.');
  request.user = user;

  const activeRole = request.get('x-active-role');
  if (activeRole && user.roles.includes(activeRole)) {
    request.activeRole = activeRole;
  } else {
    request.activeRole = user.roles.includes('owner') ? 'owner' : user.roles[0];
  }
  next();
});

function requireRole(...requiredRoles) {
  return asyncRoute(async (request, _response, next) => {
    if (!request.user) return next(new HttpError(401, 'Sign in to continue.'));
    if (!requiredRoles.includes(request.activeRole)) {
      return next(new HttpError(403, `This action requires the ${requiredRoles.join(' or ')} role.`));
    }
    if (['seller', 'sitter', 'veterinarian', 'vendor'].includes(request.activeRole)) {
      const verified = await pool.query(
        `SELECT 1 FROM kyc_submissions
         WHERE user_id = $1 AND role = $2 AND status = 'verified'`,
        [request.user.id, request.activeRole],
      );
      if (!verified.rowCount) {
        return next(new HttpError(403, 'Complete verification for this role before continuing.'));
      }
    }
    next();
  });
}

async function hasPetAccess(client, petId, user, section = 'health') {
  const { rows } = await client.query(
    `SELECT p.owner_id = $2 AS is_owner,
            EXISTS (
              SELECT 1 FROM pet_access_grants g
              WHERE g.pet_id = p.id
                AND g.recipient_id = $2
                AND g.revoked_at IS NULL
                AND (g.expires_at IS NULL OR g.expires_at > now())
                AND ($3 = ANY(g.sections) OR 'all' = ANY(g.sections))
            ) AS is_shared
     FROM pets p WHERE p.id = $1`,
    [petId, user.id, section],
  );
  if (!rows[0]) fail(404, 'Pet profile not found.');
  return rows[0].is_owner || rows[0].is_shared;
}

app.get('/api/health', asyncRoute(async (_request, response) => {
  await pool.query('SELECT 1');
  response.json({ status: 'ok', database: 'connected' });
}));

app.post('/api/auth/register', authLimiter, asyncRoute(async (request, response) => {
  if (!devAuthCodes && !emailIsConfigured()) fail(503, 'Configure email delivery before enabling account verification.');
  const input = validate(z.object({
    displayName: z.string().trim().min(1).max(100),
    email: emailSchema,
    phone: z.string().trim().min(7).max(40),
    password: passwordSchema,
  }).strict(), request.body);
  const passwordHash = await bcrypt.hash(input.password, 12);
  const code = devAuthCodes ? '123456' : String(randomInt(100000, 1_000_000));
  const codeHash = await bcrypt.hash(code, 10);

  const user = await transaction(async (client) => {
    let inserted;
    try {
      inserted = await client.query(
        `INSERT INTO users (email, display_name, phone, password_hash)
         VALUES ($1, $2, $3, $4)
         RETURNING id, email, display_name AS "displayName", phone`,
        [input.email, input.displayName, input.phone, passwordHash],
      );
    } catch (error) {
      if (error.code === '23505') fail(409, 'An account already exists for this email address.');
      throw error;
    }
    const created = inserted.rows[0];
    await client.query('INSERT INTO user_roles (user_id, role) VALUES ($1, $2)', [created.id, 'owner']);
    await client.query(
      `INSERT INTO verification_codes (user_id, purpose, code_hash, expires_at)
       VALUES ($1, 'verify_email', $2, now() + ($3 * interval '1 minute'))`,
      [created.id, codeHash, otpTtlMinutes],
    );
    await notify(client, created.id, 'Verify your account', 'Enter the verification code sent to your contact method.');
    await audit(client, created.id, 'Account registered', 'user', created.id);
    return created;
  });

  if (!devAuthCodes) await sendOtpEmail({ to: user.email, code, purpose: 'verify_email', expiresInMinutes: otpTtlMinutes });

  response.status(201).json({
    message: 'Account created. Verify the code to continue.',
    user,
    ...(devAuthCodes ? { devCode: code } : {}),
  });
}));

app.post('/api/auth/verify', authLimiter, asyncRoute(async (request, response) => {
  const input = validate(z.object({
    email: emailSchema,
    code: z.string().trim().regex(/^\d{6}$/),
  }).strict(), request.body);

  const user = await transaction(async (client) => {
    const account = await client.query(
      'SELECT id FROM users WHERE email = $1 AND deleted_at IS NULL',
      [input.email],
    );
    if (!account.rowCount) fail(400, 'The verification request is invalid or expired.');
    const { rows } = await client.query(
      `SELECT id, code_hash FROM verification_codes
       WHERE user_id = $1 AND purpose = 'verify_email'
         AND consumed_at IS NULL AND expires_at > now()
       ORDER BY created_at DESC LIMIT 1 FOR UPDATE`,
      [account.rows[0].id],
    );
    if (!rows[0] || !(await bcrypt.compare(input.code, rows[0].code_hash))) {
      fail(400, 'The verification code is invalid or expired.');
    }
    await client.query('UPDATE verification_codes SET consumed_at = now() WHERE id = $1', [rows[0].id]);
    await client.query('UPDATE users SET email_verified_at = now(), updated_at = now() WHERE id = $1', [account.rows[0].id]);
    await audit(client, account.rows[0].id, 'Account verified', 'user', account.rows[0].id);
    return getUserWithRoles(client, account.rows[0].id);
  });
  response.json({ token: issueToken(user), user });
}));

app.post('/api/auth/resend-code', authLimiter, asyncRoute(async (request, response) => {
  if (!devAuthCodes && !emailIsConfigured()) fail(503, 'Configure email delivery before resending verification codes.');
  const { email } = validate(z.object({ email: emailSchema }).strict(), request.body);
  const { rows } = await pool.query(
    'SELECT id, email_verified_at FROM users WHERE email = $1 AND deleted_at IS NULL',
    [email],
  );
  if (!rows[0] || rows[0].email_verified_at) {
    response.json({ message: 'If verification is pending, a new code has been issued.' });
    return;
  }
  const code = devAuthCodes ? '123456' : String(randomInt(100000, 1_000_000));
  const codeHash = await bcrypt.hash(code, 10);
  await transaction(async (client) => {
    await client.query(
      `UPDATE verification_codes SET consumed_at = now()
       WHERE user_id = $1 AND purpose = 'verify_email' AND consumed_at IS NULL`,
      [rows[0].id],
    );
    await client.query(
      `INSERT INTO verification_codes (user_id, purpose, code_hash, expires_at)
       VALUES ($1, 'verify_email', $2, now() + ($3 * interval '1 minute'))`,
      [rows[0].id, codeHash, otpTtlMinutes],
    );
    await notify(client, rows[0].id, 'Verification code reissued', 'Enter the latest verification code.');
  });
  if (!devAuthCodes) await sendOtpEmail({ to: email, code, purpose: 'verify_email', expiresInMinutes: otpTtlMinutes });
  response.json({
    message: 'A new verification code has been issued.',
    ...(devAuthCodes ? { devCode: code } : {}),
  });
}));

app.post('/api/auth/login', authLimiter, asyncRoute(async (request, response) => {
  const input = validate(z.object({
    email: emailSchema,
    password: z.string().min(1).max(128),
  }).strict(), request.body);
  const { rows } = await pool.query(
    'SELECT id, password_hash, email_verified_at FROM users WHERE email = $1 AND deleted_at IS NULL',
    [input.email],
  );
  const account = rows[0];
  if (!account || !(await bcrypt.compare(input.password, account.password_hash))) {
    fail(401, 'Email or password is incorrect.');
  }
  if (!account.email_verified_at) fail(403, 'Verify your email address before signing in.');
  const user = await getUserWithRoles(pool, account.id);
  await audit(pool, user.id, 'Successful sign-in', 'user', user.id);
  response.json({ token: issueToken(user), user });
}));

app.post('/api/auth/password-reset', authLimiter, asyncRoute(async (request, response) => {
  if (!devAuthCodes && !emailIsConfigured()) fail(503, 'Configure email delivery before enabling password resets.');
  const { email } = validate(z.object({ email: emailSchema }).strict(), request.body);
  const { rows } = await pool.query(
    'SELECT id FROM users WHERE email = $1 AND email_verified_at IS NOT NULL AND deleted_at IS NULL',
    [email],
  );
  if (!rows[0]) {
    response.json({ message: 'If the verified account exists, a reset code has been issued.' });
    return;
  }
  const code = devAuthCodes ? '654321' : String(randomInt(100000, 1_000_000));
  const codeHash = await bcrypt.hash(code, 10);
  await transaction(async (client) => {
    await client.query(
      `UPDATE verification_codes SET consumed_at = now()
       WHERE user_id = $1 AND purpose = 'reset_password' AND consumed_at IS NULL`,
      [rows[0].id],
    );
    await client.query(
      `INSERT INTO verification_codes (user_id, purpose, code_hash, expires_at)
       VALUES ($1, 'reset_password', $2, now() + ($3 * interval '1 minute'))`,
      [rows[0].id, codeHash, otpTtlMinutes],
    );
  });
  if (!devAuthCodes) await sendOtpEmail({ to: email, code, purpose: 'reset_password', expiresInMinutes: otpTtlMinutes });
  response.json({
    message: 'A password reset code has been issued.',
    ...(devAuthCodes ? { devCode: code } : {}),
  });
}));

app.post('/api/auth/password-reset/confirm', authLimiter, asyncRoute(async (request, response) => {
  const input = validate(z.object({
    email: emailSchema,
    code: z.string().trim().regex(/^\d{6}$/),
    newPassword: passwordSchema,
  }).strict(), request.body);
  const passwordHash = await bcrypt.hash(input.newPassword, 12);
  const changed = await transaction(async (client) => {
    const account = await client.query(
      'SELECT id FROM users WHERE email = $1 AND deleted_at IS NULL',
      [input.email],
    );
    if (!account.rowCount) fail(400, 'The reset code is invalid or expired.');
    const { rows } = await client.query(
      `SELECT id, code_hash FROM verification_codes
       WHERE user_id = $1 AND purpose = 'reset_password'
         AND consumed_at IS NULL AND expires_at > now()
       ORDER BY created_at DESC LIMIT 1 FOR UPDATE`,
      [account.rows[0].id],
    );
    if (!rows[0] || !(await bcrypt.compare(input.code, rows[0].code_hash))) {
      fail(400, 'The reset code is invalid or expired.');
    }
    await client.query('UPDATE verification_codes SET consumed_at = now() WHERE id = $1', [rows[0].id]);
    await client.query('UPDATE users SET password_hash = $2, updated_at = now() WHERE id = $1', [account.rows[0].id, passwordHash]);
    await audit(client, account.rows[0].id, 'Password reset', 'user', account.rows[0].id);
    return true;
  });
  response.json({ changed, message: 'Password updated. Sign in with your new password.' });
}));

app.get('/api/auth/me', authenticate, (request, response) => {
  response.json({ user: request.user, activeRole: request.activeRole });
});

app.post('/api/auth/roles', authenticate, asyncRoute(async (request, response) => {
  const { role } = validate(z.object({
    role: z.enum(roles.filter((item) => item !== 'admin')),
  }).strict(), request.body);
  if (!request.user.roles.includes(role)) fail(403, 'This role is not assigned to your account.');
  response.json({ activeRole: role });
}));

app.post('/api/kyc', authenticate, asyncRoute(async (request, response) => {
  const input = validate(z.object({
    role: z.enum(['seller', 'sitter', 'veterinarian', 'vendor']),
    documentReference: z.string().trim().min(1).max(500),
  }).strict(), request.body);
  if (!request.user.verified) fail(403, 'Verify your email before submitting KYC.');
  const { rows } = await pool.query(
    `INSERT INTO kyc_submissions (user_id, role, document_reference)
     VALUES ($1, $2, $3)
     ON CONFLICT (user_id, role) DO UPDATE
       SET document_reference = EXCLUDED.document_reference,
           status = CASE WHEN kyc_submissions.status = 'verified'
                         THEN kyc_submissions.status ELSE 'pending' END,
           reviewer_id = CASE WHEN kyc_submissions.status = 'verified'
                              THEN kyc_submissions.reviewer_id ELSE NULL END,
           review_note = NULL,
           reviewed_at = CASE WHEN kyc_submissions.status = 'verified'
                              THEN kyc_submissions.reviewed_at ELSE NULL END
     RETURNING id, role, status, created_at AS "createdAt"`,
    [request.user.id, input.role, input.documentReference],
  );
  await pool.query(
    'INSERT INTO user_roles (user_id, role) VALUES ($1, $2) ON CONFLICT DO NOTHING',
    [request.user.id, input.role],
  );
  await audit(pool, request.user.id, 'KYC submitted', 'kyc', rows[0].id, { role: input.role });
  response.status(201).json({ submission: rows[0] });
}));

app.get('/api/kyc', authenticate, asyncRoute(async (request, response) => {
  const { rows } = await pool.query(
    `SELECT id, role, status, document_reference AS "documentReference",
            review_note AS "reviewNote", created_at AS "createdAt",
            reviewed_at AS "reviewedAt"
     FROM kyc_submissions WHERE user_id = $1 ORDER BY created_at DESC`,
    [request.user.id],
  );
  response.json({ submissions: rows });
}));

app.get('/api/admin/kyc', authenticate, requireRole('admin'), asyncRoute(async (_request, response) => {
  const { rows } = await pool.query(
    `SELECT k.id, k.user_id AS "userId", u.email, u.display_name AS "displayName",
            k.role, k.status, k.document_reference AS "documentReference",
            k.created_at AS "createdAt"
     FROM kyc_submissions k JOIN users u ON u.id = k.user_id
     WHERE k.status = 'pending' ORDER BY k.created_at`,
  );
  response.json({ submissions: rows });
}));

app.patch('/api/admin/kyc/:submissionId', authenticate, requireRole('admin'), asyncRoute(async (request, response) => {
  const submissionId = validate(idSchema, request.params.submissionId);
  const input = validate(z.object({
    status: z.enum(['verified', 'rejected']),
    reviewNote: z.string().trim().max(2000).default(''),
  }).strict(), request.body);
  const result = await transaction(async (client) => {
    const { rows } = await client.query(
      `UPDATE kyc_submissions SET status = $3, reviewer_id = $2,
                                 review_note = $4, reviewed_at = now()
       WHERE id = $1 AND status = 'pending'
       RETURNING id, user_id AS "userId", role, status, review_note AS "reviewNote"`,
      [submissionId, request.user.id, input.status, input.reviewNote],
    );
    if (!rows[0]) fail(404, 'Pending KYC submission not found.');
    if (input.status === 'verified') {
      await client.query(
        'INSERT INTO user_roles (user_id, role) VALUES ($1, $2) ON CONFLICT DO NOTHING',
        [rows[0].userId, rows[0].role],
      );
    }
    await notify(
      client,
      rows[0].userId,
      'KYC review completed',
      input.status === 'verified'
        ? `Your ${rows[0].role} role has been verified.`
        : `Your ${rows[0].role} verification was not approved.`,
    );
    await audit(client, request.user.id, 'KYC reviewed', 'kyc', submissionId, { status: input.status });
    return rows[0];
  });
  response.json({ submission: result });
}));

app.get('/api/admin/listings/moderation', authenticate, requireRole('admin'), asyncRoute(async (_request, response) => {
  const { rows } = await pool.query(
    `SELECT l.id, l.seller_id AS "sellerId", u.display_name AS "sellerName",
            l.title, l.species, l.breed, l.city, l.price, l.age,
            l.image_url AS "imageUrl", l.health_notes AS "healthNotes",
            l.status, l.created_at AS "createdAt",
            (SELECT count(*)::integer FROM listings duplicate
             WHERE duplicate.id <> l.id
               AND duplicate.status IN ('pending_review', 'active')
               AND lower(regexp_replace(trim(duplicate.title), '[[:space:]]+', ' ', 'g')) =
                   lower(regexp_replace(trim(l.title), '[[:space:]]+', ' ', 'g')))
              AS "duplicateTitleCount",
            (SELECT count(*)::integer FROM listing_reports report
             WHERE report.listing_id = l.id AND report.status = 'open')
              AS "openReportCount",
            (SELECT count(*)::integer FROM listings recent
             WHERE recent.seller_id = l.seller_id
               AND recent.created_at >= now() - interval '30 days')
              AS "sellerListings30Days",
            (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY comparable.price)
             FROM listings comparable
             WHERE comparable.status = 'active'
               AND comparable.id <> l.id
               AND lower(comparable.species) = lower(l.species))
              AS "medianPrice"
     FROM listings l
     JOIN users u ON u.id = l.seller_id
     WHERE l.status = 'pending_review'
        OR EXISTS (
          SELECT 1 FROM listing_reports report
          WHERE report.listing_id = l.id AND report.status = 'open'
        )
     ORDER BY l.created_at ASC`,
  );
  const listings = rows.map((listing) => ({
    ...listing,
    ...scoreListingRisk({
      price: Number(listing.price),
      medianPrice: Number(listing.medianPrice ?? 0),
      duplicateTitleCount: listing.duplicateTitleCount,
      openReportCount: listing.openReportCount,
      sellerListings30Days: listing.sellerListings30Days,
    }),
  }));
  response.json({ listings });
}));

app.patch('/api/admin/listings/:listingId/moderation', authenticate, requireRole('admin'), asyncRoute(async (request, response) => {
  const listingId = validate(idSchema, request.params.listingId);
  const input = validate(z.object({
    status: z.enum(['active', 'rejected']),
    reviewNote: z.string().trim().max(2000).default(''),
  }).strict(), request.body);
  const listing = await transaction(async (client) => {
    const { rows } = await client.query(
      `UPDATE listings SET status = $2, updated_at = now()
       WHERE id = $1 AND status <> 'sold'
       RETURNING id, seller_id AS "sellerId", title, status`,
      [listingId, input.status],
    );
    if (!rows[0]) fail(404, 'Listing available for moderation was not found.');
    await client.query(
      `UPDATE listing_reports
       SET status = 'reviewed', reviewed_by = $2, reviewed_at = now()
       WHERE listing_id = $1 AND status = 'open'`,
      [listingId, request.user.id],
    );
    await notify(
      client,
      rows[0].sellerId,
      'Listing moderation update',
      input.status === 'active'
        ? `Your listing "${rows[0].title}" was approved and published.`
        : `Your listing "${rows[0].title}" was not approved. ${input.reviewNote}`,
    );
    await audit(client, request.user.id, 'Listing moderated', 'listing', listingId, {
      status: input.status,
      reviewNote: input.reviewNote,
    });
    return rows[0];
  });
  response.json({ listing });
}));

app.post('/api/pets', authenticate, requireRole('owner'), asyncRoute(async (request, response) => {
  const input = validate(petSchema, request.body);
  const { rows } = await transaction(async (client) => {
    const result = await client.query(
      `INSERT INTO pets (owner_id, name, species, breed, age, sex, weight_kg, microchip)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, owner_id AS "ownerId", name, species, breed, age, sex,
                 weight_kg AS "weightKg", microchip, created_at AS "createdAt"`,
      [request.user.id, input.name, input.species, input.breed, input.age, input.sex, input.weightKg, input.microchip],
    );
    await audit(client, request.user.id, 'Pet profile created', 'pet', result.rows[0].id);
    return result;
  });
  response.status(201).json({ pet: rows[0] });
}));

app.get('/api/pets', authenticate, asyncRoute(async (request, response) => {
  const { rows } = await pool.query(
    `SELECT DISTINCT p.id, p.owner_id AS "ownerId", p.name, p.species, p.breed, p.age,
            p.sex, p.weight_kg AS "weightKg", p.microchip,
            p.created_at AS "createdAt", p.updated_at AS "updatedAt"
     FROM pets p
     LEFT JOIN pet_access_grants g ON g.pet_id = p.id
       AND g.recipient_id = $1 AND g.revoked_at IS NULL
       AND (g.expires_at IS NULL OR g.expires_at > now())
     WHERE p.owner_id = $1 OR g.id IS NOT NULL
     ORDER BY p.created_at DESC`,
    [request.user.id],
  );
  response.json({ pets: rows });
}));

app.get('/api/pets/:petId', authenticate, asyncRoute(async (request, response) => {
  const petId = validate(idSchema, request.params.petId);
  if (!(await hasPetAccess(pool, petId, request.user))) fail(403, 'This pet profile has not been shared with your account.');
  const { rows } = await pool.query(
    `SELECT id, owner_id AS "ownerId", name, species, breed, age, sex,
            weight_kg AS "weightKg", microchip, created_at AS "createdAt"
     FROM pets WHERE id = $1`,
    [petId],
  );
  response.json({ pet: rows[0] });
}));

app.patch('/api/pets/:petId', authenticate, requireRole('owner'), asyncRoute(async (request, response) => {
  const petId = validate(idSchema, request.params.petId);
  const input = validate(petSchema, request.body);
  const { rows } = await pool.query(
    `UPDATE pets SET name = $3, species = $4, breed = $5, age = $6, sex = $7,
                     weight_kg = $8, microchip = $9, updated_at = now()
     WHERE id = $1 AND owner_id = $2
     RETURNING id, owner_id AS "ownerId", name, species, breed, age, sex,
               weight_kg AS "weightKg", microchip, updated_at AS "updatedAt"`,
    [petId, request.user.id, input.name, input.species, input.breed, input.age, input.sex, input.weightKg, input.microchip],
  );
  if (!rows[0]) fail(404, 'Pet profile not found.');
  await audit(pool, request.user.id, 'Pet profile updated', 'pet', petId);
  response.json({ pet: rows[0] });
}));

app.delete('/api/pets/:petId', authenticate, requireRole('owner'), asyncRoute(async (request, response) => {
  const petId = validate(idSchema, request.params.petId);
  const result = await pool.query(
    'DELETE FROM pets WHERE id = $1 AND owner_id = $2',
    [petId, request.user.id],
  );
  if (!result.rowCount) fail(404, 'Pet profile not found.');
  await audit(pool, request.user.id, 'Pet profile deleted', 'pet', petId);
  response.status(204).end();
}));

app.get('/api/pets/:petId/health-records', authenticate, asyncRoute(async (request, response) => {
  const petId = validate(idSchema, request.params.petId);
  if (!(await hasPetAccess(pool, petId, request.user))) fail(403, 'Health records are private unless the owner shares access.');
  const { rows } = await pool.query(
    `SELECT id, pet_id AS "petId", created_by AS "createdBy", title,
            record_type AS type, provider, record_date AS date,
            next_due_at AS "nextDueAt", vet_name AS "vetName",
            attachment_name AS "attachmentName", created_at AS "createdAt"
     FROM health_records WHERE pet_id = $1 ORDER BY record_date DESC`,
    [petId],
  );
  response.json({ records: rows });
}));

app.get('/api/pets/:petId/access-grants', authenticate, requireRole('owner'), asyncRoute(async (request, response) => {
  const petId = validate(idSchema, request.params.petId);
  const { rows } = await pool.query(
    `SELECT g.id, g.pet_id AS "petId", g.recipient_id AS "recipientId",
            u.display_name AS recipient, g.sections,
            g.expires_at AS "expiresAt", g.revoked_at AS "revokedAt",
            g.created_at AS "createdAt"
     FROM pet_access_grants g JOIN users u ON u.id = g.recipient_id
     JOIN pets p ON p.id = g.pet_id
     WHERE g.pet_id = $1 AND p.owner_id = $2 AND g.revoked_at IS NULL
     ORDER BY g.created_at DESC`,
    [petId, request.user.id],
  );
  response.json({ grants: rows });
}));

app.post('/api/pets/:petId/health-records', authenticate, asyncRoute(async (request, response) => {
  const petId = validate(idSchema, request.params.petId);
  const input = validate(z.object({
    title: z.string().trim().min(1).max(160),
    type: z.string().trim().min(1).max(80),
    provider: z.string().trim().min(1).max(160),
    date: z.iso.date(),
    nextDueAt: z.iso.date().nullable().optional(),
    vetName: z.string().trim().max(160).nullable().optional(),
    attachmentName: z.string().trim().max(255).nullable().optional(),
    attachmentStorageKey: z.string().trim().max(1024).nullable().optional(),
  }).strict(), request.body);

  const ownerCheck = await pool.query('SELECT owner_id FROM pets WHERE id = $1', [petId]);
  if (!ownerCheck.rowCount) fail(404, 'Pet profile not found.');
  const isOwner = ownerCheck.rows[0].owner_id === request.user.id;
  if (!isOwner) {
    if (request.activeRole !== 'veterinarian' ||
        !(await hasPetAccess(pool, petId, request.user, 'health'))) {
      fail(403, 'Only the owner or a veterinarian with an active health-record grant can add records.');
    }
  }
  const { rows } = await transaction(async (client) => {
    const result = await client.query(
      `INSERT INTO health_records
        (pet_id, created_by, title, record_type, provider, record_date, next_due_at,
         vet_name, attachment_name, attachment_storage_key)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING id, pet_id AS "petId", title, record_type AS type, provider,
                 record_date AS date, next_due_at AS "nextDueAt",
                 vet_name AS "vetName", attachment_name AS "attachmentName"`,
      [petId, request.user.id, input.title, input.type, input.provider, input.date,
        input.nextDueAt ?? null, input.vetName ?? null, input.attachmentName ?? null,
        input.attachmentStorageKey ?? null],
    );
    await audit(client, request.user.id, 'Health record added', 'pet', petId);
    return result;
  });
  response.status(201).json({ record: rows[0] });
}));

app.post('/api/pets/:petId/access-grants', authenticate, requireRole('owner'), asyncRoute(async (request, response) => {
  const petId = validate(idSchema, request.params.petId);
  const input = validate(z.object({
    recipientId: idSchema,
    sections: z.array(z.enum(['health', 'vaccinations', 'care essentials', 'all'])).min(1),
    expiresAt: z.iso.datetime().nullable().optional(),
  }).strict(), request.body);
  const pet = await pool.query('SELECT id FROM pets WHERE id = $1 AND owner_id = $2', [petId, request.user.id]);
  if (!pet.rowCount) fail(404, 'Pet profile not found.');
  if (input.recipientId === request.user.id) fail(400, 'Choose a different recipient.');
  const recipient = await getUserWithRoles(pool, input.recipientId);
  if (!recipient) fail(404, 'Recipient account not found.');
  const { rows } = await pool.query(
    `INSERT INTO pet_access_grants (pet_id, owner_id, recipient_id, sections, expires_at)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (pet_id, recipient_id) DO UPDATE
       SET sections = EXCLUDED.sections, expires_at = EXCLUDED.expires_at,
           revoked_at = NULL
     RETURNING id, pet_id AS "petId", recipient_id AS "recipientId",
               sections, expires_at AS "expiresAt"`,
    [petId, request.user.id, input.recipientId, input.sections, input.expiresAt ?? null],
  );
  await audit(pool, request.user.id, 'Pet data access granted', 'pet', petId, { recipientId: input.recipientId });
  response.status(201).json({ grant: rows[0] });
}));

app.delete('/api/pets/:petId/access-grants/:recipientId', authenticate, requireRole('owner'), asyncRoute(async (request, response) => {
  const petId = validate(idSchema, request.params.petId);
  const recipientId = validate(idSchema, request.params.recipientId);
  const result = await pool.query(
    `UPDATE pet_access_grants g SET revoked_at = now()
     FROM pets p
     WHERE g.pet_id = p.id AND g.pet_id = $1 AND g.recipient_id = $2
       AND p.owner_id = $3 AND g.revoked_at IS NULL`,
    [petId, recipientId, request.user.id],
  );
  if (!result.rowCount) fail(404, 'Active access grant not found.');
  await audit(pool, request.user.id, 'Pet data access revoked', 'pet', petId, { recipientId });
  response.status(204).end();
}));

app.get('/api/listings', asyncRoute(async (request, response) => {
  const filters = validate(z.object({
    species: z.string().trim().max(60).optional(),
    city: z.string().trim().max(100).optional(),
    minPrice: z.coerce.number().nonnegative().optional(),
    maxPrice: z.coerce.number().nonnegative().optional(),
  }).strict(), request.query);
  if (filters.minPrice !== undefined && filters.maxPrice !== undefined &&
      filters.minPrice > filters.maxPrice) fail(400, 'Minimum price must not exceed maximum price.');
  const { rows } = await pool.query(
    `SELECT l.id, l.seller_id AS "sellerId", l.title, l.species, l.breed, l.city,
            l.price, l.age, l.image_url AS "imageUrl", l.health_notes AS "healthNotes",
            l.status, u.display_name AS "sellerName",
            EXISTS (SELECT 1 FROM kyc_submissions k
                    WHERE k.user_id = l.seller_id AND k.role = 'seller' AND k.status = 'verified')
              AS "verifiedSeller"
     FROM listings l JOIN users u ON u.id = l.seller_id
     WHERE l.status = 'active'
       AND ($1::text IS NULL OR lower(l.species) = lower($1))
       AND ($2::text IS NULL OR lower(l.city) LIKE '%' || lower($2) || '%')
       AND ($3::numeric IS NULL OR l.price >= $3)
       AND ($4::numeric IS NULL OR l.price <= $4)
     ORDER BY l.created_at DESC`,
    [filters.species ?? null, filters.city ?? null, filters.minPrice ?? null, filters.maxPrice ?? null],
  );
  response.json({ listings: rows });
}));

app.get('/api/listings/favorites', authenticate, requireRole('owner'), asyncRoute(async (request, response) => {
  const { rows } = await pool.query(
    `SELECT l.id, l.seller_id AS "sellerId", l.title, l.species, l.breed, l.city,
            l.price, l.age, l.image_url AS "imageUrl", l.health_notes AS "healthNotes",
            l.status, u.display_name AS "sellerName", true AS favorite,
            EXISTS (SELECT 1 FROM kyc_submissions k
                    WHERE k.user_id = l.seller_id AND k.role = 'seller' AND k.status = 'verified')
              AS "verifiedSeller"
     FROM listing_favorites f JOIN listings l ON l.id = f.listing_id
     JOIN users u ON u.id = l.seller_id
     WHERE f.user_id = $1 AND l.status = 'active'
     ORDER BY f.created_at DESC`,
    [request.user.id],
  );
  response.json({ listings: rows });
}));

app.post('/api/listings', authenticate, requireRole('seller'), asyncRoute(async (request, response) => {
  const input = validate(listingSchema, request.body);
  const verified = await pool.query(
    `SELECT 1 FROM kyc_submissions WHERE user_id = $1 AND role = 'seller'
     AND status = 'verified'`,
    [request.user.id],
  );
  if (!verified.rowCount) fail(403, 'Seller verification must be approved before you publish a listing.');
  const { rows } = await transaction(async (client) => {
    const result = await client.query(
      `INSERT INTO listings (seller_id, title, species, breed, city, price, age, image_url, health_notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING id, seller_id AS "sellerId", title, species, breed, city,
                 price, age, image_url AS "imageUrl", health_notes AS "healthNotes",
                 status, created_at AS "createdAt"`,
      [request.user.id, input.title, input.species, input.breed, input.city,
        input.price, input.age, input.imageUrl, input.healthNotes],
    );
    await audit(client, request.user.id, 'Listing submitted for review', 'listing', result.rows[0].id);
    return result;
  });
  response.status(201).json({ listing: rows[0] });
}));

app.get('/api/listings/mine', authenticate, requireRole('seller'), asyncRoute(async (request, response) => {
  const { rows } = await pool.query(
    `SELECT id, title, species, breed, city, price, age, image_url AS "imageUrl",
            health_notes AS "healthNotes", status, created_at AS "createdAt"
     FROM listings WHERE seller_id = $1 ORDER BY created_at DESC`,
    [request.user.id],
  );
  response.json({ listings: rows });
}));

app.patch('/api/listings/:listingId', authenticate, requireRole('seller'), asyncRoute(async (request, response) => {
  const listingId = validate(idSchema, request.params.listingId);
  const input = validate(listingSchema, request.body);
  const { rows } = await pool.query(
    `UPDATE listings SET title = $3, species = $4, breed = $5, city = $6,
                         price = $7, age = $8, image_url = $9, health_notes = $10,
                         status = CASE WHEN status = 'active' THEN 'pending_review' ELSE status END,
                         updated_at = now()
     WHERE id = $1 AND seller_id = $2 AND status IN ('pending_review', 'active', 'rejected')
     RETURNING id, title, species, breed, city, price, age,
               image_url AS "imageUrl", health_notes AS "healthNotes", status`,
    [listingId, request.user.id, input.title, input.species, input.breed, input.city,
      input.price, input.age, input.imageUrl, input.healthNotes],
  );
  if (!rows[0]) fail(404, 'Editable listing not found.');
  await audit(pool, request.user.id, 'Listing updated', 'listing', listingId);
  response.json({ listing: rows[0] });
}));

app.put('/api/listings/:listingId/favorite', authenticate, requireRole('owner'), asyncRoute(async (request, response) => {
  const listingId = validate(idSchema, request.params.listingId);
  const { favorite } = validate(z.object({ favorite: z.boolean() }).strict(), request.body);
  if (favorite) {
    const result = await pool.query(
      `INSERT INTO listing_favorites (listing_id, user_id)
       SELECT id, $2 FROM listings WHERE id = $1 AND status = 'active'
       ON CONFLICT DO NOTHING`,
      [listingId, request.user.id],
    );
    if (!result.rowCount) fail(404, 'Active listing not found.');
  } else {
    await pool.query('DELETE FROM listing_favorites WHERE listing_id = $1 AND user_id = $2', [listingId, request.user.id]);
  }
  response.json({ favorite });
}));

app.post('/api/listings/:listingId/reports', authenticate, requireRole('owner'), asyncRoute(async (request, response) => {
  const listingId = validate(idSchema, request.params.listingId);
  const { reason } = validate(z.object({
    reason: z.string().trim().min(1).max(2000),
  }).strict(), request.body);
  const { rows } = await pool.query(
    `INSERT INTO listing_reports (listing_id, reporter_id, reason)
     SELECT id, $2, $3 FROM listings WHERE id = $1 AND status = 'active'
     RETURNING id, listing_id AS "listingId", status, created_at AS "createdAt"`,
    [listingId, request.user.id, reason],
  );
  if (!rows[0]) fail(404, 'Active listing not found.');
  response.status(201).json({ report: rows[0] });
}));

app.post('/api/listings/:listingId/visit-requests', authenticate, requireRole('owner'), asyncRoute(async (request, response) => {
  const listingId = validate(idSchema, request.params.listingId);
  const input = validate(z.object({
    scheduledAt: z.iso.datetime(),
    message: z.string().trim().max(2000).default(''),
  }).strict(), request.body);
  if (new Date(input.scheduledAt) <= new Date()) {
    fail(400, 'Choose a future date and time for the visit.');
  }

  const visitRequest = await transaction(async (client) => {
    const listing = await client.query(
      `SELECT id, seller_id AS "sellerId", title
       FROM listings WHERE id = $1 AND status = 'active' FOR SHARE`,
      [listingId],
    );
    if (!listing.rows[0]) fail(404, 'Active listing not found.');
    if (listing.rows[0].sellerId === request.user.id) {
      fail(400, 'You cannot request a visit for your own listing.');
    }
    const { rows } = await client.query(
      `INSERT INTO visit_requests (listing_id, buyer_id, scheduled_at, message)
       VALUES ($1, $2, $3, $4)
       RETURNING id, listing_id AS "listingId", buyer_id AS "buyerId",
                 scheduled_at AS "scheduledAt", message, status,
                 created_at AS "createdAt"`,
      [listingId, request.user.id, input.scheduledAt, input.message],
    );
    await notify(
      client,
      listing.rows[0].sellerId,
      'New pet visit request',
      `A buyer requested a visit for "${listing.rows[0].title}".`,
    );
    await audit(
      client,
      request.user.id,
      'Pet visit requested',
      'visit_request',
      rows[0].id,
      { listingId },
    );
    return rows[0];
  });

  response.status(201).json({ visitRequest });
}));

app.get('/api/visit-requests', authenticate, requireRole('owner', 'seller'), asyncRoute(async (request, response) => {
  const isOwner = request.activeRole === 'owner';
  const accountColumn = isOwner ? 'vr.buyer_id' : 'l.seller_id';
  const { rows } = await pool.query(
    `SELECT vr.id, vr.listing_id AS "listingId", vr.buyer_id AS "buyerId",
            buyer.display_name AS "buyerName", seller.display_name AS "sellerName",
            l.seller_id AS "sellerId",
            l.title AS "listingTitle", l.city, vr.scheduled_at AS "scheduledAt",
            vr.message, vr.status, vr.created_at AS "createdAt",
            vr.updated_at AS "updatedAt"
     FROM visit_requests vr
     JOIN listings l ON l.id = vr.listing_id
     JOIN users buyer ON buyer.id = vr.buyer_id
     JOIN users seller ON seller.id = l.seller_id
     WHERE ${accountColumn} = $1
     ORDER BY vr.scheduled_at DESC, vr.created_at DESC`,
    [request.user.id],
  );
  response.json({ visitRequests: rows });
}));

app.patch('/api/visit-requests/:visitRequestId/status', authenticate, requireRole('owner', 'seller'), asyncRoute(async (request, response) => {
  const visitRequestId = validate(idSchema, request.params.visitRequestId);
  const { status } = validate(z.object({
    status: z.enum(['confirmed', 'declined', 'cancelled']),
  }).strict(), request.body);
  const ownerAction = status === 'cancelled';
  if (ownerAction
    ? request.activeRole !== 'owner'
    : request.activeRole !== 'seller') {
    fail(403, ownerAction
      ? 'Only the buyer can cancel a visit request.'
      : 'Only the seller can confirm or decline a visit request.');
  }

  const updated = await transaction(async (client) => {
    const accountColumn = ownerAction ? 'vr.buyer_id' : 'l.seller_id';
    const allowedStatuses = ownerAction
      ? ['requested', 'confirmed']
      : ['requested'];
    const { rows } = await client.query(
      `UPDATE visit_requests vr
       SET status = $3, updated_at = now()
       FROM listings l
       WHERE vr.id = $1 AND vr.listing_id = l.id
         AND ${accountColumn} = $2
         AND vr.status = ANY($4::text[])
       RETURNING vr.id, vr.listing_id AS "listingId",
                 vr.buyer_id AS "buyerId", l.seller_id AS "sellerId",
                 vr.status`,
      [visitRequestId, request.user.id, status, allowedStatuses],
    );
    if (!rows[0]) fail(404, 'Visit request not found or no longer actionable.');
    const recipientId = ownerAction ? rows[0].sellerId : rows[0].buyerId;
    await notify(
      client,
      recipientId,
      'Pet visit request updated',
      `Your visit request was ${status}.`,
    );
    await audit(
      client,
      request.user.id,
      'Pet visit request status updated',
      'visit_request',
      visitRequestId,
      { status },
    );
    return rows[0];
  });
  response.json({ visitRequest: updated });
}));

app.get('/api/products', asyncRoute(async (_request, response) => {
  const { rows } = await pool.query(
    `SELECT p.id, p.vendor_id AS "vendorId", u.display_name AS "vendorName",
            p.name, p.price, p.stock, p.image_url AS "imageUrl",
            p.created_at AS "createdAt"
     FROM products p JOIN users u ON u.id = p.vendor_id
     WHERE p.published AND EXISTS (
       SELECT 1 FROM kyc_submissions k
       WHERE k.user_id = p.vendor_id AND k.role = 'vendor' AND k.status = 'verified'
     )
     ORDER BY p.name`,
  );
  response.json({ products: rows });
}));

app.get('/api/products/mine', authenticate, requireRole('vendor'), asyncRoute(async (request, response) => {
  const { rows } = await pool.query(
    `SELECT p.id, p.vendor_id AS "vendorId", u.display_name AS "vendorName",
            p.name, p.price, p.stock, p.image_url AS "imageUrl",
            p.published, p.created_at AS "createdAt"
     FROM products p JOIN users u ON u.id = p.vendor_id
     WHERE p.vendor_id = $1 ORDER BY p.created_at DESC`,
    [request.user.id],
  );
  response.json({ products: rows });
}));

app.post('/api/products', authenticate, requireRole('vendor'), asyncRoute(async (request, response) => {
  const input = validate(z.object({
    name: z.string().trim().min(1).max(160),
    price: z.coerce.number().positive().max(100_000_000),
    stock: z.coerce.number().int().nonnegative().max(1_000_000),
    imageUrl: z.string().trim().max(2048).default(''),
  }).strict(), request.body);
  const verified = await pool.query(
    `SELECT 1 FROM kyc_submissions WHERE user_id = $1 AND role = 'vendor' AND status = 'verified'`,
    [request.user.id],
  );
  if (!verified.rowCount) fail(403, 'Vendor verification must be approved before publishing products.');
  const { rows } = await pool.query(
    `INSERT INTO products (vendor_id, name, price, stock, image_url, published)
     VALUES ($1, $2, $3, $4, $5, true)
     RETURNING id, vendor_id AS "vendorId", name, price, stock, image_url AS "imageUrl"`,
    [request.user.id, input.name, input.price, input.stock, input.imageUrl],
  );
  await audit(pool, request.user.id, 'Product published', 'product', rows[0].id);
  response.status(201).json({ product: rows[0] });
}));

app.patch('/api/products/:productId', authenticate, requireRole('vendor'), asyncRoute(async (request, response) => {
  const productId = validate(idSchema, request.params.productId);
  const input = validate(z.object({
    name: z.string().trim().min(1).max(160),
    price: z.coerce.number().positive().max(100_000_000),
    stock: z.coerce.number().int().nonnegative().max(1_000_000),
    imageUrl: z.string().trim().max(2048).default(''),
  }).strict(), request.body);
  const { rows } = await pool.query(
    `UPDATE products SET name = $3, price = $4, stock = $5,
                         image_url = $6, updated_at = now()
     WHERE id = $1 AND vendor_id = $2
     RETURNING id, vendor_id AS "vendorId", name, price, stock,
               image_url AS "imageUrl", published`,
    [productId, request.user.id, input.name, input.price, input.stock, input.imageUrl],
  );
  if (!rows[0]) fail(404, 'Product not found.');
  await audit(pool, request.user.id, 'Product updated', 'product', productId);
  response.json({ product: rows[0] });
}));

app.get('/api/orders', authenticate, asyncRoute(async (request, response) => {
  let query;
  let values;
  if (request.activeRole === 'owner') {
    query = `SELECT o.id, o.status, o.payment_status AS "paymentStatus",
                    o.total, o.created_at AS "createdAt",
                    json_agg(json_build_object('productId', oi.product_id,
                      'name', p.name, 'quantity', oi.quantity,
                      'unitPrice', oi.unit_price, 'vendorId', oi.vendor_id)) AS items
             FROM orders o JOIN order_items oi ON oi.order_id = o.id
             JOIN products p ON p.id = oi.product_id
             WHERE o.buyer_id = $1 GROUP BY o.id ORDER BY o.created_at DESC`;
    values = [request.user.id];
  } else if (request.activeRole === 'vendor') {
    query = `SELECT o.id, o.status, o.payment_status AS "paymentStatus",
                    o.total, o.created_at AS "createdAt",
                    json_agg(json_build_object('productId', oi.product_id,
                      'name', p.name, 'quantity', oi.quantity,
                      'unitPrice', oi.unit_price)) AS items
             FROM orders o JOIN order_items oi ON oi.order_id = o.id
             JOIN products p ON p.id = oi.product_id
             WHERE oi.vendor_id = $1 GROUP BY o.id ORDER BY o.created_at DESC`;
    values = [request.user.id];
  } else {
    fail(403, 'Orders are available to owners and vendors.');
  }
  const { rows } = await pool.query(query, values);
  response.json({ orders: rows });
}));

app.post('/api/orders', authenticate, requireRole('owner'), asyncRoute(async (request, response) => {
  const { items } = validate(z.object({
    items: z.array(z.object({
      productId: idSchema,
      quantity: z.number().int().positive().max(100),
    }).strict()).min(1).max(50),
  }).strict(), request.body);
  const itemMap = new Map();
  for (const item of items) itemMap.set(item.productId, (itemMap.get(item.productId) ?? 0) + item.quantity);

  const order = await transaction(async (client) => {
    const productIds = [...itemMap.keys()];
    const { rows: products } = await client.query(
      `SELECT p.id, p.vendor_id, p.name, p.price, p.stock
       FROM products p
       JOIN kyc_submissions k ON k.user_id = p.vendor_id
         AND k.role = 'vendor' AND k.status = 'verified'
       WHERE p.id = ANY($1::uuid[]) AND p.published
       FOR UPDATE OF p`,
      [productIds],
    );
    if (products.length !== productIds.length) fail(409, 'A product is unavailable.');
    let total = 0;
    for (const product of products) {
      const quantity = itemMap.get(product.id);
      if (product.stock < quantity) fail(409, `Insufficient stock for ${product.name}.`);
      total += Number(product.price) * quantity;
    }
    const created = await client.query(
      `INSERT INTO orders (buyer_id, total, payment_status)
       VALUES ($1, $2, 'pending')
       RETURNING id, status, payment_status AS "paymentStatus", total,
                 created_at AS "createdAt"`,
      [request.user.id, total],
    );
    for (const product of products) {
      const quantity = itemMap.get(product.id);
      await client.query('UPDATE products SET stock = stock - $2, updated_at = now() WHERE id = $1', [product.id, quantity]);
      await client.query(
        `INSERT INTO order_items (order_id, product_id, vendor_id, quantity, unit_price)
         VALUES ($1, $2, $3, $4, $5)`,
        [created.rows[0].id, product.id, product.vendor_id, quantity, product.price],
      );
    }
    await audit(client, request.user.id, 'Order created; payment pending', 'order', created.rows[0].id);
    return created.rows[0];
  });
  response.status(201).json({ order });
}));

app.post('/api/orders/:orderId/pay', authenticate, requireRole('owner'), asyncRoute(async (request, response) => {
  const orderId = validate(idSchema, request.params.orderId);
  const input = validate(z.object({
    simulateUnavailable: z.boolean().default(false),
  }).strict(), request.body);
  if (input.simulateUnavailable && !development) {
    fail(400, 'Payment failure simulation is available only in development.');
  }

  const payment = await transaction(async (client) => {
    const { rows } = await client.query(
      `SELECT id, buyer_id AS "buyerId", total, payment_status AS "paymentStatus"
       FROM orders WHERE id = $1 AND buyer_id = $2 FOR UPDATE`,
      [orderId, request.user.id],
    );
    const order = rows[0];
    if (!order) fail(404, 'Order not found.');
    if (order.paymentStatus === 'paid') {
      return { order, providerMessage: 'This order is already paid.' };
    }
    if (order.paymentStatus !== 'pending') {
      fail(409, 'This order is no longer awaiting payment.');
    }

    const result = await paymentProvider.charge({
      amount: Number(order.total),
      currency: 'PKR',
      simulateUnavailable: input.simulateUnavailable,
    });
    if (result.status !== 'paid') {
      await client.query(
        `UPDATE products p SET stock = p.stock + oi.quantity, updated_at = now()
         FROM order_items oi WHERE oi.order_id = $1 AND oi.product_id = p.id`,
        [orderId],
      );
      const { rows: failedOrders } = await client.query(
        `UPDATE orders SET status = 'Cancelled', payment_status = 'failed',
                           updated_at = now()
         WHERE id = $1 AND buyer_id = $2 AND payment_status = 'pending'
         RETURNING id, status, payment_status AS "paymentStatus", total`,
        [orderId, request.user.id],
      );
      if (!failedOrders[0]) fail(409, 'The order payment state changed. Refresh and try again.');
      await notify(
        client,
        request.user.id,
        'Payment was not completed',
        `Order ${orderId} was cancelled. No charge was made.`,
      );
      await audit(client, request.user.id, 'Mock payment unavailable; order cancelled and stock released', 'order', orderId);
      return { order: failedOrders[0], providerMessage: result.message };
    }

    const { rows: paidOrders } = await client.query(
      `UPDATE orders SET payment_status = 'paid', payment_reference = $3,
                         updated_at = now()
       WHERE id = $1 AND buyer_id = $2 AND payment_status = 'pending'
       RETURNING id, status, payment_status AS "paymentStatus", total,
                 created_at AS "createdAt"`,
      [orderId, request.user.id, result.reference],
    );
    if (!paidOrders[0]) fail(409, 'The order payment state changed. Refresh and try again.');
    await notify(
      client,
      request.user.id,
      'Order confirmed',
      `Order ${orderId} was paid using the mock provider. No real charge was made.`,
    );
    await audit(client, request.user.id, 'Mock payment approved', 'order', orderId, {
      paymentReference: result.reference,
      amount: Number(order.total),
      currency: 'PKR',
    });
    return { order: paidOrders[0], providerMessage: result.message };
  });
  if (payment.order.paymentStatus !== 'paid') {
    fail(503, payment.providerMessage);
  }
  response.json(payment);
}));

app.patch('/api/orders/:orderId/status', authenticate, requireRole('vendor'), asyncRoute(async (request, response) => {
  const orderId = validate(idSchema, request.params.orderId);
  const { status } = validate(z.object({
    status: z.enum(['Processing', 'Shipped', 'Delivered', 'Cancelled']),
  }).strict(), request.body);
  const updated = await transaction(async (client) => {
    const { rows } = await client.query(
      `UPDATE orders o SET status = $3, updated_at = now()
       WHERE o.id = $1 AND EXISTS (
         SELECT 1 FROM order_items oi WHERE oi.order_id = o.id AND oi.vendor_id = $2
       )
       RETURNING o.id, o.buyer_id AS "buyerId", o.status`,
      [orderId, request.user.id, status],
    );
    if (!rows[0]) fail(404, 'Vendor order not found.');
    await notify(client, rows[0].buyerId, 'Order status updated', `Order ${orderId} is now ${status}.`);
    await audit(client, request.user.id, 'Order status updated', 'order', orderId, { status });
    return rows[0];
  });
  response.json({ order: updated });
}));

app.post('/api/sitting/bookings', authenticate, requireRole('owner'), asyncRoute(async (request, response) => {
  const input = validate(z.object({
    sitterId: idSchema,
    petId: idSchema,
    startsAt: z.iso.datetime(),
    endsAt: z.iso.datetime(),
    arrangement: z.string().trim().min(1).max(100),
    instructions: z.string().trim().min(1).max(5000),
    emergencyName: z.string().trim().min(1).max(100),
    emergencyPhone: z.string().trim().min(7).max(40),
  }).strict(), request.body);
  if (new Date(input.startsAt) <= new Date() || new Date(input.endsAt) <= new Date(input.startsAt)) {
    fail(400, 'Choose a future start and a later end time.');
  }
  const result = await transaction(async (client) => {
    const pet = await client.query('SELECT id FROM pets WHERE id = $1 AND owner_id = $2', [input.petId, request.user.id]);
    if (!pet.rowCount) fail(404, 'Pet profile not found.');
    const sitter = await client.query(
      `SELECT 1 FROM user_roles ur JOIN kyc_submissions k
       ON k.user_id = ur.user_id AND k.role = 'sitter' AND k.status = 'verified'
       WHERE ur.user_id = $1 AND ur.role = 'sitter'`,
      [input.sitterId],
    );
    if (!sitter.rowCount) fail(404, 'Verified sitter not found.');
    const { rows } = await client.query(
      `INSERT INTO sitter_bookings
        (owner_id, sitter_id, pet_id, starts_at, ends_at, arrangement, instructions,
         emergency_name, emergency_phone)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING id, owner_id AS "ownerId", sitter_id AS "sitterId", pet_id AS "petId",
                 starts_at AS "startsAt", ends_at AS "endsAt", arrangement,
                 status, created_at AS "createdAt"`,
      [request.user.id, input.sitterId, input.petId, input.startsAt, input.endsAt,
        input.arrangement, input.instructions, input.emergencyName, input.emergencyPhone],
    );
    await notify(client, input.sitterId, 'New sitting request', 'A pet owner sent you a booking request.');
    await audit(client, request.user.id, 'Sitting booking requested', 'booking', rows[0].id);
    return rows[0];
  });
  response.status(201).json({ booking: result });
}));

app.get('/api/sitting/bookings', authenticate, asyncRoute(async (request, response) => {
  if (!['owner', 'sitter'].includes(request.activeRole)) fail(403, 'Bookings are available to owners and sitters.');
  const owner = request.activeRole === 'owner';
  const { rows } = await pool.query(
    `SELECT b.id, b.owner_id AS "ownerId", b.sitter_id AS "sitterId",
            b.pet_id AS "petId", p.name AS "petName", b.starts_at AS "startsAt",
            b.ends_at AS "endsAt", b.arrangement, b.instructions,
            b.emergency_name AS "emergencyName", b.emergency_phone AS "emergencyPhone",
            b.status, b.created_at AS "createdAt"
     FROM sitter_bookings b JOIN pets p ON p.id = b.pet_id
     WHERE b.${owner ? 'owner_id' : 'sitter_id'} = $1 ORDER BY b.starts_at DESC`,
    [request.user.id],
  );
  response.json({ bookings: rows });
}));

app.patch('/api/sitting/bookings/:bookingId/status', authenticate, asyncRoute(async (request, response) => {
  const bookingId = validate(idSchema, request.params.bookingId);
  const { status } = validate(z.object({
    status: z.enum(['confirmed', 'declined', 'cancelled', 'complete']),
  }).strict(), request.body);
  const authorizedRole = status === 'confirmed' || status === 'declined' || status === 'complete'
    ? 'sitter'
    : 'owner';
  if (request.activeRole !== authorizedRole) fail(403, `Only the booking ${authorizedRole} can make this change.`);
  const updated = await transaction(async (client) => {
    const column = authorizedRole === 'owner' ? 'owner_id' : 'sitter_id';
    const { rows } = await client.query(
      `UPDATE sitter_bookings SET status = $3
       WHERE id = $1 AND ${column} = $2 AND status IN ('requested', 'confirmed')
       RETURNING id, owner_id AS "ownerId", sitter_id AS "sitterId", status`,
      [bookingId, request.user.id, status],
    );
    if (!rows[0]) fail(404, 'Booking not found or no longer active.');
    const recipientId = authorizedRole === 'owner' ? rows[0].sitterId : rows[0].ownerId;
    await notify(client, recipientId, 'Sitting booking updated', `Booking status is ${status}.`);
    await audit(client, request.user.id, 'Sitting booking status updated', 'booking', bookingId, { status });
    return rows[0];
  });
  response.json({ booking: updated });
}));

app.post('/api/veterinary/availability', authenticate, requireRole('veterinarian'), asyncRoute(async (request, response) => {
  const input = validate(z.object({
    startsAt: z.iso.datetime(),
    endsAt: z.iso.datetime(),
  }).strict(), request.body);
  if (new Date(input.startsAt) <= new Date() || new Date(input.endsAt) <= new Date(input.startsAt)) {
    fail(400, 'Availability must be a future time range.');
  }
  const { rows } = await pool.query(
    `INSERT INTO vet_availability (veterinarian_id, starts_at, ends_at)
     VALUES ($1, $2, $3)
     ON CONFLICT (veterinarian_id, starts_at) DO NOTHING
     RETURNING id, starts_at AS "startsAt", ends_at AS "endsAt"`,
    [request.user.id, input.startsAt, input.endsAt],
  );
  if (!rows[0]) fail(409, 'That availability slot already exists.');
  await audit(pool, request.user.id, 'Veterinary availability published', 'availability', rows[0].id);
  response.status(201).json({ availability: rows[0] });
}));

app.get('/api/veterinary/availability', asyncRoute(async (_request, response) => {
  const { rows } = await pool.query(
    `SELECT a.id, a.veterinarian_id AS "veterinarianId", u.display_name AS veterinarian,
            a.starts_at AS "startsAt", a.ends_at AS "endsAt"
     FROM vet_availability a
     JOIN users u ON u.id = a.veterinarian_id
     JOIN kyc_submissions k ON k.user_id = a.veterinarian_id
       AND k.role = 'veterinarian' AND k.status = 'verified'
     WHERE NOT a.is_booked AND a.starts_at > now()
     ORDER BY a.starts_at`,
  );
  response.json({ availability: rows });
}));

app.get('/api/providers', asyncRoute(async (request, response) => {
  const { role } = validate(z.object({
    role: z.enum(['sitter', 'veterinarian']),
  }).strict(), request.query);
  const { rows } = await pool.query(
    `SELECT u.id, u.display_name AS "displayName", ur.role
     FROM user_roles ur JOIN users u ON u.id = ur.user_id
     JOIN kyc_submissions k ON k.user_id = u.id AND k.role = ur.role
     WHERE ur.role = $1 AND k.status = 'verified' AND u.deleted_at IS NULL
     ORDER BY u.display_name`,
    [role],
  );
  response.json({ providers: rows });
}));

app.post('/api/veterinary/appointments', authenticate, requireRole('owner'), asyncRoute(async (request, response) => {
  const input = validate(z.object({
    availabilityId: idSchema,
    petId: idSchema,
    type: z.string().trim().min(1).max(120),
  }).strict(), request.body);
  const appointment = await transaction(async (client) => {
    const pet = await client.query('SELECT 1 FROM pets WHERE id = $1 AND owner_id = $2', [input.petId, request.user.id]);
    if (!pet.rowCount) fail(404, 'Pet profile not found.');
    const slot = await client.query(
      `SELECT id, veterinarian_id FROM vet_availability
       WHERE id = $1 AND NOT is_booked AND starts_at > now() FOR UPDATE`,
      [input.availabilityId],
    );
    if (!slot.rowCount) fail(409, 'This veterinary slot is no longer available.');
    const { rows } = await client.query(
      `INSERT INTO vet_appointments (veterinarian_id, owner_id, pet_id, availability_id, appointment_type)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, veterinarian_id AS "veterinarianId", owner_id AS "ownerId",
                 pet_id AS "petId", availability_id AS "availabilityId",
                 appointment_type AS type, status`,
      [slot.rows[0].veterinarian_id, request.user.id, input.petId, input.availabilityId, input.type],
    );
    await client.query('UPDATE vet_availability SET is_booked = true WHERE id = $1', [input.availabilityId]);
    await notify(client, slot.rows[0].veterinarian_id, 'New appointment', 'A pet owner booked your published appointment slot.');
    await audit(client, request.user.id, 'Veterinary appointment booked', 'appointment', rows[0].id);
    return rows[0];
  });
  response.status(201).json({ appointment });
}));

app.get('/api/veterinary/appointments', authenticate, asyncRoute(async (request, response) => {
  const column = request.activeRole === 'owner'
    ? 'owner_id'
    : request.activeRole === 'veterinarian'
      ? 'veterinarian_id'
      : null;
  if (!column) fail(403, 'Appointments are available to owners and veterinarians.');
  const { rows } = await pool.query(
    `SELECT a.id, a.veterinarian_id AS "veterinarianId", a.owner_id AS "ownerId",
            a.pet_id AS "petId", p.name AS "petName", a.appointment_type AS type,
            a.status, a.consultation_notes AS "consultationNotes",
            v.starts_at AS "startsAt", v.ends_at AS "endsAt"
     FROM vet_appointments a
     JOIN pets p ON p.id = a.pet_id
     JOIN vet_availability v ON v.id = a.availability_id
     WHERE a.${column} = $1 ORDER BY v.starts_at`,
    [request.user.id],
  );
  response.json({ appointments: rows });
}));

app.post('/api/veterinary/appointments/:appointmentId/notes', authenticate, requireRole('veterinarian'), asyncRoute(async (request, response) => {
  const appointmentId = validate(idSchema, request.params.appointmentId);
  const { notes } = validate(z.object({
    notes: z.string().trim().min(1).max(10000),
  }).strict(), request.body);
  const { rows } = await pool.query(
    `UPDATE vet_appointments SET consultation_notes = $3, status = 'Complete'
     WHERE id = $1 AND veterinarian_id = $2
     RETURNING id, status, consultation_notes AS notes`,
    [appointmentId, request.user.id, notes],
  );
  if (!rows[0]) fail(404, 'Appointment not found.');
  await audit(pool, request.user.id, 'Consultation notes saved', 'appointment', appointmentId);
  response.json({ appointment: rows[0] });
}));

app.get('/api/notifications', authenticate, asyncRoute(async (request, response) => {
  const { rows } = await pool.query(
    `SELECT id, title, body, read_at AS "readAt", created_at AS "createdAt"
     FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 100`,
    [request.user.id],
  );
  response.json({ notifications: rows });
}));

app.patch('/api/notifications/:notificationId/read', authenticate, asyncRoute(async (request, response) => {
  const notificationId = validate(idSchema, request.params.notificationId);
  const result = await pool.query(
    `UPDATE notifications SET read_at = COALESCE(read_at, now())
     WHERE id = $1 AND user_id = $2 RETURNING id`,
    [notificationId, request.user.id],
  );
  if (!result.rowCount) fail(404, 'Notification not found.');
  response.status(204).end();
}));

app.post('/api/support/requests', authenticate, asyncRoute(async (request, response) => {
  const input = validate(z.object({
    topic: z.string().trim().min(1).max(160),
    message: z.string().trim().min(1).max(5000),
  }).strict(), request.body);
  const { rows } = await pool.query(
    `INSERT INTO support_requests (user_id, topic, message)
     VALUES ($1, $2, $3)
     RETURNING id, topic, status, created_at AS "createdAt"`,
    [request.user.id, input.topic, input.message],
  );
  await audit(pool, request.user.id, 'Support request created', 'support_request', rows[0].id);
  response.status(201).json({ request: rows[0] });
}));

app.use((request, _response, next) => {
  next(new HttpError(404, `No API route for ${request.method} ${request.path}.`));
});

app.use((error, _request, response, _next) => {
  if (response.headersSent) return;
  if (error instanceof HttpError) {
    response.status(error.status).json({ error: error.message });
    return;
  }
  if (error instanceof z.ZodError) {
    response.status(400).json({ error: error.issues.map((issue) => issue.message).join('; ') });
    return;
  }
  if (error.message?.includes('CORS policy')) {
    response.status(403).json({ error: error.message });
    return;
  }
  console.error('Unhandled API error', error);
  response.status(500).json({ error: 'The server could not complete this request.' });
});

const server = app.listen(port, '0.0.0.0', () => {
  console.log(`PetVault API listening on port ${port}`);
});

async function shutdown(signal) {
  console.log(`Received ${signal}; closing API and database connections.`);
  server.close(async (error) => {
    await pool.end();
    if (error) {
      console.error('Failed to close API server cleanly', error);
      process.exitCode = 1;
    }
  });
}

process.on('SIGTERM', () => void shutdown('SIGTERM'));
process.on('SIGINT', () => void shutdown('SIGINT'));
