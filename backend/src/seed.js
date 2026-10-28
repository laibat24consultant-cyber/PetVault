import 'dotenv/config';
import bcrypt from 'bcryptjs';
import { pool, transaction } from './db.js';

if (process.env.NODE_ENV === 'production') {
  console.error('Refusing to seed demo accounts in production.');
  process.exitCode = 1;
} else if (!process.env.DEMO_PASSWORD || process.env.DEMO_PASSWORD.length < 8) {
  console.error('Set DEMO_PASSWORD (at least 8 characters) before creating demo accounts.');
  process.exitCode = 1;
} else {
  const demoUsers = [
    ['owner@petvault.demo', 'Hammad Farman', '+923000000001', ['owner']],
    ['seller@petvault.demo', 'Zara Ahmed', '+923000000002', ['owner', 'seller']],
    ['sitter@petvault.demo', 'Sana Ali', '+923000000003', ['sitter']],
    ['vet@petvault.demo', 'Dr. Ayesha Ali', '+923000000004', ['veterinarian']],
    ['vendor@petvault.demo', 'Paw Pantry', '+923000000005', ['vendor']],
    ['admin@petvault.demo', 'PetVault Admin', '+923000000006', ['admin']],
  ];
  const passwordHash = await bcrypt.hash(process.env.DEMO_PASSWORD, 12);

  try {
    await transaction(async (client) => {
      for (const [email, displayName, phone, userRoles] of demoUsers) {
      const { rows } = await client.query(
        `INSERT INTO users (email, display_name, phone, password_hash, email_verified_at)
         VALUES ($1, $2, $3, $4, now())
         ON CONFLICT (email) DO UPDATE
           SET display_name = EXCLUDED.display_name,
               phone = EXCLUDED.phone,
               password_hash = EXCLUDED.password_hash,
               email_verified_at = now(),
               deleted_at = NULL
         RETURNING id`,
        [email, displayName, phone, passwordHash],
      );
      const userId = rows[0].id;
      for (const role of userRoles) {
        await client.query(
          'INSERT INTO user_roles (user_id, role) VALUES ($1, $2) ON CONFLICT DO NOTHING',
          [userId, role],
        );
      }
    }

    const { rows: sellerRows } = await client.query(
      'SELECT id FROM users WHERE email = $1',
      ['seller@petvault.demo'],
    );
    const { rows: vetRows } = await client.query(
      'SELECT id FROM users WHERE email = $1',
      ['vet@petvault.demo'],
    );
    const { rows: sitterRows } = await client.query(
      'SELECT id FROM users WHERE email = $1',
      ['sitter@petvault.demo'],
    );
    const { rows: vendorRows } = await client.query(
      'SELECT id FROM users WHERE email = $1',
      ['vendor@petvault.demo'],
    );
    const sellerId = sellerRows[0].id;

    for (const [userId, role, reference] of [
      [sellerId, 'seller', 'DEMO-SELLER-KYC'],
      [sitterRows[0].id, 'sitter', 'DEMO-SITTER-KYC'],
      [vetRows[0].id, 'veterinarian', 'DEMO-VET-KYC'],
      [vendorRows[0].id, 'vendor', 'DEMO-VENDOR-KYC'],
    ]) {
      await client.query(
        `INSERT INTO kyc_submissions (user_id, role, status, document_reference)
         VALUES ($1, $2, 'verified', $3)
         ON CONFLICT DO NOTHING`,
        [userId, role, reference],
      );
    }

    const { rows: ownerRows } = await client.query(
      'SELECT id FROM users WHERE email = $1',
      ['owner@petvault.demo'],
    );
    const ownerId = ownerRows[0].id;
    const petInsert = await client.query(
      `INSERT INTO pets (owner_id, name, species, breed, age, sex, weight_kg)
       SELECT $1, 'ROSCO', 'Dog', 'Golden Retriever', '3 years', 'Male', 28
       WHERE NOT EXISTS (SELECT 1 FROM pets WHERE owner_id = $1 AND name = 'ROSCO')
       RETURNING id`,
      [ownerId],
    );
    if (petInsert.rows[0]) {
      await client.query(
        `INSERT INTO health_records
          (pet_id, created_by, title, record_type, provider, record_date, next_due_at)
         VALUES ($1, $2, 'Rabies booster', 'Vaccination', 'PetCare Clinic', CURRENT_DATE, CURRENT_DATE + 365)`,
        [petInsert.rows[0].id, ownerId],
      );
    }

    await client.query(
      `INSERT INTO listings (seller_id, title, species, breed, city, price, age, image_url, health_notes, status)
       SELECT $1, 'Golden Retriever Puppy — Champion Line', 'Dog', 'Golden Retriever',
              'Karachi', 45000, '8 weeks', 'assets/images/listing_golden.png',
              'Vaccination document uploaded', 'active'
       WHERE NOT EXISTS (SELECT 1 FROM listings WHERE seller_id = $1 AND title = 'Golden Retriever Puppy — Champion Line')`,
      [sellerId],
    );
    await client.query(
      `INSERT INTO products (vendor_id, name, price, stock, image_url, published)
       SELECT $1, $2, $3, $4, $5, true
       WHERE NOT EXISTS (SELECT 1 FROM products WHERE vendor_id = $1 AND name = $2)`,
      [vendorRows[0].id, 'Complete dog food', 4800, 32, 'assets/images/product_food.png'],
    );
    });
    console.log(`Seeded PetVault demo accounts (password configured via environment).`);
  } catch (error) {
    console.error('Demo seed failed', error);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}
