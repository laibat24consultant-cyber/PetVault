import crypto from 'node:crypto';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { HttpError } from './errors.js';

export const PUBLIC_ROLES = new Set([
  'owner',
  'seller',
  'sitter',
  'veterinarian',
  'vendor',
]);
export const SUPPLY_ROLES = new Set([
  'seller',
  'sitter',
  'veterinarian',
  'vendor',
]);
export const ADMIN_ROLE = 'admin';
export const DUMMY_PASSWORD_HASH =
  '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy';

export function normalizeEmail(email) {
  return email.trim().toLowerCase();
}

export function normalizePhone(phone) {
  const trimmed = phone.trim();
  const digits = trimmed.replace(/\D/g, '');
  if (digits.length < 7 || digits.length > 15) {
    throw new HttpError(400, 'Enter a valid phone number.');
  }
  return `${trimmed.startsWith('+') ? '+' : ''}${digits}`;
}

export function publicUser(row, roles) {
  return {
    id: row.id,
    email: row.email,
    displayName: row.display_name,
    roles,
    verified: row.email_verified_at !== null,
  };
}

export function hashOneTimeCode(secret, userId, purpose, code) {
  return crypto
    .createHmac('sha256', secret)
    .update(`${userId}:${purpose}:${code}`)
    .digest('hex');
}

export function safeEqualHex(left, right) {
  if (!/^[a-f0-9]{64}$/i.test(left) ||
      !/^[a-f0-9]{64}$/i.test(right)) {
    return false;
  }
  return crypto.timingSafeEqual(
    Buffer.from(left, 'hex'),
    Buffer.from(right, 'hex'),
  );
}

export function generateOneTimeCode() {
  return crypto.randomInt(0, 1_000_000).toString().padStart(6, '0');
}

export async function hashPassword(password) {
  return bcrypt.hash(password, 12);
}

export async function verifyPassword(password, passwordHash) {
  return bcrypt.compare(password, passwordHash);
}

export function signAccessToken(user, secret, expiresIn) {
  return jwt.sign(
    { sub: user.id, ver: user.token_version },
    secret,
    { expiresIn, issuer: 'petvault-api', audience: 'petvault-client' },
  );
}

export async function authenticateRequest(req, pool, config) {
  const authorization = req.get('authorization') ?? '';
  const match = /^Bearer ([^\s]+)$/i.exec(authorization);
  if (!match) {
    throw new HttpError(401, 'Sign in to continue.');
  }

  let claims;
  try {
    claims = jwt.verify(match[1], config.jwtSecret, {
      issuer: 'petvault-api',
      audience: 'petvault-client',
    });
  } catch (error) {
    if (error?.name === 'TokenExpiredError') {
      throw new HttpError(401, 'Your session has expired. Sign in again.');
    }
    throw new HttpError(401, 'Your session is invalid.');
  }
  if (!claims || typeof claims !== 'object' || typeof claims.sub !== 'string') {
    throw new HttpError(401, 'Your session is invalid.');
  }

  const result = await pool.query(
    `SELECT id, email, display_name, email_verified_at, token_version,
            deleted_at, account_status
       FROM users
      WHERE id = $1`,
    [claims.sub],
  );
  const user = result.rows[0];
  if (!user || user.deleted_at || claims.ver !== user.token_version) {
    throw new HttpError(401, 'Your session is no longer valid.');
  }
  if (user.account_status !== 'active') {
    throw new HttpError(403, 'This account is suspended. Contact support.');
  }

  const rolesResult = await pool.query(
    'SELECT role FROM user_roles WHERE user_id = $1 ORDER BY role',
    [user.id],
  );
  const roles = rolesResult.rows.map((row) => row.role);
  const requestedRole = req.get('x-active-role');
  const activeRole = requestedRole ??
    (roles.includes('owner') ? 'owner' : roles[0]);
  if (!roles.includes(activeRole)) {
    throw new HttpError(403, 'The selected role is not assigned to this account.');
  }
  if (!user.email_verified_at) {
    throw new HttpError(403, 'Verify your email before using this account.');
  }

  req.user = {
    ...user,
    roles,
    activeRole,
  };
}

export function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) return next(new HttpError(401, 'Sign in to continue.'));
    if (!roles.includes(req.user.activeRole) ||
        !req.user.roles.includes(req.user.activeRole)) {
      return next(new HttpError(403, 'You do not have permission to do that.'));
    }
    return next();
  };
}

export async function requireVerifiedSupplyRole(req, pool) {
  const role = req.user.activeRole;
  if (!SUPPLY_ROLES.has(role)) {
    throw new HttpError(403, 'Select an approved supply role to continue.');
  }
  const result = await pool.query(
    `SELECT 1
       FROM kyc_submissions
      WHERE user_id = $1 AND role = $2 AND status = 'verified'`,
    [req.user.id, role],
  );
  if (result.rowCount === 0) {
    throw new HttpError(403, 'Complete administrator-approved verification first.');
  }
}

export function requireOwnedRole(req, role) {
  if (!req.user.roles.includes(role)) {
    throw new HttpError(403, 'You do not have permission to do that.');
  }
}
