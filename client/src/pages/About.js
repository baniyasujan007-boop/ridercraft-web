import { useEffect, useMemo, useState } from "react";
import { jwtDecode } from "jwt-decode";
import api from "../services/api";
import "../styles/pages/about.css";
import { applyImageFallback, DEFAULT_FALLBACK_IMAGE } from "../utils/fallbackImage";

const toNumber = (value) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
};

export default function About() {
  const [products, setProducts] = useState([]);
  const [profile, setProfile] = useState(null);
  const [adminStats, setAdminStats] = useState(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadAboutData = async () => {
      try {
        setLoading(true);
        setError("");
        const token = localStorage.getItem("token");
        let role = null;
        if (token) {
          try {
            role = jwtDecode(token)?.role || null;
          } catch {
            role = null;
          }
        }
        const headers = token ? { Authorization: `Bearer ${token}` } : undefined;

        const requests = [{ key: "products", request: api.get("/products") }];
        if (headers) requests.push({ key: "profile", request: api.get("/auth/profile", { headers }) });
        if (headers && role === "admin") {
          requests.push({ key: "orders", request: api.get("/orders", { headers }) });
          requests.push({ key: "promos", request: api.get("/promos", { headers }) });
        }

        const results = await Promise.allSettled(requests.map((item) => item.request));
        const dataByKey = requests.reduce((acc, request, index) => {
          acc[request.key] = results[index];
          return acc;
        }, {});
        const productsResult = dataByKey.products;
        const profileResult = dataByKey.profile;
        const ordersResult = dataByKey.orders;
        const promosResult = dataByKey.promos;

        if (productsResult?.status === "fulfilled") {
          setProducts(Array.isArray(productsResult.value.data) ? productsResult.value.data : []);
        }
        if (profileResult?.status === "fulfilled") {
          setProfile(profileResult.value.data);
        }
        if (ordersResult?.status === "fulfilled" && promosResult?.status === "fulfilled") {
          setAdminStats({
            ordersCount: ordersResult.value.data.length || 0,
            promoCount: promosResult.value.data.length || 0
          });
        } else {
          setAdminStats(null);
        }
      } catch {
        setError("Could not load live data for this page.");
      } finally {
        setLoading(false);
      }
    };

    loadAboutData();
  }, []);

  const stats = useMemo(() => {
    const productCount = products.length;
    const categoryCount = new Set(products.map((item) => item.tag || "General")).size;
    const brandCount = new Set(products.map((item) => item.brand || "Generic")).size;
    const ratingValues = products
      .map((item) => toNumber(item.ratingAverage))
      .filter((value) => Number.isFinite(value) && value > 0);
    const avgRating = ratingValues.length
      ? Number((ratingValues.reduce((sum, value) => sum + value, 0) / ratingValues.length).toFixed(1))
      : 0;
    return { productCount, categoryCount, brandCount, avgRating };
  }, [products]);

  const topProducts = useMemo(() => {
    return [...products]
      .sort((a, b) => toNumber(b.ratingAverage) - toNumber(a.ratingAverage))
      .slice(0, 6);
  }, [products]);

  return (
    <div className="about-live-page">
      <section className="about-live-hero">
        <h1>About RiderCraft</h1>
        <p>
          This page is powered by live data from your current catalog and account.
        </p>
      </section>

      {loading && <p className="about-live-message">Loading real store data...</p>}
      {error && <p className="about-live-error">{error}</p>}

      {!loading && (
        <>
          <section className="about-live-stats">
            <article className="about-live-stat">
              <h3>{stats.productCount}</h3>
              <p>Products Listed</p>
            </article>
            <article className="about-live-stat">
              <h3>{stats.categoryCount}</h3>
              <p>Categories</p>
            </article>
            <article className="about-live-stat">
              <h3>{stats.brandCount}</h3>
              <p>Brands</p>
            </article>
            <article className="about-live-stat">
              <h3>{stats.avgRating.toFixed(1)}★</h3>
              <p>Average Product Rating</p>
            </article>
          </section>

          {profile && (
            <section className="about-live-section">
              <h2>Account Snapshot</h2>
              <div className="about-live-card">
                <p><strong>Name:</strong> {profile.name || "N/A"}</p>
                <p><strong>Email:</strong> {profile.email || "N/A"}</p>
                <p><strong>Role:</strong> {profile.role || "user"}</p>
              </div>
            </section>
          )}

          {adminStats && (
            <section className="about-live-section">
              <h2>Operational Snapshot (Admin)</h2>
              <div className="about-live-card-grid">
                <div className="about-live-card">
                  <p><strong>{adminStats.ordersCount}</strong></p>
                  <p>Total Orders</p>
                </div>
                <div className="about-live-card">
                  <p><strong>{adminStats.promoCount}</strong></p>
                  <p>Promo Codes</p>
                </div>
              </div>
            </section>
          )}

          <section className="about-live-section">
            <h2>Top Rated Products</h2>
            <div className="about-live-product-grid">
              {topProducts.map((product, index) => (
                <article key={product._id || `${product.name || "product"}-${index}`} className="about-live-product-card">
                  <img
                    src={product.image || DEFAULT_FALLBACK_IMAGE}
                    alt={product.name}
                    onError={applyImageFallback}
                  />
                  <div>
                    <p className="about-live-product-title">{product.name}</p>
                    <p className="about-live-product-meta">
                      {(product.brand || "Generic")} • {(product.tag || "General")}
                    </p>
                    <p className="about-live-product-meta">
                      ${toNumber(product.price).toFixed(2)} • {toNumber(product.ratingAverage).toFixed(1)}★
                    </p>
                  </div>
                </article>
              ))}
              {topProducts.length === 0 && (
                <p className="about-live-message">No products available yet.</p>
              )}
            </div>
          </section>
        </>
      )}
    </div>
  );
}
