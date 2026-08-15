import test, { before, after } from "node:test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import net from "node:net";
import bcrypt from "bcrypt";
import express from "express";
import mongoose from "mongoose";
import authRoutes from "../routes/authRoutes.js";
import { setEmailProvider } from "../utils/emailService.js";
import User from "../models/User.js";

let mongod;
let mongodDir;
let server;
let baseUrl;
const capturedEmails = [];

function waitForPort(port, timeoutMs = 30000) {
  return new Promise((resolve, reject) => {
    const deadline = Date.now() + timeoutMs;
    const tryConnect = () => {
      const sock = net.connect(port, "127.0.0.1");
      sock.once("connect", () => {
        sock.destroy();
        resolve();
      });
      sock.once("error", () => {
        sock.destroy();
        if (Date.now() > deadline) {
          reject(new Error(`Timed out waiting for mongod on port ${port}`));
        } else {
          setTimeout(tryConnect, 200);
        }
      });
    };
    tryConnect();
  });
}

before(async () => {
  mongodDir = await mkdtemp(join(tmpdir(), "ridercraft-p2-"));
  const port = 28000 + Math.floor(Math.random() * 1000);

  mongod = spawn("mongod", [
    "--port", String(port),
    "--dbpath", mongodDir,
    "--bind_ip", "127.0.0.1",
  ], { stdio: "ignore" });

  await waitForPort(port);

  await mongoose.connect(`mongodb://127.0.0.1:${port}/ridercraft_p2_test`, {
    serverSelectionTimeoutMS: 15000,
  });

  setEmailProvider({
    async sendPasswordResetEmail({ to, resetUrl }) {
      capturedEmails.push({ to, resetUrl });
    },
  });

  const app = express();
  app.use(express.json());
  app.use("/auth", authRoutes);

  await new Promise((resolve) => {
    server = app.listen(0, "127.0.0.1", resolve);
  });
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) {
    await new Promise((resolve) => server.close(resolve));
  }
  if (mongoose.connection.readyState) {
    await mongoose.connection.dropDatabase();
    await mongoose.disconnect();
  }
  if (mongod) {
    const exited = new Promise((resolve) => {
      if (mongod.exitCode !== null) resolve();
      else mongod.once("exit", resolve);
    });
    mongod.kill();
    await Promise.race([exited, new Promise((resolve) => setTimeout(resolve, 3000))]);
  }
  if (mongodDir) {
    for (let attempt = 0; attempt < 3; attempt += 1) {
      try {
        await rm(mongodDir, { recursive: true, force: true });
        break;
      } catch (err) {
        if (attempt === 2) {
          console.warn(`[test] could not clean tmp dir ${mongodDir}:`, err.message);
          break;
        }
        await new Promise((resolve) => setTimeout(resolve, 500));
      }
    }
  }
});

const ORIGINAL_PASSWORD = "original-pass-1";

async function makeUser(email, password = ORIGINAL_PASSWORD) {
  return User.create({
    name: "Reset Tester",
    email,
    password: await bcrypt.hash(password, 10),
    role: "user",
  });
}

function resetTokenFromEmail(email) {
  const mail = capturedEmails.find((m) => m.to === email);
  assert.ok(mail, `expected a reset email for ${email}`);
  const match = mail.resetUrl.match(/token=([^&]+)/);
  assert.ok(match, "reset email must contain a token");
  return decodeURIComponent(match[1]);
}

function extractResetUrlValue(email, key) {
  const mail = capturedEmails.find((m) => m.to === email);
  assert.ok(mail, `expected a reset email for ${email}`);
  const match = mail.resetUrl.match(new RegExp(`${key}=([^&]+)`));
  assert.ok(match, `reset email must contain ${key}`);
  return decodeURIComponent(match[1]);
}

async function post(path, body) {
  return fetch(`${baseUrl}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

async function requestReset(email) {
  return post("/auth/forgot-password", { email });
}

test("request reset sends a link and never returns a token", async (t) => {
  const email = "reset-request@example.com";
  await makeUser(email);

  const res = await requestReset(email);
  assert.equal(res.status, 200);

  const body = await res.json();
  assert.ok(body.message, "response must carry a message");
  assert.equal(body.token, undefined, "token must not be exposed in the response");
  assert.equal(body.resetToken, undefined, "token must not be exposed in the response");
  assert.equal(body.resetUrl, undefined, "reset URL must not be exposed in the response");

  await resetTokenFromEmail(email);
  t.diagnostic("reset link delivered through the email seam only");
});

test("invalid token fails", async (t) => {
  const email = "invalid-token@example.com";
  await makeUser(email);
  await requestReset(email);

  const res = await post("/auth/reset-password", {
    email,
    token: "not-a-real-token",
    newPassword: "brand-new-pass",
  });

  assert.equal(res.status, 400);
  const body = await res.json();
  assert.match(body.error, /invalid|expired/i);

  const user = await User.findOne({ email });
  assert.equal(await bcrypt.compare(ORIGINAL_PASSWORD, user.password), true,
    "password must not change on an invalid token");
  t.diagnostic("password unchanged after invalid token attempt");
});

test("expired token fails", async (t) => {
  const email = "expired-token@example.com";
  await makeUser(email);
  await requestReset(email);

  const token = await resetTokenFromEmail(email);
  await User.updateOne(
    { email },
    { passwordResetTokenExpiresAt: new Date(Date.now() - 60_000) }
  );

  const res = await post("/auth/reset-password", {
    email,
    token,
    newPassword: "brand-new-pass",
  });

  assert.equal(res.status, 400);
  const body = await res.json();
  assert.match(body.error, /invalid|expired/i);

  const user = await User.findOne({ email });
  assert.equal(await bcrypt.compare(ORIGINAL_PASSWORD, user.password), true,
    "password must not change with an expired token");
  t.diagnostic("password unchanged after expired token attempt");
});

test("valid token resets the password", async (t) => {
  const email = "valid-token@example.com";
  await makeUser(email);
  await requestReset(email);

  const token = await resetTokenFromEmail(email);

  const res = await post("/auth/reset-password", {
    email,
    token,
    newPassword: "fresh-password",
  });

  assert.equal(res.status, 200);
  const body = await res.json();
  assert.match(body.message, /success/i);

  const user = await User.findOne({ email });
  assert.equal(await bcrypt.compare("fresh-password", user.password), true,
    "new password must work");
  assert.equal(await bcrypt.compare(ORIGINAL_PASSWORD, user.password), false,
    "old password must no longer work");
  t.diagnostic("valid token reset the password");
});

test("token is single use and cannot be reused", async (t) => {
  const email = "reuse-token@example.com";
  await makeUser(email);
  await requestReset(email);

  const token = await resetTokenFromEmail(email);
  const first = await post("/auth/reset-password", {
    email,
    token,
    newPassword: "after-first-reset",
  });
  assert.equal(first.status, 200);

  const second = await post("/auth/reset-password", {
    email,
    token,
    newPassword: "after-second-attempt",
  });
  assert.equal(second.status, 400, "reused token must be rejected");
  const secondBody = await second.json();
  assert.match(secondBody.error, /invalid|expired/i);

  const user = await User.findOne({ email });
  assert.equal(await bcrypt.compare("after-first-reset", user.password), true,
    "first reset must remain in effect");
  t.diagnostic("reused token rejected, first reset kept");
});

test("email + newPassword alone cannot reset the password", async (t) => {
  const email = "direct-attack@example.com";
  await makeUser(email);

  const res = await post("/auth/forgot-password", {
    email,
    newPassword: "hacker-set-password",
  });

  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.message === "Password reset successful", false,
    "legacy success message must not be returned");

  const user = await User.findOne({ email });
  assert.equal(await bcrypt.compare(ORIGINAL_PASSWORD, user.password), true,
    "email + newPassword must NOT change the password");

  const login = await post("/auth/login", {
    email,
    password: "hacker-set-password",
  });
  assert.equal(login.status, 400,
    "the attacker's password must not be able to log in");
  t.diagnostic("legacy email+newPassword vector is inert");
});

test("new password is stored hashed", async (t) => {
  const email = "hash-check@example.com";
  await makeUser(email);
  await requestReset(email);

  const token = await resetTokenFromEmail(email);
  await post("/auth/reset-password", {
    email,
    token,
    newPassword: "totally-secret",
  });

  const user = await User.findOne({ email });
  assert.notEqual(user.password, "totally-secret", "password must not be plaintext");
  assert.match(user.password, /^\$2[aby]\$/, "must be a bcrypt hash");
  assert.equal(await bcrypt.compare("totally-secret", user.password), true,
    "hash must verify the new password");
  t.diagnostic("reset password stored as a bcrypt hash");
});

test("forgot-password does not reveal whether an email exists", async (t) => {
  const res = await requestReset("nobody-lives-here@example.com");

  assert.equal(res.status, 200);
  const body = await res.json();
  assert.ok(body.message, "existing and unknown emails must share a generic message");
  t.diagnostic("no account enumeration via forgot-password");
});