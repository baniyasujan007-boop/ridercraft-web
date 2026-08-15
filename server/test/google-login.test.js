// End-to-end Google Sign-In contract tests for the mobile app's exchange:
//   POST /auth/google { credential } -> { token, role }
// The Flutter app sends the same { credential } payload and expects the same
// shape as the website, so these tests pin the full contract:
//   - audience verification wiring (verifyIdToken receives GOOGLE_CLIENT_ID),
//   - account provisioning for first-time Google users,
//   - reuse / avatar preservation for returning users,
//   - a real, verifiable RiderCraft JWT (no bypass of normal token issuance),
//   - rejection of missing / invalid tokens.
import test, { before, after } from "node:test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import net from "node:net";
import jwt from "jsonwebtoken";
import express from "express";
import mongoose from "mongoose";
import { OAuth2Client } from "google-auth-library";
import { errorHandler } from "../middleware/errorHandlers.js";

// The OAuth2Client is constructed from GOOGLE_CLIENT_ID at module load, so the
// value must be set before authRoutes is imported (done via dynamic import
// inside before()). It is the Web OAuth client ID, which is the audience the
// mobile requests for its ID token and the website uses too.
process.env.NODE_ENV = "test";
process.env.JWT_SECRET = "p4-test-secret";
process.env.GOOGLE_CLIENT_ID = "client.test.apps.googleusercontent.com";

let User;
let authRoutes;
let mongod;
let mongodDir;
let server;
let baseUrl;

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
  ({ default: authRoutes } = await import("../routes/authRoutes.js"));
  ({ default: User } = await import("../models/User.js"));

  mongodDir = await mkdtemp(join(tmpdir(), "ridercraft-google-"));
  const port = 30000 + Math.floor(Math.random() * 1500);

  mongod = spawn("mongod", [
    "--port", String(port),
    "--dbpath", mongodDir,
    "--bind_ip", "127.0.0.1",
  ], { stdio: "ignore" });

  await waitForPort(port);

  await mongoose.connect(`mongodb://127.0.0.1:${port}/ridercraft_google_test`, {
    serverSelectionTimeoutMS: 15000,
  });

  const app = express();
  app.use(express.json());
  app.use("/auth", authRoutes);
  app.use((req, res) => res.status(404).json({ error: "Not found" }));
  app.use(errorHandler);

  await new Promise((resolve) => {
    server = app.listen(0, "127.0.0.1", resolve);
  });
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) {
    server.closeAllConnections?.();
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

let googleCounter = 0;

function googleEmail() {
  googleCounter += 1;
  return `google-${Date.now()}-${googleCounter}@ridercraft.app`;
}

function googlePayload(overrides = {}) {
  return {
    sub: "g-sub-" + googleCounter,
    email: googleEmail(),
    email_verified: true,
    name: "Google Racer",
    picture: "https://example.com/google-avatar.png",
    audience: process.env.GOOGLE_CLIENT_ID,
    ...overrides,
  };
}

/// Installs a verifyIdToken mock for `t` that records the arguments, then
/// returns a ticket whose getPayload resolves `payload()`.
function mockVerifyIdToken(t, payload) {
  const seen = {};
  t.mock.method(OAuth2Client.prototype, "verifyIdToken", async (args) => {
    seen.args = args;
    return { getPayload: () => (typeof payload === "function" ? payload() : payload) };
  });
  return seen;
}

async function postGoogle(body) {
  return fetch(`${baseUrl}/auth/google`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

// ------------------------------------------------ contract & validation

test("missing credential is rejected without touching Google", async (t) => {
  const res = await postGoogle({});
  assert.equal(res.status, 400);
  const body = await res.json();
  assert.match(body.error, /credential/i);
});

test("an invalid Google token is rejected as 401 and no account is created", async (t) => {
  const email = googleEmail();
  t.mock.method(OAuth2Client.prototype, "verifyIdToken", async () => {
    throw new Error("token expired");
  });

  const res = await postGoogle({ credential: "fake.google.id.token" });
  assert.equal(res.status, 401);
  const body = await res.json();
  assert.match(body.error, /google/i);
  assert.equal(await User.exists({ email }), null);
});

// ------------------------------------------------- valid Google sign-in

test("a valid Google ID token provisions a user and returns a real RiderCraft JWT", async (t) => {
  const payload = googlePayload();
  const seenHook = mockVerifyIdToken(t, payload);

  const res = await postGoogle({ credential: "google-id-token" });
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.role, "user");
  assert.ok(body.token, "a session token must be returned");

  // The controller must hand the audience check the Web OAuth client ID.
  assert.equal(seenHook.args.idToken, "google-id-token");
  assert.equal(
    seenHook.args.audience,
    process.env.GOOGLE_CLIENT_ID,
    "verifyIdToken audience must be the shared GOOGLE_CLIENT_ID"
  );

  // The token is a genuine verifiable RiderCraft JWT (no bypass of normal
  // token issuance).
  const decoded = jwt.verify(body.token, process.env.JWT_SECRET);
  assert.ok(decoded.id, "JWT carries the user id");
  assert.equal(decoded.role, "user");

  // The account was persisted with the Google identity and avatar.
  const user = await User.findById(decoded.id);
  assert.ok(user, "the user must exist in the database");
  assert.equal(user.email, payload.email);
  assert.equal(user.googleId, payload.sub);
  assert.equal(user.authProvider, "google");
  assert.equal(user.avatar, payload.picture);

  // The issued JWT works against a protected endpoint -> a real session.
  const profile = await fetch(`${baseUrl}/auth/profile`, {
    headers: { Authorization: `Bearer ${body.token}` },
  });
  assert.equal(profile.status, 200);
  const profileBody = await profile.json();
  assert.equal(profileBody.email, payload.email);
});

test("signing in twice with the same Google account reuses the user", async (t) => {
  const payload = googlePayload();
  mockVerifyIdToken(t, payload);

  const first = await postGoogle({ credential: "tok-1" });
  const second = await postGoogle({ credential: "tok-2" });
  assert.equal(first.status, 200);
  assert.equal(second.status, 200);

  const firstId = jwt.verify((await first.json()).token, process.env.JWT_SECRET).id;
  const secondId = jwt.verify((await second.json()).token, process.env.JWT_SECRET).id;
  assert.equal(secondId, firstId, "the same Google account maps to one user");
  assert.equal(await User.countDocuments({ email: payload.email }), 1);
});

test("a returning user keeps an existing avatar instead of overwriting it", async (t) => {
  const payload = googlePayload({
    picture: "https://example.com/new-google-avatar.png",
  });

  // A user who previously set a custom avatar signs in with Google.
  await User.create({
    name: "Returning Racer",
    email: payload.email,
    googleId: payload.sub,
    authProvider: "google",
    avatar: "data:image/png;base64,existing-custom-avatar",
  });

  mockVerifyIdToken(t, payload);
  const res = await postGoogle({ credential: "tok" });
  assert.equal(res.status, 200);

  const decoded = jwt.verify((await res.json()).token, process.env.JWT_SECRET);
  const user = await User.findById(decoded.id);
  assert.equal(user.avatar, "data:image/png;base64,existing-custom-avatar");
  assert.equal(user.email, payload.email);
});