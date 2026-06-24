import express from "express";
import {
  addWishlistItem,
  listWishlist,
  removeWishlistItem,
} from "../controllers/wishlistController.js";
import authMiddleware from "../middleware/authMiddleware.js";

const router = express.Router();

router.get("/", authMiddleware, listWishlist);
router.post("/add", authMiddleware, addWishlistItem);
router.delete("/remove/:id", authMiddleware, removeWishlistItem);

export default router;
