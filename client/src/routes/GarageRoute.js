import { Navigate } from "react-router-dom";
import { getActiveSession } from "../utils/authSession";

export default function GarageRoute({ children }) {
  const decoded = getActiveSession();
  if (!decoded) return <Navigate to="/" />;
  return decoded.role === "garage" ? children : <Navigate to="/" />;
}