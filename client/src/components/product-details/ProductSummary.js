function formatSoldCount(count) {
  if (count >= 1000) return `${(count / 1000).toFixed(1)}k sold`;
  return `${count} sold`;
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
  onCheckoutNow
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

      <div className="pdp-price-row">
        <p className="pdp-old-price">${product.oldPrice}</p>
        <p className="pdp-new-price">${product.price}</p>
      </div>

      <div className="pdp-meta-row">
        <span className="pdp-rating">★ {product.rating.toFixed(1)}</span>
        <span>{formatSoldCount(product.soldCount)}</span>
      </div>

      <div className="pdp-description">
        <p>{descriptionText}</p>
        {needsToggle && (
          <button className="pdp-link-btn" onClick={onToggleDescription} type="button">
            {expanded ? "See less" : "See more"}
          </button>
        )}
      </div>

      <div className="pdp-options">
        <div className="pdp-option-group">
          <p className="pdp-option-title">Color: {selectedColor.name}</p>
          <div className="pdp-color-row">
            {product.colors.map((color) => (
              <button
                key={color.name}
                title={color.name}
                className={
                  selectedColor.name === color.name
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

        <div className="pdp-option-group">
          <p className="pdp-option-title">Size</p>
          <div className="pdp-size-grid">
            {product.sizes.map((size) => (
              <button
                key={size}
                className={selectedSize === size ? "pdp-size-btn active" : "pdp-size-btn"}
                onClick={() => onSelectSize(size)}
                type="button"
              >
                {size}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="pdp-actions">
        <button className="pdp-btn pdp-btn-primary" type="button" onClick={onAddToCart}>
          Add to Cart
        </button>
        <button className="pdp-btn pdp-btn-outline" type="button" onClick={onCheckoutNow}>
          Checkout Now
        </button>
      </div>
    </section>
  );
}
