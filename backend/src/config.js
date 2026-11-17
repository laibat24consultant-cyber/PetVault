import 'dotenv/config';

const localOrigins = [
  'http://localhost:8765',
  'http://127.0.0.1:8765',
  'http://localhost:3000',
];

export function loadConfig(env = process.env) {
  const nodeEnv = env.NODE_ENV ?? 'development';
  const jwtSecret = env.JWT_SECRET ?? '';
  const developmentSecret = 'local-development-secret-change-this-32chars';
  const isProduction = nodeEnv === 'production';
  const emailProvider = env.EMAIL_PROVIDER ?? 'unconfigured';
  const paymentProvider = env.PAYMENT_PROVIDER ?? 'unconfigured';
  const origins = (env.ALLOWED_ORIGINS ?? localOrigins.join(','))
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean)
    .map((origin) => new URL(origin).origin);

  if (isProduction &&
      (jwtSecret.length < 32 || jwtSecret === developmentSecret)) {
    throw new Error('Production requires a unique JWT_SECRET of at least 32 characters.');
  }
  if (isProduction && env.DEV_AUTH_CODES === 'true') {
    throw new Error('Development authentication codes are disabled in production.');
  }
  if (isProduction && origins.includes('*')) {
    throw new Error('Wildcard CORS origins are disabled in production.');
  }
  if (!['unconfigured', 'resend'].includes(emailProvider)) {
    throw new Error('EMAIL_PROVIDER must be "unconfigured" or "resend".');
  }
  if (emailProvider === 'resend' &&
      (!env.RESEND_API_KEY || !env.EMAIL_FROM)) {
    throw new Error('Resend requires RESEND_API_KEY and EMAIL_FROM.');
  }
  if (!['unconfigured', 'mock'].includes(paymentProvider)) {
    throw new Error('PAYMENT_PROVIDER must be "unconfigured" or "mock".');
  }
  if (isProduction && paymentProvider === 'mock') {
    throw new Error('The mock payment provider is development-only.');
  }

  const otpTtlMinutes = Number.parseInt(env.OTP_TTL_MINUTES ?? '10', 10);
  if (!Number.isInteger(otpTtlMinutes) ||
      otpTtlMinutes < 1 ||
      otpTtlMinutes > 60) {
    throw new Error('OTP_TTL_MINUTES must be between 1 and 60.');
  }
  const commissionRate = Number.parseFloat(env.COMMISSION_RATE ?? '0.05');
  if (!Number.isFinite(commissionRate) ||
      commissionRate < 0 ||
      commissionRate > 0.3) {
    throw new Error('COMMISSION_RATE must be between 0 and 0.3.');
  }

  return Object.freeze({
    nodeEnv,
    isProduction,
    port: Number.parseInt(env.PORT ?? '3000', 10),
    databaseUrl: env.TEST_DATABASE_URL ?? env.DATABASE_URL,
    databaseSsl: env.DATABASE_SSL === 'true',
    jwtSecret: jwtSecret || 'local-development-secret-change-this-32chars',
    jwtExpiresIn: env.JWT_EXPIRES_IN ?? '8h',
    otpTtlMinutes,
    devAuthCodes: !isProduction && env.DEV_AUTH_CODES === 'true',
    devVerificationCode: env.DEV_VERIFICATION_CODE ?? '123456',
    devPasswordResetCode: env.DEV_PASSWORD_RESET_CODE ?? '654321',
    emailProvider,
    emailFrom: env.EMAIL_FROM ?? '',
    resendApiKey: env.RESEND_API_KEY ?? '',
    paymentProvider,
    commissionRate,
    allowedOrigins: new Set(origins),
    webPort: Number.parseInt(env.WEB_PORT ?? '8765', 10),
    webRoot: env.WEB_ROOT,
    apiOrigin: env.API_ORIGIN ?? 'http://127.0.0.1:3000',
    documentStorageDir: env.DOCUMENT_STORAGE_DIR,
  });
}
