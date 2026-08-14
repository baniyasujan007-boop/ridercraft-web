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

process.env.JWT_SECRET = "p3-test-secret";

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
  mongodDir = await mkdtemp(join(tmpdir(), "ridercraft-p3-"));
  const port = 29000 + Math.floor(Math.random() * 1000);

  mongod = spawn("mongod", [
    "--port", String(port),
    "--dbpath", mongodDir,
    "--bind_ip", "127.0.0.1",
  ], { stdio: "ignore" });

  await waitForPort(port);

  await mongoose.connect(`mongodb://127.0.0.1:${port}/ridercraft_p3_test`, {
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
    mongod.kill();
  }
  if (mongodDir) {
    await rm(mongodDir, { recursive: true, force: true });
  }
});

async function createUser() {
  return User.create({
    name: "Payment Tester",
    email: `${Date.now()}-${Math.random().toString(36).slice(2)}@test.dev`,
    password: "secret123",
    role: "user",
  });
}

async function createProduct() {
  return Product.create({
    name: "Test Helmet",
    price: 100,
    stock: 25,
  });
}

async function tokenFor(user) {
  return jwt.sign({ id: user._id.toString(), role: user.role }, process.env.JWT_SECRET);
}

async function placeOrder({ token, paymentMethod, paymentDetails = {} }) {
  const product = await createProduct();
  return fetch(`${baseUrl}/orders`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      items: [{ productId: product._id.toString(), qty: 1 }],
      paymentMethod,
      paymentDetails,
    }),
  });
}

test("COD order is created as pending", async (t) => {
  const user = await createUser();
  const res = await placeOrder({ token: await tokenFor(user), paymentMethod: "cod" });

  assert.equal(res.status, 201);
  const order = await res.json();
  assert.equal(order.paymentMethod, "cod");
  assert.equal(order.paymentStatus, "pending");
  assert.equal(order.paymentReference, "COD");
  t.diagnostic("COD order created, payment pending");
});

test("real card details without demo flag are rejected", async (t) => {
  const user = await createUser();
  const res = await placeOrder({
    token: await tokenFor(user),
    paymentMethod: "card",
    paymentDetails: {
      cardNumber: "4242424242424242",
      cardHolder: "REAL CUSTOMER",
      expiry: "12/30",
      cvv: "123",
    },
  });

  assert.equal(res.status, 400, "production card path must be rejected");
  const body = await res.json();
  assert.match(body.error, /not available/i);
  t.diagnostic("real card details cannot create a paid order");
});

test("demo card is only accepted in explicit demo mode", async (t) => {
  const user = await createUser();
  const res = await placeOrder({
    token: await tokenFor(user),
    paymentMethod: "card",
    paymentDetails: {
      cardNumber: "4242424242424242",
      cardHolder: "TEST CUSTOMER",
      expiry: "12/30",
      cvv: "123",
      isDummy: true,
    },
  });

  assert.equal(res.status, 201, "demo payment should be accepted when isDummy is true");
  const order = await res.json();
  assert.equal(order.paymentStatus, "pending", "demo card must not be paid automatically");
  assert.equal(order.paymentReference.startsWith("DEMO-CARD-"), true);
  assert.equal(order.paymentMeta?.isDemo, true);
  assert.equal(order.paymentMeta?.cardLast4, "4242");
  t.diagnostic("demo card order placed, stays pending");
});

test("full PAN is never persisted", async (t) => {
  const user = await createUser();
  const res = await placeOrder({
    token: await tokenFor(user),
    paymentMethod: "card",
    paymentDetails: {
      cardNumber: "5555555555554444",
      cardHolder: "TEST CUSTOMER",
      expiry: "12/30",
      cvv: "999",
      isDummy: true,
    },
  });

  const order = await res.json();
  const raw = JSON.stringify(order);
  assert.equal(raw.includes("cardNumber"), false, "no cardNumber field may be returned");
  assert.equal(raw.includes("5555555555554444"), false, "full PAN must not be returned");
  assert.equal(order.paymentMeta?.cardLast4, "4444", "only cardLast4 is retained");

  const stored = await mongoose.model("Order").findById(order._id).lean();
  const storedRaw = JSON.stringify(stored);
  assert.equal(storedRaw.includes("5555555555554444"), false, "full PAN must not be persisted");
  t.diagnostic("full PAN never persisted, last4 only");
});

test("CVV is never persisted", async (t) => {
  const user = await createUser();
  const res = await placeOrder({
    token: await tokenFor(user),
    paymentMethod: "card",
    paymentDetails: {
      cardNumber: "4242424242424242",
      cardHolder: "TEST CUSTOMER",
      expiry: "12/30",
      cvv: "777",
      isDummy: true,
    },
  });

  const order = await res.json();
  assert.equal(JSON.stringify(order).includes("777"), false, "CVV must not be returned");

  const stored = await mongoose.model("Order").findById(order._id).lean();
  assert.equal(JSON.stringify(stored).includes("777"), false, "CVV must not be persisted");
  t.diagnostic("CVV never persisted");
});

test("card payment cannot become paid without admin confirmation", async (t) => {
  const user = await createUser();
  const res = await placeOrder({
    token: await tokenFor(user),
    paymentMethod: "card",
    paymentDetails: {
      cardNumber: "4242424242424242",
      cardHolder: "TEST CUSTOMER",
      expiry: "12/30",
      cvv: "123",
      isDummy: true,
    },
  });

  const order = await res.json();
  assert.equal(order.paymentStatus, "pending");

  const stored = await mongoose.model("Order").findById(order._id).lean();
  assert.equal(stored.paymentStatus, "pending", "order must stay pending after creation");
  t.diagnostic("no card order starts as paid");
});

test("e-wallet without real provider is demo only too", async (t) => {
  const user = await createUser();

  const withoutDummy = await placeOrder({
    token: await tokenFor(user),
    paymentMethod: "ewallet",
    paymentDetails: { walletProvider: "PhonePe", walletId: "someone@test.dev" },
  });
  assert.equal(withoutDummy.status, 400, "e-wallet without demo flag must be rejected");
  const body = await withoutDummy.json();
  assert.match(body.error, /not available/i);

  const withDummy = await placeOrder({
    token: await tokenFor(user),
    paymentMethod: "ewallet",
    paymentDetails: {
      walletProvider: "PhonePe",
      walletId: "dummy.wallet@test.dev",
      isDummy: true,
    },
  });
  assert.equal(withDummy.status, 201, "demo e-wallet should be accepted when isDummy is true");
  const demoOrder = await withDummy.json();
  assert.equal(demoOrder.paymentStatus, "pending");
  assert.equal(demoOrder.paymentReference.startsWith("DEMO-WALLET-"), true);
  assert.equal(demoOrder.paymentMeta?.isDemo, true);
  t.diagnostic("e-wallet demo order placed, stays pending");
});