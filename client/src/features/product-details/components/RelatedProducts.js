import { applyImageFallback } from "../../../utils/fallbackImage";

export default function RelatedProducts({
  products,
  fallbackImage,
  onOpenProduct,
}) {
  return (
    <section className="pdp-related">
      <div className="pdp-related-head">
        <h2>Related Products</h2>
      </div>

      <div className="pdp-related-grid">
        {products.map((item) => (
          <article
            className="pdp-related-card"
            key={item.id}
            onClick={() => onOpenProduct(item.id)}
          >
            <div className="pdp-related-image-wrap">
              <img
                src={item.images[0] || fallbackImage}
                alt={item.title}
                className="pdp-related-image"
                onError={(e) => applyImageFallback(e, fallbackImage)}
              />
            </div>
            <p className="pdp-related-name">{item.title}</p>

            <div className="pdp-related-rating">
              ⭐ {item.rating?.toFixed(1) || "0.0"}
            </div>

            <p className="pdp-related-price">
              ₹{Number(item.price).toLocaleString("en-IN")}
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
        ))}
      </div>
    </section>
  );
}
