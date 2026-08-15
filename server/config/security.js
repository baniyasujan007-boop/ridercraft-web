import cors from "cors";

const toOrigins = (value) =>
  String(value || "")
    .split(",")
    .map((entry) => entry.trim())
    .filter(Boolean);

/**
 * Builds the allowlist of origins allowed to call the API.
 *
 * - Reads FRONTEND_URL and CLIENT_URL from the environment (comma-separated
 *   lists allowed). These are the only ways production origins get in.
 * - Development origins are allowed only when explicitly configured through
 *   the same env vars (or ALLOWED_ORIGINS). Nothing is auto-allowed.
 * - The same-origin / non-browser case (no Origin header at all — Flutter
 *   native, server-to-server, curl) is always permitted by the origin
 *   callback, which is what keeps the mobile API working.
 */
export function allowedOrigins() {
  const origins = new Set([
    ...toOrigins(process.env.FRONTEND_URL),
    ...toOrigins(process.env.CLIENT_URL),
    ...toOrigins(process.env.ALLOWED_ORIGINS),
  ]);
  return [...origins];
}

/**
 * CORS options used by the app. Never uses "*" when a request carries
 * credentials, and never echoes a disallowed Origin.
 */
export function corsOptions() {
  const allowlist = allowedOrigins();

  if (allowlist.length === 0 && process.env.NODE_ENV !== "test") {
    console.warn(
      "[security] No ALLOWED_ORIGINS/FRONTEND_URL/CLIENT_URL configured; " +
        "cross-origin browser requests will be denied."
    );
  }

  return cors({
    origin(origin, callback) {
      // Non-browser / same-origin requests carry no Origin header and do not
      // need CORS headers; let them through without echoing anything.
      if (!origin || allowlist.includes(origin)) {
        return callback(null, origin === undefined ? false : origin);
      }
      // Reject untrusted origins: no Access-Control-Allow-Origin header is
      // sent, so browsers will block the response.
      return callback(null, false);
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
    optionsSuccessStatus: 204,
  });
}