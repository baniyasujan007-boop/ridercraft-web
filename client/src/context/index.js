import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import axios from "axios";

const CART_STORAGE_KEY = "easycart_cart";
const LEGACY_CART_STORAGE_KEY = "quickgpt_cart";
const CartContext = createContext(null);
const API_BASE_URL = "https://ridercraft-api.onrender.com";

function getWishlistProductId(entry) {
  if (!entry) return "";
  const product = entry.product || entry.productId;
  return String(
    product?._id ||
      product?.id ||
      entry.productId?._id ||
      entry.productId ||
      entry.product?._id ||
      entry.product?.id ||
      "",
  );
}

function normalizeCartItem(product) {
  const id = product?._id || product?.id;
  const variant =
    product?.selectedVariant ||
    product?.variant ||
    (Array.isArray(product?.variants) && product.variants.length
      ? {
          id: product.variants[0]._id || product.variants[0].id,
          sku: product.variants[0].sku,
          name: product.variants[0].color,
          value: product.variants[0].colorHex,
          images: product.variants[0].images,
        }
      : null);
  const variantId = variant?.id || variant?._id || "";
  const cartKey = `${id}${variantId ? `:${variantId}` : ""}`;
  return {
    _id: String(cartKey),
    productId: String(id),
    variantId: String(variantId),
    variantSku: variant?.sku || product?.variantSku || "",
    color: variant?.name || product?.color || "",
    colorHex: variant?.value || product?.colorHex || "",
    name: product?.name || product?.title || "Product",
    price: Number(product?.displayPrice ?? product?.price ?? 0),
    image:
      variant?.images?.[0] ||
      product?.images?.[0] ||
      product?.image ||
      "",
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
  const [wishlistItems, setWishlistItems] = useState([]);
  const [wishlistLoading, setWishlistLoading] = useState(false);

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

  const loadWishlist = useCallback(async () => {
    const token = localStorage.getItem("token");
    if (!token) {
      setWishlistItems([]);
      return [];
    }

    try {
      setWishlistLoading(true);
      const res = await axios.get(`${API_BASE_URL}/wishlist`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const nextItems = Array.isArray(res.data) ? res.data : [];
      setWishlistItems(nextItems);
      return nextItems;
    } catch {
      setWishlistItems([]);
      return [];
    } finally {
      setWishlistLoading(false);
    }
  }, []);

  useEffect(() => {
    loadWishlist();
  }, [loadWishlist]);

  const getWishlistEntry = useCallback(
    (productId) =>
      wishlistItems.find(
        (entry) => getWishlistProductId(entry) === String(productId || ""),
      ),
    [wishlistItems],
  );

  const isWishlisted = useCallback(
    (productId) => Boolean(getWishlistEntry(productId)),
    [getWishlistEntry],
  );

  const toggleWishlist = useCallback(
    async (product) => {
      const productId = product?._id || product?.id || product?.productId;
      if (!productId) return { ok: false, error: "Product unavailable" };

      const token = localStorage.getItem("token");
      if (!token) {
        return { ok: false, error: "Please login to use wishlist" };
      }

      const existing = getWishlistEntry(productId);
      if (existing) {
        const existingProductId = getWishlistProductId(existing);
        setWishlistItems((prev) =>
          prev.filter(
            (entry) =>
              String(entry._id) !== String(existing._id) &&
              getWishlistProductId(entry) !== existingProductId,
          ),
        );
        try {
          const deleteId =
            String(existing._id || "").startsWith("local-")
              ? existingProductId
              : existing._id;
          await axios.delete(
            `${API_BASE_URL}/wishlist/remove/${deleteId}`,
            {
              headers: { Authorization: `Bearer ${token}` },
            },
          );
          return { ok: true, saved: false };
        } catch (error) {
          await loadWishlist();
          return {
            ok: false,
            error: error.response?.data?.error || "Failed to update wishlist",
          };
        }
      }

      const optimisticEntry = {
        _id: `local-${productId}`,
        productId,
        product,
        createdAt: new Date().toISOString(),
      };
      setWishlistItems((prev) => [optimisticEntry, ...prev]);

      try {
        const res = await axios.post(
          `${API_BASE_URL}/wishlist/add`,
          { productId },
          { headers: { Authorization: `Bearer ${token}` } },
        );
        const savedEntry = res.data || optimisticEntry;
        setWishlistItems((prev) =>
          prev.map((entry) =>
            String(entry._id) === String(optimisticEntry._id) ? savedEntry : entry,
          ),
        );
        return { ok: true, saved: true };
      } catch (error) {
        setWishlistItems((prev) =>
          prev.filter((entry) => String(entry._id) !== String(optimisticEntry._id)),
        );
        return {
          ok: false,
          error: error.response?.data?.error || "Failed to update wishlist",
        };
      }
    },
    [getWishlistEntry, loadWishlist],
  );

  const totalItems = useMemo(
    () => cart.reduce((sum, item) => sum + item.qty, 0),
    [cart]
  );
  const totalPrice = useMemo(
    () => cart.reduce((sum, item) => sum + item.qty * item.price, 0),
    [cart]
  );

  const value = useMemo(
    () => ({
      cart,
      addToCart,
      changeQty,
      clearCart,
      totalItems,
      totalPrice,
      wishlistItems,
      wishlistCount: wishlistItems.length,
      wishlistLoading,
      loadWishlist,
      isWishlisted,
      toggleWishlist,
    }),
    [
      cart,
      isWishlisted,
      loadWishlist,
      totalItems,
      totalPrice,
      toggleWishlist,
      wishlistItems,
      wishlistLoading,
    ]
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
