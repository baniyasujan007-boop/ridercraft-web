import { useState } from "react";
import axios from "axios";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { toast } from "react-toastify";
import PremiumAuthShell, {
  PremiumAuthInput,
  PremiumStatus,
} from "../components/PremiumAuthShell";

export default function ResetPassword() {
  const [searchParams] = useSearchParams();
  const token = searchParams.get("token") || "";
  const email = searchParams.get("email") || "";
  const navigate = useNavigate();

  const [form, setForm] = useState({
    newPassword: "",
    confirmPassword: "",
  });
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState("");
  const [error, setError] = useState("");

  const submit = async (event) => {
    event.preventDefault();
    setStatus("");
    setError("");

    if (!token) {
      setError("This reset link is missing a token.");
      return;
    }

    if (!form.newPassword || !form.confirmPassword) {
      setError("All fields are required");
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
        "https://ridercraft-api.onrender.com/auth/reset-password",
        {
          email,
          token,
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
    <section className="premium-login__card premium-login__card--auth" aria-labelledby="reset-password-title">
      <div className="premium-login__card-header">
        <p className="premium-login__eyebrow">Rider account</p>
        <h2 id="reset-password-title">Set a New Password</h2>
        <p>Choose a new password for your RiderCraft account.</p>
      </div>

      <form className="premium-login__form" onSubmit={submit}>
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
          placeholder="Confirm your new password"
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
          <span>Changed your mind?</span>
          <Link to="/">Login</Link>
        </div>
      </form>
    </section>
  );

  return (
    <PremiumAuthShell
      label="reset-password"
      title={<>Reset Your<br />RiderCraft Account</>}
      subtitle="Choose a new password for your RiderCraft account."
      card={card}
    />
  );
}