import test, { after, before } from "node:test";
import assert from "node:assert/strict";
import {
  createSmtpProvider,
  emailProviderConfigured,
  initEmailProvider,
  sendPasswordResetEmail,
  setEmailProvider,
} from "../utils/emailService.js";

// These tests never touch a real SMTP server — they exercise the provider
// factory with a fake transporter and the module's provider-selection rules.

const sentMails = [];
const fakeTransporter = {
  async sendMail(mailOptions) {
    sentMails.push(mailOptions);
    return { messageId: "fake-message-id", accepted: [mailOptions.to], rejected: [] };
  },
};

const RESET_URL = "https://ridercraft.example/reset-password?token=REDACTED&email=u@example.com";
const originalEnv = { ...process.env };

before(() => {
  setEmailProvider(null);
});

after(() => {
  setEmailProvider(null);
  for (const key of Object.keys(process.env)) {
    if (!(key in originalEnv)) delete process.env[key];
  }
  Object.assign(process.env, originalEnv);
});

function withCreds(patch = {}) {
  Object.assign(process.env, {
    EMAIL_USER: "ridercraft.send@gmail.com",
    EMAIL_APP_PASSWORD: "fake-app-password-1234",
    ...patch,
  });
}

test("emailProviderConfigured() is false without credentials", () => {
  setEmailProvider(null);
  assert.equal(emailProviderConfigured(), false);
});

test("emailProviderConfigured() is true with EMAIL_USER + EMAIL_APP_PASSWORD", () => {
  withCreds();
  assert.equal(emailProviderConfigured(), true);
});

test("dev mode without a provider logs and does not throw", async (t) => {
  setEmailProvider(null);
  const log = t.mock.method(console, "log");
  await sendPasswordResetEmail({ to: "dev@example.com", resetUrl: RESET_URL });
  assert.equal(log.mock.calls.length >= 1, true, "must log a dev-only notice");
});

test("production without a provider fails loudly instead of claiming success", async () => {
  setEmailProvider(null);
  process.env.NODE_ENV = "production";
  await assert.rejects(
    () => sendPasswordResetEmail({ to: "prod@example.com", resetUrl: RESET_URL }),
    /provider not configured/i
  );
});

test("a registered mock provider receives the send and captures to/resetUrl", async () => {
  const received = [];
  setEmailProvider({
    async sendPasswordResetEmail(msg) {
      received.push(msg);
    },
  });
  await sendPasswordResetEmail({ to: "mock@example.com", resetUrl: RESET_URL });
  assert.deepEqual(received, [{ to: "mock@example.com", resetUrl: RESET_URL }]);
});

test("smtp provider sends a reset email with a safe payload", async () => {
  withCreds({ EMAIL_FROM: "RiderCraft <noreply@example.com>" });
  sentMails.length = 0;
  const provider = createSmtpProvider({ transporter: fakeTransporter });

  await provider.sendPasswordResetEmail({ to: "user@example.com", resetUrl: RESET_URL });

  assert.equal(sentMails.length, 1);
  const mail = sentMails[0];
  assert.equal(mail.to, "user@example.com");
  assert.equal(mail.from, "RiderCraft <noreply@example.com>");
  assert.match(mail.subject, /Reset your RiderCraft password/);
  assert.match(mail.text, /expires in 15 minutes/);
  assert.ok(mail.text.includes(RESET_URL), "plaintext must contain the reset link");
  assert.ok(mail.html.includes(RESET_URL), "html must contain the reset link");
});

test("smtp provider defaults the from address to EMAIL_USER", async () => {
  withCreds();
  delete process.env.EMAIL_FROM;
  sentMails.length = 0;
  const provider = createSmtpProvider({ transporter: fakeTransporter });

  await provider.sendPasswordResetEmail({ to: "user@example.com", resetUrl: RESET_URL });
  assert.equal(sentMails[0].from, "RiderCraft <ridercraft.send@gmail.com>");
});

test("initEmailProvider registers a provider only when credentials exist", async () => {
  setEmailProvider(null);
  delete process.env.EMAIL_USER;
  delete process.env.EMAIL_APP_PASSWORD;
  assert.equal(await initEmailProvider(), null, "no provider without credentials");

  withCreds();
  const registered = await initEmailProvider();
  assert.ok(registered, "provider must register once credentials exist");
  setEmailProvider(null);
});
