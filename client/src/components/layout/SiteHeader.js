import { Link } from "react-router-dom";
import ridercraftLogo from "../../assets/ridercraft-logo.png";

export default function SiteHeader({
  searchQuery,
  setSearchQuery,
  setView,
  totalItems = 0,
  profile = {},
}) {
  const openView = (nextView) => {
    if (setView) setView(nextView);
  };

  return (
    <header className="site-header">
      <div className="site-utility-bar">
        <div className="site-utility-inner">
          <span><b>Free shipping</b> on orders above $75</span>
          <div>
            <button type="button" onClick={() => openView("orders")}>Track Order</button>
            <button type="button" onClick={() => openView("servicing")}>Help &amp; Service</button>
          </div>
        </div>
      </div>

      <div className="site-header-inner">
        <Link to="/landing" className="site-logo" aria-label="RiderCraft home">
          <span className="site-logo-mark" aria-hidden="true">
            <img src={ridercraftLogo} alt="" className="site-logo-image" />
          </span>
          <span className="site-logo-text-wrap">
            <span className="site-logo-text">RiderCraft</span>
            <span className="site-logo-sub">Ride Essentials</span>
          </span>
        </Link>

        <label className="site-header-search">
          <span className="sr-only">Search products</span>
          <input
            type="search"
            placeholder="Search helmets, gear, accessories..."
            value={searchQuery}
            onChange={(event) => setSearchQuery(event.target.value)}
          />
          <span className="header-search-btn" aria-hidden="true">⌕</span>
        </label>

        <div className="site-header-actions">
          <button type="button" className="header-action" onClick={() => openView("cart")}>
            <span className="header-action-icon" aria-hidden="true">🛒</span>
            <span className="header-action-copy"><b>Cart</b><small>{totalItems} items</small></span>
            {totalItems > 0 && <span className="header-action-badge">{totalItems}</span>}
          </button>
          <button type="button" className="header-action" onClick={() => openView("profile")}>
            <span className="header-action-icon" aria-hidden="true">♙</span>
            <span className="header-action-copy"><b>{profile.name || "My Account"}</b><small>Profile &amp; settings</small></span>
          </button>
        </div>
      </div>
    </header>
  );
}
