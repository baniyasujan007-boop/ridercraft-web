import { render, screen, fireEvent } from "@testing-library/react";

jest.mock("axios", () => ({
  get: jest.fn().mockResolvedValue({ data: [] }),
  post: jest.fn(),
  delete: jest.fn(),
}));

import { AppProviders, useCart } from "./index";

const CART_STORAGE_KEY = "easycart_cart";

const makeProduct = (overrides = {}) => ({
  _id: "p1",
  name: "Helmet",
  price: 100,
  image: "",
  tag: "Helmet",
  ...overrides,
});

const Harness = () => {
  const {
    cart,
    addToCart,
    setQty,
    removeFromCart,
    clearCart,
    totalItems,
    totalPrice,
  } = useCart();

  return (
    <div>
      <p data-testid="count">{totalItems}</p>
      <p data-testid="total">{totalPrice}</p>
      <p data-testid="cart">{JSON.stringify(cart)}</p>
      <button onClick={() => addToCart(makeProduct())}>add-a</button>
      <button
        onClick={() =>
          addToCart(
            makeProduct({
              _id: "p2",
              name: "Glove",
              price: 50,
              selectedVariant: { id: "v1", sku: "S1" },
            }),
          )
        }
      >
        add-b
      </button>
      <button
        onClick={() =>
          addToCart(
            makeProduct({
              _id: "p2",
              name: "Glove",
              price: 50,
              selectedVariant: { id: "v2", sku: "S2" },
            }),
          )
        }
      >
        add-b2
      </button>
      <button onClick={() => removeFromCart("p1")}>remove-a</button>
      <button onClick={() => setQty("p1", 3)}>set-a-3</button>
      <button onClick={() => setQty("p1", 0)}>set-a-zero</button>
      <button onClick={() => clearCart()}>clear</button>
    </div>
  );
};

const renderHarness = () =>
  render(
    <AppProviders>
      <Harness />
    </AppProviders>,
  );

describe("cart context", () => {
  beforeEach(() => {
    localStorage.clear();
  });

  test("addToCart adds a new item", () => {
    renderHarness();
    fireEvent.click(screen.getByText("add-a"));
    expect(screen.getByTestId("count").textContent).toBe("1");
    expect(screen.getByTestId("total").textContent).toBe("100");
  });

  test("addToCart merges matching items and splits variants", () => {
    renderHarness();
    fireEvent.click(screen.getByText("add-b"));
    fireEvent.click(screen.getByText("add-b"));
    fireEvent.click(screen.getByText("add-b2"));
    const cart = JSON.parse(screen.getByTestId("cart").textContent);
    expect(cart).toHaveLength(2);
    const baseVariant = cart.find((item) => item._id === "p2:v1");
    const otherVariant = cart.find((item) => item._id === "p2:v2");
    expect(baseVariant.qty).toBe(2);
    expect(otherVariant.qty).toBe(1);
    expect(screen.getByTestId("count").textContent).toBe("3");
  });

  test("removeFromCart removes only the matching item", () => {
    renderHarness();
    fireEvent.click(screen.getByText("add-a"));
    fireEvent.click(screen.getByText("add-a"));
    fireEvent.click(screen.getByText("add-b"));
    fireEvent.click(screen.getByText("remove-a"));
    const cart = JSON.parse(screen.getByTestId("cart").textContent);
    expect(cart.map((item) => item._id)).toEqual(["p2:v1"]);
    expect(screen.getByTestId("count").textContent).toBe("1");
  });

  test("setQty sets an absolute quantity", () => {
    renderHarness();
    fireEvent.click(screen.getByText("add-a"));
    fireEvent.click(screen.getByText("set-a-3"));
    const cart = JSON.parse(screen.getByTestId("cart").textContent);
    expect(cart[0].qty).toBe(3);
    expect(screen.getByTestId("count").textContent).toBe("3");
    expect(screen.getByTestId("total").textContent).toBe("300");
  });

  test("setQty cannot set quantity below one", () => {
    renderHarness();
    fireEvent.click(screen.getByText("add-a"));
    fireEvent.click(screen.getByText("set-a-zero"));
    const cart = JSON.parse(screen.getByTestId("cart").textContent);
    expect(cart[0].qty).toBe(1);
  });

  test("totals empty cart at zero", () => {
    renderHarness();
    expect(screen.getByTestId("count").textContent).toBe("0");
    expect(screen.getByTestId("total").textContent).toBe("0");
  });

  test("persists cart to localStorage", () => {
    renderHarness();
    fireEvent.click(screen.getByText("add-a"));
    fireEvent.click(screen.getByText("set-a-3"));
    const stored = JSON.parse(localStorage.getItem(CART_STORAGE_KEY));
    expect(stored).toHaveLength(1);
    expect(stored[0].qty).toBe(3);
  });

  test("clearCart empties the cart", () => {
    renderHarness();
    fireEvent.click(screen.getByText("add-a"));
    fireEvent.click(screen.getByText("clear"));
    expect(screen.getByTestId("count").textContent).toBe("0");
    expect(JSON.parse(screen.getByTestId("cart").textContent)).toEqual([]);
  });
});