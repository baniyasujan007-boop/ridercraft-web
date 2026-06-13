import express from "express";
import authMiddleware, { requireAdmin } from "../middleware/authMiddleware.js";
import {
  createFeaturedSection,
  deleteFeaturedSection,
  listAdminFeaturedSections,
  listPublicFeaturedSections,
  updateFeaturedSection
} from "../controllers/featuredSectionController.js";

const router = express.Router();

router.get("/", listPublicFeaturedSections);
router.get("/admin", authMiddleware, requireAdmin, listAdminFeaturedSections);
router.post("/admin", authMiddleware, requireAdmin, createFeaturedSection);
router.put("/admin/:id", authMiddleware, requireAdmin, updateFeaturedSection);
router.delete("/admin/:id", authMiddleware, requireAdmin, deleteFeaturedSection);

export default router;
