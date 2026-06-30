import axios from "axios";
import { useCallback, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import GoogleAuthButton from "../components/GoogleAuthButton";
import PremiumAuthShell, {
  PremiumAuthInput,
  PremiumIcon,
  PremiumStatus,
} from "../components/PremiumAuthShell";

function getDashboardPath(role) {
  const normalizedRole = String(role || "").toLowerCase();

  if (normalizedRole === "admin") {
    return "/admin";
  }

  if (normalizedRole === "garage") {
    return "/garage";
  }

  return "/landing";
}

function LoginCard({ onEmailLogin, onGoogleSuccess, onGoogleError }) {
  const [form, setForm] = useState({ email: "", password: "", remember: true });
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const handleSubmit = async (event) => {
    event.preventDefault();
    setError("");
    setSuccess("");

    if (!form.email || !form.password) {
      setError("Enter your email and password to continue.");
      return;
    }

    setIsLoading(true);
    try {
      await onEmailLogin({ email: form.email, password: form.password });
      setSuccess("Login successful. Redirecting...");
    } catch (err) {
      setError(err?.response?.data?.error || err?.message || "Login failed");
    } finally {
      setIsLoading(false);
    }
  };

  const handleGoogleError = (message) => {
    setSuccess("");
    setError(message);
    onGoogleError?.(message);
  };

  return (
    <section className="premium-login__card" aria-labelledby="premium-login-title">
      <div className="premium-login__card-header">
        <p className="premium-login__eyebrow">Rider account</p>
        <h2 id="premium-login-title">Welcome Back</h2>
        <p>Sign in to continue with your RiderCraft account.</p>
      </div>

      <form className="premium-login__form" onSubmit={handleSubmit}>
        <PremiumAuthInput
          icon="mail"
          label="Email"
          placeholder="Enter your email"
          value={form.email}
          onChange={(event) => setForm({ ...form, email: event.target.value })}
          autoComplete="email"
        />

        <PremiumAuthInput
          icon="lock"
          label="Password"
          placeholder="Enter your password"
          type={showPassword ? "text" : "password"}
          value={form.password}
          onChange={(event) => setForm({ ...form, password: event.target.value })}
          autoComplete="current-password"
          trailing={
            <button
              className="premium-login__icon-button"
              type="button"
              aria-label={showPassword ? "Hide password" : "Show password"}
              onClick={() => setShowPassword((current) => !current)}
            >
              <PremiumIcon type={showPassword ? "eyeOff" : "eye"} />
            </button>
          }
        />

        <div className="premium-login__form-row">
          <label className="premium-login__check">
            <input
              type="checkbox"
              checked={form.remember}
              onChange={(event) => setForm({ ...form, remember: event.target.checked })}
            />
            <span>Remember Me</span>
          </label>
          <Link to="/forgot-password">Forgot Password</Link>
        </div>

        <PremiumStatus type="error">{error}</PremiumStatus>
        <PremiumStatus type="success">{success}</PremiumStatus>

        <button className="premium-login__primary-button" type="submit" disabled={isLoading}>
          <span>{isLoading ? "Signing In..." : "Login"}</span>
        </button>

        <div className="premium-login__divider"><span>or continue with</span></div>

        <div className="premium-login__social-grid">
          <div className="premium-login__google-auth">
            <GoogleAuthButton
              label="signin_with"
              onSuccess={onGoogleSuccess}
              onError={handleGoogleError}
            />
          </div>
        </div>

        <div className="premium-login__signup">
          <span>Don't have an account?</span>
          <Link to="/register">Create Account</Link>
        </div>
      </form>
    </section>
  );
}

export default function Login() {
  const navigate = useNavigate();

  const completeLogin = useCallback((data) => {
    localStorage.setItem("token", data.token);
    navigate(getDashboardPath(data?.role));
  }, [navigate]);

  const handleEmailLogin = useCallback(async (form) => {
    const res = await axios.post(
      "https://ridercraft-api.onrender.com/auth/login",
      form
    );

    completeLogin(res.data);
  }, [completeLogin]);

  return (
    <PremiumAuthShell
      label="login"
      eyebrow="RiderCraft account"
      title={<>Welcome Back To<br />RiderCraft</>}
      subtitle="Access your RiderCraft account to manage orders, service requests, and account details."
      card={
        <LoginCard
          onEmailLogin={handleEmailLogin}
          onGoogleSuccess={completeLogin}
        />
      }
    />
  );
}
