import pg from 'pg';

const { Pool } = pg;

export function createPool(config = {}) {
  const connectionString = config.connectionString ??
    process.env.TEST_DATABASE_URL ??
    process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error('DATABASE_URL must be configured.');
  }

  const pool = new Pool({
    connectionString,
    ssl: config.ssl ?? (process.env.DATABASE_SSL === 'true'
      ? { rejectUnauthorized: true }
      : false),
    max: config.max ?? 10,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 5_000,
    application_name: 'petvault-api',
  });
  pool.on('error', (error) => {
    console.error('database_idle_client_error', { code: error.code ?? null });
  });
  return pool;
}

export async function inTransaction(pool, action) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await action(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function closePool(pool) {
  await pool.end();
}
