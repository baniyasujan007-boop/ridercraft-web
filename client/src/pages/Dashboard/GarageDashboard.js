import { useCallback, useEffect, useMemo, useState } from "react";
import axios from "axios";
import "../../styles/pages/garage-dashboard.css";

const STATUS_OPTIONS = ["requested", "confirmed", "in_progress", "completed", "cancelled"];

const toLabel = (value) =>
  String(value || "")
    .split("_")
    .map((chunk) => chunk.charAt(0).toUpperCase() + chunk.slice(1))
    .join(" ");

export default function GarageDashboard() {
  const [profile, setProfile] = useState(null);
  const [bookings, setBookings] = useState([]);
  const [selectedId, setSelectedId] = useState("");
  const [status, setStatus] = useState("requested");
  const [garageNote, setGarageNote] = useState("");
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  const token = localStorage.getItem("token");

  const selectedBooking = useMemo(() => {
    if (!bookings.length) return null;
    return bookings.find((row) => row._id === selectedId) || bookings[0];
  }, [bookings, selectedId]);

  const loadData = useCallback(async () => {
    if (!token) return;
    setError("");
    try {
      setLoading(true);
      const headers = { Authorization: `Bearer ${token}` };
      const [profileRes, bookingsRes] = await Promise.all([
        axios.get("http://localhost:5001/auth/profile", { headers }),
        axios.get("http://localhost:5001/service-requests/garage", { headers })
      ]);
      setProfile(profileRes.data);
      const nextBookings = Array.isArray(bookingsRes.data) ? bookingsRes.data : [];
      setBookings(nextBookings);
      if (nextBookings.length) {
        const initial = nextBookings[0];
        setSelectedId(initial._id);
        setStatus(String(initial.status || "requested"));
        setGarageNote(String(initial.garageNote || ""));
      }
    } catch (err) {
      setError(err.response?.data?.error || "Failed to load garage bookings");
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  useEffect(() => {
    if (!selectedBooking) return;
    setStatus(String(selectedBooking.status || "requested"));
    setGarageNote(String(selectedBooking.garageNote || ""));
  }, [selectedBooking]);

  const submitResponse = async () => {
    if (!selectedBooking || !token) return;
    setMessage("");
    setError("");

    try {
      setSaving(true);
      await axios.put(
        `http://localhost:5001/service-requests/${selectedBooking._id}/garage-response`,
        { status, garageNote: garageNote.trim() },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setMessage("Booking response updated");
      await loadData();
    } catch (err) {
      setError(err.response?.data?.error || "Failed to update booking response");
    } finally {
      setSaving(false);
    }
  };

  const logout = () => {
    localStorage.removeItem("token");
    window.location.href = "/";
  };

  return (
    <section className="garage-dashboard-page">
      <div className="garage-dashboard-shell">
        <header className="garage-head">
          <div>
            <h1>Garage Booking Panel</h1>
            <p>
              {profile?.garageProfile?.garageName || profile?.name || "Garage"} - Assigned requests
            </p>
          </div>
          <button type="button" onClick={logout} className="garage-logout-btn">
            Logout
          </button>
        </header>

        {error && <p className="garage-error">{error}</p>}
        {message && <p className="garage-success">{message}</p>}

        <div className="garage-grid">
          <aside className="garage-booking-list">
            <h2>Bookings</h2>
            {loading && <p>Loading...</p>}
            {!loading && bookings.length === 0 && <p>No assigned bookings yet.</p>}
            {bookings.map((booking) => (
              <button
                key={booking._id}
                type="button"
                className={`garage-list-item ${selectedBooking?._id === booking._id ? "active" : ""}`}
                onClick={() => setSelectedId(booking._id)}
              >
                <strong>{booking.bikeModel}</strong>
                <span>{toLabel(booking.priority)} Priority</span>
                <span>{toLabel(booking.status)}</span>
              </button>
            ))}
          </aside>

          <div className="garage-booking-detail">
            {!selectedBooking && <p>Select a booking to view details.</p>}
            {selectedBooking && (
              <>
                <h2>{selectedBooking.bikeModel}</h2>
                <p>
                  <strong>Customer:</strong> {selectedBooking.user?.name || "User"} (
                  {selectedBooking.user?.email || "No email"})
                </p>
                <p>
                  <strong>Priority:</strong> {toLabel(selectedBooking.priority)}
                </p>
                <p>
                  <strong>Package:</strong> {toLabel(selectedBooking.packageType)}
                </p>
                <p>
                  <strong>Preferred:</strong> {selectedBooking.preferredDate} {selectedBooking.preferredTime}
                </p>
                <p>
                  <strong>Pickup:</strong> {selectedBooking.pickupAddress}
                </p>
                <p>
                  <strong>Location:</strong> {selectedBooking.pickupLocation?.latitude}, {" "}
                  {selectedBooking.pickupLocation?.longitude}
                </p>
                {selectedBooking.priority === "emergency" && (
                  <p>
                    <strong>Breakdown Issue:</strong> {selectedBooking.breakdownIssue || "Not provided"}
                  </p>
                )}
                {!!selectedBooking.notes && (
                  <p>
                    <strong>Notes:</strong> {selectedBooking.notes}
                  </p>
                )}

                <div className="garage-response-box">
                  <label htmlFor="garage-status">Status</label>
                  <select
                    id="garage-status"
                    value={status}
                    onChange={(e) => setStatus(e.target.value)}
                  >
                    {STATUS_OPTIONS.map((option) => (
                      <option key={option} value={option}>
                        {toLabel(option)}
                      </option>
                    ))}
                  </select>

                  <label htmlFor="garage-note">Response Note</label>
                  <textarea
                    id="garage-note"
                    rows="4"
                    value={garageNote}
                    onChange={(e) => setGarageNote(e.target.value)}
                    placeholder="Add update for the customer"
                  />

                  <button type="button" onClick={submitResponse} disabled={saving}>
                    {saving ? "Saving..." : "Update Booking"}
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}
