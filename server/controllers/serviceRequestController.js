import ServiceRequest from "../models/ServiceRequest.js";
import User from "../models/User.js";

const ALLOWED_PACKAGES = ["basic", "full", "premium"];
const ALLOWED_SERVICE_STATUSES = [
  "requested",
  "confirmed",
  "in_progress",
  "completed",
  "cancelled"
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

    return res.json({ message: "Booking response submitted", request: requestDoc });
  } catch {
    return res.status(500).json({ error: "Failed to respond to booking" });
  }
};
