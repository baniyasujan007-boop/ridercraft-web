// Email delivery abstraction.
//
// RiderCraft has NO transactional email provider configured yet (no SMTP /
// SES / SendGrid / etc. credentials exist in .env). Deliberately this module
// does NOT fake delivery: no token is returned, no email is simulated.
//
// To add a real provider later, implement an object with:
//   async sendPasswordResetEmail({ to, resetUrl })
// and register it with setEmailProvider() at boot, e.g. in server.js. The
// reset URL is the only place the raw token lives; it is never exposed in an
// API response.

let provider = null;

/**
 * Register an email provider used for transactional mail.
 * @param {{ sendPasswordResetEmail: (msg: { to: string, resetUrl: string }) => Promise<void> }} nextProvider
 */
export function setEmailProvider(nextProvider) {
  provider = nextProvider;
}

/**
 * Sends a password-reset email. With no provider configured it records that
 * a reset was requested but sends nothing. Never logs the raw token.
 * @param {{ to: string, resetUrl: string }} message
 */
export async function sendPasswordResetEmail({ to, resetUrl }) {
  if (provider) {
    await provider.sendPasswordResetEmail({ to, resetUrl });
    return;
  }

  if (process.env.NODE_ENV !== "production") {
    console.log(
      `[email][dev] password reset requested for ${to}; no provider configured, no email sent.`
    );
  } else {
    console.warn(
      `[email] no provider configured; password reset email for ${to} was NOT sent.`
    );
  }
}