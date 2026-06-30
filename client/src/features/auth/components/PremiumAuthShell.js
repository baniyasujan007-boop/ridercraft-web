import { useId } from "react";
import { Link } from "react-router-dom";
import ridercraftLogo from "../../../assets/ridercraft-logo.png";
import heroImage from "../../../assets/ridercraft-premium-login-hero.png";
import "../styles/premium-login-prototype.css";

const trustBadges = ["RiderCraft account", "Secure access", "Order management"];

export function PremiumIcon({ type }) {
  const paths = {
    user: (
      <>
        <circle cx="12" cy="8" r="4" />
        <path d="M4 21a8 8 0 0 1 16 0" />
      </>
    ),
    mail: (
      <>
        <rect x="3" y="5" width="18" height="14" rx="2" />
        <path d="m4 7 8 6 8-6" />
      </>
    ),
    phone: (
      <path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.4 19.4 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1.9.3 1.7.6 2.5a2 2 0 0 1-.5 2.1L8 9.5a16 16 0 0 0 6.5 6.5l1.2-1.2a2 2 0 0 1 2.1-.5c.8.3 1.6.5 2.5.6a2 2 0 0 1 1.7 2Z" />
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
    mapPin: (
      <>
        <path d="M20 10c0 5-8 12-8 12S4 15 4 10a8 8 0 1 1 16 0Z" />
        <circle cx="12" cy="10" r="3" />
      </>
    ),
    garage: (
      <>
        <path d="M3 21V9l9-6 9 6v12" />
        <path d="M8 21v-7h8v7" />
        <path d="M8 10h8" />
      </>
    ),
  };

  return (
    <svg className="premium-login__icon" viewBox="0 0 24 24" aria-hidden="true">
      {paths[type]}
    </svg>
  );
}

export function PremiumAuthInput({
  icon,
  label,
  placeholder,
  type = "text",
  value,
  onChange,
  trailing,
  autoComplete,
  required = true,
}) {
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
          placeholder={placeholder}
          autoComplete={autoComplete}
          required={required}
        />
        {trailing}
      </span>
    </label>
  );
}

export function PremiumStatus({ type, children }) {
  if (!children) {
    return null;
  }

  return (
    <div className={`premium-login__status premium-login__status--${type}`} role="status">
      {children}
    </div>
  );
}

function PremiumHeader({ label }) {
  return (
    <header className="premium-login__header">
      <nav className="premium-login__nav" aria-label={`${label} navigation`}>
        <Link className="premium-login__brand" to="/landing" aria-label="RiderCraft home">
          <img src={ridercraftLogo} alt="" />
          <span>RiderCraft</span>
        </Link>
      </nav>
    </header>
  );
}

function PremiumTrustBadges() {
  return (
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
  );
}

function PremiumFooter() {
  return (
    <footer className="premium-login__footer">
      <Link className="premium-login__footer-brand" to="/landing">
        <img src={ridercraftLogo} alt="" />
        <span>RiderCraft</span>
      </Link>
      <p>RiderCraft account access for riders.</p>
      <div className="premium-login__footer-links">
        <Link to="/forgot-password">Support</Link>
        <Link to="/register">Create Account</Link>
      </div>
    </footer>
  );
}

export default function PremiumAuthShell({
  eyebrow = "RiderCraft account",
  title,
  subtitle,
  card,
  label = "Premium auth",
}) {
  return (
    <div className="premium-login">
      <PremiumHeader label={label} />
      <main className="premium-login__hero premium-login__hero--auth-only">
        <div className="premium-login__hero-media" aria-hidden="true">
          <img src={heroImage} alt="" />
        </div>
        <div className="premium-login__hero-overlay" />
        <div className="premium-login__hero-content">
          <section className="premium-login__copy" aria-labelledby={`${label}-title`}>
            <p className="premium-login__eyebrow">{eyebrow}</p>
            <h1 id={`${label}-title`}>{title}</h1>
            <p>{subtitle}</p>
            <PremiumTrustBadges />
          </section>
          {card}
        </div>
      </main>
      <PremiumFooter />
    </div>
  );
}
