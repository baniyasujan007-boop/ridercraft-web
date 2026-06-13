import mongoose from "mongoose";

const promoSchema = new mongoose.Schema(
  {
    code: { type: String, required: true, unique: true, uppercase: true, trim: true },
    discountType: {
      type: String,
      enum: ["percent", "flat", "shipping"],
      default: "percent"
    },
    discountValue: { type: Number, required: true, min: 0 },
    maxUses: { type: Number, required: true, min: 1 },
    usedCount: { type: Number, default: 0, min: 0 },
    startsAt: { type: Date, required: true },
    endsAt: { type: Date, required: true },
    isActive: { type: Boolean, default: true }
  },
  { timestamps: true }
);

export default mongoose.model("Promo", promoSchema);
