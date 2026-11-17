import crypto from 'node:crypto';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { z } from 'zod';
import { loadConfig } from './config.js';
import { HttpError, asyncRoute, errorHandler } from './errors.js';
import { inTransaction } from './database.js';
import { sendOneTimeCode } from './email.js';
import {
  ADMIN_ROLE,
  DUMMY_PASSWORD_HASH,
  PUBLIC_ROLES,
  SUPPLY_ROLES,
  authenticateRequest,
  generateOneTimeCode,
  hashOneTimeCode,
  hashPassword,
  normalizeEmail,
  normalizePhone,
  publicUser,
  requireRole,
  requireVerifiedSupplyRole,
  safeEqualHex,
  signAccessToken,
  verifyPassword,
} from './security.js';
import { createNotification, writeAuditEvent } from './notifications.js';
import { registerKycRoutes } from './routes/kyc.js';
import { registerMarketplaceRoutes } from './routes/marketplace.js';
import { registerCommerceRoutes } from './routes/commerce.js';
import { registerServiceRoutes } from './routes/services.js';
import { registerAccountRoutes } from './routes/account.js';
import { registerAdminRoutes } from './routes/admin.js';

const uuid = z.string().uuid();
const emailSchema = z.string().trim().email().max(254);
const passwordSchema = z.string().min(8).max(72);
const text = (max = 500) => z.string().trim().min(1).max(max);
const optionalText = (max = 500) => z.string().trim().max(max).optional();

const registerSchema = z.object({
  displayName: text(120),
  email: emailSchema,
  phone: text(40),
  password: passwordSchema,
  role: z.enum(['owner', 'seller', 'sitter', 'veterinarian', 'vendor']).optional(),
}).strict();
const emailCodeSchema = z.object({
  email: emailSchema,
  code: z.string().regex(/^\d{6}$/),
}).strict();
const petSchema = z.object({
  name: text(120),
  species: text(80),
  breed: text(120),
  age: text(80),
  sex: z.enum(['Male', 'Female', 'Unknown', 'male', 'female', 'unknown']),
  weightKg: z.number().positive().max(1000),
  microchip: optionalText(80).default(''),
}).strict();
const healthRecordSchema = z.object({
  title: text(160),
  type: text(80),
  provider: text(160),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  nextDueAt: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  attachmentName: optionalText(180),
}).strict();
const accessGrantSchema = z.object({
  recipientId: uuid,
  sections: z.array(z.enum(['profile', 'health', 'medical', 'vaccination'])).min(1).max(4),
  expiresAt: z.string().datetime({ offset: true }).optional(),
}).strict();

function parse(schema, value) {
  return schema.parse(value);
}

function mapRow(row) {
  if (!row) return row;
  const numericFields = new Set([
    'age_days', 'weight_kg', 'price', 'total', 'unit_price', 'amount',
    'commission_amount', 'rating', 'score', 'stock', 'quantity',
  ]);
  return Object.fromEntries(
    Object.entries(row).map(([key, value]) => {
      const camelKey = key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
      if (value instanceof Date) {
        return [
          camelKey,
          ['record_date', 'next_due_at'].includes(key)
            ? value.toISOString().slice(0, 10)
            : value.toISOString(),
        ];
      }
      if (value !== null && numericFields.has(key)) {
        return [camelKey, Number(value)];
      }
      return [camelKey, value];
    }),
  );
}

function mapRows(rows) {
  return rows.map(mapRow);
}

function validateId(value) {
  return uuid.parse(value);
}

async function assertPetAccess(pool, req, petId, section) {
  const petResult = await pool.query(
    'SELECT id, owner_id FROM pets WHERE id = $1',
    [petId],
  );
  const pet = petResult.rows[0];
  if (!pet) throw new HttpError(404, 'Pet was not found.');
  if (req.user.activeRole === 'owner' && pet.owner_id === req.user.id) {
    return pet;
  }
  if (SUPPLY_ROLES.has(req.user.activeRole)) {
    await requireVerifiedSupplyRole(req, pool);
    const grantResult = await pool.query(
      `SELECT 1
         FROM pet_access_grants
        WHERE pet_id = $1
          AND owner_id = $2
          AND recipient_id = $3
          AND revoked_at IS NULL
          AND (expires_at IS NULL OR expires_at > now())
          AND sections && $4::text[]
        LIMIT 1`,
      [petId, pet.owner_id, req.user.id, [section]],
    );
    if (grantResult.rowCount > 0) return pet;
  }
  throw new HttpError(403, 'You do not have access to this pet information.');
}

function addAuthMiddleware(pool, config) {
  return asyncRoute(async (req, res, next) => {
    await authenticateRequest(req, pool, config);
    next();
  });
}

export function createApp({ pool, config = loadConfig(), emailSender = sendOneTimeCode }) {
  if (!pool) throw new Error('A PostgreSQL pool is required.');

  const app = express();
  const router = express.Router();
  const publicRouter = express.Router();
  const authenticate = addAuthMiddleware(pool, config);
  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 30,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Too many authentication requests. Try again later.' },
  });
  const routerRateLimiter = rateLimit({
    windowMs: 60 * 1000,
    limit: 240,
    standardHeaders: true,
    legacyHeaders: false,
  });

  app.disable('x-powered-by');
  app.use(helmet());
  app.use(cors({
    origin(origin, callback) {
      if (!origin || config.allowedOrigins.has(origin)) {
        callback(null, true);
      } else {
        callback(new HttpError(403, 'This origin is not allowed.'));
      }
    },
    methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Authorization', 'Content-Type', 'X-Active-Role'],
    maxAge: 600,
  }));
  app.use(express.json({ limit: '1mb', strict: true }));
  app.use((req, res, next) => {
    req.id = crypto.randomUUID();
    res.setHeader('X-Request-Id', req.id);
    next();
  });
  app.use('/api', routerRateLimiter);

  router.get('/health', asyncRoute(async (req, res) => {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', database: 'ok' });
  }));

  router.post('/auth/register', authLimiter, asyncRoute(async (req, res) => {
    if (req.body?.role === ADMIN_ROLE) {
      throw new HttpError(403, 'Admin accounts can only be provisioned by an administrator.');
    }
    const body = parse(registerSchema, req.body);
    const email = normalizeEmail(body.email);
    const phone = normalizePhone(body.phone);
    const requestedRole = body.role ?? 'owner';
    const roles = requestedRole === 'seller'
      ? ['owner', 'seller']
      : [requestedRole];
    const passwordHash = await hashPassword(body.password);
    const code = config.devAuthCodes
      ? config.devVerificationCode
      : generateOneTimeCode();
    const user = await inTransaction(pool, async (client) => {
      const insert = await client.query(
        `INSERT INTO users (email, display_name, phone, password_hash)
         VALUES ($1, $2, $3, $4)
         RETURNING id, email, display_name, phone`,
        [email, body.displayName, phone, passwordHash],
      );
      const created = insert.rows[0];
      for (const role of roles) {
        await client.query(
          'INSERT INTO user_roles (user_id, role) VALUES ($1, $2)',
          [created.id, role],
        );
      }
      const actualCodeHash = hashOneTimeCode(
        config.jwtSecret,
        created.id,
        'verify_email',
        code,
      );
      await client.query(
        `INSERT INTO verification_codes
           (user_id, purpose, code_hash, expires_at)
         VALUES ($1, 'verify_email', $2,
                 now() + ($3::integer * interval '1 minute'))`,
        [created.id, actualCodeHash, config.otpTtlMinutes],
      );
      return created;
    });

    await emailSender(config, {
      email,
      code,
      purpose: 'verify_email',
    });
    await writeAuditEvent(pool, {
      actorId: user.id,
      action: 'account.registered',
      resourceType: 'user',
      resourceId: user.id,
      metadata: { requestedRole },
    });
    res.status(201).json({
      message: 'Verification code issued.',
      ...(config.devAuthCodes ? { devCode: code } : {}),
    });
  }));

  router.post('/auth/verify', authLimiter, asyncRoute(async (req, res) => {
    const body = parse(emailCodeSchema, req.body);
    const email = normalizeEmail(body.email);
    const result = await inTransaction(pool, async (client) => {
      const userResult = await client.query(
        `SELECT id, email, display_name, email_verified_at, token_version
           FROM users
          WHERE email = $1 AND deleted_at IS NULL
          FOR UPDATE`,
        [email],
      );
      const user = userResult.rows[0];
      if (!user) throw new HttpError(400, 'The verification code is invalid or expired.');
      if (user.email_verified_at) {
        throw new HttpError(409, 'This account is already verified.');
      }
      const codeResult = await client.query(
        `SELECT id, code_hash, expires_at, consumed_at
           FROM verification_codes
          WHERE user_id = $1 AND purpose = 'verify_email'
          ORDER BY created_at DESC
          LIMIT 1
          FOR UPDATE`,
        [user.id],
      );
      const issued = codeResult.rows[0];
      const expected = hashOneTimeCode(
        config.jwtSecret,
        user.id,
        'verify_email',
        body.code,
      );
      if (!issued ||
          issued.consumed_at ||
          issued.expires_at <= new Date() ||
          !safeEqualHex(issued.code_hash, expected)) {
        throw new HttpError(400, 'The verification code is invalid or expired.');
      }
      await client.query(
        'UPDATE verification_codes SET consumed_at = now() WHERE id = $1',
        [issued.id],
      );
      const updated = await client.query(
        `UPDATE users
            SET email_verified_at = now(), updated_at = now()
          WHERE id = $1
          RETURNING id, email, display_name, email_verified_at, token_version`,
        [user.id],
      );
      const rolesResult = await client.query(
        'SELECT role FROM user_roles WHERE user_id = $1 ORDER BY role',
        [user.id],
      );
      return { user: updated.rows[0], roles: rolesResult.rows.map((row) => row.role) };
    });
    const user = publicUser(result.user, result.roles);
    const token = signAccessToken(result.user, config.jwtSecret, config.jwtExpiresIn);
    await writeAuditEvent(pool, {
      actorId: result.user.id,
      action: 'account.email_verified',
      resourceType: 'user',
      resourceId: result.user.id,
    });
    res.json({ token, user });
  }));

  router.post('/auth/resend-code', authLimiter, asyncRoute(async (req, res) => {
    const { email: rawEmail } = parse(
      z.object({ email: emailSchema }).strict(),
      req.body,
    );
    const email = normalizeEmail(rawEmail);
    const result = await pool.query(
      `SELECT id, email, email_verified_at
         FROM users
        WHERE email = $1 AND deleted_at IS NULL`,
      [email],
    );
    const user = result.rows[0];
    let devCode;
    if (user && !user.email_verified_at) {
      const recent = await pool.query(
        `SELECT 1 FROM verification_codes
          WHERE user_id = $1
            AND purpose = 'verify_email'
            AND created_at > now() - interval '60 seconds'
          LIMIT 1`,
        [user.id],
      );
      if (recent.rowCount > 0) {
        throw new HttpError(429, 'Please wait before requesting another code.');
      }
      const code = config.devAuthCodes
        ? config.devVerificationCode
        : generateOneTimeCode();
      const codeHash = hashOneTimeCode(
        config.jwtSecret,
        user.id,
        'verify_email',
        code,
      );
      await inTransaction(pool, async (client) => {
        await client.query(
          `UPDATE verification_codes
              SET consumed_at = now()
            WHERE user_id = $1
              AND purpose = 'verify_email'
              AND consumed_at IS NULL`,
          [user.id],
        );
        await client.query(
          `INSERT INTO verification_codes
             (user_id, purpose, code_hash, expires_at)
           VALUES ($1, 'verify_email', $2,
                   now() + ($3::integer * interval '1 minute'))`,
          [user.id, codeHash, config.otpTtlMinutes],
        );
      });
      await emailSender(config, { email, code, purpose: 'verify_email' });
      if (config.devAuthCodes) devCode = code;
    }
    res.json({
      message: 'If the account can be verified, a code has been issued.',
      ...(devCode ? { devCode } : {}),
    });
  }));

  router.post('/auth/password-reset', authLimiter, asyncRoute(async (req, res) => {
    const { email: rawEmail } = parse(
      z.object({ email: emailSchema }).strict(),
      req.body,
    );
    const email = normalizeEmail(rawEmail);
    const result = await pool.query(
      `SELECT id, email
         FROM users
        WHERE email = $1 AND deleted_at IS NULL`,
      [email],
    );
    const user = result.rows[0];
    let devCode;
    if (user) {
      const code = config.devAuthCodes
        ? config.devPasswordResetCode
        : generateOneTimeCode();
      const codeHash = hashOneTimeCode(
        config.jwtSecret,
        user.id,
        'reset_password',
        code,
      );
      await inTransaction(pool, async (client) => {
        await client.query(
          `UPDATE verification_codes
              SET consumed_at = now()
            WHERE user_id = $1
              AND purpose = 'reset_password'
              AND consumed_at IS NULL`,
          [user.id],
        );
        await client.query(
          `INSERT INTO verification_codes
             (user_id, purpose, code_hash, expires_at)
           VALUES ($1, 'reset_password', $2,
                   now() + ($3::integer * interval '1 minute'))`,
          [user.id, codeHash, config.otpTtlMinutes],
        );
      });
      await emailSender(config, { email, code, purpose: 'reset_password' });
      if (config.devAuthCodes) devCode = code;
    }
    res.json({
      message: 'If the account exists, a password reset code has been issued.',
      ...(devCode ? { devCode } : {}),
    });
  }));

  router.post('/auth/password-reset/confirm', authLimiter, asyncRoute(async (req, res) => {
    const body = parse(z.object({
      email: emailSchema,
      code: z.string().regex(/^\d{6}$/),
      newPassword: passwordSchema,
    }).strict(), req.body);
    const email = normalizeEmail(body.email);
    const passwordHash = await hashPassword(body.newPassword);
    const changed = await inTransaction(pool, async (client) => {
      const userResult = await client.query(
        `SELECT id FROM users
          WHERE email = $1 AND deleted_at IS NULL
          FOR UPDATE`,
        [email],
      );
      const user = userResult.rows[0];
      if (!user) return false;
      const codeResult = await client.query(
        `SELECT id, code_hash, expires_at, consumed_at
           FROM verification_codes
          WHERE user_id = $1 AND purpose = 'reset_password'
          ORDER BY created_at DESC
          LIMIT 1
          FOR UPDATE`,
        [user.id],
      );
      const issued = codeResult.rows[0];
      const expected = hashOneTimeCode(
        config.jwtSecret,
        user.id,
        'reset_password',
        body.code,
      );
      if (!issued ||
          issued.consumed_at ||
          issued.expires_at <= new Date() ||
          !safeEqualHex(issued.code_hash, expected)) {
        return false;
      }
      await client.query(
        'UPDATE verification_codes SET consumed_at = now() WHERE id = $1',
        [issued.id],
      );
      await client.query(
        `UPDATE users
            SET password_hash = $2,
                failed_login_attempts = 0,
                locked_until = NULL,
                token_version = token_version + 1,
                updated_at = now()
          WHERE id = $1`,
        [user.id, passwordHash],
      );
      return true;
    });
    if (!changed) throw new HttpError(400, 'The reset code is invalid or expired.');
    res.json({
      changed: true,
      message: 'Password updated. Sign in with your new password.',
    });
  }));

  router.post('/auth/login', authLimiter, asyncRoute(async (req, res) => {
    const body = parse(z.object({
      email: emailSchema,
      password: passwordSchema,
    }).strict(), req.body);
    const email = normalizeEmail(body.email);
    const client = await pool.connect();
    let loginResult;
    try {
      await client.query('BEGIN');
      const userResult = await client.query(
        `SELECT id, email, display_name, password_hash, email_verified_at,
                failed_login_attempts, locked_until, token_version, account_status
           FROM users
          WHERE email = $1 AND deleted_at IS NULL
          FOR UPDATE`,
        [email],
      );
      const user = userResult.rows[0];
      if (!user) {
        await client.query('ROLLBACK');
        await verifyPassword(body.password, DUMMY_PASSWORD_HASH);
        loginResult = {
          error: new HttpError(401, 'Email or password is incorrect.'),
        };
      } else if (user.locked_until && user.locked_until > new Date()) {
        await client.query('COMMIT');
        loginResult = {
          user,
          error: new HttpError(423, 'This account is temporarily locked. Try again later.'),
        };
      } else {
        const validPassword = await verifyPassword(body.password, user.password_hash);
        if (!validPassword) {
          const failures = user.failed_login_attempts + 1;
          const locked = failures >= 5;
          await client.query(
            `UPDATE users
                SET failed_login_attempts = $2,
                    locked_until = CASE
                      WHEN $3 THEN now() + interval '15 minutes'
                      ELSE NULL
                    END
              WHERE id = $1`,
            [user.id, locked ? 0 : failures, locked],
          );
          await client.query('COMMIT');
          loginResult = {
            user,
            error: new HttpError(
              locked ? 423 : 401,
              locked
                ? 'This account is temporarily locked after repeated failed sign-in attempts.'
                : 'Email or password is incorrect.',
            ),
          };
        } else if (user.account_status !== 'active') {
          await client.query('COMMIT');
          loginResult = {
            user,
            error: new HttpError(
              403,
              'This account is suspended. Contact support.',
              'ACCOUNT_SUSPENDED',
            ),
          };
        } else if (!user.email_verified_at) {
          await client.query('ROLLBACK');
          loginResult = {
            user,
            error: new HttpError(403, 'Verify your email before signing in.'),
          };
        } else {
          await client.query(
            `UPDATE users
                SET failed_login_attempts = 0, locked_until = NULL
              WHERE id = $1`,
            [user.id],
          );
          const roles = await client.query(
            'SELECT role FROM user_roles WHERE user_id = $1 ORDER BY role',
            [user.id],
          );
          if (roles.rowCount === 0) {
            await client.query('ROLLBACK');
            loginResult = {
              user,
              error: new HttpError(403, 'This account has no assigned role.'),
            };
          } else {
            await client.query('COMMIT');
            loginResult = {
              user,
              roles: roles.rows.map((row) => row.role),
            };
          }
        }
      }
    } catch (error) {
      if (client) {
        try {
          await client.query('ROLLBACK');
        } catch {
          // The transaction may already have completed.
        }
      }
      throw error;
    } finally {
      client.release();
    }
    if (loginResult.error) {
      await writeAuditEvent(pool, {
        actorId: loginResult.user?.id ?? null,
        action: 'auth.login_failed',
        resourceType: 'user',
        metadata: {
          reason: loginResult.error.code === 'ACCOUNT_SUSPENDED'
            ? 'account_suspended'
            : loginResult.error.status === 423
              ? 'locked'
              : loginResult.error.status === 403
                ? 'unverified_or_unassigned'
                : 'invalid_credentials',
        },
      });
      throw loginResult.error;
    }
    const token = signAccessToken(
      loginResult.user,
      config.jwtSecret,
      config.jwtExpiresIn,
    );
    await writeAuditEvent(pool, {
      actorId: loginResult.user.id,
      action: 'auth.login_succeeded',
      resourceType: 'user',
      resourceId: loginResult.user.id,
    });
    res.json({
      token,
      user: publicUser(loginResult.user, loginResult.roles),
    });
  }));

  router.post('/auth/roles', authenticate, asyncRoute(async (req, res) => {
    const { role } = parse(
      z.object({ role: z.enum([...PUBLIC_ROLES]) }).strict(),
      req.body,
    );
    if (!req.user.roles.includes(role)) {
      throw new HttpError(403, 'Roles can only be activated after assignment and approval.');
    }
    res.json({ activeRole: role });
  }));

  router.use(authenticate);
  registerAccountRoutes(router, { pool });
  registerKycRoutes(router, { pool, requireRole });
  registerMarketplaceRoutes(publicRouter, router, { pool, requireRole });
  registerCommerceRoutes(publicRouter, router, { pool, config, requireRole });
  registerServiceRoutes(publicRouter, router, { pool, requireRole });
  registerAdminRoutes(router, { pool, requireRole });

  router.get('/pets', requireRole('owner'), asyncRoute(async (req, res) => {
    const result = await pool.query(
      `SELECT id, owner_id, name, species, breed, age, sex, weight_kg,
              microchip, created_at, updated_at
         FROM pets
        WHERE owner_id = $1
        ORDER BY created_at`,
      [req.user.id],
    );
    res.json({ pets: mapRows(result.rows) });
  }));

  router.post('/pets', requireRole('owner'), asyncRoute(async (req, res) => {
    const body = parse(petSchema, req.body);
    const result = await pool.query(
      `INSERT INTO pets
         (owner_id, name, species, breed, age, sex, weight_kg, microchip)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, owner_id, name, species, breed, age, sex, weight_kg,
                 microchip, created_at, updated_at`,
      [
        req.user.id,
        body.name,
        body.species,
        body.breed,
        body.age,
        body.sex.toLowerCase(),
        body.weightKg,
        body.microchip,
      ],
    );
    const pet = mapRow(result.rows[0]);
    await writeAuditEvent(pool, {
      actorId: req.user.id,
      action: 'pet.created',
      resourceType: 'pet',
      resourceId: pet.id,
    });
    res.status(201).json({ pet });
  }));

  router.patch('/pets/:id', requireRole('owner'), asyncRoute(async (req, res) => {
    const id = validateId(req.params.id);
    const body = parse(petSchema, req.body);
    const result = await pool.query(
      `UPDATE pets
          SET name = $3, species = $4, breed = $5, age = $6, sex = $7,
              weight_kg = $8, microchip = $9, updated_at = now()
        WHERE id = $1 AND owner_id = $2
        RETURNING id, owner_id, name, species, breed, age, sex, weight_kg,
                  microchip, created_at, updated_at`,
      [
        id,
        req.user.id,
        body.name,
        body.species,
        body.breed,
        body.age,
        body.sex.toLowerCase(),
        body.weightKg,
        body.microchip,
      ],
    );
    if (!result.rows[0]) throw new HttpError(404, 'Pet was not found.');
    res.json({ pet: mapRow(result.rows[0]) });
  }));

  router.delete('/pets/:id', requireRole('owner'), asyncRoute(async (req, res) => {
    const id = validateId(req.params.id);
    const result = await pool.query(
      'DELETE FROM pets WHERE id = $1 AND owner_id = $2 RETURNING id',
      [id, req.user.id],
    );
    if (!result.rows[0]) throw new HttpError(404, 'Pet was not found.');
    await writeAuditEvent(pool, {
      actorId: req.user.id,
      action: 'pet.deleted',
      resourceType: 'pet',
      resourceId: id,
    });
    res.status(204).end();
  }));

  router.get('/pets/:id/health-records', asyncRoute(async (req, res) => {
    const petId = validateId(req.params.id);
    await assertPetAccess(pool, req, petId, 'health');
    const result = await pool.query(
      `SELECT id, pet_id, created_by, title, record_type, provider,
              record_date, next_due_at, vet_name, attachment_name, created_at
         FROM health_records
        WHERE pet_id = $1
        ORDER BY record_date DESC, created_at DESC`,
      [petId],
    );
    const today = new Date().toISOString().slice(0, 10);
    const records = result.rows.map((row) => {
      const record = mapRow(row);
      if (record.recordType.toLowerCase().includes('vaccin')) {
        record.vaccinationStatus = !record.nextDueAt
          ? 'no_due_date'
          : record.nextDueAt < today
            ? 'overdue'
            : record.nextDueAt <= new Date(Date.now() + 14 * 86_400_000)
                .toISOString()
                .slice(0, 10)
              ? 'due_soon'
              : 'up_to_date';
      }
      return record;
    });
    res.json({ records });
  }));

  router.post('/pets/:id/health-records', asyncRoute(async (req, res) => {
    const petId = validateId(req.params.id);
    const body = parse(healthRecordSchema, req.body);
    const pet = await assertPetAccess(pool, req, petId, 'health');
    const isOwner = req.user.activeRole === 'owner' &&
      pet.owner_id === req.user.id;
    if (!isOwner && req.user.activeRole !== 'veterinarian') {
      throw new HttpError(403, 'Only the pet owner or an authorized veterinarian can add records.');
    }
    const result = await pool.query(
      `INSERT INTO health_records
         (pet_id, created_by, title, record_type, provider, record_date,
          next_due_at, vet_name, attachment_name)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING id, pet_id, created_by, title, record_type, provider,
                 record_date, next_due_at, vet_name, attachment_name, created_at`,
      [
        petId,
        req.user.id,
        body.title,
        body.type,
        body.provider,
        body.date,
        body.nextDueAt ?? null,
        isOwner ? null : req.user.display_name,
        body.attachmentName ?? null,
      ],
    );
    res.status(201).json({ record: mapRow(result.rows[0]) });
  }));

  router.get('/pets/:id/access-grants', requireRole('owner'), asyncRoute(async (req, res) => {
    const petId = validateId(req.params.id);
    const owned = await pool.query(
      'SELECT 1 FROM pets WHERE id = $1 AND owner_id = $2',
      [petId, req.user.id],
    );
    if (owned.rowCount === 0) throw new HttpError(404, 'Pet was not found.');
    const result = await pool.query(
      `SELECT g.id, g.pet_id, g.owner_id, g.recipient_id, g.sections,
              g.expires_at, g.revoked_at, g.created_at,
              u.display_name AS recipient_name, u.email AS recipient_email
         FROM pet_access_grants g
         JOIN users u ON u.id = g.recipient_id
        WHERE g.pet_id = $1 AND g.owner_id = $2
        ORDER BY g.created_at DESC`,
      [petId, req.user.id],
    );
    res.json({ grants: mapRows(result.rows) });
  }));

  router.post('/pets/:id/access-grants', requireRole('owner'), asyncRoute(async (req, res) => {
    const petId = validateId(req.params.id);
    const body = parse(accessGrantSchema, req.body);
    const owned = await pool.query(
      'SELECT 1 FROM pets WHERE id = $1 AND owner_id = $2',
      [petId, req.user.id],
    );
    if (owned.rowCount === 0) throw new HttpError(404, 'Pet was not found.');
    const recipient = await pool.query(
      `SELECT 1
         FROM user_roles
        WHERE user_id = $1 AND role IN ('sitter', 'veterinarian')`,
      [body.recipientId],
    );
    if (recipient.rowCount === 0) {
      throw new HttpError(400, 'Access can only be granted to a sitter or veterinarian account.');
    }
    const result = await pool.query(
      `INSERT INTO pet_access_grants
         (pet_id, owner_id, recipient_id, sections, expires_at, revoked_at)
       VALUES ($1, $2, $3, $4, $5, NULL)
       ON CONFLICT (pet_id, recipient_id)
       DO UPDATE SET sections = EXCLUDED.sections,
                     expires_at = EXCLUDED.expires_at,
                     revoked_at = NULL
       RETURNING id, pet_id, owner_id, recipient_id, sections, expires_at,
                 revoked_at, created_at`,
      [petId, req.user.id, body.recipientId, [...new Set(body.sections)], body.expiresAt ?? null],
    );
    res.status(201).json({ grant: mapRow(result.rows[0]) });
  }));

  router.delete('/pets/:id/access-grants/:recipientId', requireRole('owner'), asyncRoute(async (req, res) => {
    const petId = validateId(req.params.id);
    const recipientId = validateId(req.params.recipientId);
    const result = await pool.query(
      `UPDATE pet_access_grants
          SET revoked_at = now()
        WHERE pet_id = $1 AND owner_id = $2 AND recipient_id = $3
          AND revoked_at IS NULL
        RETURNING id`,
      [petId, req.user.id, recipientId],
    );
    if (result.rowCount === 0) throw new HttpError(404, 'Active access grant was not found.');
    res.status(204).end();
  }));

  router.use((req, res) => {
    res.status(404).json({ error: 'API route not found.' });
  });
  app.use('/api', publicRouter);
  app.use('/api', router);
  app.use('/api', async (error, req, res, next) => {
    if (error?.status === 401 || error?.status === 403) {
      try {
        await writeAuditEvent(pool, {
          actorId: req.user?.id ?? null,
          action: 'authorization.denied',
          resourceType: 'api',
          resourceId: req.path,
          metadata: {
            method: req.method,
            status: error.status,
            reason: error.status === 401 ? 'unauthenticated' : 'forbidden',
          },
        });
      } catch (auditError) {
        console.error('authorization_audit_failed', {
          requestId: req.id,
          method: req.method,
          path: req.path,
          code: auditError.code ?? null,
        });
      }
    }
    next(error);
  });
  app.use((error, req, res, next) => {
    if (error?.type === 'entity.parse.failed') {
      return res.status(400).json({ error: 'Request body must be valid JSON.' });
    }
    return errorHandler(error, req, res, next);
  });

  return app;
}
