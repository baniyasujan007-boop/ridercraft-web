import express from "express";
import {
  createProduct,
  deleteProduct,
  getProductById,
  listProducts,
  rateProduct,
  updateProduct,
  fetchProductFromUrl

} from "../controllers/productController.js";
import authMiddleware, { requireAdmin } from "../middleware/authMiddleware.js";
import { requireValidObjectId } from "../middleware/validators.js";

const router = express.Router();

router.get("/", listProducts);
router.get("/:id", requireValidObjectId, getProductById);
router.post("/", authMiddleware, requireAdmin, createProduct);
router.post("/:id/rate", authMiddleware, requireValidObjectId, rateProduct);
router.put("/:id", authMiddleware, requireAdmin, requireValidObjectId, updateProduct);
router.delete("/:id", authMiddleware, requireAdmin, requireValidObjectId, deleteProduct);
router.post("/fetch-url", authMiddleware, requireAdmin, fetchProductFromUrl);

export default router;
