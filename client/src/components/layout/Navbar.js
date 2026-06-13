import { useState } from "react";

export default function Navbar({
  view,
  setView,
  totalItems,
  totalOrders,
  profile,
  isAdmin,
  logout
}) {
  const [menuOpen, setMenuOpen] = useState(false);

  const goToView = (nextView) => {
    setView(nextView);
    setMenuOpen(false);
  };

  const goToPath = (path) => {
    setMenuOpen(false);
    window.location.href = path;
  };

  const handleLogout = () => {
    setMenuOpen(false);
    logout();
  };

  return (
    <nav className="landing-nav">
      <div className="nav-frame">
        <div className="nav-mobile-head">
          <span className="nav-mobile-user">{profile.name || "User"}</span>
          <button
            type="button"
            className={`nav-hamburger ${menuOpen ? "open" : ""}`}
            onClick={() => setMenuOpen((prev) => !prev)}
            aria-label="Toggle navigation"
            aria-expanded={menuOpen}
          >
            <span />
            <span />
            <span />
          </button>
        </div>

        <div className={`nav-actions ${menuOpen ? "open" : ""}`}>
          <button
            className={view === "shop" ? "nav-btn active" : "nav-btn"}
            onClick={() => goToView("shop")}
          >
            <span className="nav-chip chip-green" />
            <span>Shop</span>
          </button>
          <button
            className={view === "cart" ? "nav-btn active" : "nav-btn"}
            onClick={() => goToView("cart")}
          >
            <span className="nav-chip chip-cyan" />
            <span>Cart ({totalItems})</span>
          </button>
          <button
            className={view === "orders" ? "nav-btn active" : "nav-btn"}
            onClick={() => goToView("orders")}
          >
            <span className="nav-chip chip-lime" />
            <span>Orders ({totalOrders})</span>
          </button>
          <button
            className={view === "servicing" ? "nav-btn active" : "nav-btn"}
            onClick={() => goToView("servicing")}
          >
            <span className="nav-chip chip-sky" />
            <span>Bike Servicing</span>
          </button>
          <button
            className="nav-btn"
            onClick={() => goToPath("/about")}
          >
            <span className="nav-chip chip-white" />
            <span>About</span>
          </button>
          <button
            className={
              view === "profile"
                ? "nav-btn nav-profile-btn active"
                : "nav-btn nav-profile-btn"
            }
            onClick={() => goToView("profile")}
          >
            <span className="nav-chip chip-violet" />
            <span className="nav-user-name">{profile.name || "User"}</span>
          </button>
          {isAdmin && (
            <button
              className="nav-btn"
              onClick={() => goToPath("/admin")}
            >
              <span className="nav-chip chip-amber" />
              <span>Admin Panel</span>
            </button>
          )}
          <button onClick={handleLogout} className="logout-btn nav-logout-mobile">
            Logout
          </button>
        </div>

        <button onClick={logout} className="logout-btn nav-logout-desktop">
          Logout
        </button>
      </div>
    </nav>
  );
}
