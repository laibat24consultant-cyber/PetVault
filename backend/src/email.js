const provider = (process.env.EMAIL_PROVIDER ?? 'unconfigured').trim().toLowerCase();
const resendApiKey = process.env.RESEND_API_KEY?.trim() ?? '';
const from = process.env.EMAIL_FROM?.trim() ?? '';

export function emailIsConfigured() {
  return provider === 'resend' && Boolean(resendApiKey && from);
}

export async function sendOtpEmail({ to, code, purpose, expiresInMinutes }) {
  if (provider === 'unconfigured') {
    throw new Error('Email delivery is not configured. Set EMAIL_PROVIDER, RESEND_API_KEY, and EMAIL_FROM.');
  }
  if (provider !== 'resend') {
    throw new Error(`Unsupported EMAIL_PROVIDER: ${provider}`);
  }
  if (!resendApiKey || !from) {
    throw new Error('Resend email requires RESEND_API_KEY and EMAIL_FROM.');
  }

  const subject = purpose === 'reset_password' ? 'Reset your PetVault password' : 'Verify your PetVault account';
  const action = purpose === 'reset_password' ? 'reset your password' : 'verify your email address';
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${resendApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from,
      to: [to],
      subject,
      text: `Your PetVault code is ${code}. Use it to ${action}. It expires in ${expiresInMinutes} minutes. If you did not request this, you can ignore this email.`,
      html: `<p>Your PetVault code is:</p><p style="font-size:28px;font-weight:bold;letter-spacing:6px">${code}</p><p>Use it to ${action}. It expires in ${expiresInMinutes} minutes.</p><p>If you did not request this, you can ignore this email.</p>`,
    }),
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) {
    const details = await response.text();
    console.error('Resend email delivery failed', response.status, details.slice(0, 500));
    throw new Error('Email delivery failed. Check the email provider configuration.');
  }
}
