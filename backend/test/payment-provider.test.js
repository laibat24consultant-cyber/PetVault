import assert from 'node:assert/strict';
import test from 'node:test';
import { createPaymentProvider } from '../src/payment-provider.js';

test('mock payment approval is explicit and marked as non-production', async () => {
  const provider = createPaymentProvider({
    mode: 'mock',
    nodeEnvironment: 'development',
  });
  const result = await provider.charge({ amount: 1250, currency: 'PKR' });

  assert.equal(result.status, 'paid');
  assert.match(result.reference, /^mock-/);
  assert.match(result.message, /No real charge was made/);
});

test('mock provider outage does not return a success-shaped payment', async () => {
  const provider = createPaymentProvider({
    mode: 'mock',
    nodeEnvironment: 'development',
  });
  const result = await provider.charge({
    amount: 1250,
    currency: 'PKR',
    simulateUnavailable: true,
  });

  assert.deepEqual(result, {
    status: 'unavailable',
    message: 'The mock payment provider is unavailable. No charge was made.',
  });
});

test('production defaults to no provider and refuses mock payment configuration', async () => {
  const provider = createPaymentProvider({
    mode: 'unconfigured',
    nodeEnvironment: 'production',
  });
  assert.equal((await provider.charge()).status, 'unavailable');
  assert.throws(
    () => createPaymentProvider({ mode: 'mock', nodeEnvironment: 'production' }),
    /cannot be enabled in production/,
  );
});
