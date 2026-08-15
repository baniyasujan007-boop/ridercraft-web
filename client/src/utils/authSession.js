import { jwtDecode } from "jwt-decode";

/**
 * Returns the decoded JWT only when a token exists, is well-formed, and has
 * not expired. Clears expired/malformed tokens from localStorage so the next
 * navigation is treated as logged out.
 */
export function getActiveSession() {
  const token = localStorage.getItem("token");
  if (!token) return null;

  try {
    const decoded = jwtDecode(token);
    if (decoded && Number.isFinite(decoded.exp) && Date.now() >= decoded.exp * 1000) {
      localStorage.removeItem("token");
      return null;
    }
    return decoded;
  } catch {
    localStorage.removeItem("token");
    return null;
  }
}