import { useState } from "react";
import axios from "axios";
import { useNavigate, Link } from "react-router-dom";
import AuthLayout from "../../components/layout/AuthLayout";
import GoogleAuthButton from "../../components/layout/GoogleAuthButton";

export default function Login() {
  const [form, setForm] = useState({ email: "", password: "" });
  const [error, setError] = useState("");
  const navigate = useNavigate();

  const submit = async () => {
    try {
      const res = await axios.post(
        "https://ridercraft-api.onrender.com/auth/login",
        form
      );

      localStorage.setItem("token", res.data.token);
      const role = String(res.data?.role || "").toLowerCase();
      if (role === "admin") {
        navigate("/admin");
        return;
      }
      if (role === "garage") {
        navigate("/garage");
        return;
      }
      navigate("/landing");
    } catch (err) {
      setError(err.response?.data?.error || "Login failed");
    }
  };

  return (
    <AuthLayout type="login">
      <h2>Sign In to RiderCraft</h2>

      <input
        placeholder="Email"
        value={form.email}
        onChange={(e) =>
          setForm({ ...form, email: e.target.value })
        }
      />

      <input
        type="password"
        placeholder="Password"
        value={form.password}
        onChange={(e) =>
          setForm({ ...form, password: e.target.value })
        }
      />

      {error && <div className="error">{error}</div>}

      <button className="primary-btn" onClick={submit}>
        Sign In
      </button>

      <div className="oauth-divider">or</div>
      <GoogleAuthButton
        label="signin_with"
        onSuccess={(data) => {
          localStorage.setItem("token", data.token);
          const role = String(data?.role || "").toLowerCase();
          if (role === "admin") {
            navigate("/admin");
            return;
          }
          if (role === "garage") {
            navigate("/garage");
            return;
          }
          navigate("/landing");
        }}
        onError={(msg) => setError(msg)}
      />

      <Link to="/forgot-password" className="link">
        Forgot your password?
      </Link>
    </AuthLayout>
  );
}
