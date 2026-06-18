import mongoose from "mongoose";

const SECTION_KEYS = [
  "trending",
  "new-arrivals",
  "best-sellers",
  "deals-of-day",
  "top-electronics",
  "top-fashion"
];

const featuredSectionSchema = new mongoose.Schema(
  {
    key: { type: String, required: true, unique: true, enum: SECTION_KEYS },
    title: { type: String, required: true, trim: true, maxlength: 80 },
    products: [{ type: mongoose.Schema.Types.ObjectId, ref: "Product" }],
    sortOrder: { type: Number, default: 0 },
    countdownStartsAt: { type: Date, default: null },
    countdownEndsAt: { type: Date, default: null },
    isActive: { type: Boolean, default: true }
  },
  { timestamps: true }
);

export { SECTION_KEYS };
export default mongoose.model("FeaturedSection", featuredSectionSchema);
