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
  expanded,
  onToggleDescription,
  selectedColor,
  onSelectColor,
  selectedSize,
  onSelectSize,
  onAddToCart,
  onCheckoutNow,
}) {
  const needsToggle = product.description.length > 145;
  const descriptionText =
    expanded || !needsToggle
      ? product.description
      : `${product.description.slice(0, 145).trim()}...`;

  return (
    <section className="pdp-summary">
      <p className="pdp-brand">{product.brand}</p>

      <h1 className="pdp-title">{product.title}</h1>
      <p className="pdp-brand-name">Brand: {product.brand}</p>
      <div
        className={
          product.stock > 0
            ? "pdp-stock-badge in-stock"
            : "pdp-stock-badge out-stock"
        }
      >
        {product.stock > 0 ? `✓ In Stock (${product.stock})` : "✕ Out of Stock"}
      </div>

      <div className="pdp-price-row">
        {product.oldPrice && (
          <p className="pdp-old-price">
            ₹{Number(product.oldPrice).toLocaleString("en-IN")}
          </p>
        )}{" "}
        <p className="pdp-new-price">
          ₹{Number(product.price).toLocaleString("en-IN")}
        </p>
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
            <p className="pdp-option-title">Size</p>

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
          type="button"
          onClick={onAddToCart}
        >
          Add to Cart
        </button>
        <button
          className="pdp-btn pdp-btn-outline"
          type="button"
          onClick={onCheckoutNow}
        >
          Checkout Now
        </button>
      </div>
      <div className="pdp-trust">
        <div className="pdp-trust-item">🔒 Secure Checkout</div>

        <div className="pdp-trust-item">🚚 Fast Delivery</div>

        <div className="pdp-trust-item">✅ Genuine Products</div>

        <div className="pdp-trust-item">↩️ Easy Returns</div>
      </div>
    </section>
  );
}
