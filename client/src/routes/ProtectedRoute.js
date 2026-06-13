import { Navigate } from "react-router-dom";
import { jwtDecode } from "jwt-decode";

export default function ProtectedRoute({ children }) {
  const token = localStorage.getItem("token");
  if (!token) return <Navigate to="/" />;

  try {
    const decoded = jwtDecode(token);
    if (decoded.role === "garage") return <Navigate to="/garage" />;
    return children;
  } catch {
    return <Navigate to="/" />;
  }
}
