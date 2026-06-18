import { applyImageFallback } from "../../../../utils/fallbackImage";

export default function OrdersHeader({
  filters,
  setFilters,
  onToggleSidebar
}) {
  return (
    <header className="orders-header-card">
      <div className="orders-title-row">
        <button type="button" className="orders-mobile-toggle" onClick={onToggleSidebar}>
          ☰
        </button>
        <h2>Orders</h2>
      </div>

      <div className="orders-toolbar">
        <select
          value={filters.status}
          onChange={(e) => setFilters((prev) => ({ ...prev, status: e.target.value }))}
        >
          <option value="all">Any Status</option>
          <option value="paid">Paid</option>
          <option value="delivered">Delivered</option>
          <option value="completed">Completed</option>
          <option value="pending">Pending</option>
          <option value="refunded">Refunded</option>
        </select>

        <select
          value={filters.priceRange}
          onChange={(e) => setFilters((prev) => ({ ...prev, priceRange: e.target.value }))}
        >
          <option value="all">$100-$1500</option>
          <option value="100-500">$100-$500</option>
          <option value="501-1000">$501-$1000</option>
          <option value="1001-1500">$1001-$1500</option>
        </select>

        <select
          value={filters.dateSort}
          onChange={(e) => setFilters((prev) => ({ ...prev, dateSort: e.target.value }))}
        >
          <option value="newest">Date: Newest</option>
          <option value="oldest">Date: Oldest</option>
        </select>

        <label className="orders-search-wrap">
          <span>⌕</span>
          <input
            placeholder="Search order, customer, promo"
            value={filters.query}
            onChange={(e) => setFilters((prev) => ({ ...prev, query: e.target.value }))}
          />
        </label>

        <div className="orders-profile-pill">
          <img
            src="https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=120&q=80"
            alt="Admin"
            onError={applyImageFallback}
          />
          <div>
            <p>Olivia Stone</p>
            <small>Admin</small>
          </div>
        </div>
      </div>
    </header>
  );
}
