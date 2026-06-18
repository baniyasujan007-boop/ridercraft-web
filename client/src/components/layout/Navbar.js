import { useState, useRef, useEffect } from "react";
import axios from "axios";

export default function Navbar({
  view,
  setView,
  totalItems,
  totalOrders,
  notificationCount,
  notifications,
  profile,
  isAdmin,
  logout,
}) {
  const [menuOpen, setMenuOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [showNotifications, setShowNotifications] = useState(false);
  const [readNotifications, setReadNotifications] = useState([]);
  const notificationRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (
        notificationRef.current &&
        !notificationRef.current.contains(event.target)
      ) {
        setShowNotifications(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);

    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

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
  const getNotificationIcon = (title = "") => {
    const text = title.toLowerCase();

    if (text.includes("order")) return "📦";
    if (text.includes("service")) return "🔧";
    if (text.includes("coupon")) return "🎟️";
    if (text.includes("payment")) return "💳";
    if (text.includes("profile")) return "👤";

    return "🔔";
  };
  const markNotificationRead = async (id) => {
    try {
      const token = localStorage.getItem("token");

      await axios.put(
        `https://ridercraft-api.onrender.com/notifications/${id}/read`,
        {},
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        },
      );

      window.location.reload();
    } catch (err) {
      console.error(err);
    }
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

          <button className="nav-btn" onClick={() => goToPath("/about")}>
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
          <div className="navbar-search">
            <input
              type="text"
              placeholder="Search helmets, gloves, accessories..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>

          {isAdmin && (
            <button className="nav-btn" onClick={() => goToPath("/admin")}>
              <span className="nav-chip chip-amber" />
              <span>Admin Panel</span>
            </button>
          )}
          <div ref={notificationRef} className="notification-wrapper">
            <button
              className="notification-btn"
              onClick={() => setShowNotifications(!showNotifications)}
            >
              <span>🔔</span>

              {notificationCount > 0 && (
                <span className="notification-badge">{notificationCount}</span>
              )}
            </button>

            {showNotifications && (
              <div className="notification-dropdown">
                <div className="notification-header">
                  <span>Notifications</span>

                  <button
                    className="mark-read-btn"
                    onClick={async () => {
                      try {
                        const token = localStorage.getItem("token");

                        await axios.put(
                          "https://ridercraft-api.onrender.com/notifications/read-all",
                          {},
                          {
                            headers: {
                              Authorization: `Bearer ${token}`,
                            },
                          },
                        );

                        window.location.reload();
                      } catch (err) {
                        console.error(err);
                      }
                    }}
                  >
                    Mark all read
                  </button>
                </div>

                {notifications?.length > 0 ? (
                  notifications.slice(0, 5).map((item, index) => (
                    <div
                      key={item._id}
                      className="notification-item"
                      onClick={() => markNotificationRead(item._id)}
                    >
                      <div>
                        <div className="notification-content">
                          <strong>
                            {getNotificationIcon(item.title)} {item.title}
                          </strong>

                          <p>{item.body}</p>

                          <small>{item.time || "Just now"}</small>
                        </div>

                        {!item.isRead && (
                          <div className="notification-unread"></div>
                        )}
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="notification-item">
                    <p>No notifications yet.</p>
                  </div>
                )}

                <button
                  className="view-all-btn"
                  onClick={() => {
                    setShowNotifications(false);
                    goToView("notifications");
                  }}
                >
                  View All Notifications
                </button>
              </div>
            )}
          </div>

          <button
            onClick={handleLogout}
            className="logout-btn nav-logout-mobile"
          >
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
