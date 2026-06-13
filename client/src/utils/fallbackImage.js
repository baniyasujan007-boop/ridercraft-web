export const DEFAULT_FALLBACK_IMAGE =
  "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='1200' height='1200' viewBox='0 0 1200 1200'><rect width='1200' height='1200' fill='%235d5f64'/><rect x='355' y='430' width='490' height='300' fill='none' stroke='%23e6e6e6' stroke-width='32'/><circle cx='732' cy='500' r='44' fill='%23e6e6e6'/><path d='M410 676 L500 486 L618 635 L690 582 L792 730 L410 730 Z' fill='%23e6e6e6'/><text x='600' y='845' text-anchor='middle' font-family='Arial, Helvetica, sans-serif' font-size='78' font-weight='700' fill='%23e6e6e6'>IMAGE NOT FOUND</text></svg>";

export const applyImageFallback = (event, fallbackImage = DEFAULT_FALLBACK_IMAGE) => {
  if (event.currentTarget.src !== fallbackImage) {
    event.currentTarget.src = fallbackImage;
  }
};
