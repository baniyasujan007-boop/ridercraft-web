import { useState } from "react";
import axios from "axios";
import { Link, useNavigate } from "react-router-dom";
import AuthLayout from "../../components/layout/AuthLayout";

export default function GarageSignup() {
  const [form, setForm] = useState({
    name: "",
    email: "",
    password: "",
    garageName: "",
    garageAddress: "",
    latitude: "",
    longitude: "",
    serviceRadiusKm: "15"
  });
  const [locationLoading, setLocationLoading] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const captureCurrentLocation = () => {
    setError("");
    setMessage("");
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
        setMessage("Exact location captured from map coordinates.");
      },
      (geoError) => {
        setLocationLoading(false);
        if (geoError.code === geoError.PERMISSION_DENIED) {
          setError("Location permission denied. Please allow location access.");
          return;
        }
        if (geoError.code === geoError.TIMEOUT) {
          setError("Location request timed out. Please try again.");
          return;
        }
        setError("Could not capture current location.");
      },
      { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 }
    );
  };

  const submit = async () => {
    setError("");
    setMessage("");
    if (!form.latitude || !form.longitude) {
      setError("Please capture your exact maps location before signup.");
      return;
    }
    try {
      setLoading(true);
      await axios.post("https://ridercraft-api.onrender.com/auth/garage/signup", {
        ...form,
        latitude: Number(form.latitude),
        longitude: Number(form.longitude),
        serviceRadiusKm: Number(form.serviceRadiusKm || 15)
      });
      setMessage("Garage account created successfully. Redirecting to login...");
      setTimeout(() => navigate("/garage-login"), 1200);
    } catch (err) {
      setError(err.response?.data?.error || "Garage signup failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthLayout type="register">
      <h2>Garage Partner Signup</h2>

      <input
        placeholder="Owner name"
        value={form.name}
        onChange={(e) => setForm({ ...form, name: e.target.value })}
      />
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
        {locationLoading ? "Capturing exact location..." : "Use Exact Maps Location"}
      </button>
      {form.latitude && form.longitude && (
        <p>
          Captured coordinates: {form.latitude}, {form.longitude}{" "}
          <a
            href={`https://www.google.com/maps?q=${form.latitude},${form.longitude}`}
            target="_blank"
            rel="noreferrer"
          >
            View on Map
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

      {error && <div className="error">{error}</div>}
      {message && <div className="success">{message}</div>}

      <button className="primary-btn" onClick={submit} disabled={loading}>
        {loading ? "Creating..." : "Create Garage Account"}
      </button>

      <Link to="/garage-login" className="link">
        Already have a garage account? Login
      </Link>
    </AuthLayout>
  );
}
