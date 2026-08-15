import { render, screen, fireEvent } from "@testing-library/react";
import CartItemRow from "./CartItemRow";
import { CART_AVAILABILITY_STATUS } from "../../../utils/cartAvailability";

const makeItem = (overrides = {}) => ({
  _id: "p1",
  productId: "p1",
  variantId: "",
  name: "Aero Helmet",
  price: 100,
  image: "",
  qty: 1,
  ...overrides,
});

const availabilityFor = (status, availableStock) => ({
  status,
  availableStock,
  isUnavailable: status !== CART_AVAILABILITY_STATUS.IN_STOCK,
  exceedsStock: status === CART_AVAILABILITY_STATUS.EXCEEDS_STOCK,
});

describe("CartItemRow", () => {
  test("renders product info, price, qty, total and Remove", () => {
    render(
      <CartItemRow
        item={makeItem({ name: "Aero Helmet" })}
        availability={availabilityFor(CART_AVAILABILITY_STATUS.IN_STOCK, 10)}
        onRemove={jest.fn()}
        onChangeQty={jest.fn()}
      />,
    );
    expect(screen.getByText("Aero Helmet")).toBeInTheDocument();
    expect(screen.getByText("Remove")).toBeInTheDocument();
    expect(screen.getByText("In stock")).toBeInTheDocument();
    expect(screen.getAllByText("₹100")).toHaveLength(2);
  });

  test("marks out-of-stock and disables quantity", () => {
    render(
      <CartItemRow
        item={makeItem()}
        availability={availabilityFor(CART_AVAILABILITY_STATUS.OUT_OF_STOCK, 0)}
        onRemove={jest.fn()}
        onChangeQty={jest.fn()}
      />,
    );
    expect(screen.getByText("Out of stock")).toBeInTheDocument();
    expect(screen.getByRole("combobox")).toBeDisabled();
  });

  test("marks exceeds-stock and still allows reducing quantity", () => {
    render(
      <CartItemRow
        item={makeItem({ qty: 5 })}
        availability={availabilityFor(CART_AVAILABILITY_STATUS.EXCEEDS_STOCK, 3)}
        onRemove={jest.fn()}
        onChangeQty={jest.fn()}
      />,
    );
    expect(
      screen.getByText("Only 3 available — reduce quantity"),
    ).toBeInTheDocument();
    const select = screen.getByRole("combobox");
    expect(select).not.toBeDisabled();
    expect(select.value).toBe("5");
    const options = Array.from(select.querySelectorAll("option")).map(
      (option) => option.value,
    );
    expect(options).toContain("1");
    expect(options).toContain("3");
  });

  test("marks missing product as unavailable and disables quantity", () => {
    render(
      <CartItemRow
        item={makeItem()}
        availability={availabilityFor(CART_AVAILABILITY_STATUS.MISSING, 0)}
        onRemove={jest.fn()}
        onChangeQty={jest.fn()}
      />,
    );
    expect(screen.getByText("Unavailable")).toBeInTheDocument();
    expect(screen.getByRole("combobox")).toBeDisabled();
  });

  test("calls onRemove when Remove clicked", () => {
    const onRemove = jest.fn();
    render(
      <CartItemRow
        item={makeItem()}
        availability={availabilityFor(CART_AVAILABILITY_STATUS.IN_STOCK, 10)}
        onRemove={onRemove}
        onChangeQty={jest.fn()}
      />,
    );
    fireEvent.click(screen.getByText("Remove"));
    expect(onRemove).toHaveBeenCalledTimes(1);
  });

  test("calls onChangeQty with the new quantity", () => {
    const onChangeQty = jest.fn();
    render(
      <CartItemRow
        item={makeItem()}
        availability={availabilityFor(CART_AVAILABILITY_STATUS.IN_STOCK, 10)}
        onRemove={jest.fn()}
        onChangeQty={onChangeQty}
      />,
    );
    const select = screen.getByRole("combobox");
    fireEvent.change(select, { target: { value: "3" } });
    expect(onChangeQty).toHaveBeenCalledWith(3);
  });

  test("caps quantity options at available stock", () => {
    render(
      <CartItemRow
        item={makeItem({ qty: 1 })}
        availability={availabilityFor(CART_AVAILABILITY_STATUS.IN_STOCK, 3)}
        onRemove={jest.fn()}
        onChangeQty={jest.fn()}
      />,
    );
    const options = Array.from(
      screen.getByRole("combobox").querySelectorAll("option"),
    ).map((option) => option.value);
    expect(options).toEqual(["1", "2", "3"]);
  });

  test("handles long product names at narrow widths without error", () => {
    const longName =
      "Pro-Shift Carbon Fiber Racing Helmet with Pinlock Visor Extra Long Name";
    const { container } = render(
      <div style={{ width: "320px" }}>
        <CartItemRow
          item={makeItem({ name: longName })}
          availability={availabilityFor(CART_AVAILABILITY_STATUS.IN_STOCK, 10)}
          onRemove={jest.fn()}
          onChangeQty={jest.fn()}
        />
      </div>,
    );
    expect(screen.getByText(longName)).toBeInTheDocument();
    expect(container.querySelector(".cart-item")).not.toBeNull();
  });

  test("renders within a 430px viewport", () => {
    render(
      <div style={{ width: "430px" }}>
        <CartItemRow
          item={makeItem()}
          availability={availabilityFor(CART_AVAILABILITY_STATUS.IN_STOCK, 10)}
          onRemove={jest.fn()}
          onChangeQty={jest.fn()}
        />
      </div>,
    );
    expect(screen.getByText("In stock")).toBeInTheDocument();
    expect(screen.getByText("Remove")).toBeInTheDocument();
  });
});