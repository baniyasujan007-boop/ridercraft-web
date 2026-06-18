import { Link, useEffect, useState } from "react-router-dom";
import ridercraftLogo from "../../assets/ridercraft-logo.png";

export default function SiteHeader({
  searchQuery,
  setSearchQuery,
}) {
  // Debug: show whether SiteHeader received props
  // Note: when SiteHeader is mounted from AppShell without props, we fall back
  // to local state and emit a global event so Landing can listen and update.
  console.log("SiteHeader props:", { searchQuery, setSearchQuery });

  const [localQuery, setLocalQuery] = useState(searchQuery || "");

  useEffect(() => {
    // keep localQuery in sync when parent passes searchQuery
    if (typeof searchQuery === "string") setLocalQuery(searchQuery);
  }, [searchQuery]);

  const handleChange = (e) => {
    const v = e.target.value;
    console.log("SiteHeader input change:", v);
    if (typeof setSearchQuery === "function") {
      setSearchQuery(v);
    } else {
      setLocalQuery(v);
      // emit global event so Landing (which owns shopQuery) can pick it up
      try {
        window.dispatchEvent(new CustomEvent("shopQueryChange", { detail: v }));
      } catch (err) {
        // fallback for environments that don't support CustomEvent constructor
        const ev = document.createEvent("CustomEvent");
        ev.initCustomEvent("shopQueryChange", true, true, v);
        window.dispatchEvent(ev);
      }
    }
  };

  const inputValue = typeof setSearchQuery === "function" ? searchQuery || "" : localQuery;

  return (
    <header className="site-header">
      <div className="site-header-glow" />

      <div className="site-header-inner">
        <Link
          to="/landing"
          className="site-logo"
          aria-label="RiderCraft home"
        >
          <span className="site-logo-mark" aria-hidden>
            <img
              src={ridercraftLogo}
              alt=""
              className="site-logo-image"
            />
          </span>

          <span className="site-logo-text-wrap">
            <span className="site-logo-text">RiderCraft</span>
            <span className="site-logo-sub">
              Ride Essentials
            </span>
          </span>
        </Link>

        <div className="site-header-search">
          <input
            type="text"
            placeholder="Search helmets, gloves, riding gear..."
            value={inputValue}
            onChange={handleChange}
          />

          <button className="header-search-btn">🔍</button>
        </div>
      </div>
    </header>
  );
}