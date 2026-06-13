import { useState } from "react";
import axios from "axios";
import { Link, useNavigate } from "react-router-dom";
import AuthLayout from "../../components/layout/AuthLayout";

export default function GarageLogin() {
  const [form, setForm] = useState({ email: "", password: "" });
  const [error, setError] = useState("");
  const navigate = useNavigate();

  const submit = async () => {
    setError("");
    try {
      const res = await axios.post("https://ridercraft-api.onrender.com/auth/garage/login", form);
      localStorage.setItem("token", res.data.token);
      navigate("/garage");
    } catch (err) {
      setError(err.response?.data?.error || "Garage login failed");
    }
  };

  return (
    <AuthLayout type="login">
      <h2>Garage Partner Login</h2>

      <input
        placeholder="Garage email"
        value={form.email}
        onChange={(e) => setForm({ ...form, email: e.target.value })}
      />

      <input
        type="password"
        placeholder="Password"
        value={form.password}
        onChange={(e) => setForm({ ...form, password: e.target.value })}
      />

      {error && <div className="error">{error}</div>}

      <button className="primary-btn" onClick={submit}>
        Sign In as Garage
      </button>

      <Link to="/" className="link">
        Back to customer login
      </Link>
      <Link to="/garage-signup" className="link">
        New garage partner? Sign up
      </Link>
    </AuthLayout>
  );
}
