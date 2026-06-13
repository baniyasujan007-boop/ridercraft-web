import { applyImageFallback } from "../../utils/fallbackImage";

export default function ProductGallery({
  images,
  title,
  fallbackImage,
  activeImage,
  onSelectImage,
  onPrev,
  onNext
}) {
  const currentImage = images[activeImage] || fallbackImage;

  return (
    <section className="pdp-gallery">
      <div className="pdp-main-image-wrap">
        <button className="pdp-arrow pdp-arrow-left" onClick={onPrev} type="button">
          ‹
        </button>
        <img
          src={currentImage}
          alt={title}
          className="pdp-main-image"
          onError={(e) => applyImageFallback(e, fallbackImage)}
        />
        <button className="pdp-arrow pdp-arrow-right" onClick={onNext} type="button">
          ›
        </button>
      </div>

      <div className="pdp-thumbnails">
        {images.map((src, index) => (
          <button
            key={`${src || "fallback"}-${index}`}
            className={index === activeImage ? "pdp-thumb active" : "pdp-thumb"}
            onClick={() => onSelectImage(index)}
            type="button"
          >
            <img
              src={src || fallbackImage}
              alt={`${title} view ${index + 1}`}
              onError={(e) => applyImageFallback(e, fallbackImage)}
            />
          </button>
        ))}
      </div>
    </section>
  );
}
