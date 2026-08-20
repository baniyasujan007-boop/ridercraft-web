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
import Promo from "../models/Promo.js";
import User from "../models/User.js";

process.env.JWT_SECRET = "p6-test-secret";

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
  mongodDir = await mkdtemp(join(tmpdir(), "ridercraft-p6-"));
  const port = 29000 + Math.floor(Math.random() * 1000);

  mongod = spawn("mongod", [
    "--port", String(port),
    "--dbpath", mongodDir,
    "--bind_ip", "127.0.0.1",
  ], { stdio: "ignore" });

  await waitForPort(port);

  await mongoose.connect(`mongodb://127.0.0.1:${port}/ridercraft_p6_test`, {
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
    name: "Coupon Tester",
    email: `${Date.now()}-${Math.random().toString(36).slice(2)}@test.dev`,
    password: "secret123",
    role: "user",
  });
}

async function createProduct({ price = 120, stock = 25 } = {}) {
  return Product.create({ name: "Coupon Helmet", price, stock });
}

let promoSeq = 0;

async function createPromo({
  discountType = "percent",
  discountValue = 10,
  maxUses = 5,
  usedCount = 0,
  isActive = true,
  endsInMs = 24 * 60 * 60 * 1000,
} = {}) {
  promoSeq += 1;
  const code = `T${Date.now().toString(36)}${promoSeq}`;
  const promo = await Promo.create({
    code,
    discountType,
    discountValue,
    maxUses,
    usedCount,
    startsAt: new Date(Date.now() - 24 * 60 * 60 * 1000),
    endsAt: new Date(Date.now() + endsInMs),
    isActive,
  });
  return { promo, code: promo.code };
}

async function tokenFor(user) {
  return jwt.sign({ id: user._id.toString(), role: user.role }, process.env.JWT_SECRET);
}

async function placeOrder({ token, product, promoCode = "" }) {
  return fetch(`${baseUrl}/orders`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      items: [{ productId: product._id.toString(), qty: 1 }],
      subtotal: 120,
      tax: 0,
      shipping: 0,
      discount: 0,
      total: 120,
      promoCode,
      paymentMethod: "cod",
      paymentDetails: {},
    }),
  });
}

test("order without a coupon succeeds (discount 0)", async (t) => {
  const user = await createUser();
  const product = await createProduct();
  const res = await placeOrder({ token: await tokenFor(user), product });

  assert.equal(res.status, 201, "no-coupon order must succeed");
  const order = await res.json();
  assert.equal(order.discount, 0);
  assert.equal(order.promoCode, "");
  t.diagnostic("no-coupon order created as 201, discount 0");
});

test("valid coupon order succeeds with correct discount, total, and redemption", async (t) => {
  const user = await createUser();
  const product = await createProduct();
  const { promo, code } = await createPromo({ discountType: "percent", discountValue: 10 });

  const res = await placeOrder({ token: await tokenFor(user), product, promoCode: code });

  assert.equal(res.status, 201, "valid coupon must not cause a 500");
  const order = await res.json();
  assert.equal(order.promoCode, code);
  assert.equal(order.discount, 12, "10% of 120 subtotal");
  assert.equal(order.subtotal, 120);
  assert.equal(order.total, 117.6, "subtotal 120 + tax 9.6 - discount 12");

  const stored = await mongoose.model("Order").findById(order._id);
  assert.ok(stored, "order must be persisted");
  assert.equal(stored.discount, 12);

  const updated = await Promo.findById(promo._id);
  assert.equal(updated.usedCount, 1, "redemption must be recorded");
  assert.equal(updated.isActive, true, "promo stays active while uses remain");
  t.diagnostic("coupon order 201, discount 12, total 117.60, usedCount incremented");
});

test("flat coupon discount is calculated correctly", async (t) => {
  const user = await createUser();
  const product = await createProduct();
  const { code } = await createPromo({ discountType: "flat", discountValue: 20 });

  const res = await placeOrder({ token: await tokenFor(user), product, promoCode: code });
  assert.equal(res.status, 201);
  const order = await res.json();
  assert.equal(order.discount, 20);
  assert.equal(order.total, 109.6, "subtotal 120 + tax 9.6 - flat 20");
  t.diagnostic("flat coupon order discount 20, total 109.60");
});

test("unknown coupon returns 400, never a 500", async (t) => {
  const user = await createUser();
  const product = await createProduct();
  const before = await mongoose.model("Order").countDocuments();
  const res = await placeOrder({ token: await tokenFor(user), product, promoCode: "DOESNOTEXIST" });

  assert.equal(res.status, 400, "unknown coupon must be a clean 4xx");
  const body = await res.json();
  assert.equal(body.error, "Promo code is no longer valid");
  assert.equal(
    await mongoose.model("Order").countDocuments(),
    before,
    "no order created",
  );
  t.diagnostic("unknown coupon -> 400 with generic error, no order");
});

test("expired coupon returns 400, never a 500", async (t) => {
  const user = await createUser();
  const product = await createProduct();
  const { code } = await createPromo({ endsInMs: -24 * 60 * 60 * 1000 });
  const before = await mongoose.model("Order").countDocuments();

  const res = await placeOrder({ token: await tokenFor(user), product, promoCode: code });
  assert.equal(res.status, 400, "expired coupon must be a clean 4xx");
  const body = await res.json();
  assert.equal(body.error, "Promo code is no longer valid");
  assert.equal(
    await mongoose.model("Order").countDocuments(),
    before,
    "no order created",
  );
  t.diagnostic("expired coupon -> 400, no order");
});

test("fully redeemed coupon rolls back stock and returns 400, never a 500", async (t) => {
  const user = await createUser();
  const product = await createProduct();
  const { code } = await createPromo({ usedCount: 5, maxUses: 5 });
  const before = await mongoose.model("Order").countDocuments();

  const res = await placeOrder({ token: await tokenFor(user), product, promoCode: code });
  assert.equal(res.status, 400, "fully redeemed coupon must be a clean 4xx");
  const body = await res.json();
  assert.equal(body.error, "Promo code is no longer valid");

  const fresh = await Product.findById(product._id);
  assert.equal(fresh.stock, 25, "stock must be rolled back when redemption fails");
  assert.equal(
    await mongoose.model("Order").countDocuments(),
    before,
    "no order created",
  );
  t.diagnostic("saturated coupon -> 400, stock rolled back, no order");
});

test("coupon deactivates when redemption hits max uses", async (t) => {
  const user = await createUser();
  const product = await createProduct();
  const { promo, code } = await createPromo({ maxUses: 1 });

  const first = await placeOrder({ token: await tokenFor(user), product, promoCode: code });
  assert.equal(first.status, 201);

  const updated = await Promo.findById(promo._id);
  assert.equal(updated.usedCount, 1);
  assert.equal(updated.isActive, false, "promo auto-deactivates at max uses");

  const second = await placeOrder({ token: await tokenFor(user), product, promoCode: code });
  assert.equal(second.status, 400, "coupon cannot be reused past its limit");
  t.diagnostic("coupon auto-deactivates at max uses and cannot be reused");
});