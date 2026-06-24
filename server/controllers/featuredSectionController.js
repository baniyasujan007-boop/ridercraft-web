import FeaturedSection, { SECTION_KEYS } from "../models/FeaturedSection.js";
import { productToClient } from "./productController.js";

const parseOptionalDate = (value) => {
  if (!value) return null;
  const date = new Date(value);
  return Number.isFinite(date.getTime()) ? date : null;
};

const hasInvalidCountdownWindow = (startsAt, endsAt) =>
  startsAt && endsAt && startsAt.getTime() > endsAt.getTime();

const featuredSectionToClient = (section, now = new Date()) => {
  const plain =
    typeof section?.toObject === "function"
      ? section.toObject({ virtuals: true })
      : { ...section };
  return {
    ...plain,
    products: Array.isArray(plain.products)
      ? plain.products.map((product) => productToClient(product, now))
      : [],
  };
};

export const listPublicFeaturedSections = async (_req, res) => {
  try {
    const now = new Date();
    const sections = await FeaturedSection.find({ isActive: true })
      .populate("products")
      .sort({ sortOrder: 1, createdAt: 1 });
    res.json(sections.map((section) => featuredSectionToClient(section, now)));
  } catch {
    res.status(500).json({ error: "Failed to load featured sections" });
  }
};

export const listAdminFeaturedSections = async (_req, res) => {
  try {
    const sections = await FeaturedSection.find()
      .populate("products", "name price image tag brand colorFamily")
      .sort({ sortOrder: 1, createdAt: 1 });
    res.json(sections);
  } catch {
    res.status(500).json({ error: "Failed to load featured sections" });
  }
};

export const createFeaturedSection = async (req, res) => {
  try {
    const {
      key,
      title,
      products,
      sortOrder,
      countdownStartsAt,
      countdownEndsAt,
      isActive
    } = req.body;
    const nextKey = String(key || "").trim();
    const nextTitle = String(title || "").trim();
    const nextCountdownStartsAt = parseOptionalDate(countdownStartsAt);
    const nextCountdownEndsAt = parseOptionalDate(countdownEndsAt);
    if (!SECTION_KEYS.includes(nextKey)) {
      return res.status(400).json({ error: "Invalid section key" });
    }
    if (!nextTitle) {
      return res.status(400).json({ error: "Section title is required" });
    }
    if (hasInvalidCountdownWindow(nextCountdownStartsAt, nextCountdownEndsAt)) {
      return res.status(400).json({ error: "Countdown end must be after start" });
    }

    const section = await FeaturedSection.create({
      key: nextKey,
      title: nextTitle,
      products: Array.isArray(products) ? products : [],
      sortOrder: Number.isFinite(Number(sortOrder)) ? Number(sortOrder) : 0,
      countdownStartsAt: nextCountdownStartsAt,
      countdownEndsAt: nextCountdownEndsAt,
      isActive: isActive !== undefined ? Boolean(isActive) : true
    });

    const row = await FeaturedSection.findById(section._id).populate(
      "products",
      "name price image tag brand colorFamily"
    );
    res.status(201).json(row);
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({ error: "Section key already exists" });
    }
    res.status(500).json({ error: "Failed to create featured section" });
  }
};

export const updateFeaturedSection = async (req, res) => {
  try {
    const { id } = req.params;
    const section = await FeaturedSection.findById(id);
    if (!section) return res.status(404).json({ error: "Featured section not found" });

    if (req.body.key !== undefined) {
      const nextKey = String(req.body.key || "").trim();
      if (!SECTION_KEYS.includes(nextKey)) {
        return res.status(400).json({ error: "Invalid section key" });
      }
      section.key = nextKey;
    }

    if (req.body.title !== undefined) {
      const nextTitle = String(req.body.title || "").trim();
      if (!nextTitle) {
        return res.status(400).json({ error: "Section title is required" });
      }
      section.title = nextTitle;
    }

    if (req.body.products !== undefined) {
      section.products = Array.isArray(req.body.products) ? req.body.products : [];
    }

    if (req.body.sortOrder !== undefined) {
      const nextSort = Number(req.body.sortOrder);
      section.sortOrder = Number.isFinite(nextSort) ? nextSort : section.sortOrder;
    }

    const nextCountdownStartsAt =
      req.body.countdownStartsAt !== undefined
        ? parseOptionalDate(req.body.countdownStartsAt)
        : section.countdownStartsAt;
    const nextCountdownEndsAt =
      req.body.countdownEndsAt !== undefined
        ? parseOptionalDate(req.body.countdownEndsAt)
        : section.countdownEndsAt;

    if (hasInvalidCountdownWindow(nextCountdownStartsAt, nextCountdownEndsAt)) {
      return res.status(400).json({ error: "Countdown end must be after start" });
    }

    if (req.body.countdownStartsAt !== undefined) {
      section.countdownStartsAt = nextCountdownStartsAt;
    }

    if (req.body.countdownEndsAt !== undefined) {
      section.countdownEndsAt = nextCountdownEndsAt;
    }

    if (req.body.isActive !== undefined) {
      section.isActive = Boolean(req.body.isActive);
    }

    await section.save();

    const row = await FeaturedSection.findById(section._id).populate(
      "products",
      "name price image tag brand colorFamily"
    );
    res.json(row);
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({ error: "Section key already exists" });
    }
    res.status(500).json({ error: "Failed to update featured section" });
  }
};

export const deleteFeaturedSection = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await FeaturedSection.findByIdAndDelete(id);
    if (!deleted) return res.status(404).json({ error: "Featured section not found" });
    res.json({ message: "Featured section deleted" });
  } catch {
    res.status(500).json({ error: "Failed to delete featured section" });
  }
};
