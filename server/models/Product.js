import mongoose from "mongoose";

const productRatingSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    value: { type: Number, required: true, min: 0.5, max: 5 },
    comment: { type: String, default: "", trim: true, maxlength: 300 },
  },
  { _id: false },
);

const productVariantSchema = new mongoose.Schema(
  {
    color: { type: String, required: true, trim: true },
    colorHex: { type: String, default: "#111827", trim: true },
    images: { type: [String], default: [] },
    stock: { type: Number, default: 0, min: 0 },
    sku: { type: String, default: "", trim: true },
  },
  { _id: true },
);

const productSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    price: { type: Number, required: true, min: 0 },
    tag: { type: String, default: "General", trim: true },
    brand: { type: String, default: "Generic", trim: true },
    colorFamily: { type: String, default: "Neutral", trim: true },
    stock: { type: Number, default: 25, min: 0 },
    image: { type: String, default: "" },
    description: {
      type: String,
      default: "",
    },
    ratings: { type: [productRatingSchema], default: [] },
    ratingAverage: { type: Number, default: 0, min: 0, max: 5 },
    ratingCount: { type: Number, default: 0, min: 0 },
    sizes: {
      type: [String],
      default: [],
    },

    colors: {
      type: [String],
      default: [],
    },
    variants: {
      type: [productVariantSchema],
      default: [],
    },
    isFlashSale: {
      type: Boolean,
      default: false,
    },
    flashSalePrice: {
      type: Number,
      default: null,
      min: 0,
    },

    flashSaleEndsAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true },
);

export default mongoose.model("Product", productSchema);
