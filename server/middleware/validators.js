import mongoose from "mongoose";

/**
 * Rejects routes with a malformed :id so controllers never have to handle
 * Mongoose CastErrors for invalid ObjectIds.
 */
export function requireValidObjectId(req, res, next) {
  const { id } = req.params;
  if (!id || !mongoose.isValidObjectId(id)) {
    return res.status(400).json({ error: "Invalid resource id" });
  }
  next();
}