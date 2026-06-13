import { Navigate } from "react-router-dom";
import { jwtDecode } from "jwt-decode";

export default function GarageRoute({ children }) {
  const token = localStorage.getItem("token");
  if (!token) return <Navigate to="/" />;

  try {
    const decoded = jwtDecode(token);
    return decoded.role === "garage" ? children : <Navigate to="/" />;
  } catch {
    return <Navigate to="/" />;
  }
}
