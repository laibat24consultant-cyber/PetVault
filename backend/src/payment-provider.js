import { randomUUID } from 'node:crypto';

export function createPaymentProvider({
  mode = process.env.PAYMENT_PROVIDER ??
    (process.env.NODE_ENV === 'production' ? 'unconfigured' : 'mock'),
  nodeEnvironment = process.env.NODE_ENV ?? 'development',
} = {}) {
  if (mode !== 'mock') {
    return {
      async charge() {
        return {
          status: 'unavailable',
          message: 'No approved payment provider is configured.',
        };
      },
    };
  }

  if (nodeEnvironment === 'production') {
    throw new Error('The mock payment provider cannot be enabled in production.');
  }

  return {
    async charge({ simulateUnavailable = false } = {}) {
      if (simulateUnavailable) {
        return {
          status: 'unavailable',
          message: 'The mock payment provider is unavailable. No charge was made.',
        };
      }
      return {
        status: 'paid',
        reference: `mock-${randomUUID()}`,
        message: 'Mock payment approved. No real charge was made.',
      };
    },
  };
}
