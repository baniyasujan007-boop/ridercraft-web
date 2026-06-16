import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import axios from "axios";
import ProductGallery from "../components/product-details/ProductGallery";
import ProductSummary from "../components/product-details/ProductSummary";
import RelatedProducts from "../components/product-details/RelatedProducts";
import { useCart } from "../context";
import "../styles/pages/product-details.css";
import { DEFAULT_FALLBACK_IMAGE } from "../utils/fallbackImage";

function mapApiProductToUi(product) {
  const image = product.image || "";
  const colorMap = {
    black: "#1f1f1f",
    blue: "#2563eb",
    red: "#dc2626",
    green: "#16a34a",
    white: "#ffffff",
    gray: "#6b7280",
    grey: "#6b7280",
    yellow: "#eab308",
    orange: "#f97316"
  };
   const colorName = String(
    product.colorFamily || ""
  ).toLowerCase();
  return {
    id: product._id,
    brand: product.brand || "Generic",
    title: product.name || "Product",
    oldPrice: null,
    price: Number(product.price || 0),
    rating: Number(product.ratingAverage || 0),
    soldCount: Number(product.ratingCount || 0),
    reviews: Array.isArray(product.ratings)
      ? product.ratings
          .map((entry, index) => ({
            id: `${product._id}-${index}`,
            user: "Customer",
            value: Number(entry.value || 0),
            comment: String(entry.comment || "").trim()
          }))
          .sort((a, b) => b.value - a.value)
      : [],
    description:
  product.description || "",
   images: product.images?.length ? product.images : [image],
 colors: product.colorFamily
  ? [
      {
        name: product.colorFamily,
        value: product.colorHex || "#1f1f1f"
      } 
    ]
  : [],
   sizes: []
  };
}

export default function ProductDetails() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { addToCart } = useCart();
  const [product, setProduct] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [activeImage, setActiveImage] = useState(0);
  const [isExpanded, setIsExpanded] = useState(false);
  const [selectedColor, setSelectedColor] = useState(null);
  const [selectedSize, setSelectedSize] = useState("");
  const [relatedProducts, setRelatedProducts] = useState([]);

  useEffect(() => {
    const loadProduct = async () => {
      try {
        setLoading(true);
        setError("");

        const [productResult, productsResult] = await Promise.allSettled([
          axios.get(`https://ridercraft-api.onrender.com/products/${id}`),
          axios.get("https://ridercraft-api.onrender.com/products")
        ]);

        if (productResult.status === "fulfilled") {
          setProduct(mapApiProductToUi(productResult.value.data));
        } else {
          setProduct(null);
          setError("Could not load selected product.");
        }

        if (productsResult.status === "fulfilled") {
          const related = productsResult.value.data
            .filter((item) => item._id !== id)
            .slice(0, 4)
            .map((item) => mapApiProductToUi(item));
          setRelatedProducts(related);
        } else {
          setRelatedProducts([]);
        }
      } catch {
        setProduct(null);
        setRelatedProducts([]);
        setError("Could not load selected product.");
      } finally {
        setLoading(false);
      }
    };
    loadProduct();
  }, [id]);

  useEffect(() => {
    if (!product) return;
    setActiveImage(0);
    setIsExpanded(false);
  setSelectedColor(product.colors[0] || null);
setSelectedSize(product.sizes[0] || "");
  }, [product]);

  const fallbackImage = DEFAULT_FALLBACK_IMAGE;

  const handlePrevImage = () => {
    if (!product) return;
    setActiveImage((prev) => (prev === 0 ? product.images.length - 1 : prev - 1));
  };

  const handleNextImage = () => {
    if (!product) return;
    setActiveImage((prev) => (prev === product.images.length - 1 ? 0 : prev + 1));
  };

  const handleAddToCart = () => {
    if (!product) return;
    addToCart(product);
  };

  const handleCheckoutNow = () => {
    if (!product) return;
    addToCart(product);
    navigate("/landing", { state: { view: "cart" } });
  };

  const renderReviewStars = (value) => {
    const rounded = Math.max(0, Math.min(5, Number(value || 0)));
    const full = Math.floor(rounded);
    const hasHalf = rounded - full >= 0.5;
    return `${"★".repeat(full)}${hasHalf ? "☆" : ""}${"·".repeat(5 - full - (hasHalf ? 1 : 0))}`;
  };

  return (
    <main className="pdp-page">
      <div className="pdp-shell">
        <button className="pdp-back-btn" onClick={() => navigate("/landing")} type="button">
          Back to Shop
        </button>
        {loading && <p className="pdp-state">Loading product...</p>}
        {!loading && error && <p className="pdp-state pdp-state-error">{error}</p>}

       {!loading && product && (
          <>
            <section className="pdp-top-grid">
              <ProductGallery
                images={product.images}
                title={product.title}
                fallbackImage={fallbackImage}
                activeImage={activeImage}
                onSelectImage={setActiveImage}
                onPrev={handlePrevImage}
                onNext={handleNextImage}
              />

              <ProductSummary
                product={product}
                expanded={isExpanded}
                onToggleDescription={() => setIsExpanded((prev) => !prev)}
                selectedColor={selectedColor}
                onSelectColor={setSelectedColor}
                selectedSize={selectedSize}
                onSelectSize={setSelectedSize}
                onAddToCart={handleAddToCart}
                onCheckoutNow={handleCheckoutNow}
              />
            </section>

            <section className="pdp-reviews">
              <div className="pdp-reviews-head">
                <h2>Ratings & Reviews</h2>
                <p>
                  {product.rating.toFixed(1)} / 5 from {product.soldCount} ratings
                </p>
              </div>

              {product.reviews.length === 0 && (
                <p className="pdp-reviews-empty">
                  No reviews yet. Purchase this product to leave a rating from your orders.
                </p>
              )}

              <div className="pdp-reviews-list">
                {product.reviews.map((review) => (
                  <article className="pdp-review-card" key={review.id}>
                    <div className="pdp-review-top">
                      <p className="pdp-review-user">{review.user}</p>
                      <p className="pdp-review-rating">
                        {renderReviewStars(review.value)}{" "}
                        <span>{review.value.toFixed(1)}</span>
                      </p>
                    </div>
                    <p className="pdp-review-comment">
                      {review.comment || "No comment provided."}
                    </p>
                  </article>
                ))}
              </div>
            </section>

            <RelatedProducts
              products={relatedProducts}
              fallbackImage={fallbackImage}
              onOpenProduct={(productId) => {
                navigate(`/products/${productId}`);
                window.scrollTo({ top: 0, behavior: "smooth" });
              }}
            />
          </>
        )}
      </div>
    </main>
  );
}
