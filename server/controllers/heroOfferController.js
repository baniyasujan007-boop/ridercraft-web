import HeroOffer from "../models/HeroOffer.js";

function computeStatus(offer, now = new Date()) {
  if (!offer.isActive) return "disabled";
  if (new Date(offer.startsAt) > now) return "scheduled";
  if (offer.endsAt && new Date(offer.endsAt) <= now) return "expired";
  return "active";
}

function normalizeResponse(offer) {
  const status = computeStatus(offer);
  const nowMs = Date.now();
  const endsMs = offer.endsAt ? new Date(offer.endsAt).getTime() : null;
  const remainingSeconds =
    endsMs && endsMs > nowMs ? Math.floor((endsMs - nowMs) / 1000) : 0;
  return {
    ...offer.toObject(),
    status,
    remainingSeconds
  };
}

export const listPublicHeroOffers = async (_req, res) => {
  try {
    const rows = await HeroOffer.find({ isActive: true }).sort({ priority: -1, createdAt: -1 });
    const active = rows
      .map(normalizeResponse)
      .filter((row) => row.status === "active");
    res.json(active);
  } catch {
    res.status(500).json({ error: "Failed to load hero offers" });
  }
};

export const listAdminHeroOffers = async (_req, res) => {
  try {
    const rows = await HeroOffer.find().sort({ priority: -1, createdAt: -1 });
    res.json(rows.map(normalizeResponse));
  } catch {
    res.status(500).json({ error: "Failed to load hero offers" });
  }
};

export const createHeroOffer = async (req, res) => {
  try {
    const { title, offerType, startsAt, endsAt, priority, ctaQuery, isActive } = req.body;
    if (!title || !String(title).trim()) {
      return res.status(400).json({ error: "Offer title is required" });
    }

    const nextType = offerType === "flash" ? "flash" : "tag";
    const nextStarts = startsAt ? new Date(startsAt) : new Date();
    const nextEnds = endsAt ? new Date(endsAt) : null;
    const nextPriority = Number.isFinite(Number(priority)) ? Number(priority) : 1;

    if (!Number.isFinite(nextStarts.getTime())) {
      return res.status(400).json({ error: "Invalid start date" });
    }
    if (nextEnds && !Number.isFinite(nextEnds.getTime())) {
      return res.status(400).json({ error: "Invalid end date" });
    }
    if (nextEnds && nextEnds <= nextStarts) {
      return res.status(400).json({ error: "End date must be after start date" });
    }

    const offer = await HeroOffer.create({
      title: String(title).trim(),
      offerType: nextType,
      startsAt: nextStarts,
      endsAt: nextEnds,
      priority: nextPriority,
      ctaQuery: String(ctaQuery || "").trim(),
      isActive: isActive !== undefined ? Boolean(isActive) : true
    });

    res.status(201).json(normalizeResponse(offer));
  } catch {
    res.status(500).json({ error: "Failed to create hero offer" });
  }
};

export const updateHeroOffer = async (req, res) => {
  try {
    const { id } = req.params;
    const offer = await HeroOffer.findById(id);
    if (!offer) return res.status(404).json({ error: "Hero offer not found" });

    const nextTitle =
      req.body.title !== undefined ? String(req.body.title).trim() : offer.title;
    const nextType = req.body.offerType !== undefined ? String(req.body.offerType) : offer.offerType;
    const nextStarts =
      req.body.startsAt !== undefined ? new Date(req.body.startsAt) : new Date(offer.startsAt);
    const nextEnds =
      req.body.endsAt !== undefined
        ? req.body.endsAt
          ? new Date(req.body.endsAt)
          : null
        : offer.endsAt;
    const nextPriority =
      req.body.priority !== undefined ? Number(req.body.priority) : offer.priority;
    const nextIsActive =
      req.body.isActive !== undefined ? Boolean(req.body.isActive) : offer.isActive;

    if (!nextTitle) return res.status(400).json({ error: "Offer title is required" });
    if (!["tag", "flash"].includes(nextType)) {
      return res.status(400).json({ error: "Invalid offer type" });
    }
    if (!Number.isFinite(nextStarts.getTime())) {
      return res.status(400).json({ error: "Invalid start date" });
    }
    if (nextEnds && !Number.isFinite(new Date(nextEnds).getTime())) {
      return res.status(400).json({ error: "Invalid end date" });
    }
    if (nextEnds && new Date(nextEnds) <= nextStarts) {
      return res.status(400).json({ error: "End date must be after start date" });
    }

    offer.title = nextTitle;
    offer.offerType = nextType;
    offer.startsAt = nextStarts;
    offer.endsAt = nextEnds;
    offer.priority = Number.isFinite(nextPriority) ? nextPriority : offer.priority;
    offer.ctaQuery =
      req.body.ctaQuery !== undefined ? String(req.body.ctaQuery || "").trim() : offer.ctaQuery;
    offer.isActive = nextIsActive;

    await offer.save();
    res.json(normalizeResponse(offer));
  } catch {
    res.status(500).json({ error: "Failed to update hero offer" });
  }
};

export const deleteHeroOffer = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await HeroOffer.findByIdAndDelete(id);
    if (!deleted) return res.status(404).json({ error: "Hero offer not found" });
    res.json({ message: "Hero offer deleted" });
  } catch {
    res.status(500).json({ error: "Failed to delete hero offer" });
  }
};
