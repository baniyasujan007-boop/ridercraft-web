import { applyImageFallback } from "../../../../utils/fallbackImage";

function formatCurrency(value) {
  return `$${Number(value).toLocaleString()}`;
}

function formatDateTime(value) {
  return new Date(value).toLocaleString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit"
  });
}

export default function OrderDetailsDrawer({
  selectedOrder,
  onClose,
  onTrack,
  onRefund,
  onReturnReview,
  onReturnTracking,
  returnAdminNote,
  setReturnAdminNote,
  returnTrackingStatus,
  setReturnTrackingStatus,
  actionLoading
}) {
  return (
    <aside className={selectedOrder ? "order-drawer open" : "order-drawer"}>
      {!selectedOrder && <p className="drawer-placeholder">Select an order to view details.</p>}

      {selectedOrder && (
        <>
          <div className="drawer-head">
            <div>
              <h3>{selectedOrder.labelId || selectedOrder.id}</h3>
              <p>{formatDateTime(selectedOrder.date)}</p>
            </div>
            <button type="button" className="drawer-close" onClick={onClose}>
              ×
            </button>
          </div>

          <div className="drawer-chip-row">
            <span className={`status-badge status-${selectedOrder.status}`}>
              {selectedOrder.status}
            </span>
            <span className="promo-chip">Promo: {selectedOrder.promoCode || "-"}</span>
          </div>

          <div className="drawer-customer">
            {selectedOrder.customer.avatar ? (
              <img
                src={selectedOrder.customer.avatar}
                alt={selectedOrder.customer.name}
                onError={applyImageFallback}
              />
            ) : (
              <div className="orders-avatar-fallback drawer-avatar-fallback">
                {String(selectedOrder.customer.name || "U").slice(0, 1).toUpperCase()}
              </div>
            )}
            <div>
              <p>{selectedOrder.customer.name}</p>
              <small>{selectedOrder.customer.email}</small>
            </div>
          </div>

          <div className="drawer-contact-icons">
            {selectedOrder.customer.email && (
              <a href={`mailto:${selectedOrder.customer.email}`} aria-label="Email customer">
                ✉
              </a>
            )}
            {selectedOrder.customer.phone && (
              <a href={`tel:${selectedOrder.customer.phone}`} aria-label="Call customer">
                ☎
              </a>
            )}
          </div>

          <div className="drawer-items">
            {selectedOrder.items.map((item) => (
              <article key={item.id} className="drawer-item-row">
                <img src={item.image} alt={item.name} onError={applyImageFallback} />
                <div>
                  <p>{item.name}</p>
                  <small>{formatCurrency(item.price)}</small>
                </div>
              </article>
            ))}
          </div>

          <div className="drawer-total-row">
            <span>Total</span>
            <strong>{formatCurrency(selectedOrder.total)}</strong>
          </div>

          <div className="drawer-return-box">
            <h4>Return & Refund</h4>
            <p>Return status: {selectedOrder.returnRequest?.status || "none"}</p>
            {selectedOrder.returnRequest?.reason && (
              <p>Reason: {selectedOrder.returnRequest.reason}</p>
            )}
            {Array.isArray(selectedOrder.returnRequest?.evidence) &&
              selectedOrder.returnRequest.evidence.length > 0 && (
              <div className="drawer-return-proof-grid">
                {selectedOrder.returnRequest.evidence.map((file, idx) =>
                  file.type === "video" ? (
                    <video key={`drawer-return-proof-video-${idx}`} src={file.url} controls />
                  ) : (
                    <img
                      key={`drawer-return-proof-image-${idx}`}
                      src={file.url}
                      alt={file.name || "Defect proof"}
                      onError={applyImageFallback}
                    />
                  )
                )}
              </div>
            )}
            <input
              value={returnAdminNote}
              onChange={(e) => setReturnAdminNote?.(e.target.value)}
              placeholder="Admin note (optional)"
            />
            <div className="drawer-return-actions">
              <button
                type="button"
                className="drawer-track-btn"
                onClick={() => onReturnReview?.(selectedOrder.id, "approve")}
                disabled={actionLoading || selectedOrder.returnRequest?.status !== "requested"}
              >
                Approve
              </button>
              <button
                type="button"
                className="drawer-refund-btn"
                onClick={() => onReturnReview?.(selectedOrder.id, "reject")}
                disabled={actionLoading || selectedOrder.returnRequest?.status !== "requested"}
              >
                Reject
              </button>
            </div>
            <div className="drawer-return-actions">
              <select
                value={returnTrackingStatus}
                onChange={(e) => setReturnTrackingStatus?.(e.target.value)}
              >
                <option value="approved">Approved</option>
                <option value="in_transit">In Transit</option>
                <option value="received">Received</option>
                <option value="refund_initiated">Refund Initiated</option>
                <option value="refunded">Refunded</option>
                <option value="closed">Closed</option>
              </select>
              <button
                type="button"
                className="drawer-track-btn"
                onClick={() => onReturnTracking?.(selectedOrder.id, returnTrackingStatus)}
                disabled={actionLoading}
              >
                Update
              </button>
            </div>
          </div>

          <div className="drawer-actions">
            <button
              type="button"
              className="drawer-track-btn"
              onClick={() => onTrack?.(selectedOrder)}
              disabled={actionLoading}
            >
              {actionLoading ? "Updating..." : "Track"}
            </button>
            <button
              type="button"
              className="drawer-refund-btn"
              onClick={() => onRefund?.(selectedOrder)}
              disabled={actionLoading || selectedOrder.paymentStatus === "refunded"}
            >
              {selectedOrder.paymentStatus === "refunded" ? "Refunded" : "Refund"}
            </button>
          </div>
        </>
      )}
    </aside>
  );
}
