const toNumber = (value, fallback = 0) => {
  const number = Number(value);
  return Number.isFinite(number) ? number : fallback;
};

export const CART_AVAILABILITY_STATUS = {
  IN_STOCK: "in-stock",
  OUT_OF_STOCK: "out-of-stock",
  EXCEEDS_STOCK: "exceeds-stock",
  UNAVAILABLE: "unavailable",
  MISSING: "missing",
};

export const resolveProductVariant = (product, variantId) => {
  if (!variantId || !Array.isArray(product?.variants)) return null;
  const key = String(variantId);
  return (
    product.variants.find(
      (variant) => String(variant?._id ?? variant?.id ?? "") === key,
    ) || null
  );
};

export const getAvailableStock = (product, variantId) => {
  if (!product) return 0;
  if (variantId) {
    const variant = resolveProductVariant(product, variantId);
    if (!variant) return 0;
    return Math.max(0, toNumber(variant.stock));
  }
  return Math.max(0, toNumber(product.stock));
};

export const getCartItemLookupKey = (item) =>
  String(item?._id ?? item?.productId ?? "");

export const resolveCartItemAvailability = (item, product) => {
  const productId = String(item?.productId || item?._id || "");
  const variantId = String(item?.variantId || "");
  const qty = Math.max(1, toNumber(item?.qty, 1));

  if (!product) {
    return {
      status: CART_AVAILABILITY_STATUS.MISSING,
      reason: "product-unavailable",
      availableStock: 0,
      isUnavailable: true,
      exceedsStock: false,
      productId,
      qty,
    };
  }

  if (variantId && !resolveProductVariant(product, variantId)) {
    return {
      status: CART_AVAILABILITY_STATUS.UNAVAILABLE,
      reason: "variant-unavailable",
      availableStock: 0,
      isUnavailable: true,
      exceedsStock: false,
      productId,
      qty,
    };
  }

  const availableStock = getAvailableStock(product, variantId);
  if (availableStock <= 0) {
    return {
      status: CART_AVAILABILITY_STATUS.OUT_OF_STOCK,
      reason: "out-of-stock",
      availableStock: 0,
      isUnavailable: true,
      exceedsStock: false,
      productId,
      qty,
    };
  }
  if (qty > availableStock) {
    return {
      status: CART_AVAILABILITY_STATUS.EXCEEDS_STOCK,
      reason: "exceeds-stock",
      availableStock,
      isUnavailable: true,
      exceedsStock: true,
      productId,
      qty,
    };
  }
  return {
    status: CART_AVAILABILITY_STATUS.IN_STOCK,
    reason: "in-stock",
    availableStock,
    isUnavailable: false,
    exceedsStock: false,
    productId,
    qty,
  };
};

export const buildCartAvailability = (products, cart) => {
  const productById = new Map();
  (Array.isArray(products) ? products : []).forEach((product) => {
    const id = String(product?._id ?? product?.id ?? "");
    if (id) productById.set(id, product);
  });

  const availability = {};
  (Array.isArray(cart) ? cart : []).forEach((item) => {
    const productId = String(item?.productId || item?._id || "");
    const product = productId ? productById.get(productId) : undefined;
    availability[getCartItemLookupKey(item)] = resolveCartItemAvailability(
      item,
      product,
    );
  });
  return availability;
};

export const getUnavailableCount = (availabilityMap, cart) =>
  (Array.isArray(cart) ? cart : []).filter(
    (item) => availabilityMap[getCartItemLookupKey(item)]?.isUnavailable,
  ).length;

export const getAvailabilityMessage = (availability) => {
  if (!availability) return { text: "In stock", tone: "in-stock" };
  switch (availability.status) {
    case CART_AVAILABILITY_STATUS.OUT_OF_STOCK:
      return { text: "Out of stock", tone: "out-of-stock" };
    case CART_AVAILABILITY_STATUS.EXCEEDS_STOCK:
      return {
        text: `Only ${availability.availableStock} available — reduce quantity`,
        tone: "out-of-stock",
      };
    case CART_AVAILABILITY_STATUS.UNAVAILABLE:
    case CART_AVAILABILITY_STATUS.MISSING:
      return { text: "Unavailable", tone: "unavailable" };
    case CART_AVAILABILITY_STATUS.IN_STOCK:
    default:
      return { text: "In stock", tone: "in-stock" };
  }
};