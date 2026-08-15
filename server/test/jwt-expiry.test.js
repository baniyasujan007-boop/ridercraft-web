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
import authRoutes from "../routes/authRoutes.js";
import authMiddleware, { requireAdmin, requireGarage } from "../middleware/authMiddleware.js";
import User from "../models/User.js";

process.env.JWT_SECRET = "p5-test-secret";
process.env.JWT_EXPIRES_IN = "30m";

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
  mongodDir = await mkdtemp(join(tmpdir(), "ridercraft-p5-"));
  const port = 31000 + Math.floor(Math.random() * 1500);

  mongod = spawn("mongod", [
    "--port", String(port),
    "--dbpath", mongodDir,
    "--bind_ip", "127.0.0.1",
  ], { stdio: "ignore" });

  await waitForPort(port);

  await mongoose.connect(`mongodb://127.0.0.1:${port}/ridercraft_p5_test`, {
    serverSelectionTimeoutMS: 15000,
  });

  const app = express();
  app.use(express.json());
  app.use("/auth", authRoutes);
  app.use("/guarded", (req, res, next) => {
    if (!req.path.startsWith("/user") &&
        !req.path.startsWith("/admin") &&
        !req.path.startsWith("/garage")) {
      return res.status(404).json({ error: "Not found" });
    }
    next();
  });
  app.get("/guarded/user", authMiddleware, (req, res) => res.json({ ok: true, role: req.user.role }));
  app.get("/guarded/admin", authMiddleware, requireAdmin, (req, res) => res.json({ ok: true, role: req.user.role }));
  app.get("/guarded/garage", authMiddleware, requireGarage, (req, res) => res.json({ ok: true, role: req.user.role }));

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

function sign({ id, role, secret = process.env.JWT_SECRET, expiresIn = "60m" }) {
  return jwt.sign({ id, role }, secret, { expiresIn });
}

function expired() {
  return jwt.sign({ id: "507f1f77bcf86cd799439011", role: "user" }, process.env.JWT_SECRET, {
    expiresIn: -30,
  });
}

async function guarded(path, token) {
  return fetch(`${baseUrl}${path}`, {
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  });
}

// --------------------------------------------------------------- expiry core

test("missing token is rejected with 401", async () => {
  const res = await guarded("/guarded/user");
  assert.equal(res.status, 401);
  const body = await res.json();
  assert.match(body.error, /unauthor/i);
});

test("malformed token is rejected with 401", async () => {
  const res = await guarded("/guarded/user", "not-a-real-token");
  assert.equal(res.status, 401);
  const body = await res.json();
  assert.match(body.error, /invalid/i);
});

test("valid user token returns 200", async () => {
  const res = await guarded("/guarded/user", sign({ id: "aaaaaaaaaaaaaaaaaaaaaaaa", role: "user" }));
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.role, "user");
});

test("future-expiration token returns 200", async () => {
  const res = await guarded("/guarded/user", sign({ id: "aaaaaaaaaaaaaaaaaaaaaaaa", role: "user" }, process.env.JWT_SECRET, "user", "1h"));
  assert.equal(res.status, 200);
});

test("expired token returns 401, not 500, with a session message", async () => {
  const res = await guarded("/guarded/user", expired());
  assert.equal(res.status, 401, "expired token must be 401 (never 500)");
  const body = await res.json();
  assert.match(body.error, /session/i);
  assert.equal(body.error.includes("JWT_SECRET"), false, "no internals leaked");
});

// ------------------------------------------------------------ role matrix

test("admin token is granted admin access", async () => {
  const res = await guarded("/guarded/admin", sign({ id: "aaaaaaaaaaaaaaaaaaaaaaaa", role: "admin" }));
  assert.equal(res.status, 200);
});

test("user token is denied admin access", async () => {
  const res = await guarded("/guarded/admin", sign({ id: "aaaaaaaaaaaaaaaaaaaaaaaa", role: "user" }));
  assert.equal(res.status, 403);
});

test("garage token is granted garage access", async () => {
  const res = await guarded("/guarded/garage", sign({ id: "aaaaaaaaaaaaaaaaaaaaaaaa", role: "garage" }));
  assert.equal(res.status, 200);
});

test("bad algorithm cannot bypass HS256 verification", async () => {
  const forged = jwt.sign(
    { id: "aaaaaaaaaaaaaaaaaaaaaaaa", role: "admin" },
    process.env.JWT_SECRET,
    { algorithm: "HS384", expiresIn: "1h" }
  );
  const res = await guarded("/guarded/admin", forged);
  assert.equal(res.status, 401, "HS384-signed token must be rejected");
});

// ------------------------------------------------- login issues an exp

test("login returns a JWT that carries an expiry claim", async (t) => {
  const email = `jwt-${Date.now()}@test.dev`;
  await User.create({
    name: "JWT Tester",
    email,
    password: await bcrypt.hash("secret123", 10),
    role: "user",
  });

  const res = await fetch(`${baseUrl}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "secret123" }),
  });
  assert.equal(res.status, 200);

  const { token } = await res.json();
  const decoded = jwt.verify(token, process.env.JWT_SECRET);

  assert.ok(Number.isFinite(decoded.exp), "issued token must have an exp claim");
  const ttlSeconds = decoded.exp - Math.floor(Date.now() / 1000);
  assert.ok(ttlSeconds > 24 * 60, `expected ~30m lifetime, got ${ttlSeconds}s`);

  const ok = await guarded("/guarded/user", token);
  assert.equal(ok.status, 200, "issued token must be accepted");

  t.diagnostic(`login token lifetime ~${ttlSeconds}s`);
});