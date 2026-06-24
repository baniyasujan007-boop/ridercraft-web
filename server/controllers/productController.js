import Product from "../models/Product.js";
import Order from "../models/Order.js";
import axios from "axios";
import * as cheerio from "cheerio";

const COLOR_HEX_PATTERN = /^#([0-9a-f]{3}|[0-9a-f]{6})$/i;

export const isFlashSaleCurrentlyActive = (product, now = new Date()) =>
  Boolean(
    product?.isFlashSale === true &&
      Number(product?.flashSalePrice) > 0 &&
      (!product?.flashSaleStartsAt ||
        new Date(product.flashSaleStartsAt).getTime() <= now.getTime()) &&
      product?.flashSaleEndsAt &&
      new Date(product.flashSaleEndsAt).getTime() > now.getTime(),
  );

export const isFeaturedCurrentlyActive = (product, now = new Date()) =>
  Boolean(
    product?.isFeatured === true &&
      (!product?.featuredStartDate ||
        new Date(product.featuredStartDate).getTime() <= now.getTime()) &&
      product?.featuredEndDate &&
      new Date(product.featuredEndDate).getTime() > now.getTime(),
  );

export const productToClient = (product, now = new Date()) => {
  const plain =
    typeof product?.toObject === "function"
      ? product.toObject({ virtuals: true })
      : { ...product };
  const flashSaleActive = isFlashSaleCurrentlyActive(plain, now);
  const featuredActive = isFeaturedCurrentlyActive(plain, now);
  const price = Number(plain.price || 0);
  const flashSalePrice = Number(plain.flashSalePrice || 0);
  const displayPrice = flashSaleActive ? flashSalePrice : price;

  return {
    ...plain,
    isFlashSale: plain.isFlashSale === true,
    isFlashSaleActive: flashSaleActive,
    isFeatured: plain.isFeatured === true,
    isFeaturedActive: featuredActive,
    originalPrice: price,
    displayPrice,
    discountPercent:
      flashSaleActive && price > 0
        ? Math.round(((price - flashSalePrice) / price) * 100)
        : 0,
  };
};

const normalizeStringArray = (value) =>
  Array.isArray(value)
    ? value.map((entry) => String(entry || "").trim()).filter(Boolean)
    : [];

const normalizeVariants = (variants) => {
  if (!Array.isArray(variants)) return [];

  return variants
    .map((variant) => {
      const color = String(variant?.color || "").trim();
      const colorHex = String(variant?.colorHex || "").trim() || "#111827";
      const stock = Number(variant?.stock ?? 0);
      return {
        color,
        colorHex,
        images: normalizeStringArray(variant?.images),
        stock: Number.isInteger(stock) && stock >= 0 ? stock : 0,
        sku: String(variant?.sku || "").trim(),
      };
    })
    .filter((variant) => variant.color);
};

const validateVariants = (variants) => {
  const invalidHex = variants.find(
    (variant) => variant.colorHex && !COLOR_HEX_PATTERN.test(variant.colorHex),
  );
  if (invalidHex) {
    return "Variant color hex must be a valid hex color, e.g. #2563eb";
  }

  const invalidImage = variants
    .flatMap((variant) => variant.images)
    .find(
      (image) =>
        image &&
        !/^(https?:)?\/\//i.test(image) &&
        !/^data:image\//i.test(image),
    );
  if (invalidImage) {
    return "Variant images must be valid URLs or uploaded image data";
  }

  return "";
};

const normalizeDate = (value) => {
  if (!value) return null;
  const date = new Date(value);
  return Number.isFinite(date.getTime()) ? date : null;
};

const normalizeFlashSaleFields = ({
  isFlashSale,
  flashSalePrice,
  flashSaleStartsAt,
  flashSaleEndsAt,
}) => {
  const enabled = Boolean(isFlashSale);
  const salePrice =
    flashSalePrice === undefined || flashSalePrice === null || flashSalePrice === ""
      ? null
      : Number(flashSalePrice);

  return {
    isFlashSale: enabled,
    flashSalePrice: Number.isFinite(salePrice) && salePrice >= 0 ? salePrice : null,
    flashSaleStartsAt: normalizeDate(flashSaleStartsAt),
    flashSaleEndsAt: normalizeDate(flashSaleEndsAt),
  };
};

const normalizeFeaturedFields = ({
  isFeatured,
  featuredStartDate,
  featuredEndDate,
}) => ({
  isFeatured: Boolean(isFeatured),
  featuredStartDate: normalizeDate(featuredStartDate),
  featuredEndDate: normalizeDate(featuredEndDate),
});

export const listProducts = async (_req, res) => {
  try {
    const products = await Product.find().sort({ createdAt: -1 });
    res.json(products.map((product) => productToClient(product)));
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
    res.json(productToClient(product));
  } catch {
    res.status(500).json({ error: "Failed to load product" });
  }
};

export const createProduct = async (req, res) => {
  try {
    const {
      name,
      price,
      tag,
      brand,
      colorFamily,
      description,
      sizes,
      colors,
      stock,
      image,
      variants,
      isFeatured,
      featuredStartDate,
      featuredEndDate,
      isFlashSale,
      flashSalePrice,
      flashSaleStartsAt,
      flashSaleEndsAt,
    } = req.body;
    if (!name || price === undefined || price === null) {
      return res.status(400).json({ error: "Name and price are required" });
    }

    const numericPrice = Number(price);
    if (!Number.isFinite(numericPrice) || numericPrice < 0) {
      return res
        .status(400)
        .json({ error: "Price must be a valid non-negative number" });
    }

    const normalizedVariants = normalizeVariants(variants);
    const variantError = validateVariants(normalizedVariants);
    if (variantError) {
      return res.status(400).json({ error: variantError });
    }

    const flashSale = normalizeFlashSaleFields({
      isFlashSale,
      flashSalePrice,
      flashSaleStartsAt,
      flashSaleEndsAt,
    });
    if (flashSale.isFlashSale) {
      if (!flashSale.flashSalePrice || flashSale.flashSalePrice >= numericPrice) {
        return res
          .status(400)
          .json({ error: "Flash sale price must be greater than 0 and lower than price" });
      }
      if (!flashSale.flashSaleEndsAt || flashSale.flashSaleEndsAt <= new Date()) {
        return res
          .status(400)
          .json({ error: "Flash sale end date must be in the future" });
      }
      if (
        flashSale.flashSaleStartsAt &&
        flashSale.flashSaleStartsAt >= flashSale.flashSaleEndsAt
      ) {
        return res
          .status(400)
          .json({ error: "Flash sale end date must be after start date" });
      }
    }

    const featured = normalizeFeaturedFields({
      isFeatured,
      featuredStartDate,
      featuredEndDate,
    });
    if (featured.isFeatured) {
      if (!featured.featuredEndDate || featured.featuredEndDate <= new Date()) {
        return res
          .status(400)
          .json({ error: "Featured end date must be in the future" });
      }
      if (
        featured.featuredStartDate &&
        featured.featuredStartDate >= featured.featuredEndDate
      ) {
        return res
          .status(400)
          .json({ error: "Featured end date must be after start date" });
      }
    }

    const fallbackStock =
      Number.isInteger(Number(stock)) && Number(stock) >= 0
        ? Number(stock)
        : 25;

    const product = await Product.create({
      name: String(name).trim(),
      price: numericPrice,
      tag: tag ? String(tag).trim() : "General",
      brand: brand ? String(brand).trim() : "Generic",
      colorFamily: colorFamily ? String(colorFamily).trim() : "Neutral",
      description: description || "",
      sizes: normalizeStringArray(sizes),
      colors: normalizedVariants.length
        ? normalizedVariants.map((variant) => variant.color)
        : normalizeStringArray(colors),
      variants: normalizedVariants,
      stock: normalizedVariants.length
        ? normalizedVariants.reduce((sum, variant) => sum + variant.stock, 0)
        : fallbackStock,
      image:
        normalizedVariants.find((variant) => variant.images.length)?.images[0] ||
        (image ? String(image) : ""),
      isFeatured: featured.isFeatured,
      featuredStartDate: featured.featuredStartDate,
      featuredEndDate: featured.featuredEndDate,
      isFlashSale: flashSale.isFlashSale,
      flashSalePrice: flashSale.flashSalePrice,
      flashSaleStartsAt: flashSale.flashSaleStartsAt,
      flashSaleEndsAt: flashSale.flashSaleEndsAt,
    });
    res.status(201).json(productToClient(product));
  } catch (error) {
    console.error("Create product failed:", error);
    res.status(500).json({ error: "Failed to create product" });
  }
};

export const updateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      price,
      tag,
      brand,
      colorFamily,
      sizes,
      colors,
      stock,
      image,
      variants,
      isFeatured,
      featuredStartDate,
      featuredEndDate,
      isFlashSale,
      flashSalePrice,
      flashSaleStartsAt,
      flashSaleEndsAt,
    } = req.body;
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
        return res
          .status(400)
          .json({ error: "Price must be a valid non-negative number" });
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
    if (sizes !== undefined) {
      product.sizes = Array.isArray(sizes) ? sizes : [];
    }

    if (colors !== undefined) {
      product.colors = normalizeStringArray(colors);
    }

    if (variants !== undefined) {
      const normalizedVariants = normalizeVariants(variants);
      const variantError = validateVariants(normalizedVariants);
      if (variantError) {
        return res.status(400).json({ error: variantError });
      }
      product.variants = normalizedVariants;
      if (normalizedVariants.length) {
        product.colors = normalizedVariants.map((variant) => variant.color);
        product.stock = normalizedVariants.reduce(
          (sum, variant) => sum + variant.stock,
          0,
        );
        const firstVariantImage = normalizedVariants.find(
          (variant) => variant.images.length,
        )?.images[0];
        if (firstVariantImage) product.image = firstVariantImage;
      }
    }

    if (stock !== undefined && variants === undefined) {
      const parsedStock = Number(stock);
      if (!Number.isInteger(parsedStock) || parsedStock < 0) {
        return res
          .status(400)
          .json({ error: "Stock must be a non-negative integer" });
      }
      product.stock = parsedStock;
    }

    if (image !== undefined) {
      product.image = String(image);
    }

    if (
      isFlashSale !== undefined ||
      flashSalePrice !== undefined ||
      flashSaleStartsAt !== undefined ||
      flashSaleEndsAt !== undefined
    ) {
      const flashSale = normalizeFlashSaleFields({
        isFlashSale:
          isFlashSale !== undefined ? isFlashSale : product.isFlashSale,
        flashSalePrice:
          flashSalePrice !== undefined
            ? flashSalePrice
            : product.flashSalePrice,
        flashSaleStartsAt:
          flashSaleStartsAt !== undefined
            ? flashSaleStartsAt
            : product.flashSaleStartsAt,
        flashSaleEndsAt:
          flashSaleEndsAt !== undefined
            ? flashSaleEndsAt
            : product.flashSaleEndsAt,
      });
      if (flashSale.isFlashSale) {
        if (
          !flashSale.flashSalePrice ||
          flashSale.flashSalePrice >= Number(product.price || 0)
        ) {
          return res.status(400).json({
            error: "Flash sale price must be greater than 0 and lower than price",
          });
        }
        if (!flashSale.flashSaleEndsAt || flashSale.flashSaleEndsAt <= new Date()) {
          return res
            .status(400)
            .json({ error: "Flash sale end date must be in the future" });
        }
        if (
          flashSale.flashSaleStartsAt &&
          flashSale.flashSaleStartsAt >= flashSale.flashSaleEndsAt
        ) {
          return res
            .status(400)
            .json({ error: "Flash sale end date must be after start date" });
        }
      }
      product.isFlashSale = flashSale.isFlashSale;
      product.flashSalePrice = flashSale.flashSalePrice;
      product.flashSaleStartsAt = flashSale.flashSaleStartsAt;
      product.flashSaleEndsAt = flashSale.flashSaleEndsAt;
    }

    if (
      isFeatured !== undefined ||
      featuredStartDate !== undefined ||
      featuredEndDate !== undefined
    ) {
      const featured = normalizeFeaturedFields({
        isFeatured:
          isFeatured !== undefined ? isFeatured : product.isFeatured,
        featuredStartDate:
          featuredStartDate !== undefined
            ? featuredStartDate
            : product.featuredStartDate,
        featuredEndDate:
          featuredEndDate !== undefined ? featuredEndDate : product.featuredEndDate,
      });
      if (featured.isFeatured) {
        if (!featured.featuredEndDate || featured.featuredEndDate <= new Date()) {
          return res
            .status(400)
            .json({ error: "Featured end date must be in the future" });
        }
        if (
          featured.featuredStartDate &&
          featured.featuredStartDate >= featured.featuredEndDate
        ) {
          return res
            .status(400)
            .json({ error: "Featured end date must be after start date" });
        }
      }
      product.isFeatured = featured.isFeatured;
      product.featuredStartDate = featured.featuredStartDate;
      product.featuredEndDate = featured.featuredEndDate;
    }

    await product.save();
    res.json(productToClient(product));
  } catch (error) {
    console.error("Update product failed:", error);
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
      return res
        .status(400)
        .json({ error: "Rating must be in 0.5 steps from 0.5 to 5" });
    }
    if (comment.length > 300) {
      return res
        .status(400)
        .json({ error: "Comment must be 300 characters or less" });
    }

    const product = await Product.findById(id);
    if (!product) {
      return res.status(404).json({ error: "Product not found" });
    }

    const userId = String(req.user.id);
    const purchasedOrder = await Order.findOne({
      user: req.user.id,
      "items.productId": id,
    }).select("_id");
    if (!purchasedOrder) {
      return res
        .status(403)
        .json({ error: "You can rate this product after purchase" });
    }

    const existing = product.ratings.find(
      (entry) => String(entry.user) === userId,
    );

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
      product,
    });
  } catch {
    res.status(500).json({ error: "Failed to save rating" });
  }
};

export const fetchProductFromUrl = async (req, res) => {
  try {
    const { url } = req.body;
    if (url.includes("/cdn/") || /\.(jpg|jpeg|png|webp|gif)$/i.test(url)) {
      return res.status(400).json({
        error: "Please enter a product page URL, not an image URL",
      });
    }
    const response = await axios.get(url);
    const $ = cheerio.load(response.data);
    let price = "";

    $('script[type="application/ld+json"]').each((_, el) => {
      try {
        const json = JSON.parse($(el).html());

        if (json.offers?.price) {
          price = String(json.offers.price);
        }

        if (Array.isArray(json.offers) && json.offers[0]?.price) {
          price = String(json.offers[0].price);
        }
      } catch {}
    });

    const name =
      $('meta[property="og:title"]').attr("content") || $("title").text();

    const image = $('meta[property="og:image"]').attr("content") || "";

    const brand = name?.split(" ")[0] || "Generic";
    const description =
      $('meta[property="og:description"]').attr("content") || "";

    let sizes = [];
    let colors = [];

    $("option").each((_, el) => {
      const text = $(el).text().trim();

      if (
        ["XS", "S", "M", "L", "XL", "XXL"].includes(text) ||
        /^\d+$/.test(text)
      ) {
        sizes.push(text);
      }
    });

    const colorWords = [
      "Black",
      "Blue",
      "Red",
      "White",
      "Grey",
      "Gray",
      "Green",
      "Orange",
      "Yellow",
    ];

    colorWords.forEach((color) => {
      if (response.data.includes(color)) {
        colors.push(color);
      }
    });

    sizes = [...new Set(sizes)];
    colors = [...new Set(colors)];

    res.json({
      name,
      brand,
      image,
      description,
      sizes,
      colors,
      price: price ? Number(price) : 0,
    });
  } catch (error) {
    console.error("FETCH ERROR:", error.message);

    res.status(500).json({
      error: error.message,
    });
  }
};
