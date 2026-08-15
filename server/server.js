import express from "express";
import helmet from "helmet";
import dotenv from "dotenv";
import connectDB from "./config/db.js";
import { corsOptions } from "./config/security.js";
import { apiLimiter, authLimiter } from "./middleware/rateLimit.js";
import { errorHandler, notFoundHandler } from "./middleware/errorHandlers.js";
import authRoutes from "./routes/authRoutes.js";
import productRoutes from "./routes/productRoutes.js";
import promoRoutes from "./routes/promoRoutes.js";
import orderRoutes from "./routes/orderRoutes.js";
import heroOfferRoutes from "./routes/heroOfferRoutes.js";
import featuredSectionRoutes from "./routes/featuredSectionRoutes.js";
import serviceRequestRoutes from "./routes/serviceRequestRoutes.js";
import notificationRoutes from "./routes/notifications.js";
import wishlistRoutes from "./routes/wishlistRoutes.js";

dotenv.config();

if (process.env.NODE_ENV === "production" && !process.env.JWT_SECRET) {
  console.warn(
    "[security] JWT_SECRET is not set. Tokens will be signed with a missing " +
      "secret; authentication will fail. Set JWT_SECRET before deploying."
  );
}

const app = express();
app.disable("x-powered-by");
app.use(
  helmet({
    contentSecurityPolicy: false,
    crossOriginResourcePolicy: { policy: "cross-origin" },
  })
);
app.use(corsOptions());
app.use(apiLimiter);
app.use(express.json({ limit: "5mb" }));

connectDB();

app.use("/auth", authLimiter, authRoutes);
app.use("/products", productRoutes);
app.use("/promos", promoRoutes);
app.use("/orders", orderRoutes);
app.use("/hero-offers", heroOfferRoutes);
app.use("/featured-sections", featuredSectionRoutes);
app.use("/service-requests", serviceRequestRoutes);
app.use("/wishlist", wishlistRoutes);
app.use(
  "/notifications",
  notificationRoutes
);

app.use(notFoundHandler);
app.use(errorHandler);

const PORT = process.env.PORT || 5001;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
