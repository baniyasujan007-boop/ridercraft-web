import test, { before, after } from "node:test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import net from "node:net";
import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";
import express from "express";
import mongoose from "mongoose";
import { corsOptions } from "../config/security.js";
import { authLimiter } from "../middleware/rateLimit.js";
import { errorHandler } from "../middleware/errorHandlers.js";
import authRoutes from "../routes/authRoutes.js";
import productRoutes from "../routes/productRoutes.js";
import promoRoutes from "../routes/promoRoutes.js";
import User from "../models/User.js";

const RIDER_ORIGIN = "https://ridercraft.example.com";
const EVIL_ORIGIN = "https://attacker.example.com";

// Real-world register flows bcrypt the password; seed test users with a hash so
// password-compare login paths behave like production.
const HASHED_LOGIN_PASSWORD = bcrypt.hashSync("secret123", 10);
const WRONG_PASSWORD = "definitely-wrong";

process.env.NODE_ENV = "test";
process.env.JWT_SECRET = "p4-test-secret";
process.env.FRONTEND_URL = RIDER_ORIGIN;
process.env.CLIENT_URL = RIDER_ORIGIN;

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
  mongodDir = await mkdtemp(join(tmpdir(), "ridercraft-p4-"));
  const port = 30000 + Math.floor(Math.random() * 1500);

  mongod = spawn("mongod", [
    "--port", String(port),
    "--dbpath", mongodDir,
    "--bind_ip", "127.0.0.1",
  ], { stdio: "ignore" });

  await waitForPort(port);

  await mongoose.connect(`mongodb://127.0.0.1:${port}/ridercraft_p4_test`, {
    serverSelectionTimeoutMS: 15000,
  });

  const app = express();
  app.use(express.json());
  app.use("/auth", authRoutes);
  app.use("/products", productRoutes);
  app.use("/promos", promoRoutes);
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

async function makeUser(overrides = {}) {
  return User.create({
    name: "Security Tester",
    email: `${Date.now()}-${Math.random().toString(36).slice(2)}@test.dev`,
    password: "secret123",
    role: "user",
    ...overrides,
  });
}

function tokenFor(user, secret = process.env.JWT_SECRET, role = user.role) {
  return jwt.sign({ id: user._id.toString(), role }, secret);
}

function listen(app) {
  return new Promise((resolve) => {
    const s = app.listen(0, "127.0.0.1", () => resolve(s));
  });
}

async function shut(s) {
  s?.closeAllConnections?.();
  await new Promise((resolve) => s.close(resolve));
}

async function corsServer() {
  const corsApp = express();
  corsApp.use(corsOptions());
  corsApp.get("/ping", (req, res) => res.json({ ok: true }));
  const s = await listen(corsApp);
  return { s, url: `http://127.0.0.1:${s.address().port}/ping` };
}

async function get(path, token) {
  return fetch(`${baseUrl}${path}`, {
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  });
}

// ---------------------------------------------------------------- CORS

test("allowed CORS origin is echoed", async (t) => {
  const { s, url } = await corsServer();
  try {
    const res = await fetch(url, { headers: { Origin: RIDER_ORIGIN } });
    assert.equal(res.status, 200);
    assert.equal(res.headers.get("access-control-allow-origin"), RIDER_ORIGIN);
    assert.equal(res.headers.get("access-control-allow-credentials"), "true");
    t.diagnostic("RiderCraft origin allowed with credentials");
  } finally {
    await shut(s);
  }
});

test("disallowed CORS origin is rejected", async (t) => {
  const { s, url } = await corsServer();
  try {
    const res = await fetch(url, { headers: { Origin: EVIL_ORIGIN } });
    assert.equal(
      res.headers.get("access-control-allow-origin"),
      null,
      "untrusted origin must never be echoed"
    );
    t.diagnostic("untrusted origin gets no CORS allow header");
  } finally {
    await shut(s);
  }
});

test("non-browser requests (Flutter API) still work with no Origin header", async (t) => {
  const { s, url } = await corsServer();
  try {
    const res = await fetch(url);
    assert.equal(res.status, 200);
    t.diagnostic("origin-less requests are not blocked");
  } finally {
    await shut(s);
  }
});

test("multiple comma-separated production origins are all allowed", async (t) => {
  const secondOrigin = "https://ridercraft-admin.example.com";
  process.env.FRONTEND_URL = `${RIDER_ORIGIN}, ${secondOrigin}`;
  try {
    const { s, url } = await corsServer();
    try {
      for (const origin of [RIDER_ORIGIN, secondOrigin]) {
        const res = await fetch(url, { headers: { Origin: origin } });
        assert.equal(
          res.headers.get("access-control-allow-origin"),
          origin,
          `${origin} must be echoed`
        );
        assert.equal(res.headers.get("access-control-allow-credentials"), "true");
      }

      const blocked = await fetch(url, { headers: { Origin: EVIL_ORIGIN } });
      assert.equal(
        blocked.headers.get("access-control-allow-origin"),
        null,
        "unlisted origin stays blocked even when the list has multiple entries"
      );
    } finally {
      await shut(s);
    }
  } finally {
    process.env.FRONTEND_URL = RIDER_ORIGIN;
  }
});

// ------------------------------------------------------------- enumeration

test("login with an unknown email returns the generic invalid-credentials response", async () => {
  const res = await fetch(`${baseUrl}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: "no-such-account@test.dev", password: WRONG_PASSWORD }),
  });
  assert.equal(res.status, 400);
  const body = await res.json();
  assert.equal(body.error, "Invalid email or password");
});

test("login with a wrong password returns the identical generic response", async () => {
  const user = await makeUser({ password: HASHED_LOGIN_PASSWORD });
  const res = await fetch(`${baseUrl}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: user.email, password: WRONG_PASSWORD }),
  });
  assert.equal(res.status, 400);
  const body = await res.json();
  assert.equal(body.error, "Invalid email or password");
});

test("login with correct credentials still succeeds for known roles", async () => {
  for (const role of ["user", "admin"]) {
    const user = await makeUser({ role, password: HASHED_LOGIN_PASSWORD });
    const res = await fetch(`${baseUrl}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: user.email, password: "secret123" }),
    });
    assert.equal(res.status, 200, `${role} login must succeed`);
    const body = await res.json();
    assert.ok(body.token, `${role} login must return a token`);
    assert.equal(body.role, role);
  }
});

// ---------------------------------------------------- admin authorization

test("admin endpoint rejects a request without a token", async (t) => {
  const res = await get("/promos");
  assert.equal(res.status, 401);
  const body = await res.json();
  assert.match(body.error, /unauthor/i);
  t.diagnostic("no token -> 401 on admin endpoint");
});

test("normal user cannot reach an admin endpoint", async (t) => {
  const user = await makeUser();
  const res = await get("/promos", tokenFor(user));
  assert.equal(res.status, 403);
  const body = await res.json();
  assert.match(body.error, /admin/i);
  t.diagnostic("user -> 403 on admin endpoint");
});

test("admin can reach the admin endpoint", async (t) => {
  const admin = await makeUser({ role: "admin" });
  const res = await get("/promos", tokenFor(admin));
  assert.equal(res.status, 200);
  t.diagnostic("admin -> 200 on admin endpoint");
});

test("token signed with the wrong secret is rejected", async (t) => {
  const user = await makeUser();
  const res = await get("/promos", tokenFor(user, "wrong-secret"));
  assert.equal(res.status, 401);
  t.diagnostic("forged token -> 401");
});

// ------------------------------------------------------ garage registration

test("public registration rejects the garage role", async (t) => {
  const email = "want-to-be-garage@test.dev";
  const res = await fetch(`${baseUrl}/auth/register`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      name: "Escalator",
      email,
      password: "secret123",
      role: "garage",
      garageName: "Hacked Garage",
      garageAddress: "123 Evil St",
      latitude: 12.9,
      longitude: 77.5,
      serviceRadiusKm: 10,
    }),
  });

  assert.equal(res.status, 400);
  const body = await res.json();
  assert.match(body.error, /role/i);
  assert.equal(await User.exists({ email }), null, "no garage account may be created");
  t.diagnostic("public register cannot self-assign the garage role");
});

test("public registration still creates a normal user", async (t) => {
  const email = `normal-${Date.now()}@test.dev`;
  const res = await fetch(`${baseUrl}/auth/register`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name: "Plain User", email, password: "secret123" }),
  });

  assert.equal(res.status, 200);
  const user = await User.findOne({ email });
  assert.equal(user.role, "user");
  t.diagnostic("public register creates role=user only");
});

test("admin workflow can still create a garage account", async (t) => {
  const admin = await makeUser({ role: "admin" });
  const res = await fetch(`${baseUrl}/auth/garage/register`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${tokenFor(admin)}`,
    },
    body: JSON.stringify({
      name: "Legit Garage",
      email: `garage-${Date.now()}@test.dev`,
      password: "secret123",
      garageName: "Legit Garage",
      garageAddress: "Main Road",
      latitude: 12.9,
      longitude: 77.5,
      serviceRadiusKm: 10,
    }),
  });

  assert.equal(res.status, 201);
  const body = await res.json();
  assert.equal(body.garage.role, "garage");
  t.diagnostic("authorized admin garage registration preserved");
});

test("non-admin cannot use the admin garage workflow", async (t) => {
  const user = await makeUser();
  const res = await fetch(`${baseUrl}/auth/garage/register`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${tokenFor(user)}`,
    },
    body: JSON.stringify({
      name: "Sneaky Garage",
      email: `sneaky-${Date.now()}@test.dev`,
      password: "secret123",
      garageName: "Sneaky",
      garageAddress: "X",
      latitude: 12.9,
      longitude: 77.5,
    }),
  });

  assert.equal(res.status, 403);
  t.diagnostic("non-admin rejected on garage management");
});

// ------------------------------------------------------ input validation

test("malformed ObjectId is rejected with 400, not a 500 CastError", async (t) => {
  const res = await get("/products/not-a-valid-object-id");
  assert.equal(res.status, 400);
  const body = await res.json();
  assert.match(body.error, /resource id/i);
  t.diagnostic("invalid ObjectId -> 400");
});

test("admin routes reject malformed ids before any DB lookup", async (t) => {
  const admin = await makeUser({ role: "admin" });
  const res = await fetch(`${baseUrl}/promos/not-an-id`, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${tokenFor(admin)}`,
    },
    body: JSON.stringify({ code: "X" }),
  });
  assert.equal(res.status, 400);
  const body = await res.json();
  assert.match(body.error, /resource id/i);
  t.diagnostic("route-level ObjectId guard active");
});

// ---------------------------------------------------------- error handling

test("malformed JSON body returns a clean JSON error without internals", async (t) => {
  const raw = await fetch(`${baseUrl}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: "{ this is not json",
  });

  assert.equal(raw.status, 400);
  const text = await raw.text();
  assert.equal(raw.headers.get("content-type").includes("application/json"), true);
  const body = JSON.parse(text);
  assert.match(body.error, /request body/i);
  assert.equal(text.includes("/Users"), false, "no filesystem paths leaked");
  assert.equal(text.includes("node:"), false, "no module paths leaked");
  assert.equal(text.includes(" at "), false, "no stack traces leaked");
  t.diagnostic("parse errors are clean, generic JSON");
});

test("unknown routes return JSON 404, not an HTML stack page", async (t) => {
  const res = await fetch(`${baseUrl}/no-such-route`);
  assert.equal(res.status, 404);
  assert.equal(res.headers.get("content-type").includes("application/json"), true);
  const body = await res.json();
  assert.match(body.error, /not found/i);
  t.diagnostic("404 responses are JSON only");
});

// ------------------------------------------------------------ rate limiting

test("auth endpoints are rate limited more strictly", async (t) => {
  process.env.AUTH_RATE_MAX = "4";

  const rateApp = express();
  rateApp.use(express.json());
  rateApp.use(authLimiter);
  rateApp.post("/auth/login", (req, res) => res.status(400).json({ error: "User not found" }));
  const s = await listen(rateApp);
  const url = `http://127.0.0.1:${s.address().port}/auth/login`;

  try {
    const attempt = () =>
      fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: "x@test.dev", password: "wrong" }),
      });

    for (let i = 0; i < 4; i += 1) {
      const res = await attempt();
      assert.notEqual(res.status, 429, `attempt ${i + 1} should not be limited yet`);
    }

    const limited = await attempt();
    assert.equal(limited.status, 429, "5th attempt within the window must be blocked");
    const body = await limited.json();
    assert.match(body.error, /too many/i);
    t.diagnostic("auth limiter blocks after max attempts");
  } finally {
    delete process.env.AUTH_RATE_MAX;
    await shut(s);
  }
});