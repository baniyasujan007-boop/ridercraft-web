import express from "express";
import authMiddleware, { requireAdmin } from "../middleware/authMiddleware.js";
import { requireValidObjectId } from "../middleware/validators.js";
import {
  createOrder,
  getOrderReturnTracking,
  listMyOrders,
  listOrdersAdmin,
  requestOrderReturn,
  reviewOrderReturn,
  updateOrderPaymentStatus,
  updateOrderReturnTracking,
  updateOrderStatus
} from "../controllers/orderController.js";

const router = express.Router();

router.post("/", authMiddleware, createOrder);
router.get("/my", authMiddleware, listMyOrders);
router.get("/", authMiddleware, requireAdmin, listOrdersAdmin);
router.put("/:id/status", authMiddleware, requireAdmin, requireValidObjectId, updateOrderStatus);
router.put("/:id/payment-status", authMiddleware, requireAdmin, requireValidObjectId, updateOrderPaymentStatus);
router.post("/:id/return-request", authMiddleware, requireValidObjectId, requestOrderReturn);
router.put("/:id/return-review", authMiddleware, requireAdmin, requireValidObjectId, reviewOrderReturn);
router.put("/:id/return-tracking", authMiddleware, requireAdmin, requireValidObjectId, updateOrderReturnTracking);
router.get("/:id/return-tracking", authMiddleware, requireValidObjectId, getOrderReturnTracking);

export default router;
