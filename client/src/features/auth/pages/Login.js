import axios from "axios";
import { useCallback, useId, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import ridercraftLogo from "../../../assets/ridercraft-logo.png";
import heroImage from "../../../assets/ridercraft-premium-login-hero.png";
import GoogleAuthButton from "../components/GoogleAuthButton";
import "../styles/premium-login-prototype.css";

const navItems = ["Helmets", "Riding Gear", "Bike Service", "Accessories"];

const trustBadges = [
  "Genuine Products",
  "Fast Delivery",
  "Secure Payments",
];

const featureCards = [
  {
    title: "100% Genuine Products",
    description: "Certified helmets, jackets, gloves, and parts selected for serious riders.",
    icon: (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M12 3 5 6v5c0 4.6 2.9 8.6 7 10 4.1-1.4 7-5.4 7-10V6l-7-3Z" />
        <path d="m9 12 2 2 4-5" />
      </svg>
    ),
  },
  {
    title: "Expert Bike Servicing",
    description: "Book trusted service support from trained garage partners.",
    icon: (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="m14.7 6.3 3-3a5 5 0 0 1-6.4 6.4L5.8 15.2a2.5 2.5 0 1 0 3.5 3.5l5.4-5.4a5 5 0 0 1 6.4-6.4l-3 3-3.4-3.4Z" />
      </svg>
    ),
  },
  {
    title: "Fast Delivery",
    description: "Priority dispatch for riding essentials, daily gear, and service spares.",
    icon: (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M3 7h11v9H3z" />
        <path d="M14 10h3l4 4v2h-7z" />
        <circle cx="7" cy="18" r="2" />
        <circle cx="17" cy="18" r="2" />
      </svg>
    ),
  },
  {
    title: "Secure Checkout",
    description: "Protected payments and account access built for confident shopping.",
    icon: (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <rect x="5" y="10" width="14" height="10" rx="2" />
        <path d="M8 10V7a4 4 0 0 1 8 0v3" />
        <path d="M12 14v2" />
      </svg>
    ),
  },
];

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

function PremiumIcon({ type }) {
  const paths = {
    mail: (
      <>
        <rect x="3" y="5" width="18" height="14" rx="2" />
        <path d="m4 7 8 6 8-6" />
      </>
    ),
    lock: (
      <>
        <rect x="5" y="10" width="14" height="10" rx="2" />
        <path d="M8 10V7a4 4 0 0 1 8 0v3" />
      </>
    ),
    eye: (
      <>
        <path d="M2.5 12s3.5-6 9.5-6 9.5 6 9.5 6-3.5 6-9.5 6-9.5-6-9.5-6Z" />
        <circle cx="12" cy="12" r="3" />
      </>
    ),
    eyeOff: (
      <>
        <path d="m3 3 18 18" />
        <path d="M10.6 10.6A3 3 0 0 0 13.4 13.4" />
        <path d="M9.2 5.4A10.9 10.9 0 0 1 12 5c6 0 9.5 7 9.5 7a16.8 16.8 0 0 1-2.8 3.7" />
        <path d="M6.1 6.6C3.8 8.2 2.5 12 2.5 12s3.5 7 9.5 7c1.5 0 2.9-.4 4.1-1" />
      </>
    ),
    google: (
      <>
        <path d="M20.5 12.2c0-.7-.1-1.3-.2-1.9H12v3.6h4.8a4.1 4.1 0 0 1-1.8 2.7v2.2h2.9a8.7 8.7 0 0 0 2.6-6.6Z" />
        <path d="M12 21a8.5 8.5 0 0 0 5.9-2.2L15 16.6a5.4 5.4 0 0 1-8-2.8H4v2.3A9 9 0 0 0 12 21Z" />
        <path d="M7 13.8a5.4 5.4 0 0 1 0-3.6V7.9H4a9 9 0 0 0 0 8.2l3-2.3Z" />
        <path d="M12 6.6c1.3 0 2.5.5 3.4 1.3L18 5.4A8.8 8.8 0 0 0 12 3a9 9 0 0 0-8 4.9l3 2.3a5.4 5.4 0 0 1 5-3.6Z" />
      </>
    ),
  };

  return (
    <svg className="premium-login__icon" viewBox="0 0 24 24" aria-hidden="true">
      {paths[type]}
    </svg>
  );
}

function StatusMessage({ type, children }) {
  if (!children) {
    return null;
  }

  return (
    <div className={`premium-login__status premium-login__status--${type}`} role="status">
      {children}
    </div>
  );
}

function LoginField({ icon, label, type = "text", value, onChange, trailing }) {
  const fieldId = useId();

  return (
    <label className="premium-login__field" htmlFor={fieldId}>
      <span className="premium-login__field-label">{label}</span>
      <span className="premium-login__field-shell">
        <PremiumIcon type={icon} />
        <input
          id={fieldId}
          type={type}
          value={value}
          onChange={onChange}
          placeholder={label}
          autoComplete={type === "password" ? "current-password" : "email"}
          required
        />
        {trailing}
      </span>
    </label>
  );
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
        <p>Sign in to manage orders, service bookings, and riding essentials.</p>
      </div>

      <form className="premium-login__form" onSubmit={handleSubmit}>
        <LoginField
          icon="mail"
          label="Email"
          value={form.email}
          onChange={(event) => setForm({ ...form, email: event.target.value })}
        />

        <LoginField
          icon="lock"
          label="Password"
          type={showPassword ? "text" : "password"}
          value={form.password}
          onChange={(event) => setForm({ ...form, password: event.target.value })}
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

        <StatusMessage type="error">{error}</StatusMessage>
        <StatusMessage type="success">{success}</StatusMessage>

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

function PremiumHeader() {
  return (
    <header className="premium-login__header">
      <div className="premium-login__shipping-bar">
        <span>Free shipping on premium riding gear orders above Rs. 4999</span>
        <span>Service bookings now open in select cities</span>
      </div>
      <nav className="premium-login__nav" aria-label="Premium login navigation">
        <Link className="premium-login__brand" to="/landing" aria-label="RiderCraft home">
          <img src={ridercraftLogo} alt="" />
          <span>RiderCraft</span>
        </Link>
        <div className="premium-login__nav-links">
          {navItems.map((item) => (
            <a href="#premium-login-features" key={item}>
              {item}
            </a>
          ))}
        </div>
      </nav>
    </header>
  );
}

function PremiumHero({ onEmailLogin, onGoogleSuccess, onGoogleError }) {
  return (
    <main className="premium-login__hero">
      <div className="premium-login__hero-media" aria-hidden="true">
        <img src={heroImage} alt="" />
      </div>
      <div className="premium-login__hero-overlay" />
      <div className="premium-login__hero-content">
        <section className="premium-login__copy" aria-labelledby="premium-login-hero-title">
          <p className="premium-login__eyebrow">Premium rider access</p>
          <h1 id="premium-login-hero-title">
            <span>Welcome Back To</span>
            RiderCraft
          </h1>
          <p>
            Continue your riding journey with premium helmets, riding gear and bike services.
          </p>
          <div className="premium-login__trust-list" aria-label="RiderCraft trust badges">
            {trustBadges.map((badge) => (
              <span key={badge}>
                <svg viewBox="0 0 24 24" aria-hidden="true">
                  <path d="m5 12 4 4L19 6" />
                </svg>
                {badge}
              </span>
            ))}
          </div>
        </section>
        <LoginCard
          onEmailLogin={onEmailLogin}
          onGoogleSuccess={onGoogleSuccess}
          onGoogleError={onGoogleError}
        />
      </div>
    </main>
  );
}

function PremiumFeatures() {
  return (
    <section className="premium-login__features" id="premium-login-features" aria-labelledby="premium-features-title">
      <div className="premium-login__section-heading">
        <p className="premium-login__eyebrow">Built for every ride</p>
        <h2 id="premium-features-title">Premium RiderCraft Features</h2>
      </div>
      <div className="premium-login__feature-grid">
        {featureCards.map((feature) => (
          <article className="premium-login__feature-card" key={feature.title}>
            <div className="premium-login__feature-icon">{feature.icon}</div>
            <h3>{feature.title}</h3>
            <p>{feature.description}</p>
          </article>
        ))}
      </div>
    </section>
  );
}

function PremiumFooter() {
  return (
    <footer className="premium-login__footer">
      <Link className="premium-login__footer-brand" to="/landing">
        <img src={ridercraftLogo} alt="" />
        <span>RiderCraft</span>
      </Link>
      <p>Premium gear, verified service, and secure shopping for riders.</p>
      <div className="premium-login__footer-links">
        <a href="#premium-login-features">Features</a>
        <Link to="/forgot-password">Support</Link>
        <Link to="/register">Create Account</Link>
      </div>
    </footer>
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
    <div className="premium-login">
      <PremiumHeader />
      <PremiumHero
        onEmailLogin={handleEmailLogin}
        onGoogleSuccess={completeLogin}
      />
      <PremiumFeatures />
      <PremiumFooter />
    </div>
  );
}
