import ServiceRequest from "../models/ServiceRequest.js";
import User from "../models/User.js";
import Notification from "../models/Notification.js";

const ALLOWED_PACKAGES = ["basic", "full", "premium"];
const ALLOWED_SERVICE_STATUSES = [
  "requested",
  "confirmed",
  "in_progress",
  "completed",
  "cancelled"
];
const ALLOWED_BILLING_PAYMENT_STATUSES = ["issued", "paid", "cancelled"];
const ALLOWED_BILLING_PAYMENT_METHODS = [
  "",
  "cash",
  "card",
  "upi",
  "ewallet",
  "bank_transfer",
  "other"
];

const degToRad = (value) => (value * Math.PI) / 180;

const getDistanceKm = (lat1, lon1, lat2, lon2) => {
  const earthRadiusKm = 6371;
  const dLat = degToRad(lat2 - lat1);
  const dLon = degToRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(degToRad(lat1)) *
      Math.cos(degToRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusKm * c;
};

const sortServiceRequests = (requests) =>
  [...requests].sort((a, b) => {
    const aEmergency = String(a.priority || "normal") === "emergency" ? 1 : 0;
    const bEmergency = String(b.priority || "normal") === "emergency" ? 1 : 0;
    if (aEmergency !== bEmergency) return bEmergency - aEmergency;
    return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
  });

const toMoney = (value) => {
  const amount = Number(value || 0);
  if (!Number.isFinite(amount) || amount < 0) return null;
  return Number(amount.toFixed(2));
};

const normalizeBillingItems = (items) => {
  if (!Array.isArray(items)) return [];

  return items
    .map((item) => {
      const name = String(item?.name || "").trim();
      const quantity = toMoney(item?.quantity === undefined ? 1 : item.quantity);
      const unitPrice = toMoney(item?.unitPrice);

      if (!name && Number(unitPrice || 0) === 0) return null;
      if (!name || quantity === null || unitPrice === null || quantity <= 0) {
        return { invalid: true };
      }

      return {
        name,
        quantity,
        unitPrice,
        total: Number((quantity * unitPrice).toFixed(2))
      };
    })
    .filter(Boolean);
};

const canGarageAccessRequest = (requestDoc, user) =>
  String(requestDoc?.assignedGarage || "") === String(user?.id || "");

const findClosestGarage = async (pickupLatitude, pickupLongitude) => {
  const garages = await User.find({
    role: "garage",
    "garageProfile.isAvailable": true,
    "garageProfile.location.latitude": { $ne: null },
    "garageProfile.location.longitude": { $ne: null }
  }).select("name email garageProfile");

  if (!garages.length) {
    return null;
  }

  let inRadiusClosest = null;
  let fallbackClosest = null;

  for (const garage of garages) {
    const latitude = Number(garage.garageProfile?.location?.latitude);
    const longitude = Number(garage.garageProfile?.location?.longitude);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) continue;

    const distanceKm = getDistanceKm(pickupLatitude, pickupLongitude, latitude, longitude);
    if (!Number.isFinite(distanceKm)) continue;

    if (!fallbackClosest || distanceKm < fallbackClosest.distanceKm) {
      fallbackClosest = { garage, distanceKm };
    }

    const radiusKm = Number(garage.garageProfile?.serviceRadiusKm || 15);
    const effectiveRadiusKm = Number.isFinite(radiusKm) && radiusKm > 0 ? radiusKm : 15;
    if (distanceKm <= effectiveRadiusKm) {
      if (!inRadiusClosest || distanceKm < inRadiusClosest.distanceKm) {
        inRadiusClosest = { garage, distanceKm };
      }
    }
  }

  return inRadiusClosest || fallbackClosest;
};

export const createServiceRequest = async (req, res) => {
  try {
    const packageType = String(req.body?.packageType || "").toLowerCase();
    const bikeModel = String(req.body?.bikeModel || "").trim();
    const preferredDate = String(req.body?.preferredDate || "").trim();
    const preferredTime = String(req.body?.preferredTime || "").trim();
    const pickupAddress = String(req.body?.pickupAddress || "").trim();
    const pickupLocationBody = req.body?.pickupLocation || {};
    const pickupLatitude = Number(pickupLocationBody.latitude);
    const pickupLongitude = Number(pickupLocationBody.longitude);
    const pickupAccuracyMeters =
      pickupLocationBody.accuracyMeters === undefined ||
      pickupLocationBody.accuracyMeters === null ||
      pickupLocationBody.accuracyMeters === ""
        ? null
        : Number(pickupLocationBody.accuracyMeters);
    const pickupCapturedAt = pickupLocationBody.capturedAt
      ? new Date(pickupLocationBody.capturedAt)
      : new Date();
    const contactNumber = String(req.body?.contactNumber || "").trim();
    const priorityRaw = String(req.body?.priority || "normal").toLowerCase();
    const priority = priorityRaw === "emergency" ? "emergency" : "normal";
    const breakdownIssue = String(req.body?.breakdownIssue || "").trim();
    const notes = String(req.body?.notes || "").trim();

    if (!ALLOWED_PACKAGES.includes(packageType)) {
      return res.status(400).json({ error: "Invalid service package" });
    }
    if (!bikeModel) {
      return res.status(400).json({ error: "Bike model is required" });
    }
    if (!preferredDate) {
      return res.status(400).json({ error: "Preferred date is required" });
    }
    if (!preferredTime) {
      return res.status(400).json({ error: "Preferred time is required" });
    }
    if (!pickupAddress) {
      return res.status(400).json({ error: "Pickup address is required" });
    }
    if (!Number.isFinite(pickupLatitude) || pickupLatitude < -90 || pickupLatitude > 90) {
      return res.status(400).json({ error: "Valid pickup latitude is required" });
    }
    if (!Number.isFinite(pickupLongitude) || pickupLongitude < -180 || pickupLongitude > 180) {
      return res.status(400).json({ error: "Valid pickup longitude is required" });
    }
    if (
      pickupAccuracyMeters !== null &&
      (!Number.isFinite(pickupAccuracyMeters) || pickupAccuracyMeters < 0)
    ) {
      return res.status(400).json({ error: "Pickup accuracy must be a valid number" });
    }
    if (Number.isNaN(pickupCapturedAt.getTime())) {
      return res.status(400).json({ error: "Pickup location capture time is invalid" });
    }
    if (!contactNumber) {
      return res.status(400).json({ error: "Contact number is required" });
    }
    if (priority === "emergency" && !breakdownIssue) {
      return res.status(400).json({ error: "Breakdown issue is required for emergency service" });
    }

    const nearestGarage = await findClosestGarage(pickupLatitude, pickupLongitude);

    const request = await ServiceRequest.create({
      user: req.user.id,
      packageType,
      bikeModel,
      preferredDate,
      preferredTime,
      pickupAddress,
      pickupLocation: {
        latitude: pickupLatitude,
        longitude: pickupLongitude,
        accuracyMeters: pickupAccuracyMeters,
        capturedAt: pickupCapturedAt
      },
      contactNumber,
      priority,
      breakdownIssue,
      notes,
      assignedGarage: nearestGarage?.garage?._id || null,
      assignedGarageDistanceKm: nearestGarage?.distanceKm
        ? Number(nearestGarage.distanceKm.toFixed(2))
        : null,
      garageAssignedAt: nearestGarage?.garage ? new Date() : null
    });

    const populated = await request.populate(
      "assignedGarage",
      "name email contactNumber garageProfile"
    );
await Notification.create({
  userId: req.user.id,
  title: "Service Request Submitted",
  body: "Your bike service request has been submitted successfully.",
  type: "service"
});
    return res.status(201).json({
      message: nearestGarage?.garage
        ? "Service request submitted and assigned to the nearest garage"
        : "Service request submitted",
      request: populated
    });
  } catch {
    return res.status(500).json({ error: "Failed to create service request" });
  }
};

export const listMyServiceRequests = async (req, res) => {
  try {
    const requests = await ServiceRequest.find({ user: req.user.id })
      .populate("assignedGarage", "name email contactNumber garageProfile")
      .sort({ createdAt: -1 });
    return res.json(requests);
  } catch {
    return res.status(500).json({ error: "Failed to load service requests" });
  }
};

export const listServiceRequestsAdmin = async (_req, res) => {
  try {
    const requests = await ServiceRequest.find()
      .populate("user", "name email avatar contactNumber deliveryAddress")
      .populate("assignedGarage", "name email contactNumber garageProfile")
      .sort({ createdAt: -1 });
    return res.json(sortServiceRequests(requests));
  } catch {
    return res.status(500).json({ error: "Failed to load service requests" });
  }
};

export const listGarageServiceRequests = async (req, res) => {
  try {
    const requests = await ServiceRequest.find({ assignedGarage: req.user.id })
      .populate("user", "name email avatar contactNumber deliveryAddress")
      .sort({ createdAt: -1 });
    return res.json(sortServiceRequests(requests));
  } catch {
    return res.status(500).json({ error: "Failed to load garage service requests" });
  }
};

export const updateServiceRequestStatus = async (req, res) => {
  try {
    const requestId = String(req.params?.id || "");
    const nextStatus = String(req.body?.status || "").toLowerCase();
    const adminNote = String(req.body?.adminNote || "").trim();

    if (!ALLOWED_SERVICE_STATUSES.includes(nextStatus)) {
      return res.status(400).json({ error: "Invalid service request status" });
    }

    const requestDoc = await ServiceRequest.findById(requestId);
    if (!requestDoc) {
      return res.status(404).json({ error: "Service request not found" });
    }

    requestDoc.status = nextStatus;
requestDoc.adminNote = adminNote;

await requestDoc.save();

await Notification.create({
  userId: requestDoc.user,
  title: "Service Status Updated",
  body: `Your service request is now ${nextStatus.replace("_", " ")}.`,
  type: "service"
});

    return res.json({ message: "Service request updated", request: requestDoc });
  } catch {
    return res.status(500).json({ error: "Failed to update service request" });
  }
};

export const respondGarageServiceRequest = async (req, res) => {
  try {
    const requestId = String(req.params?.id || "");
    const nextStatus = String(req.body?.status || "").toLowerCase();
    const garageNote = String(req.body?.garageNote || "").trim();

    if (!ALLOWED_SERVICE_STATUSES.includes(nextStatus)) {
      return res.status(400).json({ error: "Invalid service request status" });
    }

    const requestDoc = await ServiceRequest.findById(requestId);
    if (!requestDoc) {
      return res.status(404).json({ error: "Service request not found" });
    }

    if (String(requestDoc.assignedGarage || "") !== String(req.user.id || "")) {
      return res.status(403).json({ error: "This booking is not assigned to your garage" });
    }

    requestDoc.status = nextStatus;
    requestDoc.garageNote = garageNote;
    requestDoc.garageRespondedAt = new Date();
    await requestDoc.save();

await Notification.create({
  userId: requestDoc.user,
  title: "Garage Update",
  body: `Your service booking is now ${nextStatus.replace("_", " ")}.`,
  type: "service"
});

    return res.json({ message: "Booking response submitted", request: requestDoc });
  } catch {
    return res.status(500).json({ error: "Failed to respond to booking" });
  }
};

export const updateGarageServiceBilling = async (req, res) => {
  try {
    const requestId = String(req.params?.id || "");
    const laborCharge = toMoney(req.body?.laborCharge);
    const tax = toMoney(req.body?.tax);
    const discount = toMoney(req.body?.discount);
    const notes = String(req.body?.notes || "").trim();
    const items = normalizeBillingItems(req.body?.items);

    if (laborCharge === null) {
      return res.status(400).json({ error: "Labor charge must be a valid amount" });
    }
    if (tax === null) {
      return res.status(400).json({ error: "Tax must be a valid amount" });
    }
    if (discount === null) {
      return res.status(400).json({ error: "Discount must be a valid amount" });
    }
    if (items.some((item) => item.invalid)) {
      return res.status(400).json({ error: "Billing items need a name, quantity, and price" });
    }
    if (items.length > 20) {
      return res.status(400).json({ error: "You can add up to 20 billing items" });
    }

    const requestDoc = await ServiceRequest.findById(requestId);
    if (!requestDoc) {
      return res.status(404).json({ error: "Service request not found" });
    }
    if (!canGarageAccessRequest(requestDoc, req.user)) {
      return res.status(403).json({ error: "This booking is not assigned to your garage" });
    }
    if (requestDoc.billing?.status === "paid") {
      return res.status(400).json({ error: "Paid bills cannot be edited" });
    }

    const partsTotal = items.reduce((sum, item) => sum + item.total, 0);
    const subtotal = Number((laborCharge + partsTotal).toFixed(2));
    const totalBeforeDiscount = Number((subtotal + tax).toFixed(2));

    if (discount > totalBeforeDiscount) {
      return res.status(400).json({ error: "Discount cannot exceed subtotal plus tax" });
    }

    const total = Number((totalBeforeDiscount - discount).toFixed(2));
    const existingIssuedAt = requestDoc.billing?.issuedAt || null;

    requestDoc.billing = {
      laborCharge,
      items,
      subtotal,
      tax,
      discount,
      total,
      status: "issued",
      notes,
      paymentMethod: "",
      paymentReference: "",
      issuedAt: existingIssuedAt || new Date(),
      paidAt: null,
      updatedBy: req.user.id
    };

    await requestDoc.save();
    await Notification.create({
      userId: requestDoc.user,
      title: "Service Bill Issued",
      body: `Your garage bill for ${requestDoc.bikeModel} is ₹${total.toLocaleString("en-IN")}.`,
      type: "payment"
    });

    return res.json({ message: "Service bill updated", request: requestDoc });
  } catch {
    return res.status(500).json({ error: "Failed to update service bill" });
  }
};

export const updateGarageServiceBillingPayment = async (req, res) => {
  try {
    const requestId = String(req.params?.id || "");
    const nextStatus = String(req.body?.billingStatus || req.body?.status || "").toLowerCase();
    const paymentMethod = String(req.body?.paymentMethod || "").toLowerCase();
    const paymentReference = String(req.body?.paymentReference || "").trim();

    if (!ALLOWED_BILLING_PAYMENT_STATUSES.includes(nextStatus)) {
      return res.status(400).json({ error: "Invalid billing payment status" });
    }
    if (!ALLOWED_BILLING_PAYMENT_METHODS.includes(paymentMethod)) {
      return res.status(400).json({ error: "Invalid payment method" });
    }
    if (nextStatus === "paid" && !paymentMethod) {
      return res.status(400).json({ error: "Payment method is required when marking paid" });
    }

    const requestDoc = await ServiceRequest.findById(requestId);
    if (!requestDoc) {
      return res.status(404).json({ error: "Service request not found" });
    }
    if (!canGarageAccessRequest(requestDoc, req.user)) {
      return res.status(403).json({ error: "This booking is not assigned to your garage" });
    }
    if (!requestDoc.billing || requestDoc.billing.status === "unbilled") {
      return res.status(400).json({ error: "Create a service bill before updating payment" });
    }

    requestDoc.billing.status = nextStatus;
    requestDoc.billing.paymentMethod = nextStatus === "paid" ? paymentMethod : "";
    requestDoc.billing.paymentReference = nextStatus === "paid" ? paymentReference : "";
    requestDoc.billing.paidAt = nextStatus === "paid" ? new Date() : null;
    requestDoc.billing.updatedBy = req.user.id;

    await requestDoc.save();
    await Notification.create({
      userId: requestDoc.user,
      title: nextStatus === "paid" ? "Service Payment Received" : "Service Bill Updated",
      body:
        nextStatus === "paid"
          ? `Payment received for your ${requestDoc.bikeModel} service bill.`
          : `Your service bill is now ${nextStatus}.`,
      type: "payment"
    });

    return res.json({ message: "Service bill payment updated", request: requestDoc });
  } catch {
    return res.status(500).json({ error: "Failed to update service bill payment" });
  }
};
