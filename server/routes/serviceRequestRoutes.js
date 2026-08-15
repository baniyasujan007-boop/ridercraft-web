import express from "express";
import authMiddleware, { requireAdmin, requireGarage } from "../middleware/authMiddleware.js";
import { requireValidObjectId } from "../middleware/validators.js";
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
router.put("/:id/status", authMiddleware, requireAdmin, requireValidObjectId, updateServiceRequestStatus);
router.put("/:id/garage-response", authMiddleware, requireGarage, requireValidObjectId, respondGarageServiceRequest);
router.put("/:id/billing", authMiddleware, requireGarage, requireValidObjectId, updateGarageServiceBilling);
router.put("/:id/billing/payment", authMiddleware, requireGarage, requireValidObjectId, updateGarageServiceBillingPayment);

export default router;
