import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import GoogleAuthButton from "../components/GoogleAuthButton";
import PremiumAuthShell, {
  PremiumAuthInput,
  PremiumIcon,
  PremiumStatus,
} from "../components/PremiumAuthShell";
import api from "../../../services/api";

export default function Register() {
  const [form, setForm] = useState({
    role: "user",
    name: "",
    email: "",
    phone: "",
    password: "",
    confirmPassword: "",
    garageName: "",
    garageAddress: "",
    latitude: "",
    longitude: "",
    serviceRadiusKm: "15",
    terms: false,
  });
  const [error, setError] = useState("");
  const [locationLoading, setLocationLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const navigate = useNavigate();

  const updateForm = (field, value) => {
    setForm((current) => ({ ...current, [field]: value }));
  };

  const captureCurrentLocation = () => {
    setError("");
    if (!navigator.geolocation) {
      setError("Geolocation is not supported in this browser");
      return;
    }

    setLocationLoading(true);
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setForm((prev) => ({
          ...prev,
          latitude: String(Number(position.coords.latitude.toFixed(6))),
          longitude: String(Number(position.coords.longitude.toFixed(6))),
        }));
        setLocationLoading(false);
      },
      () => {
        setLocationLoading(false);
        setError("Could not capture current location");
      },
      { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 }
    );
  };

  const submit = async (event) => {
    event.preventDefault();

    try {
      setError("");

      if (!form.terms) {
        setError("Please agree to the Terms & Conditions");
        return;
      }

      if (form.password !== form.confirmPassword) {
        setError("Passwords do not match");
        return;
      }

      if (form.role === "garage" && (!form.latitude || !form.longitude)) {
        setError("Please capture exact map location for garage signup");
        return;
      }

      await api.post("auth/register", {
        role: form.role,
        name: form.name,
        email: form.email,
        phone: form.phone,
        password: form.password,
        garageName: form.garageName,
        garageAddress: form.garageAddress,
        latitude: Number(form.latitude),
        longitude: Number(form.longitude),
        serviceRadiusKm: Number(form.serviceRadiusKm || 15),
      });
      navigate("/");
    } catch (err) {
      setError(err.response?.data?.error || "Registration failed");
    }
  };

  const card = (
    <section className="premium-login__card premium-login__card--auth" aria-labelledby="register-title">
      <div className="premium-login__card-header">
        <p className="premium-login__eyebrow">Rider account</p>
        <h2 id="register-title">Create Account</h2>
        <p>Create your account and start your journey with premium riding gear.</p>
      </div>

      <form className="premium-login__form" onSubmit={submit}>
        <div className="premium-login__role-toggle" aria-label="Account type">
          <button
            type="button"
            className={form.role === "user" ? "is-active" : ""}
            onClick={() => updateForm("role", "user")}
          >
            Customer
          </button>
          <button
            type="button"
            className={form.role === "garage" ? "is-active" : ""}
            onClick={() => updateForm("role", "garage")}
          >
            Garage Partner
          </button>
        </div>

        <PremiumAuthInput
          icon="user"
          label={form.role === "garage" ? "Owner name" : "Full Name"}
          value={form.name}
          onChange={(event) => updateForm("name", event.target.value)}
          autoComplete="name"
        />
        <PremiumAuthInput
          icon="mail"
          label="Email Address"
          value={form.email}
          onChange={(event) => updateForm("email", event.target.value)}
          autoComplete="email"
        />
        <PremiumAuthInput
          icon="phone"
          label="Phone Number"
          value={form.phone}
          onChange={(event) => updateForm("phone", event.target.value)}
          autoComplete="tel"
          required={false}
        />
        <PremiumAuthInput
          icon="lock"
          label="Password"
          type={showPassword ? "text" : "password"}
          value={form.password}
          onChange={(event) => updateForm("password", event.target.value)}
          autoComplete="new-password"
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
        <PremiumAuthInput
          icon="lock"
          label="Confirm Password"
          type={showConfirmPassword ? "text" : "password"}
          value={form.confirmPassword}
          onChange={(event) => updateForm("confirmPassword", event.target.value)}
          autoComplete="new-password"
          trailing={
            <button
              className="premium-login__icon-button"
              type="button"
              aria-label={showConfirmPassword ? "Hide confirm password" : "Show confirm password"}
              onClick={() => setShowConfirmPassword((current) => !current)}
            >
              <PremiumIcon type={showConfirmPassword ? "eyeOff" : "eye"} />
            </button>
          }
        />

        {form.role === "garage" && (
          <>
            <PremiumAuthInput
              icon="garage"
              label="Garage Name"
              value={form.garageName}
              onChange={(event) => updateForm("garageName", event.target.value)}
              autoComplete="organization"
            />
            <PremiumAuthInput
              icon="mapPin"
              label="Garage Address"
              value={form.garageAddress}
              onChange={(event) => updateForm("garageAddress", event.target.value)}
              autoComplete="street-address"
            />
            <button
              type="button"
              className="premium-login__secondary-button"
              onClick={captureCurrentLocation}
              disabled={locationLoading}
            >
              {locationLoading ? "Capturing location..." : "Use Exact Maps Location"}
            </button>
            {form.latitude && form.longitude && (
              <p className="premium-login__helper">
                Location: {form.latitude}, {form.longitude}{" "}
                <a
                  href={`https://www.google.com/maps?q=${form.latitude},${form.longitude}`}
                  target="_blank"
                  rel="noreferrer"
                >
                  View map
                </a>
              </p>
            )}
            <PremiumAuthInput
              icon="mapPin"
              label="Service Radius (km)"
              type="number"
              value={form.serviceRadiusKm}
              onChange={(event) => updateForm("serviceRadiusKm", event.target.value)}
              required={false}
            />
          </>
        )}

        <label className="premium-login__check premium-login__terms">
          <input
            type="checkbox"
            checked={form.terms}
            onChange={(event) => updateForm("terms", event.target.checked)}
          />
          <span>
            I agree to the <Link to="/about">Terms & Conditions</Link>
          </span>
        </label>

        <PremiumStatus type="error">{error}</PremiumStatus>

        <button className="premium-login__primary-button" type="submit">
          <span>Create Account</span>
        </button>

        {form.role === "user" && (
          <>
            <div className="premium-login__divider"><span>or continue with</span></div>
            <div className="premium-login__social-grid">
              <div className="premium-login__google-auth">
                <GoogleAuthButton
                  label="signup_with"
                  onSuccess={(data) => {
                    localStorage.setItem("token", data.token);
                    navigate("/landing");
                  }}
                  onError={(msg) => setError(msg)}
                />
              </div>
            </div>
          </>
        )}

        <div className="premium-login__signup premium-login__signup--center">
          <span>Already have an account?</span>
          <Link to="/">Login</Link>
        </div>
      </form>
    </section>
  );

  return (
    <PremiumAuthShell
      label="register"
      title={<>Join The<br />RiderCraft Community</>}
      subtitle="Create your account and start your journey with premium helmets, riding gear and bike services."
      card={card}
    />
  );
}
