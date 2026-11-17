import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { loadConfig } from './config.js';
import { createPool, inTransaction } from './database.js';
import { hashPassword, normalizeEmail, normalizePhone } from './security.js';
import { writeAuditEvent } from './notifications.js';

export async function provisionAdmin({
  pool,
  email,
  displayName,
  phone,
  password,
}) {
  const normalizedEmail = normalizeEmail(email);
  const passwordHash = await hashPassword(password);
  const user = await inTransaction(pool, async (client) => {
    const existing = await client.query(
      'SELECT id FROM users WHERE lower(email) = $1 FOR UPDATE',
      [normalizedEmail],
    );
    if (existing.rowCount) {
      throw new Error('An account already uses this email; no role was changed.');
    }
    const created = await client.query(
      `INSERT INTO users
         (email, display_name, phone, password_hash, email_verified_at)
       VALUES ($1, $2, $3, $4, now())
       RETURNING id, email`,
      [normalizedEmail, displayName.trim(), normalizePhone(phone), passwordHash],
    );
    await client.query(
      'INSERT INTO user_roles (user_id, role) VALUES ($1, $2)',
      [created.rows[0].id, 'admin'],
    );
    return created.rows[0];
  });
  await writeAuditEvent(pool, {
    actorId: user.id,
    action: 'admin.provisioned',
    resourceType: 'user',
    resourceId: user.id,
  });
  return user;
}

if (process.argv[1] &&
    import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  const config = loadConfig();
  const email = process.env.ADMIN_EMAIL ?? '';
  const displayName = process.env.ADMIN_DISPLAY_NAME ?? '';
  const phone = process.env.ADMIN_PHONE ?? '';
  const password = process.env.ADMIN_PASSWORD ?? '';
  if (!email || !displayName || !phone || password.length < 16) {
    throw new Error(
      'Set ADMIN_EMAIL, ADMIN_DISPLAY_NAME, ADMIN_PHONE, and ADMIN_PASSWORD (at least 16 characters).',
    );
  }
  if (process.env.ADMIN_PROVISION_CONFIRM !== email) {
    throw new Error('Set ADMIN_PROVISION_CONFIRM to the exact ADMIN_EMAIL to proceed.');
  }
  const pool = createPool({
    connectionString: config.databaseUrl,
    ssl: config.databaseSsl ? { rejectUnauthorized: true } : false,
  });
  provisionAdmin({ pool, email, displayName, phone, password })
    .then((user) => {
      console.info('admin_provisioned', { userId: user.id, email: user.email });
    })
    .catch((error) => {
      console.error('admin_provision_failed', {
        message: error.message,
        code: error.code ?? null,
      });
      process.exitCode = 1;
    })
    .finally(() => pool.end());
}
