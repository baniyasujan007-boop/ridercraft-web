import { applyImageFallback } from "../../../../utils/fallbackImage";

function formatCurrency(value) {
  return `$${Number(value).toLocaleString()}`;
}

function formatDate(value) {
  return new Date(value).toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric"
  });
}

export default function OrdersTable({ orders, selectedId, onSelect }) {
  return (
    <section className="orders-table-card">
      <table className="orders-table">
        <thead>
          <tr>
            <th>
              <input type="checkbox" aria-label="Select all" />
            </th>
            <th>Order ID</th>
            <th>Customer</th>
            <th>Status</th>
            <th>Promo Code</th>
            <th>Total</th>
            <th>Date</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          {orders.map((order) => (
            <tr
              key={order.id}
              className={selectedId === order.id ? "row-selected" : ""}
              onClick={() => onSelect(order)}
            >
              <td>
                <input type="checkbox" aria-label={`Select ${order.id}`} />
              </td>
              <td>{order.labelId || order.id}</td>
              <td>
                <div className="orders-customer-cell">
                  {order.customer.avatar ? (
                    <img
                      src={order.customer.avatar}
                      alt={order.customer.name}
                      onError={applyImageFallback}
                    />
                  ) : (
                    <div className="orders-avatar-fallback">
                      {String(order.customer.name || "U").slice(0, 1).toUpperCase()}
                    </div>
                  )}
                  <span>{order.customer.name}</span>
                </div>
              </td>
              <td>
                <span className={`status-badge status-${order.status}`}>{order.status}</span>
              </td>
              <td>{order.promoCode || "-"}</td>
              <td>{formatCurrency(order.total)}</td>
              <td>{formatDate(order.date)}</td>
              <td>
                <button type="button" className="orders-more-btn" onClick={(e) => e.stopPropagation()}>
                  ⋯
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}
