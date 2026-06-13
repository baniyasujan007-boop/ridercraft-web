import mongoose from "mongoose";

const heroOfferSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true, maxlength: 120 },
    offerType: { type: String, enum: ["tag", "flash"], default: "tag" },
    startsAt: { type: Date, required: true, default: Date.now },
    endsAt: { type: Date, default: null },
    priority: { type: Number, default: 1 },
    ctaQuery: { type: String, default: "", trim: true, maxlength: 80 },
    isActive: { type: Boolean, default: true }
  },
  { timestamps: true }
);

export default mongoose.model("HeroOffer", heroOfferSchema);
