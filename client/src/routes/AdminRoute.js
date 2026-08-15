import { Navigate } from "react-router-dom";
import { getActiveSession } from "../utils/authSession";

export default function AdminRoute({ children }) {
  const decoded = getActiveSession();
  if (!decoded) return <Navigate to="/" />;
  if (decoded.role === "admin") return children;
  if (decoded.role === "garage") return <Navigate to="/garage" />;
  return <Navigate to="/landing" />;
}