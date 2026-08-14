import { useState } from "react";
import axios from "axios";
import { Link } from "react-router-dom";
import { toast } from "react-toastify";
import PremiumAuthShell, {
  PremiumAuthInput,
  PremiumStatus,
} from "../components/PremiumAuthShell";

export default function ForgotPassword() {
  const [form, setForm] = useState({ email: "" });
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState("");
  const [error, setError] = useState("");

  const validateEmail = (email) => {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  };

  const submit = async (event) => {
    event.preventDefault();
    setStatus("");
    setError("");

    if (!form.email) {
      setError("Email is required");
      return;
    }

    if (!validateEmail(form.email)) {
      setError("Invalid email format");
      return;
    }

    try {
      setLoading(true);

      const res = await axios.post(
        "https://ridercraft-api.onrender.com/auth/forgot-password",
        { email: form.email }
      );

      const message = res.data.message;
      setStatus(message);
      toast.success(message);
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
        <p>Enter the email associated with your RiderCraft account and we will send you a reset link.</p>
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

        <PremiumStatus type="error">{error}</PremiumStatus>
        <PremiumStatus type="success">{status}</PremiumStatus>

        <button className="premium-login__primary-button" type="submit" disabled={loading}>
          <span>{loading ? "Sending..." : "Send Reset Link"}</span>
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