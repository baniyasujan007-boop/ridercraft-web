import express from "express";
import authMiddleware, { requireAdmin } from "../middleware/authMiddleware.js";
import {
  createHeroOffer,
  deleteHeroOffer,
  listAdminHeroOffers,
  listPublicHeroOffers,
  updateHeroOffer
} from "../controllers/heroOfferController.js";

const router = express.Router();

router.get("/", listPublicHeroOffers);
router.get("/admin", authMiddleware, requireAdmin, listAdminHeroOffers);
router.post("/admin", authMiddleware, requireAdmin, createHeroOffer);
router.put("/admin/:id", authMiddleware, requireAdmin, updateHeroOffer);
router.delete("/admin/:id", authMiddleware, requireAdmin, deleteHeroOffer);

export default router;
