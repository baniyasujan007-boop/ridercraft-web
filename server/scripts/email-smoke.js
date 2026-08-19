import "dotenv/config";
import { createSmtpProvider, emailProviderConfigured } from "../utils/emailService.js";

// Safe, one-shot password-reset email delivery check.
//
// Sends exactly ONE reset-style email to the configured sender account
// (EMAIL_USER) so you can confirm SMTP auth + delivery without spamming
// strangers or using a real token. The reset URL uses a REDACTED placeholder —
// no real reset token is ever created, logged, or sent.

const to = process.env.EMAIL_USER;
if (!emailProviderConfigured()) {
  console.error("[email-smoke] MISSING config: set EMAIL_USER and EMAIL_APP_PASSWORD in server/.env");
  console.error("[email-smoke] EMAIL_APP_PASSWORD must be a Gmail App Password, not your normal password.");
  process.exit(1);
}

const redactedUrl = `${process.env.CLIENT_URL || "http://localhost:3000"}/reset-password?token=[REDACTED]&email=[REDACTED]`;

const provider = createSmtpProvider();
console.log(`[email-smoke] sending one reset email to ${to} ...`);

try {
  const info = await provider.sendPasswordResetEmail({ to, resetUrl: redactedUrl });
  console.log("[email-smoke] provider accepted = true");
  console.log(`[email-smoke] messageId = ${info?.messageId ? "present" : "absent"}`);
  console.log(`[email-smoke] recipient = ${info?.accepted?.join(", ") || to}`);
  console.log("[email-smoke] NEXT: check that Gmail inbox (Inbox / Promotions / Spam / Updates).");
} catch (err) {
  const code = err?.code || err?.responseCode || err?.name || "unknown";
  const detail = err?.responseCode
    ? `SMTP code ${err.responseCode}`
    : err?.response?.status
      ? `HTTP ${err.response.status}`
      : (err?.message || "no detail").slice(0, 300);
  console.error(`[email-smoke] FAILED error type/code = ${code}`);
  console.error(`[email-smoke] detail = ${detail}`);
  console.error("[email-smoke] If it is 535/534: the App Password is wrong or 2-Step Verification is off.");
  console.error("[email-smoke] If it is 550 5.7.1: sender not verified / sending limits / TLS policy.");
  process.exit(1);
}
