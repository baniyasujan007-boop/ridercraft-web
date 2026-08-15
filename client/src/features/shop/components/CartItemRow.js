import { applyImageFallback } from "../../../utils/fallbackImage";
import {
  CART_AVAILABILITY_STATUS,
  getAvailabilityMessage,
} from "../../../utils/cartAvailability";

const formatCurrency = (value) =>
  `₹${Number(value || 0).toLocaleString("en-IN")}`;

const isQtyEditable = (availability) =>
  availability?.status === CART_AVAILABILITY_STATUS.IN_STOCK ||
  availability?.status === CART_AVAILABILITY_STATUS.EXCEEDS_STOCK;

const buildQtyOptions = (item, availability) => {
  const currentQty = Math.max(1, Number(item?.qty) || 1);
  if (!isQtyEditable(availability)) return [currentQty];
  const maxQty = Math.max(1, Math.floor(availability?.availableStock || 1));
  const capped = Math.min(10, maxQty);
  const options = [];
  for (let qty = 1; qty <= Math.max(capped, currentQty); qty += 1) {
    options.push(qty);
  }
  return [...new Set(options)];
};

export default function CartItemRow({
  item,
  availability,
  onRemove,
  onChangeQty,
}) {
  const price = Number(item?.price) || 0;
  const qty = Math.max(1, Number(item?.qty) || 1);
  const message = getAvailabilityMessage(availability);
  const editable = isQtyEditable(availability);
  const qtyOptions = buildQtyOptions(item, availability);

  return (
    <article className="cart-item">
      <div className="cart-product-cell">
        {item.image ? (
          <img
            src={item.image}
            alt={item.name}
            className="cart-item-image"
            onError={applyImageFallback}
          />
        ) : (
          <div className="cart-item-image cart-item-placeholder">No image</div>
        )}
        <div>
          <h3>{item.name}</h3>
          <p>Color: {item.color || item.tag || "General"}</p>
          {item.variantSku && <p>SKU: {item.variantSku}</p>}
          <p className={`cart-availability ${message.tone}`}>{message.text}</p>
          <div className="cart-item-actions">
            <button type="button" className="remove" onClick={onRemove}>
              Remove
            </button>
          </div>
        </div>
      </div>

      <p className="cart-cell-price">{formatCurrency(price)}</p>

      <div className="cart-cell-qty">
        <select
          value={qty}
          disabled={!editable}
          onChange={(e) => onChangeQty(Number(e.target.value))}
        >
          {qtyOptions.map((optionQty) => (
            <option key={optionQty} value={optionQty}>
              {optionQty}
            </option>
          ))}
        </select>
      </div>

      <p className="cart-cell-total">{formatCurrency(price * qty)}</p>
    </article>
  );
}