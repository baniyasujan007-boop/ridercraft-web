import User from "../models/User.js";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { OAuth2Client } from "google-auth-library";

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

export const register = async (req, res) => {
  try {
    const {
      name,
      email,
      password,
      role,
      garageName,
      garageAddress,
      latitude,
      longitude,
      serviceRadiusKm
    } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ error: "Name, email, and password are required" });
    }

    const normalizedRole = String(role || "user").toLowerCase();
    if (!["user", "garage"].includes(normalizedRole)) {
      return res.status(400).json({ error: "Invalid role selected" });
    }

    const createPayload = {
      name: String(name).trim(),
      email: String(email).toLowerCase().trim()
    };

    if (normalizedRole === "garage") {
      if (!garageName || !garageAddress) {
        return res
          .status(400)
          .json({ error: "Garage name and garage address are required for garage signup" });
      }
      const lat = Number(latitude);
      const lng = Number(longitude);
      const radius = Number(serviceRadiusKm || 15);
      if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
        return res.status(400).json({ error: "Valid garage latitude is required" });
      }
      if (!Number.isFinite(lng) || lng < -180 || lng > 180) {
        return res.status(400).json({ error: "Valid garage longitude is required" });
      }
      if (!Number.isFinite(radius) || radius < 1 || radius > 200) {
        return res.status(400).json({ error: "Service radius must be between 1 and 200 km" });
      }

      createPayload.role = "garage";
      createPayload.garageProfile = {
        garageName: String(garageName).trim(),
        garageAddress: String(garageAddress).trim(),
        location: {
          latitude: lat,
          longitude: lng
        },
        serviceRadiusKm: radius,
        isAvailable: true
      };
    }

    const hashed = await bcrypt.hash(password, 10);
    await User.create({ ...createPayload, password: hashed });
    res.json({ message: "Registered" });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({ error: "Email already registered" });
    }
    res.status(500).json({ error: "Registration failed" });
  }
};

export const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ error: "User not found" });

    const ok = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(400).json({ error: "Wrong password" });

    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET
    );

    res.json({ token, role: user.role });
  } catch {
    res.status(500).json({ error: "Login failed" });
  }
};

export const garageLogin = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user || user.role !== "garage") {
      return res.status(400).json({ error: "Garage account not found" });
    }
    if (!user.password) {
      return res.status(400).json({ error: "Garage account has no password set" });
    }

    const ok = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(400).json({ error: "Wrong password" });

    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET);
    return res.json({ token, role: user.role });
  } catch {
    return res.status(500).json({ error: "Garage login failed" });
  }
};

export const registerGarage = async (req, res) => {
  try {
    const {
      name,
      email,
      password,
      garageName,
      garageAddress,
      latitude,
      longitude,
      serviceRadiusKm
    } = req.body;

    if (!name || !email || !password || !garageName || !garageAddress) {
      return res.status(400).json({
        error: "Name, email, password, garage name, and garage address are required"
      });
    }

    const lat = Number(latitude);
    const lng = Number(longitude);
    const radius = Number(serviceRadiusKm || 15);
    if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
      return res.status(400).json({ error: "Valid garage latitude is required" });
    }
    if (!Number.isFinite(lng) || lng < -180 || lng > 180) {
      return res.status(400).json({ error: "Valid garage longitude is required" });
    }
    if (!Number.isFinite(radius) || radius < 1 || radius > 200) {
      return res.status(400).json({ error: "Service radius must be between 1 and 200 km" });
    }

    const hashed = await bcrypt.hash(password, 10);
    const garageUser = await User.create({
      name: String(name).trim(),
      email: String(email).toLowerCase().trim(),
      password: hashed,
      role: "garage",
      garageProfile: {
        garageName: String(garageName).trim(),
        garageAddress: String(garageAddress).trim(),
        location: {
          latitude: lat,
          longitude: lng
        },
        serviceRadiusKm: radius,
        isAvailable: true
      }
    });

    return res.status(201).json({
      message: "Garage account created",
      garage: {
        id: garageUser._id,
        name: garageUser.name,
        email: garageUser.email,
        role: garageUser.role,
        garageProfile: garageUser.garageProfile
      }
    });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({ error: "Email already registered" });
    }
    return res.status(500).json({ error: "Failed to create garage account" });
  }
};

export const googleLogin = async (req, res) => {
  try {
    const { credential } = req.body;
    if (!credential) {
      return res.status(400).json({ error: "Google credential is required" });
    }

    const ticket = await googleClient.verifyIdToken({
      idToken: credential,
      audience: process.env.GOOGLE_CLIENT_ID
    });
    const payload = ticket.getPayload();
    if (!payload?.email) {
      return res.status(400).json({ error: "Invalid Google token payload" });
    }

    let user = await User.findOne({ email: payload.email });
    if (!user) {
      user = await User.create({
        name: payload.name || payload.email.split("@")[0],
        email: payload.email,
        googleId: payload.sub,
        authProvider: "google",
        avatar: payload.picture || ""
      });
    } else {
      user.googleId = user.googleId || payload.sub;
      user.authProvider = user.authProvider || "google";
      if (!user.avatar && payload.picture) user.avatar = payload.picture;
      await user.save();
    }

    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET
    );

    res.json({ token, role: user.role });
  } catch {
    res.status(401).json({ error: "Google authentication failed" });
  }
};

export const forgotPassword = async (req, res) => {
  try {
    const { email, newPassword } = req.body;
    if (!email || !newPassword) {
      return res.status(400).json({ error: "Email and new password are required" });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ error: "Password must be at least 6 characters" });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    user.password = await bcrypt.hash(newPassword, 10);
    await user.save();

    res.json({ message: "Password reset successful" });
  } catch {
    res.status(500).json({ error: "Password reset failed" });
  }
};

export const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select(
      "name email role avatar contactNumber deliveryAddress garageProfile"
    );
    if (!user) return res.status(404).json({ error: "User not found" });
    res.json(user);
  } catch {
    res.status(500).json({ error: "Failed to load profile" });
  }
};

export const updateProfile = async (req, res) => {
  try {
    const { name, avatar, contactNumber, deliveryAddress } = req.body;
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: "User not found" });

    if (typeof name === "string") {
      const trimmedName = name.trim();
      if (!trimmedName) {
        return res.status(400).json({ error: "Name cannot be empty" });
      }
      user.name = trimmedName;
    }

    if (typeof avatar === "string") {
      user.avatar = avatar;
    }

    if (typeof contactNumber === "string") {
      const trimmedContact = contactNumber.trim();
      if (trimmedContact && !/^[+\d\s\-()]{7,20}$/.test(trimmedContact)) {
        return res.status(400).json({ error: "Please enter a valid contact number" });
      }
      user.contactNumber = trimmedContact;
    }

    if (typeof deliveryAddress === "string") {
      user.deliveryAddress = deliveryAddress.trim();
    }

    await user.save();
    res.json({
      message: "Profile updated",
      user: {
        name: user.name,
        email: user.email,
        role: user.role,
        avatar: user.avatar,
        contactNumber: user.contactNumber || "",
        deliveryAddress: user.deliveryAddress || ""
      }
    });
  } catch {
    res.status(500).json({ error: "Failed to update profile" });
  }
};
