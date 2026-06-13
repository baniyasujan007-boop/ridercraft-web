import mongoose from "mongoose";

const userSchema = new mongoose.Schema({
  name: String,
  email: { type: String, unique: true },
  password: String,
  googleId: { type: String, unique: true, sparse: true },
  authProvider: { type: String, default: "local" },
  role: {
    type: String,
    enum: ["user", "admin", "garage"],
    default: "user"
  },
  avatar: { type: String, default: "" },
  contactNumber: { type: String, default: "" },
  deliveryAddress: { type: String, default: "" },
  garageProfile: {
    garageName: { type: String, default: "", trim: true },
    garageAddress: { type: String, default: "", trim: true },
    location: {
      latitude: { type: Number, default: null, min: -90, max: 90 },
      longitude: { type: Number, default: null, min: -180, max: 180 }
    },
    serviceRadiusKm: { type: Number, default: 15, min: 1, max: 200 },
    isAvailable: { type: Boolean, default: true }
  }
});

export default mongoose.model("User", userSchema);
