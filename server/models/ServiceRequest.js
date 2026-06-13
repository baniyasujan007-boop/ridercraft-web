import mongoose from "mongoose";

const serviceRequestSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    packageType: {
      type: String,
      enum: ["basic", "full", "premium"],
      required: true
    },
    bikeModel: { type: String, required: true, trim: true },
    preferredDate: { type: String, required: true, trim: true },
    preferredTime: { type: String, required: true, trim: true },
    pickupAddress: { type: String, required: true, trim: true },
    pickupLocation: {
      latitude: { type: Number, required: true, min: -90, max: 90 },
      longitude: { type: Number, required: true, min: -180, max: 180 },
      accuracyMeters: { type: Number, default: null, min: 0 },
      capturedAt: { type: Date, default: Date.now }
    },
    contactNumber: { type: String, required: true, trim: true },
    priority: {
      type: String,
      enum: ["normal", "emergency"],
      default: "normal"
    },
    breakdownIssue: { type: String, default: "", trim: true },
    notes: { type: String, default: "", trim: true },
    adminNote: { type: String, default: "", trim: true },
    assignedGarage: { type: mongoose.Schema.Types.ObjectId, ref: "User", default: null },
    assignedGarageDistanceKm: { type: Number, default: null, min: 0 },
    garageAssignedAt: { type: Date, default: null },
    garageNote: { type: String, default: "", trim: true },
    garageRespondedAt: { type: Date, default: null },
    status: {
      type: String,
      enum: ["requested", "confirmed", "in_progress", "completed", "cancelled"],
      default: "requested"
    }
  },
  { timestamps: true }
);

export default mongoose.model("ServiceRequest", serviceRequestSchema);
