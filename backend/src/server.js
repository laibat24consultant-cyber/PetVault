import { loadConfig } from './config.js';
import { createPool } from './database.js';
import { createApp } from './app.js';

const config = loadConfig();
const pool = createPool({
  connectionString: config.databaseUrl,
  ssl: config.databaseSsl ? { rejectUnauthorized: true } : false,
});
const app = createApp({ pool, config });
const server = app.listen(config.port, '0.0.0.0', () => {
  console.info('api_started', { port: config.port, environment: config.nodeEnv });
});

async function shutdown(signal) {
  console.info('api_shutdown', { signal });
  server.close(async () => {
    await pool.end();
    process.exit(0);
  });
}

process.once('SIGINT', () => shutdown('SIGINT'));
process.once('SIGTERM', () => shutdown('SIGTERM'));
