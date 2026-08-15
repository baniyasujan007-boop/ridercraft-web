import express from "express";
import authMiddleware, { requireAdmin } from "../middleware/authMiddleware.js";
import { requireValidObjectId } from "../middleware/validators.js";
import {
  createPromo,
  listPublicActivePromos,
  listPromos,
  redeemPromo,
  updatePromo,
  validatePromo
} from "../controllers/promoController.js";

const router = express.Router();

router.get("/active", listPublicActivePromos);
router.get("/", authMiddleware, requireAdmin, listPromos);
router.post("/", authMiddleware, requireAdmin, createPromo);
router.put("/:id", authMiddleware, requireAdmin, requireValidObjectId, updatePromo);
router.post("/validate", validatePromo);
router.post("/redeem", redeemPromo);

export default router;
