import { HttpError } from './errors.js';

export async function sendOneTimeCode(config, { email, code, purpose }) {
  if (config.devAuthCodes && !config.isProduction) return;
  if (config.emailProvider !== 'resend') {
    throw new HttpError(
      503,
      'Email delivery is not configured. Contact the administrator.',
    );
  }

  const action = purpose === 'verify_email' ? 'verify your email' : 'reset your password';
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${config.resendApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: config.emailFrom,
      to: [email],
      subject: 'Your ThePetsVault verification code',
      text: `Use ${code} to ${action}. It expires in ${config.otpTtlMinutes} minutes.`,
    }),
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) {
    console.error('email_provider_rejected_request', {
      status: response.status,
      purpose,
    });
    throw new HttpError(503, 'Email delivery failed. Please try again later.');
  }
}
