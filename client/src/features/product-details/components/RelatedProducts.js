import { applyImageFallback } from "../../../utils/fallbackImage";

export default function RelatedProducts({
  products,
  fallbackImage,
  onOpenProduct,
}) {
  const formatCurrency = (value) => `₹${Number(value || 0).toLocaleString("en-IN")}`;

  const getDisplayPrice = (p) =>
    Number(p.isFlashSale ? p.flashSalePrice || p.displayPrice || p.price : p.displayPrice ?? p.price ?? 0);
  const getOriginalPrice = (p) => Number(p.originalPrice ?? p.oldPrice ?? p.price ?? 0);
  const isFlash = (p) => Boolean(p.isFlashSaleActive || p.isFlashSale);
  const getDiscountPercent = (p, displayPrice, originalPrice) => {
    const explicitDiscount = Number(p.discountPercent || 0);
    if (explicitDiscount > 0) return explicitDiscount;
    if (!originalPrice || displayPrice >= originalPrice) return 0;
    return Math.round(((originalPrice - displayPrice) / originalPrice) * 100);
  };
  const getImage = (p) => {
    return (
      (p.variants && p.variants.find((v) => v.images?.length)?.images?.[0]) ||
      (Array.isArray(p.images) && p.images[0]) ||
      p.image ||
      fallbackImage
    );
  };

  return (
    <section className="pdp-related">
      <div className="pdp-related-head">
        <h2>Related Products</h2>
      </div>

      <div className="pdp-related-grid">
        {products.map((item) => {
          const imageSrc = getImage(item) || fallbackImage;
          const displayPrice = getDisplayPrice(item);
          const originalPrice = getOriginalPrice(item);
          const isFlashSale = isFlash(item);
          const discount = getDiscountPercent(item, displayPrice, originalPrice);

          return (
            <article
              className="pdp-related-card"
              key={item.id}
              onClick={() => onOpenProduct(item.id)}
            >
              <div className="pdp-related-image-wrap">
                <img
                  src={imageSrc}
                  alt={item.title}
                  className="pdp-related-image"
                  onError={(e) => applyImageFallback(e, fallbackImage)}
                />
              </div>

              <p className="pdp-related-name">{item.title}</p>

              {isFlashSale && (
                <span className="pdp-related-flash-badge">⚡ Flash Sale</span>
              )}

              <div className="pdp-related-rating">
                ⭐ {item.rating?.toFixed(1) || "0.0"}
              </div>

              <p className="pdp-related-price">
                {isFlashSale && originalPrice > displayPrice ? (
                  <>
                    <strong>{formatCurrency(displayPrice)}</strong>
                    <small>
                      <s>{formatCurrency(originalPrice)}</s>
                      {discount ? ` ${discount}% OFF` : ""}
                    </small>
                  </>
                ) : (
                  <>{formatCurrency(displayPrice)}</>
                )}
              </p>

              <button
                className="pdp-related-btn"
                onClick={(e) => {
                  e.stopPropagation();
                  onOpenProduct(item.id);
                }}
              >
                View Product
              </button>
            </article>
          );
        })}
      </div>
    </section>
  );
}
