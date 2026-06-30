import { useState } from "react";
import axios from "axios";
import { Link, useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import PremiumAuthShell, {
  PremiumAuthInput,
  PremiumStatus,
} from "../components/PremiumAuthShell";

export default function ForgotPassword() {
  const [form, setForm] = useState({
    email: "",
    newPassword: "",
    confirmPassword: "",
  });
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState("");
  const [error, setError] = useState("");
  const navigate = useNavigate();

  const validateEmail = (email) => {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  };

  const submit = async (event) => {
    event.preventDefault();
    setStatus("");
    setError("");

    if (!form.email || !form.newPassword || !form.confirmPassword) {
      setError("All fields are required");
      return;
    }

    if (!validateEmail(form.email)) {
      setError("Invalid email format");
      return;
    }

    if (form.newPassword.length < 6) {
      setError("Password must be at least 6 characters");
      return;
    }

    if (form.newPassword !== form.confirmPassword) {
      setError("Passwords do not match");
      return;
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

      const message = res.data.message || "Password reset successful";
      setStatus(message);
      toast.success(message);

      setTimeout(() => navigate("/"), 1500);
    } catch (err) {
      const message = err.response?.data?.error || "Password reset failed";
      setError(message);
      toast.error(message);
    } finally {
      setLoading(false);
    }
  };

  const card = (
    <section className="premium-login__card premium-login__card--auth" aria-labelledby="forgot-password-title">
      <div className="premium-login__card-header">
        <p className="premium-login__eyebrow">Rider account</p>
        <h2 id="forgot-password-title">Forgot Password</h2>
        <p>Enter the email associated with your RiderCraft account and set a new password.</p>
      </div>

      <form className="premium-login__form" onSubmit={submit}>
        <PremiumAuthInput
          icon="mail"
          label="Email Address"
          placeholder="Enter your email"
          value={form.email}
          onChange={(event) => setForm({ ...form, email: event.target.value })}
          autoComplete="email"
        />
        <PremiumAuthInput
          icon="lock"
          label="New Password"
          placeholder="Enter your new password"
          type="password"
          value={form.newPassword}
          onChange={(event) => setForm({ ...form, newPassword: event.target.value })}
          autoComplete="new-password"
        />
        <PremiumAuthInput
          icon="lock"
          label="Confirm Password"
          placeholder="Confirm your password"
          type="password"
          value={form.confirmPassword}
          onChange={(event) => setForm({ ...form, confirmPassword: event.target.value })}
          autoComplete="new-password"
        />

        <PremiumStatus type="error">{error}</PremiumStatus>
        <PremiumStatus type="success">{status}</PremiumStatus>

        <button className="premium-login__primary-button" type="submit" disabled={loading}>
          <span>{loading ? "Processing..." : "Reset Password"}</span>
        </button>

        <div className="premium-login__signup premium-login__signup--center">
          <span>Remember your password?</span>
          <Link to="/">Login</Link>
        </div>
      </form>
    </section>
  );

  return (
    <PremiumAuthShell
      label="forgot-password"
      title={<>Reset Your<br />RiderCraft Account</>}
      subtitle="Enter the email associated with your RiderCraft account."
      card={card}
    />
  );
}
