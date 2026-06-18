const menuItems = [
  { key: "dashboard", label: "Dashboard", icon: "▦" },
  { key: "orders", label: "Orders", icon: "◫" },
  { key: "payments", label: "Payments", icon: "◍" },
  { key: "customers", label: "Customers", icon: "◎" },
  { key: "reports", label: "Reports", icon: "◷" },
  { key: "statistics", label: "Statistics", icon: "◪" },
  { key: "notifications", label: "Notifications", icon: "◉" },
  { key: "help", label: "Help", icon: "?" },
  { key: "settings", label: "Settings", icon: "◌" }
];

export default function OrdersSidebar({ mobileOpen, onLogout }) {
  return (
    <aside className={mobileOpen ? "orders-sidebar mobile-open" : "orders-sidebar"}>
      <div className="orders-logo-row">
        <div className="orders-logo-badge">PP</div>
        <div>
          <h1>ProfitPulse</h1>
          <p>Admin Console</p>
        </div>
      </div>

      <nav className="orders-nav-list">
        {menuItems.map((item) => (
          <button
            type="button"
            key={item.key}
            className={item.key === "orders" ? "orders-nav-item active" : "orders-nav-item"}
          >
            <span className="orders-nav-icon" aria-hidden>
              {item.icon}
            </span>
            <span>{item.label}</span>
          </button>
        ))}
      </nav>

      <button type="button" className="orders-logout-btn" onClick={onLogout}>
        Logout
      </button>
    </aside>
  );
}
