import nodemailer from "nodemailer";

// Transactional email (password reset) delivery via Nodemailer + Gmail SMTP.
//
// Security contract:
//   - Never logs or returns the raw reset token or the full reset URL (the URL
//     embeds the token). Only safe metadata is logged (recipient, provider
//     configured, accepted, messageId present/absent, error code).
//   - In production, if no provider is configured, the send FAILS LOUDLY
//     (throws) so the API returns an error instead of claiming success while
//     no email was sent.
//
// Configuration (read from server/.env, all names are non-secret):
//   EMAIL_USER            Gmail address / SMTP username (sender + default from)
//   EMAIL_APP_PASSWORD    Gmail App Password (NOT your normal Gmail password)
//   EMAIL_FROM            Optional display envelope; defaults to EMAIL_USER
//   SMTP_HOST             Default smtp.gmail.com
//   SMTP_PORT             Default 465
//   SMTP_SECURE           Default true (TLS on 465)
//   CLIENT_URL            Base URL of the web app that hosts /reset-password
//
// Tests inject a mock provider via setEmailProvider() and never touch SMTP.

let provider = null;

/**
 * Register an email provider used for transactional mail. Tests pass a mock;
 * boot registers the real SMTP provider when credentials are present.
 * @param {{ sendPasswordResetEmail: (msg: { to: string, resetUrl: string }) => Promise<object> } | null} nextProvider
 */
export function setEmailProvider(nextProvider) {
  provider = nextProvider;
}

/** @returns {{ user: string, pass: string, configured: boolean }} */
function emailCreds() {
  const user = process.env.EMAIL_USER || process.env.SMTP_USER || "";
  const pass = process.env.EMAIL_APP_PASSWORD || process.env.SMTP_PASSWORD || "";
  return { user, pass, configured: Boolean(user && pass) };
}

/** Safe, secret-free signal used for diagnostics and tests. */
export function emailProviderConfigured() {
  return emailCreds().configured;
}

function smtpTransport() {
  const { user, pass } = emailCreds();
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST || "smtp.gmail.com",
    port: Number(process.env.SMTP_PORT || 465),
    secure: (process.env.SMTP_SECURE ?? "true") !== "false",
    auth: { user, pass },
  });
}

/**
 * Builds the real SMTP provider. `transporter` is injectable so automated
 * tests can verify the mail payload without opening an SMTP connection.
 */
export function createSmtpProvider({ transporter } = {}) {
  return {
    async sendPasswordResetEmail({ to, resetUrl }) {
      const transport = transporter || smtpTransport();
      const { user } = emailCreds();
      return transport.sendMail({
        from: process.env.EMAIL_FROM || `RiderCraft <${user}>`,
        to,
        subject: "Reset your RiderCraft password",
        text: [
          "Hi,",
          "",
          "We received a request to reset your RiderCraft password.",
          "Open the link below to choose a new one (it expires in 15 minutes):",
          "",
          resetUrl,
          "",
          "If you didn't ask to reset your password, you can safely ignore this email.",
          "",
          "RiderCraft",
        ].join("\n"),
        html:
          "<p>Hi,</p>" +
          "<p>We received a request to reset your RiderCraft password. " +
          "Click the button below to choose a new one (it expires in 15 minutes):</p>" +
          `<p style="text-align:center"><a href="${resetUrl}" ` +
          'style="background:#E31B23;color:#ffffff;text-decoration:none;padding:12px 24px;border-radius:8px;display:inline-block;font-weight:bold">' +
          "Reset your password</a></p>" +
          `<p>If the button doesn't work, copy this link into your browser:<br/>${resetUrl}</p>` +
          "<p>If you didn't ask to reset your password, you can safely ignore this email.</p>" +
          "<p>RiderCraft</p>",
      });
    },
  };
}

/**
 * Registers the real SMTP provider at boot when credentials exist. Safe to
 * call from server.js; never throws on a missing configuration, only logs.
 */
export async function initEmailProvider() {
  if (provider) return provider;
  if (!emailProviderConfigured()) {
    if (process.env.NODE_ENV === "production") {
      console.warn(
        "[email] no EMAIL_USER / EMAIL_APP_PASSWORD configured; " +
          "password-reset emails will NOT be delivered."
      );
    }
    return null;
  }
  setEmailProvider(createSmtpProvider());
  console.log("[email] SMTP provider configured (Gmail).");
  return provider;
}

/**
 * Sends a password-reset email.
 *   - Real SMTP provider when configured (or the test mock).
 *   - Dev without config: logs and returns (local iteration friendly).
 *   - Production without config: throws so the API returns an error rather
 *     than pretending a reset email was delivered.
 * Never logs the raw token or the reset URL.
 */
export async function sendPasswordResetEmail({ to, resetUrl }) {
  if (provider) {
    try {
      const info = await provider.sendPasswordResetEmail({ to, resetUrl });
      if (process.env.NODE_ENV === "production") {
        console.log(
          `[email] reset requested for ${to}; provider accepted = true, messageId = ${info?.messageId ? "present" : "absent"}`
        );
      }
      return;
    } catch (err) {
      // Log only safe metadata; never the token, URL, or credentials.
      console.warn(
        `[email] send failed for ${to}; ` +
          `error type/code = ${err?.code || err?.responseCode || err?.name || "unknown"}`
      );
      throw err;
    }
  }

  if (process.env.NODE_ENV === "production") {
    console.warn("[email] no provider configured; password reset email NOT sent.");
    throw new Error("Email provider not configured");
  }

  console.log(
    `[email][dev] password reset requested for ${to}; no provider configured, no email sent.`
  );
}
