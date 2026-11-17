import assert from 'node:assert/strict';
import test from 'node:test';
import { loadConfig } from '../src/config.js';

test('development configuration normalizes allowed origins and provider defaults', () => {
  const config = loadConfig({
    NODE_ENV: 'development',
    ALLOWED_ORIGINS: 'https://app.example.test/path,http://localhost:8765',
  });
  assert.deepEqual([...config.allowedOrigins], [
    'https://app.example.test',
    'http://localhost:8765',
  ]);
  assert.equal(config.paymentProvider, 'unconfigured');
  assert.equal(config.devAuthCodes, false);
});

test('production rejects development auth codes and mock payments', () => {
  const base = {
    NODE_ENV: 'production',
    JWT_SECRET: 'production-only-secret-with-more-than-32-characters',
    ALLOWED_ORIGINS: 'https://app.example.test',
  };
  assert.throws(
    () => loadConfig({ ...base, DEV_AUTH_CODES: 'true' }),
    /Development authentication codes are disabled/,
  );
  assert.throws(
    () => loadConfig({ ...base, PAYMENT_PROVIDER: 'mock' }),
    /mock payment provider is development-only/,
  );
});

test('OTP lifetime must remain within the supported range', () => {
  assert.throws(
    () => loadConfig({ OTP_TTL_MINUTES: '0' }),
    /OTP_TTL_MINUTES must be between 1 and 60/,
  );
  assert.throws(
    () => loadConfig({ OTP_TTL_MINUTES: '61' }),
    /OTP_TTL_MINUTES must be between 1 and 60/,
  );
});
