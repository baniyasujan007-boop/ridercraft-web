import express from "express";
import {
  forgotPassword,
  getProfile,
  googleLogin,
  login,
  registerGarage,
  register,
  updateProfile
} from "../controllers/authController.js";
import authMiddleware, { requireAdmin } from "../middleware/authMiddleware.js";

const router = express.Router();
router.post("/register", register);
router.post("/login", login);
router.post("/garage/register", authMiddleware, requireAdmin, registerGarage);
router.post("/google", googleLogin);
router.post("/forgot-password", forgotPassword);
router.get("/profile", authMiddleware, getProfile);
router.put("/profile", authMiddleware, updateProfile);

export default router;
