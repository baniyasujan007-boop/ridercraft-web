import express from "express";
import authMiddleware, { requireAdmin } from "../middleware/authMiddleware.js";
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
router.put("/:id/status", authMiddleware, requireAdmin, updateOrderStatus);
router.put("/:id/payment-status", authMiddleware, requireAdmin, updateOrderPaymentStatus);
router.post("/:id/return-request", authMiddleware, requestOrderReturn);
router.put("/:id/return-review", authMiddleware, requireAdmin, reviewOrderReturn);
router.put("/:id/return-tracking", authMiddleware, requireAdmin, updateOrderReturnTracking);
router.get("/:id/return-tracking", authMiddleware, getOrderReturnTracking);

export default router;
