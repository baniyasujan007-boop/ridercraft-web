import {
  buildCartAvailability,
  getAvailableStock,
  getCartItemLookupKey,
  getUnavailableCount,
  resolveCartItemAvailability,
  CART_AVAILABILITY_STATUS,
} from "./cartAvailability";

const makeItem = (overrides = {}) => ({
  _id: "p1",
  productId: "p1",
  variantId: "",
  qty: 1,
  ...overrides,
});

const makeProduct = (overrides = {}) => ({
  _id: "p1",
  name: "Helmet",
  price: 100,
  stock: 10,
  ...overrides,
});

describe("getAvailableStock", () => {
  test("returns product stock when no variant", () => {
    expect(getAvailableStock(makeProduct({ stock: 7 }), "")).toBe(7);
  });

  test("returns 0 for missing product", () => {
    expect(getAvailableStock(null, "")).toBe(0);
  });

  test("returns variant stock when variant selected", () => {
    const product = makeProduct({
      variants: [
        { _id: "v1", color: "Red", stock: 3 },
        { _id: "v2", color: "Blue", stock: 8 },
      ],
    });
    expect(getAvailableStock(product, "v1")).toBe(3);
    expect(getAvailableStock(product, "v2")).toBe(8);
  });

  test("returns 0 when selected variant missing", () => {
    const product = makeProduct({
      variants: [{ _id: "v1", color: "Red", stock: 3 }],
    });
    expect(getAvailableStock(product, "nope")).toBe(0);
  });

  test("coerces string stock values", () => {
    expect(getAvailableStock(makeProduct({ stock: "4" }), "")).toBe(4);
  });

  test("never returns negative stock", () => {
    expect(getAvailableStock(makeProduct({ stock: -2 }), "")).toBe(0);
  });
});

describe("resolveCartItemAvailability", () => {
  test("in stock when qty fits", () => {
    const result = resolveCartItemAvailability(
      makeItem({ qty: 2 }),
      makeProduct({ stock: 3 }),
    );
    expect(result.status).toBe(CART_AVAILABILITY_STATUS.IN_STOCK);
    expect(result.isUnavailable).toBe(false);
    expect(result.availableStock).toBe(3);
  });

  test("out of stock when stock is zero", () => {
    const result = resolveCartItemAvailability(
      makeItem({ qty: 1 }),
      makeProduct({ stock: 0 }),
    );
    expect(result.status).toBe(CART_AVAILABILITY_STATUS.OUT_OF_STOCK);
    expect(result.isUnavailable).toBe(true);
  });

  test("out of stock for variant when variant stock is zero", () => {
    const product = makeProduct({
      variants: [{ _id: "v1", color: "Red", stock: 0 }],
    });
    const result = resolveCartItemAvailability(
      makeItem({ variantId: "v1" }),
      product,
    );
    expect(result.status).toBe(CART_AVAILABILITY_STATUS.OUT_OF_STOCK);
    expect(result.isUnavailable).toBe(true);
  });

  test("exceeds stock when qty above available stock", () => {
    const result = resolveCartItemAvailability(
      makeItem({ qty: 5 }),
      makeProduct({ stock: 3 }),
    );
    expect(result.status).toBe(CART_AVAILABILITY_STATUS.EXCEEDS_STOCK);
    expect(result.exceedsStock).toBe(true);
    expect(result.availableStock).toBe(3);
    expect(result.isUnavailable).toBe(true);
  });

  test("missing when product not found", () => {
    const result = resolveCartItemAvailability(makeItem(), null);
    expect(result.status).toBe(CART_AVAILABILITY_STATUS.MISSING);
    expect(result.isUnavailable).toBe(true);
  });

  test("unavailable when selected variant removed", () => {
    const product = makeProduct({
      variants: [{ _id: "v1", color: "Red", stock: 5 }],
    });
    const result = resolveCartItemAvailability(
      makeItem({ variantId: "gone" }),
      product,
    );
    expect(result.status).toBe(CART_AVAILABILITY_STATUS.UNAVAILABLE);
    expect(result.isUnavailable).toBe(true);
  });
});

describe("buildCartAvailability", () => {
  test("maps each cart item by lookup key", () => {
    const products = [makeProduct({ _id: "p1", stock: 3 })];
    const cart = [
      makeItem({ _id: "p1", productId: "p1", qty: 1 }),
      makeItem({ _id: "p2", productId: "p2", qty: 1 }),
    ];
    const map = buildCartAvailability(products, cart);
    expect(map["p1"].status).toBe(CART_AVAILABILITY_STATUS.IN_STOCK);
    expect(map["p2"].status).toBe(CART_AVAILABILITY_STATUS.MISSING);
  });

  test("resolves via cart item _id when productId absent", () => {
    const products = [makeProduct({ _id: "p1", stock: 3 })];
    const cart = [makeItem({ _id: "p1", productId: "", qty: 1 })];
    const map = buildCartAvailability(products, cart);
    expect(map["p1"].status).toBe(CART_AVAILABILITY_STATUS.IN_STOCK);
  });
});

describe("getCartItemLookupKey", () => {
  test("prefers _id and falls back to productId", () => {
    expect(getCartItemLookupKey({ _id: "a", productId: "b" })).toBe("a");
    expect(getCartItemLookupKey({ productId: "b" })).toBe("b");
  });
});

describe("getUnavailableCount", () => {
  const availability = buildCartAvailability(
    [
      makeProduct({ _id: "p1", stock: 0 }),
      makeProduct({ _id: "p2", stock: 5 }),
    ],
    [
      makeItem({ _id: "p1", productId: "p1", qty: 1 }),
      makeItem({ _id: "p2", productId: "p2", qty: 1 }),
    ],
  );

  test("counts only unavailable items", () => {
    const cart = [
      makeItem({ _id: "p1", productId: "p1", qty: 1 }),
      makeItem({ _id: "p2", productId: "p2", qty: 1 }),
    ];
    expect(getUnavailableCount(availability, cart)).toBe(1);
  });
});