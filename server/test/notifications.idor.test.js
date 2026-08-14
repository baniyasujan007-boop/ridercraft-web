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
import notificationRoutes from "../routes/notifications.js";
import Notification from "../models/Notification.js";
import User from "../models/User.js";

process.env.JWT_SECRET = "p1-test-secret";

let mongod;
let mongodDir;
let mongoUri;
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
  mongodDir = await mkdtemp(join(tmpdir(), "ridercraft-test-"));
  const port = 27000 + Math.floor(Math.random() * 1000);

  mongod = spawn("mongod", [
    "--port", String(port),
    "--dbpath", mongodDir,
    "--bind_ip", "127.0.0.1",
  ], { stdio: "ignore" });

  await waitForPort(port);

  mongoUri = `mongodb://127.0.0.1:${port}/ridercraft_p1_test`;
  await mongoose.connect(mongoUri, {
    serverSelectionTimeoutMS: 15000,
  });

  const app = express();
  app.use(express.json());
  app.use("/notifications", notificationRoutes);

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
    mongod.kill();
  }
  if (mongodDir) {
    await rm(mongodDir, { recursive: true, force: true });
  }
});

async function makeUser(overrides = {}) {
  return User.create({
    name: "Test User",
    email: `${Date.now()}-${Math.random().toString(36).slice(2)}@test.dev`,
    password: "secret123",
    role: "user",
    ...overrides,
  });
}

function tokenFor(user) {
  return jwt.sign({ id: user._id.toString(), role: user.role }, process.env.JWT_SECRET);
}

async function markRead(user, notificationId) {
  return fetch(`${baseUrl}/notifications/${notificationId}/read`, {
    method: "PUT",
    headers: {
      Authorization: `Bearer ${tokenFor(user)}`,
    },
  });
}

test("User A can mark their own notification as read", async (t) => {
  const userA = await makeUser();
  const notification = await Notification.create({
    userId: userA._id,
    title: "Order update",
    body: "Your order shipped",
    type: "order",
    isRead: false,
  });

  const res = await markRead(userA, notification._id);
  assert.equal(res.status, 200);

  const body = await res.json();
  assert.deepEqual(body, { success: true });

  const after = await Notification.findById(notification._id);
  assert.equal(after.isRead, true);

  t.diagnostic("User A owned notification marked read");
});

test("User B cannot mark User A's notification as read", async (t) => {
  const userA = await makeUser();
  const userB = await makeUser();

  const notification = await Notification.create({
    userId: userA._id,
    title: "Private notice",
    body: "Only user A should see this",
    type: "general",
    isRead: false,
  });

  const res = await markRead(userB, notification._id);
  assert.equal(res.status, 200);

  const after = await Notification.findById(notification._id);
  assert.equal(after.isRead, false, "User B must not be able to mark User A's notification read");

  t.diagnostic("User B's attempt left User A's notification untouched");
});
