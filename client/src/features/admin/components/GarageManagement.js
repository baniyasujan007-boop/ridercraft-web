import { useState } from "react";
import axios from "axios";

const initialForm = {
  name: "",
  email: "",
  password: "",
  garageName: "",
  garageAddress: "",
  latitude: "",
  longitude: "",
  serviceRadiusKm: "15",
};

export default function GarageManagement({ token }) {
  const [form, setForm] = useState(initialForm);
  const [locationLoading, setLocationLoading] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const update = (field, value) =>
    setForm((current) => ({ ...current, [field]: value }));

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
        setForm((current) => ({
          ...current,
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

  const createGarage = async () => {
    setError("");
    setMessage("");
    if (
      !form.name.trim() ||
      !form.email.trim() ||
      !form.password ||
      !form.garageName.trim() ||
      !form.garageAddress.trim()
    ) {
      setError("Owner name, email, password, garage name, and garage address are required");
      return;
    }
    if (!form.latitude || !form.longitude) {
      setError("Please capture the exact location before saving");
      return;
    }
    try {
      setLoading(true);
      await axios.post(
        "https://ridercraft-api.onrender.com/auth/garage/register",
        {
          name: form.name.trim(),
          email: form.email.trim().toLowerCase(),
          password: form.password,
          garageName: form.garageName.trim(),
          garageAddress: form.garageAddress.trim(),
          latitude: Number(form.latitude),
          longitude: Number(form.longitude),
          serviceRadiusKm: Number(form.serviceRadiusKm || 15),
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setMessage(
        `Garage "${form.garageName.trim()}" created. The garage can now sign in with its email and password.`
      );
      setForm(initialForm);
    } catch (err) {
      setError(err.response?.data?.error || "Failed to create garage account");
    } finally {
      setLoading(false);
    }
  };

  return (
    <section className="admin-form-wrap">
      <h2>Create Garage Account</h2>
      <p className="admin-hint">
        Garage accounts are created by admins only. The garage signs in through
        the normal login page using the email and password set here.
      </p>
      <div className="admin-form-grid">
        <label className="admin-field-label">
          Owner name
          <input
            placeholder="Owner name"
            value={form.name}
            onChange={(e) => update("name", e.target.value)}
          />
        </label>
        <label className="admin-field-label">
          Garage email
          <input
            placeholder="Garage email"
            value={form.email}
            onChange={(e) => update("email", e.target.value)}
          />
        </label>
        <label className="admin-field-label">
          Password
          <input
            type="password"
            placeholder="Set garage login password"
            value={form.password}
            onChange={(e) => update("password", e.target.value)}
          />
        </label>
        <label className="admin-field-label">
          Garage name
          <input
            placeholder="Garage name"
            value={form.garageName}
            onChange={(e) => update("garageName", e.target.value)}
          />
        </label>
        <label className="admin-field-label">
          Garage address
          <input
            placeholder="Garage address"
            value={form.garageAddress}
            onChange={(e) => update("garageAddress", e.target.value)}
          />
        </label>
        <label className="admin-field-label">
          Service radius (km)
          <input
            type="number"
            min="1"
            max="200"
            placeholder="15"
            value={form.serviceRadiusKm}
            onChange={(e) => update("serviceRadiusKm", e.target.value)}
          />
        </label>
      </div>
      <div className="admin-actions">
        <button
          type="button"
          onClick={captureCurrentLocation}
          disabled={locationLoading}
          className="admin-secondary-btn"
        >
          {locationLoading ? "Capturing location..." : "Use Exact Maps Location"}
        </button>
        {(form.latitude || form.longitude) && (
          <span className="admin-garage-coords">
            Location: {form.latitude}, {form.longitude}
          </span>
        )}
        <button
          type="button"
          onClick={createGarage}
          disabled={loading}
          className="admin-primary-btn"
        >
          {loading ? "Creating..." : "Create Garage Account"}
        </button>
      </div>
      {error && <p className="admin-error">{error}</p>}
      {message && <p className="admin-success">{message}</p>}
    </section>
  );
}