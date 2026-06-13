import mongoose from "mongoose";

const orderItemSchema = new mongoose.Schema(
  {
    productId: { type: mongoose.Schema.Types.ObjectId, ref: "Product", required: true },
    name: { type: String, required: true },
    price: { type: Number, required: true, min: 0 },
    qty: { type: Number, required: true, min: 1 },
    image: { type: String, default: "" }
  },
  { _id: false }
);

const orderSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    items: { type: [orderItemSchema], default: [] },
    subtotal: { type: Number, required: true, min: 0 },
    tax: { type: Number, required: true, min: 0 },
    shipping: { type: Number, required: true, min: 0 },
    discount: { type: Number, default: 0, min: 0 },
    total: { type: Number, required: true, min: 0 },
    promoCode: { type: String, default: "" },
    paymentMethod: {
      type: String,
      enum: ["card", "cod", "ewallet"],
      default: "cod"
    },
    paymentStatus: {
      type: String,
      enum: ["pending", "paid", "refunded"],
      default: "pending"
    },
    paymentReference: { type: String, default: "" },
    paymentMeta: {
      type: {
        cardLast4: { type: String, default: "" },
        walletProvider: { type: String, default: "" },
        walletId: { type: String, default: "" }
      },
      default: () => ({})
    },
    status: {
      type: String,
      enum: ["placed", "processing", "shipped", "delivered"],
      default: "placed"
    },
    returnRequest: {
      type: {
        status: {
          type: String,
          enum: [
            "none",
            "requested",
            "approved",
            "rejected",
            "in_transit",
            "received",
            "refund_initiated",
            "refunded",
            "closed"
          ],
          default: "none"
        },
        reason: { type: String, default: "" },
        customerNote: { type: String, default: "" },
        adminNote: { type: String, default: "" },
        requestedAt: { type: Date, default: null },
        reviewedAt: { type: Date, default: null },
        reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User", default: null },
        refundTriggeredAt: { type: Date, default: null },
        trackingCode: { type: String, default: "" },
        carrier: { type: String, default: "" },
        evidence: {
          type: [
            {
              _id: false,
              type: { type: String, enum: ["image", "video"], required: true },
              url: { type: String, required: true },
              name: { type: String, default: "" }
            }
          ],
          default: []
        },
        timeline: {
          type: [
            {
              _id: false,
              status: { type: String, required: true },
              note: { type: String, default: "" },
              actor: { type: String, enum: ["user", "admin", "system"], default: "system" },
              at: { type: Date, default: Date.now }
            }
          ],
          default: []
        }
      },
      default: () => ({})
    }
  },
  { timestamps: true }
);

export default mongoose.model("Order", orderSchema);
