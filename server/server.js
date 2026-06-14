import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import connectDB from "./config/db.js";
import authRoutes from "./routes/authRoutes.js";
import productRoutes from "./routes/productRoutes.js";
import promoRoutes from "./routes/promoRoutes.js";
import orderRoutes from "./routes/orderRoutes.js";
import heroOfferRoutes from "./routes/heroOfferRoutes.js";
import featuredSectionRoutes from "./routes/featuredSectionRoutes.js";
import serviceRequestRoutes from "./routes/serviceRequestRoutes.js";
import notificationRoutes from "./routes/notifications.js";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({ limit: "5mb" }));

connectDB();

app.use("/auth", authRoutes);
app.use("/products", productRoutes);
app.use("/promos", promoRoutes);
app.use("/orders", orderRoutes);
app.use("/hero-offers", heroOfferRoutes);
app.use("/featured-sections", featuredSectionRoutes);
app.use("/service-requests", serviceRequestRoutes);
app.use(
  "/notifications",
  notificationRoutes
);

const PORT = process.env.PORT || 5001;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
