import rateLimit from "express-rate-limit";

const positiveInt = (value, fallback) => {
  const n = Number(value);
  return Number.isInteger(n) && n > 0 ? n : fallback;
};

const WINDOW_MS = positiveInt(process.env.RATE_WINDOW_MS, 15 * 60 * 1000);

const message = { error: "Too many requests. Please try again later." };

const limitFromEnv = (name, fallback) => (req, res) =>
  positiveInt(process.env[name], fallback);

/**
 * Applies to /auth endpoints (register, login, google, password reset).
 * Kept intentionally strict to slow down credential guessing / abuse.
 * Defaults can be overridden with AUTH_RATE_MAX / RATE_WINDOW_MS.
 */
export const authLimiter = rateLimit({
  windowMs: WINDOW_MS,
  max: limitFromEnv("AUTH_RATE_MAX", 20),
  standardHeaders: true,
  legacyHeaders: false,
  message,
});

/** Generous global limit for the rest of the API. */
export const apiLimiter = rateLimit({
  windowMs: WINDOW_MS,
  max: limitFromEnv("API_RATE_MAX", 300),
  standardHeaders: true,
  legacyHeaders: false,
  message,
});