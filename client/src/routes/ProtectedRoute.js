import { Navigate } from "react-router-dom";
import { getActiveSession } from "../utils/authSession";

export default function ProtectedRoute({ children }) {
  const decoded = getActiveSession();
  if (!decoded) return <Navigate to="/" />;
  if (decoded.role === "garage") return <Navigate to="/garage" />;
  return children;
}