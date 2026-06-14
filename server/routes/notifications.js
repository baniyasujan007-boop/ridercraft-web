import express from "express";
import Notification from "../models/Notification.js";
import authMiddleware from "../middleware/authMiddleware.js";

const router = express.Router();

router.get("/", authMiddleware, async (req, res) => {
  try {
    console.log("Logged in user:", req.user.id);

    const notifications = await Notification
      .find({ userId: req.user.id })
      .sort({ createdAt: -1 });

    console.log(
      "Notifications found:",
      notifications.length
    );

    res.json(notifications);
  } catch (err) {
    res.status(500).json({
      error: "Failed to load notifications"
    });
  }
});

router.put("/read-all", authMiddleware, async (req, res) => {
  try {
    await Notification.updateMany(
      {
        userId: req.user.id,
        isRead: false
      },
      {
        $set: {
          isRead: true
        }
      }
    );

    res.json({
      success: true
    });
  } catch (err) {
    res.status(500).json({
      error: "Failed to mark notifications"
    });
  }
});

router.put("/:id/read", authMiddleware, async (req, res) => {
  try {
    await Notification.findByIdAndUpdate(
      req.params.id,
      {
        isRead: true
      }
    );

    res.json({
      success: true
    });
  } catch (err) {
    res.status(500).json({
      error: "Failed"
    });
  }
});


export default router;