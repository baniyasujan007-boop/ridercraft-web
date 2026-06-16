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

const router = express.Router();

router.get("/", listProducts);
router.get("/:id", getProductById);
router.post("/", authMiddleware, requireAdmin, createProduct);
router.post("/:id/rate", authMiddleware, rateProduct);
router.put("/:id", authMiddleware, requireAdmin, updateProduct);
router.delete("/:id", authMiddleware, requireAdmin, deleteProduct);
router.post("/fetch-url", authMiddleware, requireAdmin, fetchProductFromUrl);

export default router;
