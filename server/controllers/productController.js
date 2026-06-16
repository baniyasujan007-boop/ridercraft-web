import Product from "../models/Product.js";
import Order from "../models/Order.js";
import axios from "axios";
import * as cheerio from "cheerio";

export const listProducts = async (_req, res) => {
  try {
    const products = await Product.find().sort({ createdAt: -1 });
    res.json(products);
  } catch {
    res.status(500).json({ error: "Failed to load products" });
  }
};

export const getProductById = async (req, res) => {
  try {
    const { id } = req.params;
    const product = await Product.findById(id);
    if (!product) {
      return res.status(404).json({ error: "Product not found" });
    }
    res.json(product);
  } catch {
    res.status(500).json({ error: "Failed to load product" });
  }
};

export const createProduct = async (req, res) => {
  try {
    const { name, price, tag, brand, colorFamily, stock, image } = req.body;
    if (!name || price === undefined || price === null) {
      return res.status(400).json({ error: "Name and price are required" });
    }

    const numericPrice = Number(price);
    if (!Number.isFinite(numericPrice) || numericPrice < 0) {
      return res.status(400).json({ error: "Price must be a valid non-negative number" });
    }

    const product = await Product.create({
      name: String(name).trim(),
      price: numericPrice,
      tag: tag ? String(tag).trim() : "General",
      brand: brand ? String(brand).trim() : "Generic",
      colorFamily: colorFamily ? String(colorFamily).trim() : "Neutral",
      stock:
        Number.isInteger(Number(stock)) && Number(stock) >= 0 ? Number(stock) : 25,
      image: image ? String(image) : ""
    });

    res.status(201).json(product);
  } catch {
    res.status(500).json({ error: "Failed to create product" });
  }
};

export const updateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, price, tag, brand, colorFamily, stock, image } = req.body;
    const product = await Product.findById(id);

    if (!product) {
      return res.status(404).json({ error: "Product not found" });
    }

    if (name !== undefined) {
      const trimmedName = String(name).trim();
      if (!trimmedName) {
        return res.status(400).json({ error: "Product name cannot be empty" });
      }
      product.name = trimmedName;
    }

    if (price !== undefined) {
      const numericPrice = Number(price);
      if (!Number.isFinite(numericPrice) || numericPrice < 0) {
        return res.status(400).json({ error: "Price must be a valid non-negative number" });
      }
      product.price = numericPrice;
    }

    if (tag !== undefined) {
      product.tag = String(tag).trim() || "General";
    }

    if (brand !== undefined) {
      product.brand = String(brand).trim() || "Generic";
    }

    if (colorFamily !== undefined) {
      product.colorFamily = String(colorFamily).trim() || "Neutral";
    }

    if (stock !== undefined) {
      const parsedStock = Number(stock);
      if (!Number.isInteger(parsedStock) || parsedStock < 0) {
        return res.status(400).json({ error: "Stock must be a non-negative integer" });
      }
      product.stock = parsedStock;
    }

    if (image !== undefined) {
      product.image = String(image);
    }

    await product.save();
    res.json(product);
  } catch {
    res.status(500).json({ error: "Failed to update product" });
  }
};

export const deleteProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await Product.findByIdAndDelete(id);
    if (!deleted) {
      return res.status(404).json({ error: "Product not found" });
    }
    res.json({ message: "Product deleted" });
  } catch {
    res.status(500).json({ error: "Failed to delete product" });
  }
};

export const rateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const parsed = Number(req.body?.rating);
    const commentInput = req.body?.comment ?? "";
    const comment = String(commentInput).trim();
    const rating = Number.isFinite(parsed) ? parsed : NaN;
    const hasHalfStep = Number.isInteger(rating * 2);

    if (rating < 0.5 || rating > 5 || !hasHalfStep) {
      return res.status(400).json({ error: "Rating must be in 0.5 steps from 0.5 to 5" });
    }
    if (comment.length > 300) {
      return res.status(400).json({ error: "Comment must be 300 characters or less" });
    }

    const product = await Product.findById(id);
    if (!product) {
      return res.status(404).json({ error: "Product not found" });
    }

    const userId = String(req.user.id);
    const purchasedOrder = await Order.findOne({
      user: req.user.id,
      "items.productId": id
    }).select("_id");
    if (!purchasedOrder) {
      return res.status(403).json({ error: "You can rate this product after purchase" });
    }

    const existing = product.ratings.find((entry) => String(entry.user) === userId);

    if (existing) {
      existing.value = rating;
      existing.comment = comment;
    } else {
      product.ratings.push({ user: req.user.id, value: rating, comment });
    }

    const total = product.ratings.reduce((sum, entry) => sum + entry.value, 0);
    const count = product.ratings.length;
    product.ratingCount = count;
    product.ratingAverage = count ? Number((total / count).toFixed(1)) : 0;

    await product.save();
    res.json({
      message: existing ? "Rating updated" : "Rating added",
      product
    });
  } catch {
    res.status(500).json({ error: "Failed to save rating" });
  }
};
export const fetchProductFromUrl = async (req, res) => {
  try {
    const { url } = req.body;

   const response = await axios.get(url);
const $ = cheerio.load(response.data);
const price =
  $('meta[property="product:price:amount"]').attr("content") ||
  $('meta[property="product:price"]').attr("content") ||
  $('[data-product-price]').first().text().trim() ||
  "";
  
const name =
  $('meta[property="og:title"]').attr("content") ||
  $("title").text();

const image =
  $('meta[property="og:image"]').attr("content") || "";

    const brand = name?.split(" ")[0] || "Generic";

    res.json({
      name,
      brand,
      image,
      price: ""
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: "Failed to fetch product"
    });
  }
};