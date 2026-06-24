import mongoose from "mongoose";
import Product from "../models/Product.js";
import Wishlist from "../models/Wishlist.js";
import { productToClient } from "./productController.js";

const serializeWishlistEntry = (entry, now = new Date()) => {
  const product = entry.productId;
  return {
    _id: entry._id,
    userId: entry.userId,
    productId: product?._id || entry.productId,
    createdAt: entry.createdAt,
    product: product && typeof product === "object" ? productToClient(product, now) : null,
  };
};

export const listWishlist = async (req, res) => {
  try {
    const now = new Date();
    const entries = await Wishlist.find({ userId: req.user.id })
      .populate("productId")
      .sort({ createdAt: -1 });

    res.json(
      entries
        .map((entry) => serializeWishlistEntry(entry, now))
        .filter((entry) => entry.product),
    );
  } catch (error) {
    console.error("List wishlist failed:", error);
    res.status(500).json({ error: "Failed to load wishlist" });
  }
};

export const addWishlistItem = async (req, res) => {
  try {
    const productId = req.body?.productId || req.body?.id;
    if (!mongoose.isValidObjectId(productId)) {
      return res.status(400).json({ error: "Valid productId is required" });
    }

    const product = await Product.findById(productId);
    if (!product) {
      return res.status(404).json({ error: "Product not found" });
    }

    let entry;
    try {
      entry = await Wishlist.findOneAndUpdate(
        { userId: req.user.id, productId },
        {
          $setOnInsert: {
            userId: req.user.id,
            productId,
            createdAt: new Date(),
          },
        },
        { new: true, upsert: true, setDefaultsOnInsert: true },
      ).populate("productId");
    } catch (error) {
      if (error.code !== 11000) throw error;
      entry = await Wishlist.findOne({ userId: req.user.id, productId }).populate(
        "productId",
      );
    }

    res.status(201).json(serializeWishlistEntry(entry));
  } catch (error) {
    console.error("Add wishlist failed:", error);
    res.status(500).json({ error: "Failed to add wishlist item" });
  }
};

export const removeWishlistItem = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({ error: "Valid wishlist or product id is required" });
    }

    const deleted = await Wishlist.findOneAndDelete({
      userId: req.user.id,
      $or: [{ _id: id }, { productId: id }],
    });

    if (!deleted) {
      return res.status(404).json({ error: "Wishlist item not found" });
    }

    res.json({ message: "Wishlist item removed", productId: deleted.productId });
  } catch (error) {
    console.error("Remove wishlist failed:", error);
    res.status(500).json({ error: "Failed to remove wishlist item" });
  }
};
