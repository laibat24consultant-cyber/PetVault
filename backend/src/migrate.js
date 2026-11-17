import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { loadConfig } from './config.js';
import { createPool } from './database.js';

const directory = path.dirname(fileURLToPath(import.meta.url));

export async function runMigrations(pool, migrationsDirectory =
  path.resolve(directory, '../migrations')) {
  const client = await pool.connect();
  try {
    await client.query('SELECT pg_advisory_lock($1)', [7_914_031]);
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        name text PRIMARY KEY,
        applied_at timestamptz NOT NULL DEFAULT now()
      )
    `);
    const appliedResult = await client.query('SELECT name FROM schema_migrations');
    const applied = new Set(appliedResult.rows.map((row) => row.name));
    const files = (await fs.readdir(migrationsDirectory))
      .filter((name) => /^\d+_[a-z0-9_]+\.sql$/i.test(name))
      .sort();

    for (const name of files) {
      if (applied.has(name)) continue;
      const sql = await fs.readFile(path.join(migrationsDirectory, name), 'utf8');
      await client.query('BEGIN');
      try {
        await client.query(sql);
        await client.query('INSERT INTO schema_migrations (name) VALUES ($1)', [name]);
        await client.query('COMMIT');
      } catch (error) {
        await client.query('ROLLBACK');
        throw new Error(`Migration ${name} failed: ${error.message}`, {
          cause: error,
        });
      }
      console.info('database_migration_applied', { name });
    }
  } finally {
    try {
      await client.query('SELECT pg_advisory_unlock($1)', [7_914_031]);
    } finally {
      client.release();
    }
  }
}

if (process.argv[1] &&
    import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  const config = loadConfig();
  const pool = createPool({ connectionString: config.databaseUrl });
  runMigrations(pool)
    .catch((error) => {
      console.error('database_migration_failed', {
        message: error.message,
        code: error.code ?? null,
      });
      process.exitCode = 1;
    })
    .finally(() => pool.end());
}
