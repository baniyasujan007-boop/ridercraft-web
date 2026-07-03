import { useCallback, useEffect, useMemo, useState } from "react";
import axios from "axios";
import "../styles/garage-dashboard.css";

const STATUS_OPTIONS = ["requested", "confirmed", "in_progress", "completed", "cancelled"];
const PAYMENT_METHOD_OPTIONS = [
  { value: "cash", label: "Cash" },
  { value: "upi", label: "UPI" },
  { value: "card", label: "Card" },
  { value: "ewallet", label: "E-Wallet" },
  { value: "bank_transfer", label: "Bank Transfer" },
  { value: "other", label: "Other" }
];

const createBillingItem = (item = {}) => ({
  name: String(item.name || ""),
  quantity: item.quantity === undefined || item.quantity === null ? "1" : String(item.quantity),
  unitPrice: item.unitPrice === undefined || item.unitPrice === null ? "" : String(item.unitPrice)
});

const createBillingForm = (booking) => {
  const billing = booking?.billing || {};
  const items =
    Array.isArray(billing.items) && billing.items.length
      ? billing.items.map(createBillingItem)
      : [createBillingItem()];

  return {
    laborCharge:
      billing.laborCharge === undefined || billing.laborCharge === null
        ? ""
        : String(billing.laborCharge),
    tax: billing.tax === undefined || billing.tax === null ? "" : String(billing.tax),
    discount:
      billing.discount === undefined || billing.discount === null
        ? ""
        : String(billing.discount),
    notes: String(billing.notes || ""),
    paymentMethod: String(billing.paymentMethod || "cash"),
    paymentReference: String(billing.paymentReference || ""),
    items
  };
};

const toAmount = (value) => {
  const amount = Number(value || 0);
  return Number.isFinite(amount) && amount > 0 ? amount : 0;
};

const getBillingPreview = (form) => {
  const laborCharge = toAmount(form.laborCharge);
  const partsTotal = (form.items || []).reduce(
    (sum, item) => sum + toAmount(item.quantity) * toAmount(item.unitPrice),
    0
  );
  const subtotal = laborCharge + partsTotal;
  const tax = toAmount(form.tax);
  const discount = toAmount(form.discount);
  const total = Math.max(0, subtotal + tax - discount);

  return {
    subtotal: Number(subtotal.toFixed(2)),
    tax: Number(tax.toFixed(2)),
    discount: Number(discount.toFixed(2)),
    total: Number(total.toFixed(2))
  };
};

const formatCurrency = (value) => `₹${Number(value || 0).toLocaleString("en-IN")}`;

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
  const [billingForm, setBillingForm] = useState(createBillingForm());
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [billingSaving, setBillingSaving] = useState(false);
  const [billingPaymentSaving, setBillingPaymentSaving] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  const token = localStorage.getItem("token");

  const selectedBooking = useMemo(() => {
    if (!bookings.length) return null;
    return bookings.find((row) => row._id === selectedId) || bookings[0];
  }, [bookings, selectedId]);

  const billingPreview = useMemo(() => getBillingPreview(billingForm), [billingForm]);

  const loadData = useCallback(async (preferredSelectedId = "") => {
    if (!token) return;
    setError("");
    try {
      setLoading(true);
      const headers = { Authorization: `Bearer ${token}` };
      const [profileRes, bookingsRes] = await Promise.all([
        axios.get("https://ridercraft-api.onrender.com/auth/profile", { headers }),
        axios.get("https://ridercraft-api.onrender.com/service-requests/garage", { headers })
      ]);
      setProfile(profileRes.data);
      const nextBookings = Array.isArray(bookingsRes.data) ? bookingsRes.data : [];
      setBookings(nextBookings);
      if (nextBookings.length) {
        const initial =
          nextBookings.find((booking) => booking._id === preferredSelectedId) || nextBookings[0];
        setSelectedId(initial._id);
        setStatus(String(initial.status || "requested"));
        setGarageNote(String(initial.garageNote || ""));
        setBillingForm(createBillingForm(initial));
      } else {
        setSelectedId("");
        setStatus("requested");
        setGarageNote("");
        setBillingForm(createBillingForm());
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
    setBillingForm(createBillingForm(selectedBooking));
  }, [selectedBooking]);

  const submitResponse = async () => {
    if (!selectedBooking || !token) return;
    setMessage("");
    setError("");

    try {
      setSaving(true);
      await axios.put(
        `https://ridercraft-api.onrender.com/service-requests/${selectedBooking._id}/garage-response`,
        { status, garageNote: garageNote.trim() },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setMessage("Booking response updated");
      await loadData(selectedBooking._id);
    } catch (err) {
      setError(err.response?.data?.error || "Failed to update booking response");
    } finally {
      setSaving(false);
    }
  };

  const updateBillingField = (field, value) => {
    setBillingForm((prev) => ({ ...prev, [field]: value }));
  };

  const updateBillingItem = (index, field, value) => {
    setBillingForm((prev) => ({
      ...prev,
      items: prev.items.map((item, itemIndex) =>
        itemIndex === index ? { ...item, [field]: value } : item
      )
    }));
  };

  const addBillingItem = () => {
    setBillingForm((prev) => ({ ...prev, items: [...prev.items, createBillingItem()] }));
  };

  const removeBillingItem = (index) => {
    setBillingForm((prev) => ({
      ...prev,
      items:
        prev.items.length > 1
          ? prev.items.filter((_, itemIndex) => itemIndex !== index)
          : prev.items
    }));
  };

  const saveBilling = async () => {
    if (!selectedBooking || !token) return;
    setMessage("");
    setError("");

    try {
      setBillingSaving(true);
      await axios.put(
        `https://ridercraft-api.onrender.com/service-requests/${selectedBooking._id}/billing`,
        {
          laborCharge: Number(billingForm.laborCharge || 0),
          tax: Number(billingForm.tax || 0),
          discount: Number(billingForm.discount || 0),
          notes: billingForm.notes.trim(),
          items: billingForm.items
            .map((item) => ({
              name: item.name.trim(),
              quantity: Number(item.quantity || 0),
              unitPrice: Number(item.unitPrice || 0)
            }))
            .filter((item) => item.name || item.unitPrice > 0)
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setMessage("Service bill issued");
      await loadData(selectedBooking._id);
    } catch (err) {
      setError(err.response?.data?.error || "Failed to update service bill");
    } finally {
      setBillingSaving(false);
    }
  };

  const updateBillingPayment = async (billingStatus) => {
    if (!selectedBooking || !token) return;
    setMessage("");
    setError("");

    try {
      setBillingPaymentSaving(true);
      await axios.put(
        `https://ridercraft-api.onrender.com/service-requests/${selectedBooking._id}/billing/payment`,
        {
          billingStatus,
          paymentMethod: billingForm.paymentMethod,
          paymentReference: billingForm.paymentReference.trim()
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setMessage("Service bill payment updated");
      await loadData(selectedBooking._id);
    } catch (err) {
      setError(err.response?.data?.error || "Failed to update bill payment");
    } finally {
      setBillingPaymentSaving(false);
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
            {bookings.map((booking) => {
              const billing = booking.billing || {};
              const billingStatus = String(billing.status || "unbilled");
              return (
                <button
                  key={booking._id}
                  type="button"
                  className={`garage-list-item ${selectedBooking?._id === booking._id ? "active" : ""}`}
                  onClick={() => setSelectedId(booking._id)}
                >
                  <strong>{booking.bikeModel}</strong>
                  <span>{toLabel(booking.priority)} Priority</span>
                  <span>{toLabel(booking.status)}</span>
                  {billingStatus !== "unbilled" && (
                    <span>
                      Bill {toLabel(billingStatus)} - {formatCurrency(billing.total)}
                    </span>
                  )}
                </button>
              );
            })}
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

                {(() => {
                  const billing = selectedBooking.billing || {};
                  const billingStatus = String(billing.status || "unbilled");
                  const billingLocked = billingStatus === "paid";
                  const hasBill = billingStatus !== "unbilled";

                  return (
                    <div className="garage-billing-panel">
                      <div className="garage-section-head">
                        <div>
                          <h3>Billing</h3>
                          <p>Create the final service bill for this booking.</p>
                        </div>
                        <span className={`garage-bill-status garage-bill-status-${billingStatus}`}>
                          {toLabel(billingStatus)}
                        </span>
                      </div>

                      <div className="garage-billing-summary">
                        <div>
                          <span>Subtotal</span>
                          <strong>{formatCurrency(billingPreview.subtotal)}</strong>
                        </div>
                        <div>
                          <span>Tax</span>
                          <strong>{formatCurrency(billingPreview.tax)}</strong>
                        </div>
                        <div>
                          <span>Discount</span>
                          <strong>{formatCurrency(billingPreview.discount)}</strong>
                        </div>
                        <div className="garage-billing-total">
                          <span>Total Due</span>
                          <strong>{formatCurrency(billingPreview.total)}</strong>
                        </div>
                      </div>

                      <div className="garage-billing-grid">
                        <label>
                          Labor Charge
                          <input
                            type="number"
                            min="0"
                            step="0.01"
                            value={billingForm.laborCharge}
                            onChange={(e) => updateBillingField("laborCharge", e.target.value)}
                            disabled={billingLocked}
                            placeholder="0"
                          />
                        </label>
                        <label>
                          Tax
                          <input
                            type="number"
                            min="0"
                            step="0.01"
                            value={billingForm.tax}
                            onChange={(e) => updateBillingField("tax", e.target.value)}
                            disabled={billingLocked}
                            placeholder="0"
                          />
                        </label>
                        <label>
                          Discount
                          <input
                            type="number"
                            min="0"
                            step="0.01"
                            value={billingForm.discount}
                            onChange={(e) => updateBillingField("discount", e.target.value)}
                            disabled={billingLocked}
                            placeholder="0"
                          />
                        </label>
                      </div>

                      <div className="garage-billing-items">
                        <div className="garage-billing-items-head">
                          <strong>Parts / Materials</strong>
                          <button type="button" onClick={addBillingItem} disabled={billingLocked}>
                            Add Item
                          </button>
                        </div>

                        {billingForm.items.map((item, index) => (
                          <div className="garage-billing-item-row" key={`billing-item-${index}`}>
                            <input
                              value={item.name}
                              onChange={(e) => updateBillingItem(index, "name", e.target.value)}
                              disabled={billingLocked}
                              placeholder="Item name"
                              aria-label="Billing item name"
                            />
                            <input
                              type="number"
                              min="0.01"
                              step="0.01"
                              value={item.quantity}
                              onChange={(e) => updateBillingItem(index, "quantity", e.target.value)}
                              disabled={billingLocked}
                              placeholder="Qty"
                              aria-label="Billing item quantity"
                            />
                            <input
                              type="number"
                              min="0"
                              step="0.01"
                              value={item.unitPrice}
                              onChange={(e) => updateBillingItem(index, "unitPrice", e.target.value)}
                              disabled={billingLocked}
                              placeholder="Price"
                              aria-label="Billing item unit price"
                            />
                            <span>{formatCurrency(toAmount(item.quantity) * toAmount(item.unitPrice))}</span>
                            <button
                              type="button"
                              onClick={() => removeBillingItem(index)}
                              disabled={billingLocked || billingForm.items.length === 1}
                            >
                              Remove
                            </button>
                          </div>
                        ))}
                      </div>

                      <label className="garage-billing-notes">
                        Bill Notes
                        <textarea
                          rows="3"
                          value={billingForm.notes}
                          onChange={(e) => updateBillingField("notes", e.target.value)}
                          disabled={billingLocked}
                          placeholder="Parts replaced, warranty note, payment terms"
                        />
                      </label>

                      {billingLocked && (
                        <p className="garage-muted-note">
                          Paid bills are locked. Mark this bill unpaid before editing charges.
                        </p>
                      )}

                      <button
                        type="button"
                        className="garage-primary-btn"
                        onClick={saveBilling}
                        disabled={billingSaving || billingLocked}
                      >
                        {billingSaving ? "Saving Bill..." : hasBill ? "Update Bill" : "Issue Bill"}
                      </button>

                      <div className="garage-payment-box">
                        <div className="garage-billing-grid">
                          <label>
                            Payment Method
                            <select
                              value={billingForm.paymentMethod}
                              onChange={(e) => updateBillingField("paymentMethod", e.target.value)}
                            >
                              {PAYMENT_METHOD_OPTIONS.map((option) => (
                                <option key={option.value} value={option.value}>
                                  {option.label}
                                </option>
                              ))}
                            </select>
                          </label>
                          <label>
                            Payment Reference
                            <input
                              value={billingForm.paymentReference}
                              onChange={(e) =>
                                updateBillingField("paymentReference", e.target.value)
                              }
                              placeholder="Receipt, UPI, or card reference"
                            />
                          </label>
                        </div>

                        <div className="garage-payment-actions">
                          <button
                            type="button"
                            onClick={() => updateBillingPayment("paid")}
                            disabled={
                              billingPaymentSaving ||
                              !hasBill ||
                              billingStatus === "paid" ||
                              billingStatus === "cancelled"
                            }
                          >
                            Mark Paid
                          </button>
                          <button
                            type="button"
                            onClick={() => updateBillingPayment("issued")}
                            disabled={
                              billingPaymentSaving ||
                              !hasBill ||
                              billingStatus === "issued"
                            }
                          >
                            Mark Unpaid
                          </button>
                          <button
                            type="button"
                            onClick={() => updateBillingPayment("cancelled")}
                            disabled={
                              billingPaymentSaving ||
                              !hasBill ||
                              billingStatus === "cancelled"
                            }
                          >
                            Void Bill
                          </button>
                        </div>
                      </div>
                    </div>
                  );
                })()}

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
