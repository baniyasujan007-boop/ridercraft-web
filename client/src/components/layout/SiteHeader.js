import { Link } from "react-router-dom";
import ridercraftLogo from "../../assets/ridercraft-logo.png";

export default function SiteHeader() {
  return (
    <header className="site-header">
      <div className="site-header-glow" />
      <div className="site-header-inner">
        <Link to="/landing" className="site-logo" aria-label="RiderCraft home">
          <span className="site-logo-mark" aria-hidden>
            <img src={ridercraftLogo} alt="" className="site-logo-image" />
          </span>
          <span className="site-logo-text-wrap">
            <span className="site-logo-text">RiderCraft</span>
            <span className="site-logo-sub">Ride Essentials</span>
          </span>
        </Link>
      </div>
    </header>
  );
}
