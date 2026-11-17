import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { loadConfig } from './config.js';
import { createPool, inTransaction } from './database.js';
import { hashPassword, normalizePhone } from './security.js';

const demoAccounts = [
  { email: 'owner@petvault.demo', name: 'Pet Owner', phone: '+12025550101', roles: ['owner'] },
  { email: 'seller@petvault.demo', name: 'Pet Seller', phone: '+12025550102', roles: ['owner', 'seller'] },
  { email: 'sitter@petvault.demo', name: 'Pet Sitter', phone: '+12025550103', roles: ['sitter'] },
  { email: 'vet@petvault.demo', name: 'Veterinarian', phone: '+12025550104', roles: ['veterinarian'] },
  { email: 'vendor@petvault.demo', name: 'Product Vendor', phone: '+12025550105', roles: ['vendor'] },
  { email: 'admin@petvault.demo', name: 'PetVault Admin', phone: '+12025550106', roles: ['admin'] },
];

export async function seedDemoData(pool, password) {
  if (password.length < 8) {
    throw new Error('DEMO_PASSWORD must contain at least 8 characters.');
  }
  const passwordHash = await hashPassword(password);
  return inTransaction(pool, async (client) => {
    const accounts = new Map();
    for (const account of demoAccounts) {
      const email = account.email.toLowerCase();
      const existing = await client.query(
        'SELECT id FROM users WHERE lower(email) = $1 FOR UPDATE',
        [email],
      );
      let userId = existing.rows[0]?.id;
      if (userId) {
        const roleResult = await client.query(
          'SELECT role FROM user_roles WHERE user_id = $1',
          [userId],
        );
        if (account.roles.some((role) => !roleResult.rows.some((row) => row.role === role))) {
          throw new Error(`Existing demo identity ${email} is not a seeded account; refusing to promote it.`);
        }
      } else {
        const created = await client.query(
          `INSERT INTO users
             (email, display_name, phone, password_hash, email_verified_at)
           VALUES ($1, $2, $3, $4, now())
           RETURNING id`,
          [email, account.name, normalizePhone(account.phone), passwordHash],
        );
        userId = created.rows[0].id;
        for (const role of account.roles) {
          await client.query(
            'INSERT INTO user_roles (user_id, role) VALUES ($1, $2)',
            [userId, role],
          );
        }
      }
      accounts.set(email, userId);
    }

    for (const role of ['seller', 'sitter', 'veterinarian', 'vendor']) {
      const email = demoAccounts.find((account) => account.roles.includes(role)).email;
      const userId = accounts.get(email);
      await client.query(
        `INSERT INTO kyc_submissions
           (user_id, role, status, document_reference, review_note, reviewed_at)
         VALUES ($1, $2, 'verified', 'local-demo', 'Local demo account', now())
         ON CONFLICT (user_id, role) DO NOTHING`,
        [userId, role],
      );
    }

    const ownerId = accounts.get('owner@petvault.demo');
    const existingPet = await client.query(
      'SELECT id FROM pets WHERE owner_id = $1 LIMIT 1',
      [ownerId],
    );
    if (!existingPet.rowCount) {
      await client.query(
        `INSERT INTO pets (owner_id, name, species, breed, age, sex, weight_kg)
         VALUES ($1, 'Milo', 'dog', 'Mixed breed', '3 years', 'unknown', 12.5)`,
        [ownerId],
      );
    }

    const sellerId = accounts.get('seller@petvault.demo');
    const listing = await client.query(
      'SELECT id FROM listings WHERE seller_id = $1 AND title = $2 LIMIT 1',
      [sellerId, 'Demo companion listing'],
    );
    if (!listing.rowCount) {
      await client.query(
        `INSERT INTO listings
           (seller_id, title, species, breed, city, price, age, status)
         VALUES ($1, 'Demo companion listing', 'dog', 'Mixed breed',
                 'Sample City', 250, '2 years', 'active')`,
        [sellerId],
      );
    }

    const vendorId = accounts.get('vendor@petvault.demo');
    const product = await client.query(
      'SELECT id FROM products WHERE vendor_id = $1 AND name = $2 LIMIT 1',
      [vendorId, 'Demo pet care product'],
    );
    if (!product.rowCount) {
      await client.query(
        `INSERT INTO products (vendor_id, name, price, stock, published)
         VALUES ($1, 'Demo pet care product', 25, 50, true)`,
        [vendorId],
      );
    }
    return { accounts: Object.fromEntries(accounts) };
  });
}

if (process.argv[1] &&
    import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  const config = loadConfig();
  if (config.isProduction) {
    throw new Error('Demo seeding is disabled in production.');
  }
  const pool = createPool({
    connectionString: config.databaseUrl,
    ssl: config.databaseSsl ? { rejectUnauthorized: true } : false,
  });
  seedDemoData(pool, process.env.DEMO_PASSWORD ?? 'demo1234')
    .then(() => console.info('demo_data_seeded'))
    .catch((error) => {
      console.error('demo_seed_failed', {
        message: error.message,
        code: error.code ?? null,
      });
      process.exitCode = 1;
    })
    .finally(() => pool.end());
}
