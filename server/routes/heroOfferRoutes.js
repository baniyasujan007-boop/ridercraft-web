import express from "express";
import authMiddleware, { requireAdmin } from "../middleware/authMiddleware.js";
import { requireValidObjectId } from "../middleware/validators.js";
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
router.put("/admin/:id", authMiddleware, requireAdmin, requireValidObjectId, updateHeroOffer);
router.delete("/admin/:id", authMiddleware, requireAdmin, requireValidObjectId, deleteHeroOffer);

export default router;
