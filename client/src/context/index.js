import { createContext, useContext, useEffect, useMemo, useState } from "react";

const CART_STORAGE_KEY = "easycart_cart";
const LEGACY_CART_STORAGE_KEY = "quickgpt_cart";
const CartContext = createContext(null);

function normalizeCartItem(product) {
  const id = product?._id || product?.id;
  return {
    _id: String(id),
    name: product?.name || product?.title || "Product",
    price: Number(product?.price || 0),
    image: product?.image || product?.images?.[0] || "",
    tag: product?.tag || product?.brand || "General"
  };
}

export function AppProviders({ children }) {
  const [cart, setCart] = useState(() => {
    try {
      const currentRaw = localStorage.getItem(CART_STORAGE_KEY);
      if (currentRaw) {
        const parsed = JSON.parse(currentRaw);
        return Array.isArray(parsed) ? parsed : [];
      }

      const legacyRaw = localStorage.getItem(LEGACY_CART_STORAGE_KEY);
      if (!legacyRaw) return [];
      const legacyParsed = JSON.parse(legacyRaw);
      if (!Array.isArray(legacyParsed)) return [];
      localStorage.setItem(CART_STORAGE_KEY, JSON.stringify(legacyParsed));
      localStorage.removeItem(LEGACY_CART_STORAGE_KEY);
      return legacyParsed;
    } catch {
      return [];
    }
  });

  useEffect(() => {
    localStorage.setItem(CART_STORAGE_KEY, JSON.stringify(cart));
  }, [cart]);

  const addToCart = (product, qty = 1) => {
    const normalized = normalizeCartItem(product);
    if (!normalized._id) return;

    setCart((prev) => {
      const existing = prev.find((item) => item._id === normalized._id);
      if (existing) {
        return prev.map((item) =>
          item._id === normalized._id ? { ...item, qty: item.qty + qty } : item
        );
      }
      return [...prev, { ...normalized, qty: Math.max(1, qty) }];
    });
  };

  const changeQty = (id, delta) => {
    const key = String(id);
    setCart((prev) =>
      prev
        .map((item) =>
          item._id === key ? { ...item, qty: Math.max(0, item.qty + delta) } : item
        )
        .filter((item) => item.qty > 0)
    );
  };
  const clearCart = () => setCart([]);

  const totalItems = useMemo(
    () => cart.reduce((sum, item) => sum + item.qty, 0),
    [cart]
  );
  const totalPrice = useMemo(
    () => cart.reduce((sum, item) => sum + item.qty * item.price, 0),
    [cart]
  );

  const value = useMemo(
    () => ({ cart, addToCart, changeQty, clearCart, totalItems, totalPrice }),
    [cart, totalItems, totalPrice]
  );

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export function useCart() {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error("useCart must be used within AppProviders");
  }
  return context;
}
