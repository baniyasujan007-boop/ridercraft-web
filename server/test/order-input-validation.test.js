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
import orderRoutes from "../routes/orderRoutes.js";
import Product from "../models/Product.js";
import User from "../models/User.js";

process.env.JWT_SECRET = "p5-test-secret";

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
  const port = 29000 + Math.floor(Math.random() * 1000);

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
  app.use("/orders", orderRoutes);

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

async function createUser() {
  return User.create({
    name: "Input Tester",
    email: `${Date.now()}-${Math.random().toString(36).slice(2)}@test.dev`,
    password: "secret123",
    role: "user",
  });
}

async function createProduct() {
  return Product.create({
    name: "Test Jacket",
    price: 120,
    stock: 25,
  });
}

async function tokenFor(user) {
  return jwt.sign({ id: user._id.toString(), role: user.role }, process.env.JWT_SECRET);
}

async function placeOrder({ token, items, paymentMethod = "cod", paymentDetails = {} }) {
  return fetch(`${baseUrl}/orders`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      items,
      subtotal: 120,
      tax: 0,
      shipping: 0,
      discount: 0,
      total: 120,
      promoCode: "",
      paymentMethod,
      paymentDetails,
    }),
  });
}

test("malformed productId is rejected as a 4xx, never a 500 CastError", async (t) => {
  const user = await createUser();
  const res = await placeOrder({
    token: await tokenFor(user),
    items: [{ productId: "abc", qty: 1 }],
  });

  assert.equal(res.status, 400, "malformed id must be a clean 4xx validation error");
  const body = await res.json();
  assert.equal(body.error, "Invalid order items");
  assert.doesNotMatch(JSON.stringify(body), /CastError/, "raw mongoose CastError must not leak");
  assert.equal(body.name, undefined, "dangerous error metadata must not be returned");

  const orderCount = await mongoose.model("Order").countDocuments();
  assert.equal(orderCount, 0, "no order may be created for a malformed id");
  t.diagnostic("malformed productId returned 400 with generic error, no order created");
});

test("empty productId is rejected as 400 without touching stock", async (t) => {
  const user = await createUser();
  const product = await createProduct();
  const res = await placeOrder({
    token: await tokenFor(user),
    items: [{ productId: "", qty: 1 }],
  });

  assert.equal(res.status, 400);
  const body = await res.json();
  assert.equal(body.error, "Invalid order items");

  const fresh = await Product.findById(product._id);
  assert.equal(fresh.stock, 25, "stock must not be decremented for a rejected request");
  t.diagnostic("empty productId rejected as 400, stock untouched");
});

test("valid productId still creates the order normally", async (t) => {
  const user = await createUser();
  const product = await createProduct();
  const res = await placeOrder({
    token: await tokenFor(user),
    items: [{ productId: product._id.toString(), qty: 1 }],
  });

  assert.equal(res.status, 201, "legitimate order creation must be unchanged");
  const order = await res.json();
  assert.equal(order.paymentMethod, "cod");
  assert.equal(order.paymentStatus, "pending");
  assert.equal(order.paymentReference, "COD");

  const stored = await mongoose.model("Order").findById(order._id);
  assert.ok(stored, "order must be persisted");
  assert.equal(stored.items[0].productId.toString(), product._id.toString());
  t.diagnostic("valid order still created with status 201");
});