import express from "express";
import authMiddleware, { requireAdmin, requireGarage } from "../middleware/authMiddleware.js";
import {
  createServiceRequest,
  listGarageServiceRequests,
  listMyServiceRequests,
  listServiceRequestsAdmin,
  respondGarageServiceRequest,
  updateGarageServiceBilling,
  updateGarageServiceBillingPayment,
  updateServiceRequestStatus
} from "../controllers/serviceRequestController.js";

const router = express.Router();

router.post("/", authMiddleware, createServiceRequest);
router.get("/my", authMiddleware, listMyServiceRequests);
router.get("/admin", authMiddleware, requireAdmin, listServiceRequestsAdmin);
router.get("/garage", authMiddleware, requireGarage, listGarageServiceRequests);
router.put("/:id/status", authMiddleware, requireAdmin, updateServiceRequestStatus);
router.put("/:id/garage-response", authMiddleware, requireGarage, respondGarageServiceRequest);
router.put("/:id/billing", authMiddleware, requireGarage, updateGarageServiceBilling);
router.put("/:id/billing/payment", authMiddleware, requireGarage, updateGarageServiceBillingPayment);

export default router;
