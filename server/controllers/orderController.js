import Order from "../models/Order.js";
import Notification from "../models/Notification.js";
import Product from "../models/Product.js";
import Promo from "../models/Promo.js";
import User from "../models/User.js";
import { isFlashSaleCurrentlyActive } from "./productController.js";

const money = (value) => Number(Number(value).toFixed(2));
const shippingFor = (subtotal) => (subtotal >= 75 || subtotal === 0 ? 0 : 7.99);
const taxFor = (subtotal) => money(subtotal * 0.08);
const promoIsValid = (promo, now = new Date()) =>
  Boolean(
    promo?.isActive &&
      promo.usedCount < promo.maxUses &&
      new Date(promo.startsAt) <= now &&
      new Date(promo.endsAt) >= now,
  );
const promoDiscountFor = (promo, subtotal, shipping) => {
  if (promo.discountType === "shipping") return money(Math.min(shipping, subtotal + shipping));
  if (promo.discountType === "flat") return money(Math.min(promo.discountValue, subtotal));
  return money(Math.min((subtotal * promo.discountValue) / 100, subtotal));
};

const RETURN_STATUSES = [
  "none",
  "requested",
  "approved",
  "rejected",
  "in_transit",
  "received",
  "refund_initiated",
  "refunded",
  "closed"
];

const canAccessOrder = (order, user) => {
  const orderUserId = order?.user?._id || order?.user;
  return user?.role === "admin" || String(orderUserId) === String(user?.id);
};

const pushReturnEvent = (order, { status, note = "", actor = "system" }) => {
  if (!order.returnRequest) {
    order.returnRequest = {};
  }
  if (!Array.isArray(order.returnRequest.timeline)) {
    order.returnRequest.timeline = [];
  }
  order.returnRequest.timeline.push({
    status,
    note,
    actor,
    at: new Date()
  });
};

export const createOrder = async (req, res) => {
  try {
    const {
      items,
      promoCode,
      paymentMethod,
      paymentDetails
    } = req.body;
    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: "Order items are required" });
    }

    const requestedItems = items.map((item) => ({
      productId: item.productId || item._id,
      variantId: String(item.variantId || ""),
      variantSku: String(item.variantSku || item.sku || ""),
      color: String(item.color || ""),
      colorHex: String(item.colorHex || ""),
      size: String(item.size || ""),
      qty: Number(item.qty || 0),
    }));

    if (
      requestedItems.some(
        (item) =>
          !item.productId ||
          !Number.isInteger(item.qty) ||
          item.qty < 1
      )
    ) {
      return res.status(400).json({ error: "Invalid order items" });
    }

    const products = await Product.find({
      _id: { $in: requestedItems.map((item) => item.productId) }
    });
    const productById = new Map(products.map((product) => [String(product._id), product]));
    if (productById.size !== new Set(requestedItems.map((item) => String(item.productId))).size) {
      return res.status(404).json({ error: "One or more products are no longer available" });
    }

    const normalizedItems = [];
    const stockRequests = new Map();
    for (const item of requestedItems) {
      const product = productById.get(String(item.productId));
      let variant = null;
      if (item.variantId) {
        variant = product.variants.id(item.variantId);
        if (!variant) return res.status(422).json({ error: "Selected product variant is no longer available" });
      }
      if (item.size && product.sizes.length > 0 && !product.sizes.includes(item.size)) {
        return res.status(422).json({ error: "Selected product size is no longer available" });
      }
      const available = variant ? variant.stock : product.stock;
      const key = `${product._id}:${variant?._id || ""}`;
      stockRequests.set(key, (stockRequests.get(key) || 0) + item.qty);
      if (stockRequests.get(key) > available) {
        return res.status(409).json({ error: `Insufficient stock for ${product.name}` });
      }
      const price = isFlashSaleCurrentlyActive(product) ? product.flashSalePrice : product.price;
      normalizedItems.push({
        productId: product._id,
        variantId: variant ? String(variant._id) : "",
        variantSku: variant?.sku || "",
        color: variant?.color || "",
        colorHex: variant?.colorHex || "",
        size: item.size,
        name: product.name,
        price: money(price),
        qty: item.qty,
        image: variant?.images?.[0] || product.image || ""
      });
    }

    const method = String(paymentMethod || "").toLowerCase();
    if (!["card", "cod", "ewallet"].includes(method)) {
      return res
        .status(400)
        .json({ error: "Payment method must be card, cod, or ewallet" });
    }

    let paymentReference = "";
    let paymentStatus = "pending";
    const paymentMeta = {};

    // Card and e-wallet payments are NOT backed by a payment provider. They
    // are accepted only as explicit DEMO/TEST payments (paymentDetails.isDummy
    // === true) so they can never be mistaken for a real charge. Real card
    // details are rejected outright. The order is always created "pending";
    // it becomes "paid" only through the admin-only reconciliation endpoint.
    if (method === "card") {
      const isDummy = paymentDetails?.isDummy === true;
      if (!isDummy) {
        return res.status(400).json({
          error: "Card payments are not available yet. Please use Cash on Delivery."
        });
      }

      const cardNumberRaw = String(paymentDetails?.cardNumber || "").replace(/\s+/g, "");
      const cardHolder = String(paymentDetails?.cardHolder || "").trim();
      const expiry = String(paymentDetails?.expiry || "").trim();
      const cvv = String(paymentDetails?.cvv || "").trim();
      if (!/^\d{16}$/.test(cardNumberRaw)) {
        return res.status(400).json({ error: "Demo card number must be 16 digits" });
      }
      if (!cardHolder) {
        return res.status(400).json({ error: "Demo card holder name is required" });
      }
      if (!/^\d{2}\/\d{2}$/.test(expiry)) {
        return res.status(400).json({ error: "Demo expiry must be in MM/YY format" });
      }
      if (!/^\d{3,4}$/.test(cvv)) {
        return res.status(400).json({ error: "Demo CVV must be 3 or 4 digits" });
      }
      paymentReference = `DEMO-CARD-${Date.now()}`;
      paymentMeta.cardLast4 = cardNumberRaw.slice(-4);
      paymentMeta.isDemo = true;
    }

    if (method === "ewallet") {
      const isDummy = paymentDetails?.isDummy === true;
      if (!isDummy) {
        return res.status(400).json({
          error: "E-wallet payments are not available yet. Please use Cash on Delivery."
        });
      }

      const walletProvider = String(paymentDetails?.walletProvider || "").trim();
      const walletId = String(paymentDetails?.walletId || "").trim();
      if (!walletProvider || !walletId) {
        return res.status(400).json({ error: "Wallet provider and wallet ID are required" });
      }
      paymentReference = `DEMO-WALLET-${Date.now()}`;
      paymentMeta.walletProvider = walletProvider;
      paymentMeta.walletId = walletId;
      paymentMeta.isDemo = true;
    }

    if (method === "cod") {
      paymentStatus = "pending";
      paymentReference = "COD";
    }

    const subtotal = money(normalizedItems.reduce((sum, item) => sum + item.price * item.qty, 0));
    const shipping = shippingFor(subtotal);
    const tax = taxFor(subtotal);
    const code = String(promoCode || "").toUpperCase().trim();
    let promo = null;
    let discount = 0;
    if (code) {
      promo = await Promo.findOne({ code });
      if (!promo || !promoIsValid(promo)) {
        return res.status(400).json({ error: "Promo code is no longer valid" });
      }
      discount = promoDiscountFor(promo, subtotal, shipping);
    }
    const total = money(Math.max(0, subtotal + tax + shipping - discount));

    // Reserve stock with conditional updates so concurrent checkouts cannot
    // oversell. Nothing is decremented until validation/payment are complete.
    const reserved = [];
    for (const [key, qty] of stockRequests) {
      const [productId, variantId] = key.split(":");
      const update = variantId
        ? await Product.findOneAndUpdate(
            { _id: productId, variants: { $elemMatch: { _id: variantId, stock: { $gte: qty } } } },
            { $inc: { "variants.$.stock": -qty } },
            { new: false },
          )
        : await Product.findOneAndUpdate(
            { _id: productId, stock: { $gte: qty } },
            { $inc: { stock: -qty } },
            { new: false },
          );
      if (!update) {
        for (const entry of reserved) {
          const path = entry.variantId ? "variants.$.stock" : "stock";
          const filter = entry.variantId
            ? { _id: entry.productId, "variants._id": entry.variantId }
            : { _id: entry.productId };
          await Product.updateOne(filter, { $inc: { [path]: entry.qty } });
        }
        return res.status(409).json({ error: "Insufficient stock for one or more items" });
      }
      reserved.push({ productId, variantId, qty });
    }

    if (promo) {
      const redeemed = await Promo.updateOne(
        { _id: promo._id, isActive: true, $expr: { $lt: ["$usedCount", "$maxUses"] } },
        [
          { $set: { usedCount: { $add: ["$usedCount", 1] } } },
          { $set: { isActive: { $lt: ["$usedCount", "$maxUses"] } } },
        ],
      );
      if (redeemed.modifiedCount !== 1) {
        for (const entry of reserved) {
          const path = entry.variantId ? "variants.$.stock" : "stock";
          const filter = entry.variantId ? { _id: entry.productId, "variants._id": entry.variantId } : { _id: entry.productId };
          await Product.updateOne(filter, { $inc: { [path]: entry.qty } });
        }
        return res.status(400).json({ error: "Promo code is no longer valid" });
      }
    }

    let order;
    try {
      const user = await User.findById(req.user.id).select("deliveryAddress contactNumber");
      order = await Order.create({ user: req.user.id, items: normalizedItems, subtotal, tax, shipping, discount, total, promoCode: code, deliveryAddress: user?.deliveryAddress || "", contactNumber: user?.contactNumber || "", paymentMethod: method, paymentStatus, paymentReference, paymentMeta });
    } catch (error) {
      for (const entry of reserved) {
        const path = entry.variantId ? "variants.$.stock" : "stock";
        const filter = entry.variantId ? { _id: entry.productId, "variants._id": entry.variantId } : { _id: entry.productId };
        await Product.updateOne(filter, { $inc: { [path]: entry.qty } });
      }
      if (promo) await Promo.updateOne({ _id: promo._id }, { $inc: { usedCount: -1 } });
      throw error;
    }

await Notification.create({
  userId: req.user.id,
  title: "Order Created",
  body: `Your order #${order._id
    .toString()
    .slice(-6)} has been placed successfully.`,
  type: "order"
});

res.status(201).json(order);
  } catch {
    res.status(500).json({ error: "Failed to create order" });
  }
};

export const listOrdersAdmin = async (_req, res) => {
  try {
    const orders = await Order.find()
      .populate("user", "name email avatar contactNumber deliveryAddress")
      .sort({ createdAt: -1 });
    res.json(orders);
  } catch {
    res.status(500).json({ error: "Failed to load orders" });
  }
};

export const listMyOrders = async (req, res) => {
  try {
    const orders = await Order.find({ user: req.user.id }).sort({ createdAt: -1 });
    res.json(orders);
  } catch {
    res.status(500).json({ error: "Failed to load your orders" });
  }
};

export const updateOrderStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const allowedStatuses = ["placed", "processing", "shipped", "delivered"];
    const nextStatus = String(req.body?.status || "").toLowerCase();

    if (!allowedStatuses.includes(nextStatus)) {
      return res.status(400).json({ error: "Invalid order status" });
    }

    const order = await Order.findById(id);
    if (!order) {
      return res.status(404).json({ error: "Order not found" });
    }

   order.status = nextStatus;

await order.save();

await Notification.create({
  userId: order.user,
  title: "Order Status Updated",
  body: `Your order #${order._id
    .toString()
    .slice(-6)} is now ${nextStatus}.`,
  type: "order"
});

res.json({
  message: "Order status updated",
  order
});
  } catch {
    res.status(500).json({ error: "Failed to update order status" });
  }
};

export const updateOrderPaymentStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const allowedStatuses = ["pending", "paid", "refunded"];
    const nextStatus = String(req.body?.paymentStatus || "").toLowerCase();

    if (!allowedStatuses.includes(nextStatus)) {
      return res.status(400).json({ error: "Invalid payment status" });
    }

    const order = await Order.findById(id);
    if (!order) {
      return res.status(404).json({ error: "Order not found" });
    }

    order.paymentStatus = nextStatus;
    await order.save();
    await Notification.create({
  userId: order.user,
  title: "Payment Status Updated",
  body: `Payment for order #${order._id
    .toString()
    .slice(-6)} is now ${nextStatus}.`,
  type: "payment"
});
    res.json({ message: "Payment status updated", order });
  } catch {
    res.status(500).json({ error: "Failed to update payment status" });
  }
};

export const requestOrderReturn = async (req, res) => {
  try {
    const { id } = req.params;
    const reason = String(req.body?.reason || "").trim();
    const customerNote = String(req.body?.customerNote || "").trim();
    const rawEvidence = Array.isArray(req.body?.evidence) ? req.body.evidence : [];
    if (!reason) {
      return res.status(400).json({ error: "Return reason is required" });
    }
    if (rawEvidence.length > 4) {
      return res.status(400).json({ error: "You can upload up to 4 proof files" });
    }
    const evidence = rawEvidence
      .map((item) => ({
        type: String(item?.type || "").toLowerCase(),
        url: String(item?.url || "").trim(),
        name: String(item?.name || "").trim()
      }))
      .filter((item) => item.url);
    const hasInvalidEvidence = evidence.some(
      (item) =>
        !["image", "video"].includes(item.type) ||
        !item.url.startsWith("data:") ||
        item.url.length > 5_000_000
    );
    if (hasInvalidEvidence) {
      return res.status(400).json({ error: "Invalid proof file format" });
    }

    const order = await Order.findById(id);
    if (!order) {
      return res.status(404).json({ error: "Order not found" });
    }
    if (!canAccessOrder(order, req.user) || req.user?.role === "admin") {
      return res.status(403).json({ error: "Not authorized for this order" });
    }
    if (String(order.status || "").toLowerCase() !== "delivered") {
      return res.status(400).json({ error: "Return can be requested only after delivery" });
    }

    const currentStatus = String(order.returnRequest?.status || "none");
    if (!["none", "rejected"].includes(currentStatus)) {
      return res.status(400).json({ error: "Return request already in progress" });
    }

    order.returnRequest.status = "requested";
    order.returnRequest.reason = reason;
    order.returnRequest.customerNote = customerNote;
    order.returnRequest.evidence = evidence;
    order.returnRequest.adminNote = "";
    order.returnRequest.requestedAt = new Date();
    order.returnRequest.reviewedAt = null;
    order.returnRequest.reviewedBy = null;
    pushReturnEvent(order, {
      status: "requested",
      note: customerNote || reason,
      actor: "user"
    });

    await order.save();
    res.json({ message: "Return request submitted", order });
  } catch {
    res.status(500).json({ error: "Failed to submit return request" });
  }
};

export const reviewOrderReturn = async (req, res) => {
  try {
    const { id } = req.params;
    const action = String(req.body?.action || "").toLowerCase();
    const adminNote = String(req.body?.adminNote || "").trim();
    if (!["approve", "reject"].includes(action)) {
      return res.status(400).json({ error: "Action must be approve or reject" });
    }

    const order = await Order.findById(id);
    if (!order) {
      return res.status(404).json({ error: "Order not found" });
    }

    const currentStatus = String(order.returnRequest?.status || "none");
    if (currentStatus !== "requested") {
      return res.status(400).json({ error: "No pending return request to review" });
    }

    if (action === "reject") {
      order.returnRequest.status = "rejected";
      order.returnRequest.adminNote = adminNote;
      order.returnRequest.reviewedAt = new Date();
      order.returnRequest.reviewedBy = req.user.id;
      pushReturnEvent(order, {
        status: "rejected",
        note: adminNote || "Return request rejected",
        actor: "admin"
      });
     await Notification.create({
  userId: order.user,
  title: "Return Rejected",
  body: `Your return request for order #${order._id
    .toString()
    .slice(-6)} was rejected.`,
  type: "order"
});

await order.save();

return res.json({
  message: "Return request rejected",
  order
});
    }

    order.returnRequest.status = "approved";
    order.returnRequest.adminNote = adminNote;
    order.returnRequest.reviewedAt = new Date();
    order.returnRequest.reviewedBy = req.user.id;
    pushReturnEvent(order, {
      status: "approved",
      note: adminNote || "Return request approved",
      actor: "admin"
    });

    if (order.paymentStatus === "paid") {
      order.returnRequest.status = "refund_initiated";
      order.returnRequest.refundTriggeredAt = new Date();
      pushReturnEvent(order, {
        status: "refund_initiated",
        note: "Auto refund trigger executed",
        actor: "system"
      });
      order.paymentStatus = "refunded";
      await Notification.create({
  userId: order.user,
  title: "Refund Processed",
  body: `Refund for order #${order._id
    .toString()
    .slice(-6)} has been processed successfully.`,
  type: "payment"
});
      order.returnRequest.status = "refunded";
      pushReturnEvent(order, {
        status: "refunded",
        note: "Payment refunded successfully",
        actor: "system"
      });
    }
await Notification.create({
  userId: order.user,
  title: "Return Approved",
  body: `Your return request for order #${order._id
    .toString()
    .slice(-6)} has been approved.`,
  type: "order"
});
    await order.save();
    return res.json({
      message:
        order.paymentStatus === "refunded"
          ? "Return approved and refund triggered"
          : "Return approved",
      order
    });
  } catch {
    res.status(500).json({ error: "Failed to review return request" });
  }
};

export const updateOrderReturnTracking = async (req, res) => {
  try {
    const { id } = req.params;
    const nextStatus = String(req.body?.status || "").toLowerCase();
    const note = String(req.body?.note || "").trim();
    const trackingCode = String(req.body?.trackingCode || "").trim();
    const carrier = String(req.body?.carrier || "").trim();

    if (!RETURN_STATUSES.includes(nextStatus) || nextStatus === "none") {
      return res.status(400).json({ error: "Invalid return tracking status" });
    }

    const order = await Order.findById(id);
    if (!order) {
      return res.status(404).json({ error: "Order not found" });
    }

    if (trackingCode) {
      order.returnRequest.trackingCode = trackingCode;
    }
    if (carrier) {
      order.returnRequest.carrier = carrier;
    }
    order.returnRequest.status = nextStatus;
    pushReturnEvent(order, {
      status: nextStatus,
      note: note || "Return tracking updated",
      actor: "admin"
    });

    if (nextStatus === "refunded" && order.paymentStatus === "paid") {
      order.paymentStatus = "refunded";
      order.returnRequest.refundTriggeredAt = new Date();
    }

    await order.save();
    res.json({ message: "Return tracking updated", order });
  } catch {
    res.status(500).json({ error: "Failed to update return tracking" });
  }
};

export const getOrderReturnTracking = async (req, res) => {
  try {
    const { id } = req.params;
    const order = await Order.findById(id).populate(
      "user",
      "name email avatar contactNumber deliveryAddress"
    );
    if (!order) {
      return res.status(404).json({ error: "Order not found" });
    }
    if (!canAccessOrder(order, req.user)) {
      return res.status(403).json({ error: "Not authorized for this order" });
    }

    res.json({
      orderId: order._id,
      paymentStatus: order.paymentStatus,
      orderStatus: order.status,
      returnRequest: order.returnRequest || { status: "none", timeline: [] }
    });
  } catch {
    res.status(500).json({ error: "Failed to load return tracking" });
  }
};
