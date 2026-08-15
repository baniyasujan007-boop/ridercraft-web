import jwt from "jsonwebtoken";

export default function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization || "";
  const token = authHeader.startsWith("Bearer ")
    ? authHeader.split(" ")[1]
    : null;

  if (!token) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET, {
      algorithms: ["HS256"]
    });
    req.user = decoded;
    next();
  } catch (err) {
    if (err?.name === "TokenExpiredError") {
      console.log("JWT Error: token expired");
      return res.status(401).json({ error: "Session expired" });
    }
    console.log("JWT Error:", err.message);
    return res.status(401).json({
      error: "Invalid token"
    });
  }
}

export function requireAdmin(req, res, next) {
  if (req.user?.role !== "admin") {
    return res.status(403).json({ error: "Admin access required" });
  }
  next();
}

export function requireGarage(req, res, next) {
  if (req.user?.role !== "garage") {
    return res.status(403).json({ error: "Garage access required" });
  }
  next();
}
