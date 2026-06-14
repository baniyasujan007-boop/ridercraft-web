import Promo from "../models/Promo.js";

function computeDiscount(promo, subtotal, shipping = 0) {
  if (promo.discountType === "shipping") {
    return Number(Math.min(shipping, subtotal + shipping).toFixed(2));
  }
  if (promo.discountType === "flat") {
    return Number(Math.min(promo.discountValue, subtotal).toFixed(2));
  }
  return Number(Math.min((subtotal * promo.discountValue) / 100, subtotal).toFixed(2));
}

function isPromoCurrentlyValid(promo, now = new Date()) {
  if (!promo.isActive) return false;
  if (promo.usedCount >= promo.maxUses) return false;
  if (new Date(promo.startsAt) > now) return false;
  if (new Date(promo.endsAt) < now) return false;
  return true;
}

function getPromoStatus(promo) {
  const now = new Date();
  if (!promo.isActive) return "disabled";
  if (promo.usedCount >= promo.maxUses) return "exhausted";
  if (new Date(promo.startsAt) > now) return "scheduled";
  if (new Date(promo.endsAt) < now) return "expired";
  return "active";
}

export const listPromos = async (_req, res) => {
  try {
    const promos = await Promo.find().sort({ createdAt: -1 });
    const rows = promos.map((promo) => ({
      ...promo.toObject(),
      status: getPromoStatus(promo)
    }));
    res.json(rows);
  } catch {
    res.status(500).json({ error: "Failed to load promo codes" });
  }
};

export const listPublicActivePromos = async (_req, res) => {
  try {
    const now = new Date();
    const promos = await Promo.find({
      isActive: true,
      startsAt: { $lte: now },
      endsAt: { $gte: now },
      $expr: { $lt: ["$usedCount", "$maxUses"] }
    })
      .sort({ endsAt: 1, createdAt: -1 })
      .limit(6);

    res.json(
      promos.map((promo) => ({
        _id: promo._id,
        code: promo.code,
        discountType: promo.discountType,
        discountValue: promo.discountValue,
        endsAt: promo.endsAt,
        status: getPromoStatus(promo)
      }))
    );
  } catch {
    res.status(500).json({ error: "Failed to load active promo codes" });
  }
};

export const createPromo = async (req, res) => {
  try {
    const { code, discountType, discountValue, maxUses, startsAt, endsAt } = req.body;
    if (!code || !startsAt || !endsAt) {
      return res.status(400).json({ error: "Code, startsAt and endsAt are required" });
    }

    const starts = new Date(startsAt);
    const ends = new Date(endsAt);
    if (!Number.isFinite(starts.getTime()) || !Number.isFinite(ends.getTime())) {
      return res.status(400).json({ error: "Invalid start or end date" });
    }
    if (starts >= ends) {
      return res.status(400).json({ error: "End time must be after start time" });
    }

    const parsedValue = Number(discountValue);
    const parsedUses = Number(maxUses);
    if (!Number.isFinite(parsedValue) || parsedValue < 0) {
      return res.status(400).json({ error: "Discount value must be valid" });
    }
    if (!Number.isInteger(parsedUses) || parsedUses < 1) {
      return res.status(400).json({ error: "Max uses must be an integer greater than 0" });
    }

    const promo = await Promo.create({
      code: String(code).toUpperCase().trim(),
      discountType: discountType || "percent",
      discountValue: parsedValue,
      maxUses: parsedUses,
      startsAt: starts,
      endsAt: ends
    });

    res.status(201).json({ ...promo.toObject(), status: getPromoStatus(promo) });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({ error: "Promo code already exists" });
    }
    res.status(500).json({ error: "Failed to create promo code" });
  }
};

export const updatePromo = async (req, res) => {
  try {
    const { id } = req.params;
    const promo = await Promo.findById(id);
    if (!promo) return res.status(404).json({ error: "Promo code not found" });

    const nextCode =
      req.body.code !== undefined ? String(req.body.code).toUpperCase().trim() : promo.code;
    const nextType = req.body.discountType ?? promo.discountType;
    const nextValue =
      req.body.discountValue !== undefined ? Number(req.body.discountValue) : promo.discountValue;
    const nextMaxUses =
      req.body.maxUses !== undefined ? Number(req.body.maxUses) : promo.maxUses;
    const nextStarts =
      req.body.startsAt !== undefined ? new Date(req.body.startsAt) : new Date(promo.startsAt);
    const nextEnds =
      req.body.endsAt !== undefined ? new Date(req.body.endsAt) : new Date(promo.endsAt);
    const nextIsActive =
      req.body.isActive !== undefined ? Boolean(req.body.isActive) : promo.isActive;

    if (!nextCode) return res.status(400).json({ error: "Code is required" });
    if (!["percent", "flat", "shipping"].includes(nextType)) {
      return res.status(400).json({ error: "Invalid discount type" });
    }
    if (!Number.isFinite(nextValue) || nextValue < 0) {
      return res.status(400).json({ error: "Discount value must be valid" });
    }
    if (!Number.isInteger(nextMaxUses) || nextMaxUses < 1) {
      return res.status(400).json({ error: "Max uses must be an integer greater than 0" });
    }
    if (!Number.isFinite(nextStarts.getTime()) || !Number.isFinite(nextEnds.getTime())) {
      return res.status(400).json({ error: "Invalid start or end date" });
    }
    if (nextStarts >= nextEnds) {
      return res.status(400).json({ error: "End time must be after start time" });
    }
    if (promo.usedCount > nextMaxUses) {
      return res
        .status(400)
        .json({ error: "Max uses cannot be less than current used count" });
    }

    promo.code = nextCode;
    promo.discountType = nextType;
    promo.discountValue = nextValue;
    promo.maxUses = nextMaxUses;
    promo.startsAt = nextStarts;
    promo.endsAt = nextEnds;
    promo.isActive = nextIsActive && promo.usedCount < promo.maxUses;

    await promo.save();
    res.json({ ...promo.toObject(), status: getPromoStatus(promo) });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({ error: "Promo code already exists" });
    }
    res.status(500).json({ error: "Failed to update promo code" });
  }
};

export const validatePromo = async (req, res) => {
  try {
    const code = String(req.body?.code || "").toUpperCase().trim();
    const subtotal = Number(req.body?.subtotal || 0);
    const shipping = Number(req.body?.shipping || 0);
    if (!code) return res.status(400).json({ error: "Promo code is required" });
    if (!Number.isFinite(subtotal) || subtotal < 0) {
      return res.status(400).json({ error: "Invalid subtotal" });
    }

    const promo = await Promo.findOne({ code });
    if (!promo) return res.status(404).json({ error: "Promo code not found" });
    if (!isPromoCurrentlyValid(promo)) {
      return res.status(400).json({ error: `Promo code is ${getPromoStatus(promo)}` });
    }

    const discountAmount = computeDiscount(promo, subtotal, shipping);
    res.json({
      message: "Promo applied",
      promo: {
        code: promo.code,
        discountType: promo.discountType,
        discountValue: promo.discountValue,
        status: getPromoStatus(promo)
      },
      discountAmount
    });
  } catch {
    res.status(500).json({ error: "Failed to validate promo code" });
  }
};

export const redeemPromo = async (req, res) => {
  try {
    const code = String(req.body?.code || "").toUpperCase().trim();
    const subtotal = Number(req.body?.subtotal || 0);
    const shipping = Number(req.body?.shipping || 0);
    if (!code) return res.status(400).json({ error: "Promo code is required" });
    if (!Number.isFinite(subtotal) || subtotal < 0) {
      return res.status(400).json({ error: "Invalid subtotal" });
    }

    const promo = await Promo.findOne({ code });
    if (!promo) return res.status(404).json({ error: "Promo code not found" });
    if (!isPromoCurrentlyValid(promo)) {
      return res.status(400).json({ error: `Promo code is ${getPromoStatus(promo)}` });
    }

    const discountAmount = computeDiscount(promo, subtotal, shipping);
    promo.usedCount += 1;
    if (promo.usedCount >= promo.maxUses) {
      promo.isActive = false;
    }
    await promo.save();

    res.json({
      message: "Promo redeemed",
      discountAmount,
      status: getPromoStatus(promo),
      usedCount: promo.usedCount,
      maxUses: promo.maxUses
    });
  } catch {
    res.status(500).json({ error: "Failed to redeem promo code" });
  }
};
