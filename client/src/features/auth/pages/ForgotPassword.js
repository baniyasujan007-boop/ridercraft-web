import { useState } from "react";
import axios from "axios";
import { Link, useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import AuthLayout from "../components/AuthLayout";
import AuthInput from "../components/AuthInput";

export default function ForgotPassword() {
  const [form, setForm] = useState({
    email: "",
    newPassword: "",
    confirmPassword: "",
  });

  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const validateEmail = (email) => {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  };

  const submit = async () => {
    if (!form.email || !form.newPassword || !form.confirmPassword) {
      return toast.error("All fields are required");
    }

    if (!validateEmail(form.email)) {
      return toast.error("Invalid email format");
    }

    if (form.newPassword.length < 6) {
      return toast.error("Password must be at least 6 characters");
    }

    if (form.newPassword !== form.confirmPassword) {
      return toast.error("Passwords do not match");
    }

    try {
      setLoading(true);

      const res = await axios.post(
        "https://ridercraft-api.onrender.com/auth/forgot-password",
        {
          email: form.email,
          newPassword: form.newPassword,
        }
      );

      toast.success(res.data.message || "Password reset successful");

      setTimeout(() => navigate("/"), 1500);
    } catch (err) {
      toast.error(
        err.response?.data?.error || "Password reset failed"
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthLayout type="login">
      <h2>Reset Password</h2>

      <AuthInput
        placeholder="Email"
        value={form.email}
        onChange={(e) =>
          setForm({ ...form, email: e.target.value })
        }
      />

      <AuthInput
        placeholder="New Password"
        value={form.newPassword}
        onChange={(e) =>
          setForm({ ...form, newPassword: e.target.value })
        }
        isPassword
      />

      <AuthInput
        placeholder="Confirm Password"
        value={form.confirmPassword}
        onChange={(e) =>
          setForm({ ...form, confirmPassword: e.target.value })
        }
        isPassword
      />

      <button
        className="primary-btn"
        onClick={submit}
        disabled={loading}
      >
        {loading ? "Processing..." : "Reset Password"}
      </button>

      <p>
        Back to <Link to="/">Login</Link>
      </p>
    </AuthLayout>
  );
}
