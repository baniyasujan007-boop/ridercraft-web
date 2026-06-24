function formatSoldCount(count) {
  if (count >= 1000) return `${(count / 1000).toFixed(1)}k sold`;
  return `${count} sold`;
}

function renderRatingStars(value) {
  const rounded =
    Math.round(Math.max(0, Math.min(5, Number(value || 0))) * 2) / 2;
  return [1, 2, 3, 4, 5].map((star) => {
    const isFull = star <= rounded;
    const isHalf = !isFull && star - 0.5 === rounded;
    return (
      <span
        key={star}
        className={`pdp-display-star${isFull ? " pdp-display-star-full" : ""}${isHalf ? " pdp-display-star-half" : ""}`}
      >
        ★
      </span>
    );
  });
}

export default function ProductSummary({
  product,
  stock,
  expanded,
  onToggleDescription,
  selectedColor,
  onSelectColor,
  selectedSize,
  onSelectSize,
  onAddToCart,
  onCheckoutNow,
  isWishlisted,
  onToggleWishlist,
  onShare,
}) {
  const visibleStock = Number.isFinite(Number(stock))
    ? Number(stock)
    : Number(product.stock || 0);
  const needsToggle = product.description.length > 145;
  const descriptionText =
    expanded || !needsToggle
      ? product.description
      : `${product.description.slice(0, 145).trim()}...`;

  return (
    <section className="pdp-summary">
      <div className="pdp-top-actions">
        <button
          type="button"
          className={isWishlisted ? "active" : ""}
          aria-label={isWishlisted ? "Remove from wishlist" : "Add to wishlist"}
          onClick={onToggleWishlist}
        >
          {isWishlisted ? "♥" : "♡"}
        </button>
        <button type="button" aria-label="Share product" onClick={onShare}>
          ↗
        </button>
      </div>
      <p className="pdp-brand">{product.brand}</p>

      <h1 className="pdp-title">{product.title}</h1>
      {product.isFlashSale && (
        <div className="pdp-flash-badge">⚡ Flash Sale</div>
      )}
      <p className="pdp-brand-name">Brand: {product.brand}</p>
      <div
        className={
          visibleStock > 0
            ? "pdp-stock-badge in-stock"
            : "pdp-stock-badge out-stock"
        }
      >
        {visibleStock > 0 ? `✓ In Stock (${visibleStock})` : "✕ Out of Stock"}
      </div>

      <div className="pdp-price-card">
        <div className="pdp-price-row">
          {product.oldPrice && (
            <p className="pdp-old-price">
              ₹{product.oldPrice.toLocaleString("en-IN")}
            </p>
          )}

          <p className="pdp-new-price">
            ₹{product.price.toLocaleString("en-IN")}
          </p>
        </div>

        {product.oldPrice && (
          <div className="pdp-discount-badge">
            {product.discountPercent ||
              Math.round(
                ((product.oldPrice - product.price) / product.oldPrice) * 100,
              )}
            % OFF
          </div>
        )}
      </div>
      <div className="pdp-highlights">
        <div className="pdp-highlight-item">✅ Genuine Product</div>

        <div className="pdp-highlight-item">🚚 Fast Delivery</div>

        <div className="pdp-highlight-item">🔒 Secure Payment</div>

        <div className="pdp-highlight-item">↩ Easy Returns</div>
      </div>

      <div className="pdp-meta-row">
        <span
          className="pdp-rating"
          aria-label={`Rating ${product.rating.toFixed(1)} out of 5`}
        >
          <span className="pdp-display-star-row">
            {renderRatingStars(product.rating)}
          </span>
          <strong>{product.rating.toFixed(1)} / 5</strong>
        </span>
        <span>{formatSoldCount(product.soldCount)} ratings</span>
      </div>

      {product.description && (
        <div className="pdp-description">
          <p>{descriptionText}</p>
          {needsToggle && (
            <button
              className="pdp-link-btn"
              onClick={onToggleDescription}
              type="button"
            >
              {expanded ? "See less" : "See more"}
            </button>
          )}
        </div>
      )}
      <div className="pdp-options">
        {product.colors.length > 0 && (
          <div className="pdp-option-group">
            <p className="pdp-option-title">Color: {selectedColor?.name}</p>

            <div className="pdp-color-row">
              {product.colors.map((color) => (
                <button
                  key={color.name}
                  title={color.name}
                  className={
                    selectedColor?.name === color.name
                      ? "pdp-color-swatch active"
                      : "pdp-color-swatch"
                  }
                  style={{ backgroundColor: color.value }}
                  onClick={() => onSelectColor(color)}
                  type="button"
                />
              ))}
            </div>
          </div>
        )}

        {product.sizes.length > 0 && (
          <div className="pdp-option-group">
            <p className="pdp-option-title">Size: {selectedSize}</p>
            <div className="pdp-size-grid">
              {product.sizes.map((size) => (
                <button
                  key={size}
                  className={
                    selectedSize === size
                      ? "pdp-size-btn active"
                      : "pdp-size-btn"
                  }
                  onClick={() => onSelectSize(size)}
                  type="button"
                >
                  {size}
                </button>
              ))}
            </div>
          </div>
        )}
      </div>
      <div className="pdp-actions">
        <button
          className="pdp-btn pdp-btn-primary"
          onClick={onAddToCart}
          type="button"
        >
          🛒 Add to Cart
        </button>

        <button
          className="pdp-btn pdp-btn-outline"
          onClick={onCheckoutNow}
          type="button"
        >
          ⚡ Buy Now
        </button>
      </div>
      <div className="pdp-trust-bar">
        <div>🛡 100% Genuine</div>
        <div>🚚 Free Shipping</div>
        <div>↩ Easy Returns</div>
        <div>💳 Secure Payment</div>
      </div>
      <div className="pdp-mobile-bar">
        <div className="pdp-mobile-price">
          ₹{product.price.toLocaleString("en-IN")}
        </div>

        <button
          className="pdp-mobile-cart-btn"
          onClick={onAddToCart}
          type="button"
        >
          Add to Cart
        </button>
      </div>
    </section>
  );
}
