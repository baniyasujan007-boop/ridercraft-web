import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import axios from "axios";
import ProductGallery from "../components/ProductGallery";
import ProductSummary from "../components/ProductSummary";
import RelatedProducts from "../components/RelatedProducts";
import { useCart } from "../../../context";
import "../styles/product-details.css";
import { DEFAULT_FALLBACK_IMAGE } from "../../../utils/fallbackImage";

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
    orange: "#f97316",
  };

  const variants = Array.isArray(product.variants)
    ? product.variants.map((variant) => ({
        id: variant._id || variant.id || variant.sku || variant.color,
        name: variant.color || "Default",
        value:
          variant.colorHex ||
          colorMap[String(variant.color || "").trim().toLowerCase()] ||
          "#1f1f1f",
        images: Array.isArray(variant.images)
          ? variant.images.filter(Boolean)
          : [],
        stock: Number(variant.stock || 0),
        sku: variant.sku || "",
      }))
    : [];
  const legacyColors = Array.isArray(product.colors)
    ? product.colors.map((color) => ({
        id: color,
        name: color,
        value: colorMap[String(color).trim().toLowerCase()] || "#1f1f1f",
        images: [],
        stock: Number(product.stock || 0),
        sku: "",
      }))
    : [];
  const activeFlashSale = Boolean(product.isFlashSaleActive || product.isFlashSale);
  const originalPrice = Number(product.originalPrice || product.price || 0);
  const displayPrice = Number(product.displayPrice || product.price || 0);

  return {
    id: product._id,
    brand: product.brand || "Generic",
    title: product.name || "Product",
    isFlashSale: activeFlashSale,
    oldPrice: activeFlashSale ? originalPrice : null,
    price: displayPrice,
    originalPrice,
    flashSalePrice: Number(product.flashSalePrice || 0),
    discountPercent: Number(product.discountPercent || 0),
    rating: Number(product.ratingAverage || 0),
    soldCount: Number(product.ratingCount || 0),
    stock: Number(product.stock || 0),
    reviews: Array.isArray(product.ratings)
      ? product.ratings
          .map((entry, index) => ({
            id: `${product._id}-${index}`,
            user: "Customer",
            value: Number(entry.value || 0),
            comment: String(entry.comment || "").trim(),
          }))
          .sort((a, b) => b.value - a.value)
      : [],
    description: product.description || "",
    images: product.images?.length ? product.images : [image].filter(Boolean),
    variants,
    colors: variants.length ? variants : legacyColors,
    sizes: Array.isArray(product.sizes) ? product.sizes : [],
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
          axios.get("https://ridercraft-api.onrender.com/products"),
        ]);

        if (productResult.status === "fulfilled") {
          setProduct(mapApiProductToUi(productResult.value.data));
        } else {
          setProduct(null);
          setError("Could not load selected product.");
        }

        if (
          productsResult.status === "fulfilled" &&
          productResult.status === "fulfilled"
        ) {
          const currentProduct = productResult.value.data;

          const related = productsResult.value.data
            .filter(
              (item) => item._id !== id && item.tag === currentProduct.tag,
            )
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
  const activeImages =
    selectedColor?.images?.length > 0
      ? selectedColor.images
      : product?.images?.length
        ? product.images
        : [fallbackImage];
  const currentStock =
    selectedColor && Number.isFinite(Number(selectedColor.stock))
      ? Number(selectedColor.stock)
      : Number(product?.stock || 0);

  const handlePrevImage = () => {
    if (!product) return;
    setActiveImage((prev) =>
      prev === 0 ? activeImages.length - 1 : prev - 1,
    );
  };

  const handleNextImage = () => {
    if (!product) return;
    setActiveImage((prev) =>
      prev === activeImages.length - 1 ? 0 : prev + 1,
    );
  };

  const handleAddToCart = () => {
    if (!product) return;
    addToCart({
      ...product,
      stock: currentStock,
      selectedVariant: selectedColor,
      image: activeImages[activeImage] || activeImages[0],
    });
  };

  const handleCheckoutNow = () => {
    if (!product) return;
    addToCart({
      ...product,
      stock: currentStock,
      selectedVariant: selectedColor,
      image: activeImages[activeImage] || activeImages[0],
    });
    navigate("/landing", { state: { view: "cart" } });
  };

  const handleSelectColor = (color) => {
    setSelectedColor(color);
    setActiveImage(0);
  };

  const renderReviewStars = (value) => {
    const rounded = Math.max(0, Math.min(5, Number(value || 0)));
    const full = Math.floor(rounded);
    const hasHalf = rounded - full >= 0.5;
    return `${"★".repeat(full)}${hasHalf ? "☆" : ""}${"·".repeat(5 - full - (hasHalf ? 1 : 0))}`;
  };

const reviewCounts = product
  ? [5, 4, 3, 2, 1].map(
      (star) =>
        (product.reviews || []).filter(
          (review) => Math.round(review.value) === star
        ).length
    )
  : [0, 0, 0, 0, 0];

const totalReviews = reviewCounts.reduce(
  (sum, count) => sum + count,
  0
);

  return (
    <main className="pdp-page">
      <div className="pdp-shell">
        <div className="pdp-breadcrumbs">
          <span onClick={() => navigate("/landing")}>Home</span>

          <span className="pdp-breadcrumb-separator">›</span>

          <span>Shop</span>

          <span className="pdp-breadcrumb-separator">›</span>

          <span>{product?.brand || "Product"}</span>

          <span className="pdp-breadcrumb-separator">›</span>

          <span className="active">{product?.title}</span>
        </div>
        <button
          className="pdp-back-btn"
          onClick={() => navigate("/landing")}
          type="button"
        >
          Back to Shop
        </button>
        {loading && <p className="pdp-state">Loading product...</p>}
        {!loading && error && (
          <p className="pdp-state pdp-state-error">{error}</p>
        )}

        {!loading && product && (
          <>
            <section className="pdp-top-grid">
              <ProductGallery
                images={activeImages}
                title={product.title}
                fallbackImage={fallbackImage}
                activeImage={activeImage}
                onSelectImage={setActiveImage}
                onPrev={handlePrevImage}
                onNext={handleNextImage}
              />

              <ProductSummary
                product={product}
                stock={currentStock}
                expanded={isExpanded}
                onToggleDescription={() => setIsExpanded((prev) => !prev)}
                selectedColor={selectedColor}
                onSelectColor={handleSelectColor}
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
                  {product.rating.toFixed(1)} / 5 from {product.soldCount}{" "}
                  ratings
                </p>
              </div>

              <div className="pdp-review-summary">
                <div className="pdp-review-score">
                  <h3>{product.rating.toFixed(1)}</h3>
                  <p>★★★★★</p>
                  <span>{totalReviews} reviews</span>
                </div>

                <div className="pdp-review-bars">
                  {[5, 4, 3, 2, 1].map((star, index) => {
                    const count = reviewCounts[index];
                    const width =
                      totalReviews > 0
                        ? `${(count / totalReviews) * 100}%`
                        : "0%";

                    return (
                      <div className="pdp-review-bar" key={star}>
                        <span>{star}★</span>

                        <div className="pdp-bar-track">
                          <div className="pdp-bar-fill" style={{ width }} />
                        </div>

                        <strong>{count}</strong>
                      </div>
                    );
                  })}
                </div>

                {product.reviews.length === 0 && (
                  <div className="pdp-reviews-empty">
                    <strong>No reviews yet</strong>
                    <span>Be the first to review this product</span>
                    <button className="pdp-review-btn" type="button">
                      Write a Review
                    </button>
                  </div>
                )}
              </div>

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
