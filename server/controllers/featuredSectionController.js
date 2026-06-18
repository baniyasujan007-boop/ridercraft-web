import FeaturedSection, { SECTION_KEYS } from "../models/FeaturedSection.js";

const parseCountdownEndsAt = (value) => {
  if (!value) return null;
  const date = new Date(value);
  return Number.isFinite(date.getTime()) ? date : null;
};

export const listPublicFeaturedSections = async (_req, res) => {
  try {
    const sections = await FeaturedSection.find({ isActive: true })
      .populate("products")
      .sort({ sortOrder: 1, createdAt: 1 });
    res.json(sections);
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
    const { key, title, products, sortOrder, countdownEndsAt, isActive } = req.body;
    const nextKey = String(key || "").trim();
    const nextTitle = String(title || "").trim();
    if (!SECTION_KEYS.includes(nextKey)) {
      return res.status(400).json({ error: "Invalid section key" });
    }
    if (!nextTitle) {
      return res.status(400).json({ error: "Section title is required" });
    }

    const section = await FeaturedSection.create({
      key: nextKey,
      title: nextTitle,
      products: Array.isArray(products) ? products : [],
      sortOrder: Number.isFinite(Number(sortOrder)) ? Number(sortOrder) : 0,
      countdownEndsAt: parseCountdownEndsAt(countdownEndsAt),
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

    if (req.body.countdownEndsAt !== undefined) {
      section.countdownEndsAt = parseCountdownEndsAt(req.body.countdownEndsAt);
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
