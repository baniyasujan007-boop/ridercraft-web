import { Navigate } from "react-router-dom";
import { jwtDecode } from "jwt-decode";

export default function AdminRoute({ children }) {
  const token = localStorage.getItem("token");
  if (!token) return <Navigate to="/" />;

  try {
    const decoded = jwtDecode(token);
    if (decoded.role === "admin") return children;
    if (decoded.role === "garage") return <Navigate to="/garage" />;
    return <Navigate to="/landing" />;
  } catch {
    return <Navigate to="/" />;
  }
}
