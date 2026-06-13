import express from "express";
import authMiddleware, { requireAdmin } from "../middleware/authMiddleware.js";
import {
  createPromo,
  listPromos,
  redeemPromo,
  updatePromo,
  validatePromo
} from "../controllers/promoController.js";

const router = express.Router();

router.get("/", authMiddleware, requireAdmin, listPromos);
router.post("/", authMiddleware, requireAdmin, createPromo);
router.put("/:id", authMiddleware, requireAdmin, updatePromo);
router.post("/validate", validatePromo);
router.post("/redeem", redeemPromo);

export default router;
