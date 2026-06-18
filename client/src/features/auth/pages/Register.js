import { useState } from "react";
import { useNavigate } from "react-router-dom";
import AuthLayout from "../components/AuthLayout";
import GoogleAuthButton from "../components/GoogleAuthButton";
import api from "../../../services/api";

export default function Register() {
  const [form, setForm] = useState({
    role: "user",
    name: "",
    email: "",
    password: "",
    garageName: "",
    garageAddress: "",
    latitude: "",
    longitude: "",
    serviceRadiusKm: "15"
  });
  const [error, setError] = useState("");
  const [locationLoading, setLocationLoading] = useState(false);
  const navigate = useNavigate();

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
          longitude: String(Number(position.coords.longitude.toFixed(6)))
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

  const submit = async () => {
    try {
      setError("");
      if (form.role === "garage" && (!form.latitude || !form.longitude)) {
        setError("Please capture exact map location for garage signup");
        return;
      }

      await api.post("auth/register", {
        role: form.role,
        name: form.name,
        email: form.email,
        password: form.password,
        garageName: form.garageName,
        garageAddress: form.garageAddress,
        latitude: Number(form.latitude),
        longitude: Number(form.longitude),
        serviceRadiusKm: Number(form.serviceRadiusKm || 15)
      });
      navigate("/");
    } catch (err) {
      setError(err.response?.data?.error || "Registration failed");
    }
  };

  return (
    <AuthLayout type="register">
      <h2>Create Account</h2>

      <select
        value={form.role}
        onChange={(e) => setForm({ ...form, role: e.target.value })}
      >
        <option value="user">Customer</option>
        <option value="garage">Garage Partner</option>
      </select>

      <input
        placeholder={form.role === "garage" ? "Owner name" : "Name"}
        value={form.name}
        onChange={(e) => setForm({ ...form, name: e.target.value })}
      />

      <input
        placeholder="Email"
        value={form.email}
        onChange={(e) => setForm({ ...form, email: e.target.value })}
      />

      <input
        type="password"
        placeholder="Password"
        value={form.password}
        onChange={(e) => setForm({ ...form, password: e.target.value })}
      />

      {form.role === "garage" && (
        <>
          <input
            placeholder="Garage name"
            value={form.garageName}
            onChange={(e) => setForm({ ...form, garageName: e.target.value })}
          />
          <input
            placeholder="Garage address"
            value={form.garageAddress}
            onChange={(e) => setForm({ ...form, garageAddress: e.target.value })}
          />
          <button
            type="button"
            className="primary-btn"
            onClick={captureCurrentLocation}
            disabled={locationLoading}
          >
            {locationLoading ? "Capturing location..." : "Use Exact Maps Location"}
          </button>
          {form.latitude && form.longitude && (
            <p>
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
          <input
            type="number"
            min="1"
            max="200"
            placeholder="Service radius (km)"
            value={form.serviceRadiusKm}
            onChange={(e) => setForm({ ...form, serviceRadiusKm: e.target.value })}
          />
        </>
      )}

      {error && <div className="error">{error}</div>}

      <button className="primary-btn" onClick={submit}>
        Sign Up
      </button>

      {form.role === "user" && (
        <>
          <div className="oauth-divider">or</div>
          <GoogleAuthButton
            label="signup_with"
            onSuccess={(data) => {
              localStorage.setItem("token", data.token);
              navigate("/landing");
            }}
            onError={(msg) => setError(msg)}
          />
        </>
      )}
    </AuthLayout>
  );
}
