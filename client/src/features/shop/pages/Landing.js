import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import axios from "axios";
import { jwtDecode } from "jwt-decode";
import { useLocation, useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import Navbar from "../../../components/layout/Navbar";
import { useCart } from "../../../context";
import "../styles/landing-base.css";
import "../styles/landing-nav.css";
import "../styles/landing-shop.css";
import "../styles/landing-cart.css";
import "../styles/landing-profile.css";
import "../styles/landing-service.css";
import { applyImageFallback } from "../../../utils/fallbackImage";

const SERVICE_BIKE_MODELS = [
  "Hero Xpulse 200",
  "Royal Enfield Classic 350",
  "Bajaj Pulsar NS200",
  "Yamaha MT 15",
  "TVS Apache RTR 160",
  "Honda CB350",
  "KTM Duke 200",
];

const getTodayDateValue = () => {
  const date = new Date();
  const offset = date.getTimezoneOffset();
  const local = new Date(date.getTime() - offset * 60 * 1000);
  return local.toISOString().slice(0, 10);
};

const DUMMY_CARD = {
  cardNumber: "4242424242424242",
  cardHolder: "TEST CUSTOMER",
  expiry: "12/30",
  cvv: "123",
};

const DUMMY_EWALLET = {
  walletProvider: "Google Pay",
  walletId: "dummy.wallet@quickgpt.test",
};

const CUSTOMER_NOTIFICATION_STORAGE_KEY = "ridercraft_customer_notifications";

export default function Landing() {
  const [dbNotifications, setDbNotifications] = useState([]);

  const loadDbNotifications = async () => {
    try {
      const token = localStorage.getItem("token");

      const res = await axios.get(
        "https://ridercraft-api.onrender.com/notifications",
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        },
      );

      setDbNotifications(res.data || []);
    } catch (err) {
      console.error("Notification error:", err.response?.data || err);
    }
  };

  useEffect(() => {
    loadDbNotifications();
  }, []);

  useEffect(() => {
    console.log("DB Notifications:", dbNotifications);
  }, [dbNotifications]);
  const navigate = useNavigate();
  const location = useLocation();
  const [view, setView] = useState("shop");
  const [products, setProducts] = useState([]);
  const [heroOffers, setHeroOffers] = useState([]);
  const [activePromos, setActivePromos] = useState([]);
  const [featuredSectionsData, setFeaturedSectionsData] = useState([]);
  const [productsError, setProductsError] = useState("");
  const [categoryQuery, setCategoryQuery] = useState("");
  const [activeTag, setActiveTag] = useState("All");
  const [activeBrand, setActiveBrand] = useState("All");
  const [activeColorFamily, setActiveColorFamily] = useState("All");
  const [minRating, setMinRating] = useState(0);
  const [sortBy, setSortBy] = useState("popular");
  const [ratingInputs, setRatingInputs] = useState({});
  const [ratingComments, setRatingComments] = useState({});
  const [ratingHover, setRatingHover] = useState({});
  const [ratingMessage, setRatingMessage] = useState("");
  const [ratingError, setRatingError] = useState("");
  const [ratingLoadingId, setRatingLoadingId] = useState("");
  const [orderHistory, setOrderHistory] = useState([]);
  const [ordersLoading, setOrdersLoading] = useState(false);
  const [ordersError, setOrdersError] = useState("");
  const [serviceRequests, setServiceRequests] = useState([]);
  const [serviceRequestsLoading, setServiceRequestsLoading] = useState(false);
  const [serviceSubmitting, setServiceSubmitting] = useState(false);
  const [serviceMessage, setServiceMessage] = useState("");
  const [serviceError, setServiceError] = useState("");
  const [serviceLocationLoading, setServiceLocationLoading] = useState(false);
  const [serviceForm, setServiceForm] = useState({
    packageType: "basic",
    priority: "normal",
    bikeModel: SERVICE_BIKE_MODELS[0],
    preferredDate: getTodayDateValue(),
    preferredTime: "10:00",
    pickupAddress: "",
    pickupLocation: {
      latitude: null,
      longitude: null,
      accuracyMeters: null,
      capturedAt: "",
    },
    contactNumber: "",
    breakdownIssue: "",
    notes: "",
  });
  const [returnReasonByOrder, setReturnReasonByOrder] = useState({});
  const [returnEvidenceByOrder, setReturnEvidenceByOrder] = useState({});
  const [returnActionLoadingId, setReturnActionLoadingId] = useState("");
  const [returnMessage, setReturnMessage] = useState("");
  const [returnError, setReturnError] = useState("");
  const { cart, addToCart, changeQty, clearCart, totalItems, totalPrice } =
    useCart();
  const [profile, setProfile] = useState({
    name: "",
    email: "",
    avatar: "",
    contactNumber: "",
    deliveryAddress: "",
  });
  const [profileForm, setProfileForm] = useState({
    name: "",
    avatar: "",
    contactNumber: "",
    deliveryAddress: "",
  });
  const [promoCode, setPromoCode] = useState("");
  const [promoDiscount, setPromoDiscount] = useState(0);
  const [appliedPromoCode, setAppliedPromoCode] = useState("");
  const [promoMessage, setPromoMessage] = useState("");
  const [paymentSuccessMessage, setPaymentSuccessMessage] = useState("");
  const [paymentProcessing, setPaymentProcessing] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState("cod");
  const [paymentDetails, setPaymentDetails] = useState({
    cardNumber: "",
    cardHolder: "",
    expiry: "",
    cvv: "",
    walletProvider: "",
    walletId: "",
  });
  const [profileMessage, setProfileMessage] = useState("");
  const [profileError, setProfileError] = useState("");
  const [isAdmin, setIsAdmin] = useState(false);
  const [currentUserId, setCurrentUserId] = useState("");
  const [offerNow, setOfferNow] = useState(Date.now());
  const [customerNotifications, setCustomerNotifications] = useState(() => {
    try {
      return JSON.parse(
        localStorage.getItem(CUSTOMER_NOTIFICATION_STORAGE_KEY) || "[]",
      );
    } catch {
      return [];
    }
  });
  const prevTotalsRef = useRef({ totalPrice: 0, shipping: 0 });
  const orderStatusSnapshotRef = useRef(null);

  const logout = () => {
    localStorage.removeItem("token");
    window.location.href = "/";
  };

  const availableTags = useMemo(
    () => ["All", ...new Set(products.map((item) => item.tag || "General"))],
    [products],
  );
  const availableBrands = useMemo(
    () => ["All", ...new Set(products.map((item) => item.brand || "Generic"))],
    [products],
  );
  const availableColorFamilies = useMemo(
    () => [
      "All",
      ...new Set(products.map((item) => item.colorFamily || "Neutral")),
    ],
    [products],
  );
  const tagCounts = useMemo(() => {
    const counts = products.reduce((acc, item) => {
      const tag = item.tag || "General";
      acc[tag] = (acc[tag] || 0) + 1;
      return acc;
    }, {});
    return { All: products.length, ...counts };
  }, [products]);
  const visibleTags = useMemo(() => {
    const query = categoryQuery.trim().toLowerCase();
    if (!query) return availableTags;
    return availableTags.filter((tag) => tag.toLowerCase().includes(query));
  }, [availableTags, categoryQuery]);
  const showFilters = shopQuery.trim().length > 0;
  const filteredProducts = useMemo(() => {
    const query = shopQuery.trim().toLowerCase();
    const filtered = products.filter((item) => {
      const matchesTag =
        activeTag === "All" || (item.tag || "General") === activeTag;
      const matchesBrand =
        activeBrand === "All" || (item.brand || "Generic") === activeBrand;
      const matchesColorFamily =
        activeColorFamily === "All" ||
        (item.colorFamily || "Neutral") === activeColorFamily;
      const itemRating = Number(item.ratingAverage || 0);
      const matchesRating = itemRating >= minRating;
      const matchesQuery =
        !query ||
        item.name?.toLowerCase().includes(query) ||
        item.tag?.toLowerCase().includes(query) ||
        item.brand?.toLowerCase().includes(query) ||
        item.colorFamily?.toLowerCase().includes(query);
      return (
        matchesTag &&
        matchesBrand &&
        matchesColorFamily &&
        matchesQuery &&
        matchesRating
      );
    });

    const sorted = [...filtered];
    if (sortBy === "price-low") {
      sorted.sort((a, b) => Number(a.price) - Number(b.price));
    } else if (sortBy === "price-high") {
      sorted.sort((a, b) => Number(b.price) - Number(a.price));
    } else if (sortBy === "name-asc") {
      sorted.sort((a, b) => String(a.name).localeCompare(String(b.name)));
    }
    return sorted;
  }, [
    products,
    shopQuery,
    activeTag,
    activeBrand,
    activeColorFamily,
    sortBy,
    minRating,
  ]);
  const featuredSections = useMemo(
    () =>
      featuredSectionsData
        .filter((section) => section.isActive && section.key !== "deals-of-day")
        .sort((a, b) => Number(a.sortOrder || 0) - Number(b.sortOrder || 0)),
    [featuredSectionsData],
  );
  const flashDealsSection = useMemo(
    () =>
      featuredSectionsData.find(
        (section) => section.key === "deals-of-day",
      ) || {
        key: "deals-of-day",
        title: "Flash Sale Section",
        products: [],
      },
    [featuredSectionsData],
  );
  const flashSaleProducts = useMemo(() => {
    if (
      !Array.isArray(flashDealsSection.products) ||
      flashDealsSection.products.length === 0
    ) {
      return [];
    }
    return flashDealsSection.products.slice(0, 4);
  }, [flashDealsSection]);
  const activeHeroOffers = useMemo(() => {
    const now = offerNow;
    return heroOffers
      .filter((offer) => {
        if (!offer?.isActive) return false;
        const startsAt = offer.startsAt
          ? new Date(offer.startsAt).getTime()
          : 0;
        const endsAt = offer.endsAt ? new Date(offer.endsAt).getTime() : 0;
        if (startsAt && startsAt > now) return false;
        if (endsAt && endsAt <= now) return false;
        return true;
      })
      .sort((a, b) => Number(b.priority || 0) - Number(a.priority || 0));
  }, [heroOffers, offerNow]);
  const flashHeroOffer = useMemo(
    () => activeHeroOffers.find((offer) => offer.offerType === "flash"),
    [activeHeroOffers],
  );
  const tagHeroOffers = useMemo(
    () => activeHeroOffers.filter((offer) => offer.offerType !== "flash"),
    [activeHeroOffers],
  );
  const tax = useMemo(
    () => Number((totalPrice * 0.08).toFixed(2)),
    [totalPrice],
  );
  const shipping = useMemo(
    () => (totalPrice >= 75 || totalPrice === 0 ? 0 : 7.99),
    [totalPrice],
  );
  const estimatedTotal = useMemo(
    () => Number((totalPrice + tax + shipping - promoDiscount).toFixed(2)),
    [totalPrice, tax, shipping, promoDiscount],
  );
  const freeShippingGap = useMemo(
    () => Math.max(0, Number((75 - totalPrice).toFixed(2))),
    [totalPrice],
  );

  const submitRating = async (productId, value, comment = "") => {
    setRatingMessage("");
    setRatingError("");

    const token = localStorage.getItem("token");
    if (!token) {
      setRatingError("Please login to rate products");
      return;
    }

    const selected = Number(value);
    if (
      !Number.isFinite(selected) ||
      selected < 0.5 ||
      selected > 5 ||
      !Number.isInteger(selected * 2)
    ) {
      setRatingError("Select a rating from 0.5 to 5");
      return;
    }

    try {
      setRatingLoadingId(productId);
      const res = await axios.post(
        `https://ridercraft-api.onrender.com/products/${productId}/rate`,
        { rating: selected, comment: String(comment || "").trim() },
        { headers: { Authorization: `Bearer ${token}` } },
      );
      setProducts((prev) =>
        prev.map((item) => (item._id === productId ? res.data.product : item)),
      );
      setRatingInputs((prev) => ({ ...prev, [productId]: selected }));
      if (comment !== undefined) {
        setRatingComments((prev) => ({
          ...prev,
          [productId]: String(comment || "").trim(),
        }));
      }
      setRatingMessage("Rating submitted");
    } catch (err) {
      setRatingError(err.response?.data?.error || "Failed to submit rating");
    } finally {
      setRatingLoadingId("");
    }
  };
  const applyPromoCode = async () => {
    const normalized = promoCode.trim().toUpperCase();
    if (!normalized) {
      setPromoDiscount(0);
      setAppliedPromoCode("");
      setPromoMessage("Enter a promo code.");
      return;
    }
    try {
      const res = await axios.post(
        "https://ridercraft-api.onrender.com/promos/validate",
        {
          code: normalized,
          subtotal: totalPrice,
          shipping,
        },
      );
      setPromoDiscount(Number(res.data.discountAmount || 0));
      setAppliedPromoCode(normalized);
      setPromoMessage(res.data.message || "Promo applied");
    } catch (err) {
      setPromoDiscount(0);
      setAppliedPromoCode("");
      setPromoMessage(err.response?.data?.error || "Invalid promo code.");
    }
  };
  const validatePayment = () => {
    if (paymentMethod === "card") {
      const cardNumber = paymentDetails.cardNumber.replace(/\s+/g, "");
      if (!/^\d{16}$/.test(cardNumber)) return "Card number must be 16 digits.";
      if (!paymentDetails.cardHolder.trim())
        return "Card holder name is required.";
      if (!/^\d{2}\/\d{2}$/.test(paymentDetails.expiry.trim())) {
        return "Card expiry must be in MM/YY format.";
      }
      if (!/^\d{3,4}$/.test(paymentDetails.cvv.trim()))
        return "CVV must be 3 or 4 digits.";
    }
    if (paymentMethod === "ewallet") {
      if (!paymentDetails.walletProvider.trim())
        return "Please select wallet provider.";
      if (!paymentDetails.walletId.trim())
        return "Wallet number/email is required.";
    }
    return "";
  };
  const checkoutCart = async () => {
    setPaymentSuccessMessage("");
    if (cart.length === 0) {
      setPromoMessage("Your cart is empty.");
      return;
    }
    const paymentError = validatePayment();
    if (paymentError) {
      setPromoMessage(paymentError);
      return;
    }

    try {
      const token = localStorage.getItem("token");
      if (!token) {
        setPromoMessage("Please login again.");
        return;
      }
      setPaymentProcessing(true);

      if (paymentMethod === "card" || paymentMethod === "ewallet") {
        await new Promise((resolve) => setTimeout(resolve, 1000));
      }

      if (appliedPromoCode) {
        const res = await axios.post(
          "https://ridercraft-api.onrender.com/promos/redeem",
          {
            code: appliedPromoCode,
            subtotal: totalPrice,
            shipping,
          },
        );
        setPromoMessage(
          `Promo ${appliedPromoCode} used (${res.data.usedCount}/${res.data.maxUses}).`,
        );
      } else {
        setPromoMessage("");
      }

      await axios.post(
        "https://ridercraft-api.onrender.com/orders",
        {
          items: cart.map((item) => ({
            productId: item._id,
            name: item.name,
            price: item.price,
            qty: item.qty,
            image: item.image,
          })),
          subtotal: totalPrice,
          tax,
          shipping,
          discount: promoDiscount,
          total: estimatedTotal,
          promoCode: appliedPromoCode,
          paymentMethod,
          paymentDetails: {
            ...paymentDetails,
            isDummy: paymentMethod === "card" || paymentMethod === "ewallet",
          },
        },
        { headers: { Authorization: `Bearer ${token}` } },
      );

      const baseMessage =
        paymentMethod === "card" || paymentMethod === "ewallet"
          ? "Dummy payment approved. Checkout complete."
          : "Checkout complete.";
      setPromoMessage(
        appliedPromoCode
          ? `${baseMessage} Promo kept applied to order.`
          : baseMessage,
      );
      setPaymentSuccessMessage(
        "Payment successful. Your order has been placed.",
      );

      clearCart();
      setPromoCode("");
      setAppliedPromoCode("");
      setPromoDiscount(0);
      setPaymentMethod("cod");
      setPaymentDetails({
        cardNumber: "",
        cardHolder: "",
        expiry: "",
        cvv: "",
        walletProvider: "",
        walletId: "",
      });
      await loadMyOrders();
    } catch (err) {
      setPromoMessage(err.response?.data?.error || "Checkout failed");
    } finally {
      setPaymentProcessing(false);
    }
  };
  const useDummyCardDetails = () => {
    setPaymentMethod("card");
    setPaymentDetails((prev) => ({
      ...prev,
      cardNumber: DUMMY_CARD.cardNumber,
      cardHolder: DUMMY_CARD.cardHolder,
      expiry: DUMMY_CARD.expiry,
      cvv: DUMMY_CARD.cvv,
    }));
    setPromoMessage("Dummy card details filled.");
  };
  const useDummyEwalletDetails = () => {
    setPaymentMethod("ewallet");
    setPaymentDetails((prev) => ({
      ...prev,
      walletProvider: DUMMY_EWALLET.walletProvider,
      walletId: DUMMY_EWALLET.walletId,
    }));
    setPromoMessage("Dummy e-wallet details filled.");
  };
  const formatCurrency = (value) => `$${Number(value || 0).toFixed(2)}`;
  const renderRatingStars = (value) => {
    const rounded =
      Math.round(Math.max(0, Math.min(5, Number(value || 0))) * 2) / 2;
    return [1, 2, 3, 4, 5].map((star) => {
      const isFull = star <= rounded;
      const isHalf = !isFull && star - 0.5 === rounded;
      return (
        <span
          key={star}
          className={`display-star${isFull ? " display-star-full" : ""}${isHalf ? " display-star-half" : ""}`}
        >
          ★
        </span>
      );
    });
  };
  const formatCountdown = (targetDate) => {
    if (!targetDate) return "";
    const targetTime = new Date(targetDate).getTime();
    if (!Number.isFinite(targetTime)) return "";
    const remaining = Math.max(0, targetTime - offerNow);
    const hours = Math.floor(remaining / (1000 * 60 * 60));
    const minutes = Math.floor((remaining % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((remaining % (1000 * 60)) / 1000);
    const pad = (num) => String(num).padStart(2, "0");
    return `${pad(hours)}:${pad(minutes)}:${pad(seconds)}`;
  };
  const getFeaturedCountdown = (featuredSection) => {
    const startTime = featuredSection.countdownStartsAt
      ? new Date(featuredSection.countdownStartsAt).getTime()
      : null;
    const endTime = featuredSection.countdownEndsAt
      ? new Date(featuredSection.countdownEndsAt).getTime()
      : null;

    if (Number.isFinite(startTime) && offerNow < startTime) {
      return {
        label: "Starts in",
        value: formatCountdown(featuredSection.countdownStartsAt),
      };
    }

    if (Number.isFinite(endTime) && offerNow <= endTime) {
      return {
        label: "Ends in",
        value: formatCountdown(featuredSection.countdownEndsAt),
      };
    }

    return null;
  };
  const formatOrderDate = (value) =>
    new Date(value).toLocaleDateString(undefined, {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  const trackingSteps = ["placed", "processing", "shipped", "delivered"];
  const servicePackages = [
    {
      value: "basic",
      label: "Basic Tune-Up",
      summary:
        "Brake check, chain lube, tire pressure, and quick safety inspection.",
      includes: [
        "Brake check",
        "Chain lubrication",
        "Tire pressure setup",
        "Safety inspection",
      ],
    },
    {
      value: "full",
      label: "Full Service",
      summary:
        "Complete drivetrain cleaning, brake alignment, and multi-point diagnostics.",
      includes: [
        "Drivetrain deep clean",
        "Brake alignment",
        "Bolt torque check",
        "Multi-point diagnostics",
      ],
    },
    {
      value: "premium",
      label: "Premium Care",
      summary:
        "Suspension setup, wheel truing, deep clean, and performance optimization.",
      includes: [
        "Suspension setup",
        "Wheel truing",
        "Full detailing",
        "Performance optimization",
      ],
    },
  ];
  const servicePackageLabels = Object.fromEntries(
    servicePackages.map((pkg) => [pkg.value, pkg.label]),
  );
  const returnTrackingSteps = [
    "requested",
    "approved",
    "in_transit",
    "received",
    "refund_initiated",
    "refunded",
  ];
  const getStatusIndex = (status) => {
    const index = trackingSteps.indexOf(String(status || "").toLowerCase());
    return index === -1 ? 0 : index;
  };
  const getStatusLabel = useCallback((status) => {
    const normalized = String(status || "").toLowerCase();
    return normalized.charAt(0).toUpperCase() + normalized.slice(1);
  }, []);
  const getReturnStatusIndex = (status) => {
    const index = returnTrackingSteps.indexOf(
      String(status || "").toLowerCase(),
    );
    return index === -1 ? 0 : index;
  };
  const addCustomerNotification = useCallback((notification) => {
    setCustomerNotifications((prev) => {
      const next = [
        {
          createdAt: new Date().toISOString(),
          ...notification,
        },
        ...prev.filter((item) => item.id !== notification.id),
      ].slice(0, 20);
      localStorage.setItem(
        CUSTOMER_NOTIFICATION_STORAGE_KEY,
        JSON.stringify(next),
      );
      return next;
    });
  }, []);
  const createOrderStatusSnapshot = useCallback(
    (orders) =>
      orders.reduce((acc, order) => {
        acc[order._id] = String(order.status || "placed").toLowerCase();
        return acc;
      }, {}),
    [],
  );
  const notifications = useMemo(() => {
    const items = [];
    const latestOrder = [...orderHistory].sort(
      (a, b) =>
        new Date(b.createdAt || 0).getTime() -
        new Date(a.createdAt || 0).getTime(),
    )[0];
    const activeReturns = orderHistory.filter(
      (order) =>
        String(order.returnRequest?.status || "none").toLowerCase() !== "none",
    );
    const latestServiceRequest = [...serviceRequests].sort(
      (a, b) =>
        new Date(b.createdAt || 0).getTime() -
        new Date(a.createdAt || 0).getTime(),
    )[0];

    customerNotifications.forEach((notification) => {
      items.push(notification);
    });

    activeHeroOffers.slice(0, 4).forEach((offer) => {
      items.push({
        id: `sale-${offer._id}`,
        type: offer.offerType === "flash" ? "danger" : "success",
        title:
          offer.offerType === "flash" ? "Flash sale is live" : "Sale available",
        body: offer.title,
        meta: offer.endsAt
          ? `Ends ${formatOrderDate(offer.endsAt)}`
          : "Limited time",
        action: "Shop sale",
        view: "shop",
      });
    });

    activePromos.slice(0, 4).forEach((promo) => {
      const promoDescription =
        promo.discountType === "shipping"
          ? "Free shipping available"
          : promo.discountType === "flat"
            ? `${formatCurrency(promo.discountValue)} off available`
            : `${Number(promo.discountValue || 0)}% off available`;
      items.push({
        id: `promo-available-${promo._id || promo.code}`,
        type: "success",
        title: `Discount code ${promo.code}`,
        body: `${promoDescription}. Apply this code at checkout.`,
        meta: promo.endsAt ? `Ends ${formatOrderDate(promo.endsAt)}` : "Active",
        action: "Use code",
        view: "cart",
      });
    });

    if (paymentSuccessMessage) {
      items.push({
        id: "payment-success",
        type: "success",
        title: "Payment confirmed",
        body: paymentSuccessMessage,
        meta: "Just now",
        action: "View orders",
        view: "orders",
      });
    }

    if (promoMessage) {
      items.push({
        id: "promo-message",
        type: appliedPromoCode ? "success" : "info",
        title: appliedPromoCode
          ? `Promo ${appliedPromoCode} applied`
          : "Promo update",
        body: promoMessage,
        meta: "Cart",
        action: "Open cart",
        view: "cart",
      });
    }

    if (cart.length > 0) {
      items.push({
        id: "cart-items",
        type: freeShippingGap > 0 ? "warning" : "success",
        title: `${totalItems} item${totalItems === 1 ? "" : "s"} in your cart`,
        body:
          freeShippingGap > 0
            ? `Add ${formatCurrency(freeShippingGap)} more to unlock free shipping.`
            : "You unlocked free shipping for this order.",
        meta: formatCurrency(totalPrice),
        action: "Checkout",
        view: "cart",
      });
    }

    if (latestOrder) {
      items.push({
        id: `order-${latestOrder._id}`,
        type: "info",
        title: `Order ${getStatusLabel(latestOrder.status || "placed")}`,
        body: `#${String(latestOrder._id).slice(-8).toUpperCase()} total ${formatCurrency(latestOrder.total)}.`,
        meta: latestOrder.createdAt
          ? formatOrderDate(latestOrder.createdAt)
          : "Recent",
        action: "Track order",
        view: "orders",
      });
    }

    activeReturns.slice(0, 2).forEach((order) => {
      items.push({
        id: `return-${order._id}`,
        type: "warning",
        title: `Return ${getStatusLabel(order.returnRequest?.status || "requested")}`,
        body: `Return request for order #${String(order._id).slice(-8).toUpperCase()} is being reviewed.`,
        meta: order.returnRequest?.requestedAt
          ? formatOrderDate(order.returnRequest.requestedAt)
          : "Return",
        action: "View return",
        view: "orders",
      });
    });

    if (latestServiceRequest) {
      items.push({
        id: `service-${latestServiceRequest._id}`,
        type:
          String(latestServiceRequest.priority || "normal").toLowerCase() ===
          "emergency"
            ? "danger"
            : "info",
        title: `Service ${getStatusLabel(latestServiceRequest.status || "requested")}`,
        body: `${latestServiceRequest.bikeModel || "Bike"} booking for ${
          latestServiceRequest.preferredDate || "your selected date"
        } at ${latestServiceRequest.preferredTime || "your selected time"}.`,
        meta:
          servicePackageLabels[latestServiceRequest.packageType] || "Service",
        action: "View service",
        view: "servicing",
      });
    }

    if (!profile.contactNumber || !profile.deliveryAddress) {
      items.push({
        id: "profile-missing",
        type: "warning",
        title: "Complete your delivery profile",
        body: "Add contact number and delivery address to make checkout and service booking faster.",
        meta: "Profile",
        action: "Update profile",
        view: "profile",
      });
    }

    if (items.length === 0) {
      items.push({
        id: "all-clear",
        type: "success",
        title: "All caught up",
        body: "No urgent account, order, cart, or service updates right now.",
        meta: "RiderCraft",
        action: "Browse shop",
        view: "shop",
      });
    }

    return items;
  }, [
    appliedPromoCode,
    activeHeroOffers,
    activePromos,
    cart.length,
    customerNotifications,
    freeShippingGap,
    getStatusLabel,
    orderHistory,
    paymentSuccessMessage,
    profile.contactNumber,
    profile.deliveryAddress,
    promoMessage,
    servicePackageLabels,
    serviceRequests,
    totalItems,
    totalPrice,
  ]);
  const notificationCount =
    notifications.length === 1 && notifications[0].id === "all-clear"
      ? 0
      : notifications.length;
  const normalizeProductKey = (id) => String(id?._id || id || "");
  const loadMyOrders = useCallback(
    async ({ notifyChanges = false, silent = false } = {}) => {
      setOrdersError("");
      try {
        const token = localStorage.getItem("token");
        if (!token) return;
        if (!silent) setOrdersLoading(true);
        const res = await axios.get(
          "https://ridercraft-api.onrender.com/orders/my",
          {
            headers: { Authorization: `Bearer ${token}` },
          },
        );
        const nextOrders = Array.isArray(res.data) ? res.data : [];
        const nextSnapshot = createOrderStatusSnapshot(nextOrders);
        const previousSnapshot = orderStatusSnapshotRef.current;

        if (notifyChanges && previousSnapshot) {
          nextOrders.forEach((order) => {
            const orderId = String(order._id || "");
            const previousStatus = previousSnapshot[orderId];
            const nextStatus = nextSnapshot[orderId];
            if (!previousStatus || previousStatus === nextStatus) return;

            const notification = {
              id: `order-status-${orderId}-${nextStatus}`,
              type: nextStatus === "delivered" ? "success" : "info",
              title: `Order ${getStatusLabel(nextStatus)}`,
              body: `Your order #${orderId.slice(-8).toUpperCase()} changed from ${getStatusLabel(
                previousStatus,
              )} to ${getStatusLabel(nextStatus)}.`,
              meta: "Order update",
              action: "Track order",
              view: "orders",
            };
            addCustomerNotification(notification);
            toast.info(notification.body);
          });
        }

        orderStatusSnapshotRef.current = nextSnapshot;
        setOrderHistory(nextOrders);
      } catch (err) {
        setOrdersError(
          err.response?.data?.error || "Could not load order history",
        );
      } finally {
        if (!silent) setOrdersLoading(false);
      }
    },
    [addCustomerNotification, createOrderStatusSnapshot, getStatusLabel],
  );
  const loadActivePromos = useCallback(async () => {
    try {
      const res = await axios.get(
        "https://ridercraft-api.onrender.com/promos/active",
      );
      setActivePromos(Array.isArray(res.data) ? res.data : []);
    } catch {
      setActivePromos([]);
    }
  }, []);
  const loadMyServiceRequests = async () => {
    setServiceError("");
    try {
      const token = localStorage.getItem("token");
      if (!token) return;
      setServiceRequestsLoading(true);
      const res = await axios.get(
        "https://ridercraft-api.onrender.com/service-requests/my",
        {
          headers: { Authorization: `Bearer ${token}` },
        },
      );
      setServiceRequests(Array.isArray(res.data) ? res.data : []);
    } catch (err) {
      setServiceError(
        err.response?.data?.error || "Could not load service requests",
      );
    } finally {
      setServiceRequestsLoading(false);
    }
  };
  const submitServiceRequest = async () => {
    setServiceError("");
    setServiceMessage("");

    const bikeModel = String(serviceForm.bikeModel || "").trim();
    const pickupAddress = String(serviceForm.pickupAddress || "").trim();
    const contactNumber = String(serviceForm.contactNumber || "").trim();
    const priority =
      String(serviceForm.priority || "normal").toLowerCase() === "emergency"
        ? "emergency"
        : "normal";
    const breakdownIssue = String(serviceForm.breakdownIssue || "").trim();
    const pickupLatitude = Number(serviceForm.pickupLocation?.latitude);
    const pickupLongitude = Number(serviceForm.pickupLocation?.longitude);
    const pickupAccuracyMeters =
      serviceForm.pickupLocation?.accuracyMeters === null ||
      serviceForm.pickupLocation?.accuracyMeters === undefined ||
      serviceForm.pickupLocation?.accuracyMeters === ""
        ? null
        : Number(serviceForm.pickupLocation?.accuracyMeters);
    const pickupCapturedAt = serviceForm.pickupLocation?.capturedAt
      ? String(serviceForm.pickupLocation.capturedAt)
      : new Date().toISOString();

    if (!bikeModel) {
      setServiceError("Bike model is required");
      return;
    }
    if (!serviceForm.preferredDate) {
      setServiceError("Preferred date is required");
      return;
    }
    if (!serviceForm.preferredTime) {
      setServiceError("Preferred time is required");
      return;
    }
    if (!pickupAddress) {
      setServiceError("Pickup address is required");
      return;
    }
    if (
      !Number.isFinite(pickupLatitude) ||
      pickupLatitude < -90 ||
      pickupLatitude > 90
    ) {
      setServiceError("Please capture your exact pickup location");
      return;
    }
    if (
      !Number.isFinite(pickupLongitude) ||
      pickupLongitude < -180 ||
      pickupLongitude > 180
    ) {
      setServiceError("Please capture your exact pickup location");
      return;
    }
    if (
      pickupAccuracyMeters !== null &&
      (!Number.isFinite(pickupAccuracyMeters) || pickupAccuracyMeters < 0)
    ) {
      setServiceError(
        "Captured pickup accuracy is invalid. Recapture location.",
      );
      return;
    }
    if (!contactNumber) {
      setServiceError("Contact number is required");
      return;
    }
    if (priority === "emergency" && !breakdownIssue) {
      setServiceError(
        "Please describe your breakdown issue for emergency service",
      );
      return;
    }

    try {
      const token = localStorage.getItem("token");
      if (!token) {
        setServiceError("Please login again");
        return;
      }
      setServiceSubmitting(true);
      await axios.post(
        "https://ridercraft-api.onrender.com/service-requests",
        {
          packageType: serviceForm.packageType,
          bikeModel,
          preferredDate: serviceForm.preferredDate,
          preferredTime: serviceForm.preferredTime,
          pickupAddress,
          pickupLocation: {
            latitude: pickupLatitude,
            longitude: pickupLongitude,
            accuracyMeters: pickupAccuracyMeters,
            capturedAt: pickupCapturedAt,
          },
          contactNumber,
          priority,
          breakdownIssue,
          notes: String(serviceForm.notes || "").trim(),
        },
        { headers: { Authorization: `Bearer ${token}` } },
      );
      setServiceMessage(
        priority === "emergency"
          ? "Emergency service request submitted with first priority."
          : "Service request submitted",
      );
      setServiceForm((prev) => ({
        ...prev,
        priority: "normal",
        bikeModel: SERVICE_BIKE_MODELS[0],
        preferredDate: getTodayDateValue(),
        breakdownIssue: "",
        notes: "",
      }));
      await loadMyServiceRequests();
    } catch (err) {
      setServiceError(
        err.response?.data?.error || "Failed to submit service request",
      );
    } finally {
      setServiceSubmitting(false);
    }
  };
  const captureServiceLocation = () => {
    setServiceError("");
    setServiceMessage("");
    if (!navigator.geolocation) {
      setServiceError("Geolocation is not supported in this browser");
      return;
    }

    setServiceLocationLoading(true);
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const latitude = Number(position.coords.latitude.toFixed(6));
        const longitude = Number(position.coords.longitude.toFixed(6));
        const accuracyMeters = Number.isFinite(position.coords.accuracy)
          ? Number(position.coords.accuracy.toFixed(0))
          : null;
        const capturedAt = new Date(
          position.timestamp || Date.now(),
        ).toISOString();
        setServiceForm((prev) => ({
          ...prev,
          pickupLocation: {
            latitude,
            longitude,
            accuracyMeters,
            capturedAt,
          },
        }));
        setServiceLocationLoading(false);
      },
      (error) => {
        setServiceLocationLoading(false);
        if (error.code === error.PERMISSION_DENIED) {
          setServiceError(
            "Location permission denied. Please allow location access.",
          );
          return;
        }
        if (error.code === error.TIMEOUT) {
          setServiceError("Location request timed out. Try again.");
          return;
        }
        setServiceError("Could not capture your location. Try again.");
      },
      {
        enableHighAccuracy: true,
        timeout: 15000,
        maximumAge: 0,
      },
    );
  };
  const requestReturnForOrder = async (orderId) => {
    const reason = String(returnReasonByOrder[orderId] || "").trim();
    const evidence = Array.isArray(returnEvidenceByOrder[orderId])
      ? returnEvidenceByOrder[orderId]
      : [];
    if (!reason) {
      setReturnError("Return reason is required");
      return;
    }
    if (!evidence.length) {
      setReturnError("Please attach defect proof photo/video");
      return;
    }
    setReturnMessage("");
    setReturnError("");
    try {
      const token = localStorage.getItem("token");
      if (!token) {
        setReturnError("Please login again");
        return;
      }
      setReturnActionLoadingId(orderId);
      await axios.post(
        `https://ridercraft-api.onrender.com/orders/${orderId}/return-request`,
        { reason, evidence },
        { headers: { Authorization: `Bearer ${token}` } },
      );
      setReturnMessage("Return request submitted");
      setReturnReasonByOrder((prev) => ({ ...prev, [orderId]: "" }));
      setReturnEvidenceByOrder((prev) => ({ ...prev, [orderId]: [] }));
      await loadMyOrders();
    } catch (err) {
      setReturnError(
        err.response?.data?.error || "Failed to submit return request",
      );
    } finally {
      setReturnActionLoadingId("");
    }
  };
  const handleReturnEvidenceChange = async (orderId, event) => {
    const files = Array.from(event.target.files || []);
    if (!files.length) return;
    const limited = files.slice(0, 4);
    try {
      const converted = await Promise.all(
        limited.map(async (file) => {
          const isImage = file.type.startsWith("image/");
          const isVideo = file.type.startsWith("video/");
          if (!isImage && !isVideo) {
            throw new Error("Only image/video files are allowed");
          }
          const maxSize = isVideo ? 3 * 1024 * 1024 : 2 * 1024 * 1024;
          if (file.size > maxSize) {
            throw new Error(
              `${file.name} is too large (${isVideo ? "max 3MB video" : "max 2MB image"})`,
            );
          }
          const dataUrl = await readFileAsDataUrl(file);
          return {
            type: isVideo ? "video" : "image",
            url: dataUrl,
            name: file.name,
          };
        }),
      );
      setReturnEvidenceByOrder((prev) => ({ ...prev, [orderId]: converted }));
      setReturnError("");
    } catch (err) {
      setReturnError(err.message || "Failed to read proof files");
    } finally {
      event.target.value = "";
    }
  };

  useEffect(() => {
    if (location.state?.view === "cart") {
      setView("cart");
      navigate("/landing", { replace: true });
    }
  }, [location.state, navigate]);

  useEffect(() => {
    const changed =
      prevTotalsRef.current.totalPrice !== totalPrice ||
      prevTotalsRef.current.shipping !== shipping;
    prevTotalsRef.current = { totalPrice, shipping };
    if (!appliedPromoCode || !changed) return;
    setAppliedPromoCode("");
    setPromoDiscount(0);
    setPromoMessage("Cart changed. Reapply promo code.");
  }, [totalPrice, shipping, appliedPromoCode]);

  useEffect(() => {
    const token = localStorage.getItem("token");
    if (!token) return;
    try {
      const decoded = jwtDecode(token);
      setIsAdmin(decoded.role === "admin");
      setCurrentUserId(String(decoded.id || ""));
    } catch {
      setIsAdmin(false);
      setCurrentUserId("");
    }
  }, []);

  useEffect(() => {
    const loadProfile = async () => {
      try {
        const token = localStorage.getItem("token");
        if (!token) return;
        const res = await axios.get(
          "https://ridercraft-api.onrender.com/auth/profile",
          {
            headers: { Authorization: `Bearer ${token}` },
          },
        );
        setProfile({
          name: res.data.name || "",
          email: res.data.email || "",
          avatar: res.data.avatar || "",
          contactNumber: res.data.contactNumber || "",
          deliveryAddress: res.data.deliveryAddress || "",
        });
        setProfileForm({
          name: res.data.name || "",
          avatar: res.data.avatar || "",
          contactNumber: res.data.contactNumber || "",
          deliveryAddress: res.data.deliveryAddress || "",
        });
      } catch {
        setProfileError("Could not load profile");
      }
    };
    loadProfile();
  }, []);

  useEffect(() => {
    const loadProducts = async () => {
      try {
        const res = await axios.get(
          "https://ridercraft-api.onrender.com/products",
        );
        setProducts(res.data);
      } catch {
        setProductsError("Could not load products");
      }
    };
    loadProducts();
  }, []);

  useEffect(() => {
    const loadHeroOffers = async () => {
      try {
        const res = await axios.get(
          "https://ridercraft-api.onrender.com/hero-offers",
        );
        setHeroOffers(Array.isArray(res.data) ? res.data : []);
      } catch {
        setHeroOffers([]);
      }
    };
    loadHeroOffers();
  }, []);

  useEffect(() => {
    loadActivePromos();
  }, [loadActivePromos]);

  useEffect(() => {
    const loadFeaturedSections = async () => {
      try {
        const res = await axios.get(
          "https://ridercraft-api.onrender.com/featured-sections",
        );
        setFeaturedSectionsData(Array.isArray(res.data) ? res.data : []);
      } catch {
        setFeaturedSectionsData([]);
      }
    };
    loadFeaturedSections();
  }, []);

  useEffect(() => {
    const timer = setInterval(() => setOfferNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    loadMyOrders();
  }, [loadMyOrders]);

  useEffect(() => {
    if (view !== "orders") return;
    loadMyOrders({ notifyChanges: true });
  }, [loadMyOrders, view]);

  useEffect(() => {
    const timer = setInterval(() => {
      loadMyOrders({ notifyChanges: true, silent: true });
    }, 30000);
    return () => clearInterval(timer);
  }, [loadMyOrders]);

  useEffect(() => {
    const timer = setInterval(async () => {
      try {
        const [offersRes, promosRes] = await Promise.all([
          axios.get("https://ridercraft-api.onrender.com/hero-offers"),
          axios.get("https://ridercraft-api.onrender.com/promos/active"),
        ]);
        setHeroOffers(Array.isArray(offersRes.data) ? offersRes.data : []);
        setActivePromos(Array.isArray(promosRes.data) ? promosRes.data : []);
      } catch {
        setActivePromos([]);
      }
    }, 60000);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    loadMyServiceRequests();
  }, []);

  useEffect(() => {
    if (view !== "servicing") return;
    loadMyServiceRequests();
  }, [view]);

  useEffect(() => {
    setServiceForm((prev) => ({
      ...prev,
      pickupAddress: prev.pickupAddress || profile.deliveryAddress || "",
      contactNumber: prev.contactNumber || profile.contactNumber || "",
    }));
  }, [profile.deliveryAddress, profile.contactNumber]);

  useEffect(() => {
    if (!currentUserId || products.length === 0) return;

    setRatingInputs((prev) => {
      const next = { ...prev };
      products.forEach((product) => {
        const entry = product.ratings?.find(
          (rating) => String(rating.user) === currentUserId,
        );
        if (entry && next[product._id] === undefined) {
          next[product._id] = entry.value;
        }
      });
      return next;
    });

    setRatingComments((prev) => {
      const next = { ...prev };
      products.forEach((product) => {
        const entry = product.ratings?.find(
          (rating) => String(rating.user) === currentUserId,
        );
        if (entry && next[product._id] === undefined) {
          next[product._id] = entry.comment || "";
        }
      });
      return next;
    });
  }, [products, currentUserId]);

  const readFileAsDataUrl = (file) =>
    new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result);
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });

  const handleImageChange = async (e) => {
    setProfileError("");
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      setProfileError("Please select an image file");
      return;
    }
    if (file.size > 2 * 1024 * 1024) {
      setProfileError("Image must be 2MB or less");
      return;
    }
    try {
      const dataUrl = await readFileAsDataUrl(file);
      setProfileForm((prev) => ({ ...prev, avatar: dataUrl }));
    } catch {
      setProfileError("Failed to read image");
    }
  };

  const saveProfile = async () => {
    setProfileMessage("");
    setProfileError("");
    try {
      const token = localStorage.getItem("token");
      if (!token) {
        setProfileError("Please login again");
        return;
      }
      const res = await axios.put(
        "https://ridercraft-api.onrender.com/auth/profile",
        {
          name: profileForm.name,
          avatar: profileForm.avatar,
          contactNumber: profileForm.contactNumber,
          deliveryAddress: profileForm.deliveryAddress,
        },
        { headers: { Authorization: `Bearer ${token}` } },
      );
      setProfile(res.data.user);
      setProfileForm({
        name: res.data.user.name || "",
        avatar: res.data.user.avatar || "",
        contactNumber: res.data.user.contactNumber || "",
        deliveryAddress: res.data.user.deliveryAddress || "",
      });
      setProfileMessage("Profile updated successfully");
    } catch (err) {
      setProfileError(err.response?.data?.error || "Failed to update profile");
    }
  };

  return (
    <div className="shop-wrapper">
      <Navbar
        view={view}
        setView={setView}
        totalItems={totalItems}
        totalOrders={orderHistory.length}
        notifications={dbNotifications}
        notificationCount={
          dbNotifications.filter((item) => !item.isRead).length
        }
        profile={profile}
        isAdmin={isAdmin}
        logout={logout}
        searchQuery={shopQuery}
        setSearchQuery={setShopQuery}
      />

      {view === "home" && (
        <section className="hero">
          <h2>Your Daily Tech Deals</h2>
          <p>
            Discover gadgets, accessories, and essentials curated for quick
            checkout.
          </p>
          <button className="primary" onClick={() => setView("shop")}>
            Browse Items
          </button>
        </section>
      )}

      {view === "shop" && (
        <section className="shop-experience">
          <section className="flash-sale-banner">
            <div className="flash-sale-head">
              <h3>⚡ {flashDealsSection.title || "Flash Sale Section"}</h3>
              <p>Limited-time offers</p>
            </div>
            <p className="flash-sale-countdown">
              {flashHeroOffer?.endsAt
                ? `Ends in ${formatCountdown(flashHeroOffer.endsAt)}`
                : "No flash countdown configured by admin"}
            </p>
            <div className="flash-sale-grid">
              {flashSaleProducts.map((product) => {
                const stock = Math.max(0, Number(product.stock ?? 0));
                const maxStockBase = 20;
                const soldProgress = Math.min(
                  100,
                  Math.max(0, ((maxStockBase - stock) / maxStockBase) * 100),
                );
                return (
                  <article
                    className="flash-sale-card"
                    key={`flash-${product._id}`}
                    onClick={() => navigate(`/products/${product._id}`)}
                  >
                    <div className="flash-sale-card-top">
                      {product.image ? (
                        <img
                          src={product.image}
                          alt={product.name}
                          className="flash-sale-image"
                          onError={applyImageFallback}
                        />
                      ) : (
                        <div className="flash-sale-image flash-sale-image-placeholder">
                          No image
                        </div>
                      )}
                      <div>
                        <p className="flash-sale-name">{product.name}</p>
                        <p className="flash-sale-price">
                          ${Number(product.price || 0).toFixed(2)}
                        </p>
                      </div>
                    </div>
                    <p className="flash-sale-stock">
                      {stock > 0 ? `Only ${stock} left!` : "Out of stock"}
                    </p>
                    <div className="flash-sale-progress-track">
                      <span
                        className="flash-sale-progress-fill"
                        style={{ width: `${soldProgress}%` }}
                      />
                    </div>
                  </article>
                );
              })}
            </div>
            {flashSaleProducts.length === 0 && (
              <p className="shop-hero-empty">
                No flash sale products assigned by admin yet.
              </p>
            )}
          </section>

          <div className="featured-sections">
            {featuredSections.map((section) => {
              const featuredCountdown = getFeaturedCountdown(section);
              return (
                <section
                  className="featured-block"
                  key={section._id || section.key}
                >
                  <div className="featured-head">
                    <h3>{section.title}</h3>
                    {featuredCountdown && (
                      <span className="featured-countdown">
                        {featuredCountdown.label} {featuredCountdown.value}
                      </span>
                    )}
                  </div>
                  <div className="featured-grid">
                    {(section.products || []).map((product) => (
                      <article
                        className="featured-card"
                        key={`${section._id}-${product._id}`}
                        onClick={() => navigate(`/products/${product._id}`)}
                      >
                        <div className="featured-image-wrap">
                          {product.image ? (
                            <img
                              src={product.image}
                              alt={product.name}
                              className="featured-image"
                              onError={applyImageFallback}
                            />
                          ) : (
                            <div className="product-card-image-placeholder">
                              No image
                            </div>
                          )}
                        </div>
                        <p className="featured-name">{product.name}</p>
                        <p className="featured-price">
                          ${Number(product.price || 0).toFixed(2)}
                        </p>
                        <button
                          type="button"
                          className="featured-add-btn"
                          onClick={(e) => {
                            e.stopPropagation();
                            addToCart(product);
                          }}
                        >
                          Add
                        </button>
                      </article>
                    ))}
                  </div>
                  {(!section.products || section.products.length === 0) && (
                    <p className="empty">
                      No products assigned by admin for this section yet.
                    </p>
                  )}
                </section>
              );
            })}
          </div>

          {/* <div className="shop-hero-banner">
            <div>
              <p className="shop-hero-eyebrow">New Season Collection</p>
              <h2>Discover premium picks for your everyday lifestyle</h2>
              <p className="shop-hero-text">
                Curated essentials with top-rated quality, fast delivery, and exclusive deals.
              </p>
              {flashHeroOffer && (
                <p className="shop-hero-flash">
                  {flashHeroOffer.title}
                  {flashHeroOffer.endsAt
                    ? ` (Ends in ${formatCountdown(flashHeroOffer.endsAt)})`
                    : ""}
                </p>
              )}
              {!flashHeroOffer && (
                <p className="shop-hero-flash">No active flash sale configured by admin.</p>
              )}
              <div className="shop-hero-tags">
                {tagHeroOffers.map((offer) => (
                  <button
                    type="button"
                    key={offer._id}
                    className="shop-hero-tag-btn"
                    onClick={() => setShopQuery(offer.ctaQuery || offer.title)}
                  >
                    {offer.title}
                  </button>
                ))}
                {tagHeroOffers.length === 0 && (
                  <p className="shop-hero-empty">No active hero offers configured by admin.</p>
                )}
              </div>
            </div>
            <div className="shop-hero-actions">
              <button
                type="button"
                className="shop-hero-btn-primary"
                onClick={() => setShopQuery("top rated")}
              >
                Explore Top Rated
              </button>
              <button
                type="button"
                className="shop-hero-btn-outline"
                onClick={() => setSortBy("price-low")}
              >
                Shop Deals
              </button>
            </div>
          </div> */}
          <section className="ridercraft-hero">
            <div className="ridercraft-hero-content">
              <p className="hero-badge">🏍 Premium Motorcycle Marketplace</p>

              <h1>
                Ride Better.
                <br />
                Ride Safer.
              </h1>

              <p>
                Premium helmets, riding gear, bike accessories, servicing and
                exclusive flash sale deals.
              </p>

              <div className="hero-buttons">
                <button
                  className="hero-primary-btn"
                  onClick={() => setShopQuery("")}
                >
                  Shop Now
                </button>

                <button
                  className="hero-secondary-btn"
                  onClick={() => setView("servicing")}
                >
                  Book Service
                </button>
              </div>
            </div>

            <div className="ridercraft-hero-image">
              <img
                src="https://images.unsplash.com/photo-1558981806-ec527fa84c39"
                alt="Motorcycle Rider"
              />
            </div>
          </section>

          <section className="category-grid">
            <div className="category-card" onClick={() => setActiveTag("All")}>
              <span className="category-icon">🏍</span>
              <h3>All product</h3>
            </div>
            <div
              className="category-card"
              onClick={() => setActiveTag("Helmet")}
            >
              <span className="category-icon">🪖</span>
              <h3>Helmets</h3>
            </div>

            <div
              className="category-card"
              onClick={() => setActiveTag("Gloves")}
            >
              <span className="category-icon">🧤</span>
              <h3>Gloves</h3>
            </div>

            <div
              className="category-card"
              onClick={() => setActiveTag("Riding Gear")}
            >
              <span className="category-icon">🛡️</span>
              <h3>Riding Gear</h3>
            </div>

            <div
              className="category-card"
              onClick={() => setActiveTag("Lights")}
            >
              <span className="category-icon">💡</span>
              <h3>Lights</h3>
            </div>

            <div
              className="category-card"
              onClick={() => setActiveTag("Luggage")}
            >
              <span className="category-icon">🎒</span>
              <h3>Luggage</h3>
            </div>

            <div
              className="category-card"
              onClick={() => setActiveTag("Mobile Holder")}
            >
              <span className="category-icon">📱</span>
              <h3>Mobile Holders</h3>
            </div>

            <div
              className="category-card"
              onClick={() => setActiveTag("Bike Parts")}
            >
              <span className="category-icon">🔧</span>
              <h3>Bike Parts</h3>
            </div>

            <div
              className="category-card"
              onClick={() => setActiveTag("Maintenance")}
            >
              <span className="category-icon">⚙️</span>
              <h3>Maintenance</h3>
            </div>
          </section>
          <div
            className={showFilters ? "shop-content" : "shop-content no-filters"}
          >
            {showFilters && (
              <aside className="shop-filters">
                <div className="shop-filters-head">
                  <h3>Filter</h3>
                  <button
                    className="filter-reset-btn"
                    onClick={() => {
                      setActiveTag("All");
                      setActiveBrand("All");
                      setActiveColorFamily("All");
                      setMinRating(0);
                      setShopQuery("");
                      setCategoryQuery("");
                      setSortBy("popular");
                    }}
                  >
                    Reset
                  </button>
                </div>
                <div className="shop-filter-section">
                  <h4>Category</h4>
                  <input
                    className="category-search"
                    placeholder="Search category"
                    value={categoryQuery}
                    onChange={(e) => setCategoryQuery(e.target.value)}
                  />
                  <div className="tag-filter-list">
                    {visibleTags.map((tag) => (
                      <button
                        key={tag}
                        className={
                          activeTag === tag ? "tag-pill active" : "tag-pill"
                        }
                        onClick={() =>
                          setActiveTag((prev) =>
                            prev === tag || tag === "All" ? "All" : tag,
                          )
                        }
                        aria-pressed={activeTag === tag}
                      >
                        <span>{tag}</span>
                        <span className="tag-count">{tagCounts[tag] || 0}</span>
                      </button>
                    ))}
                  </div>
                  {visibleTags.length === 0 && (
                    <p className="category-empty">No categories found.</p>
                  )}
                </div>
                <div className="shop-filter-section">
                  <h4>Rating</h4>
                  <div className="rating-filter-list">
                    {[
                      { label: "All Ratings", value: 0 },
                      { label: "4★ & up", value: 4 },
                      { label: "3★ & up", value: 3 },
                      { label: "2★ & up", value: 2 },
                    ].map((option) => (
                      <button
                        key={option.label}
                        className={
                          minRating === option.value
                            ? "rating-filter-btn active"
                            : "rating-filter-btn"
                        }
                        onClick={() => setMinRating(option.value)}
                      >
                        {option.label}
                      </button>
                    ))}
                  </div>
                </div>
                <div className="shop-filter-section">
                  <h4>Brand</h4>
                  <div className="brand-filter-list">
                    {availableBrands.map((brand) => (
                      <button
                        key={brand}
                        className={
                          activeBrand === brand
                            ? "brand-filter-btn active"
                            : "brand-filter-btn"
                        }
                        onClick={() => setActiveBrand(brand)}
                      >
                        {brand}
                      </button>
                    ))}
                  </div>
                </div>
                <div className="shop-filter-section">
                  <h4>Colour Family</h4>
                  <div className="brand-filter-list">
                    {availableColorFamilies.map((family) => (
                      <button
                        key={family}
                        className={
                          activeColorFamily === family
                            ? "brand-filter-btn active"
                            : "brand-filter-btn"
                        }
                        onClick={() => setActiveColorFamily(family)}
                      >
                        {family}
                      </button>
                    ))}
                  </div>
                </div>
              </aside>
            )}

            <div className="shop-results">
              <div className="shop-toolbar">
                <select
                  className="shop-sort"
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value)}
                >
                  <option value="popular">Sort: Popular</option>
                  <option value="price-low">Price: Low to High</option>
                  <option value="price-high">Price: High to Low</option>
                  <option value="name-asc">Name: A to Z</option>
                </select>
              </div>

              <p className="results-count">{filteredProducts.length} results</p>
              {productsError && <p className="error-text">{productsError}</p>}
              {ratingMessage && (
                <p className="rating-success">{ratingMessage}</p>
              )}
              {ratingError && <p className="rating-error">{ratingError}</p>}

              <div className="products-grid">
                {filteredProducts.map((product) => (
                  <article
                    className="product-card product-card-clickable"
                    key={product._id}
                    onClick={() => navigate(`/products/${product._id}`)}
                  >
                    <div className="product-card-image-wrap">
                      {product.image ? (
                        <img
                          src={product.image}
                          alt={product.name}
                          className="product-card-image"
                          onError={applyImageFallback}
                        />
                      ) : (
                        <div className="product-card-image-placeholder">
                          No image
                        </div>
                      )}
                    </div>
                    <p className="product-brand">{product.tag}</p>
                    <h3>{product.name}</h3>
                    <p className="price">${product.price}</p>
                    <div className="product-rating-display">
                      <div
                        className="display-star-row"
                        aria-label={`Rating ${(product.ratingAverage || 0).toFixed(1)} out of 5`}
                      >
                        {renderRatingStars(product.ratingAverage)}
                      </div>
                      <p className="product-rating-text">
                        {(product.ratingAverage || 0).toFixed(1)} / 5 from{" "}
                        {product.ratingCount || 0} ratings
                      </p>
                    </div>
                    <p className="your-rating-text">
                      Buy this product to leave a rating from your orders.
                    </p>
                    <button
                      className="primary"
                      onClick={(e) => {
                        e.stopPropagation();
                        addToCart(product);
                      }}
                    >
                      Add to Cart
                    </button>
                  </article>
                ))}
              </div>

              {filteredProducts.length === 0 && !productsError && (
                <p className="empty">No products matched your filters.</p>
              )}
            </div>
          </div>
        </section>
      )}

      {view === "cart" && (
        <section className="cart-wrap">
          <h2 className="cart-title">My Cart</h2>
          <div className="cart-layout">
            <div className="cart-items-panel">
              <div className="cart-table-head">
                <span>Product</span>
                <span>Each</span>
                <span>Quantity</span>
                <span>Total</span>
              </div>

              {cart.length === 0 && (
                <p className="empty">Your cart is empty.</p>
              )}

              {cart.map((item) => (
                <article className="cart-item" key={item._id}>
                  <div className="cart-product-cell">
                    {item.image ? (
                      <img
                        src={item.image}
                        alt={item.name}
                        className="cart-item-image"
                        onError={applyImageFallback}
                      />
                    ) : (
                      <div className="cart-item-image cart-item-placeholder">
                        No image
                      </div>
                    )}
                    <div>
                      <h3>{item.name}</h3>
                      <p>Color: {item.tag || "General"}</p>
                      <p>In stock</p>
                      <div className="cart-item-actions">
                        <button
                          type="button"
                          onClick={() => changeQty(item._id, -item.qty)}
                        >
                          Remove
                        </button>
                      </div>
                    </div>
                  </div>

                  <p className="cart-cell-price">
                    {formatCurrency(item.price)}
                  </p>

                  <div className="cart-cell-qty">
                    <select
                      value={item.qty}
                      onChange={(e) =>
                        changeQty(item._id, Number(e.target.value) - item.qty)
                      }
                    >
                      {Array.from({ length: 10 }, (_, i) => i + 1).map(
                        (qty) => (
                          <option key={qty} value={qty}>
                            {qty}
                          </option>
                        ),
                      )}
                    </select>
                  </div>

                  <p className="cart-cell-total">
                    {formatCurrency(item.price * item.qty)}
                  </p>
                </article>
              ))}

              <div className="cart-footer-row">
                <p>{totalItems} Items</p>
                <p>{formatCurrency(totalPrice)}</p>
              </div>
            </div>

            <aside className="cart-summary-panel">
              <p className="promo-title">ENTER PROMO CODE</p>
              <div className="promo-row">
                <input
                  placeholder="Promo Code"
                  value={promoCode}
                  onChange={(e) => setPromoCode(e.target.value)}
                />
                <button type="button" onClick={applyPromoCode}>
                  Submit
                </button>
              </div>
              {promoMessage && <p className="promo-message">{promoMessage}</p>}
              {paymentSuccessMessage && (
                <p className="payment-success-message">
                  {paymentSuccessMessage}
                </p>
              )}

              <div className="payment-block">
                <p className="promo-title">PAYMENT METHOD</p>
                <div className="payment-methods">
                  <label>
                    <input
                      type="radio"
                      name="paymentMethod"
                      value="card"
                      checked={paymentMethod === "card"}
                      onChange={(e) => setPaymentMethod(e.target.value)}
                    />
                    <span>Card</span>
                  </label>
                  <label>
                    <input
                      type="radio"
                      name="paymentMethod"
                      value="cod"
                      checked={paymentMethod === "cod"}
                      onChange={(e) => setPaymentMethod(e.target.value)}
                    />
                    <span>Cash on Delivery</span>
                  </label>
                  <label>
                    <input
                      type="radio"
                      name="paymentMethod"
                      value="ewallet"
                      checked={paymentMethod === "ewallet"}
                      onChange={(e) => setPaymentMethod(e.target.value)}
                    />
                    <span>E-Wallet</span>
                  </label>
                </div>

                {paymentMethod === "card" && (
                  <div className="payment-fields">
                    <p className="payment-dummy-note">
                      Dummy mode: use test card only, no real charge.
                    </p>
                    <input
                      placeholder="Card Number (16 digits)"
                      value={paymentDetails.cardNumber}
                      maxLength={19}
                      onChange={(e) =>
                        setPaymentDetails((prev) => ({
                          ...prev,
                          cardNumber: e.target.value,
                        }))
                      }
                    />
                    <input
                      placeholder="Card Holder Name"
                      value={paymentDetails.cardHolder}
                      onChange={(e) =>
                        setPaymentDetails((prev) => ({
                          ...prev,
                          cardHolder: e.target.value,
                        }))
                      }
                    />
                    <div className="payment-row-two">
                      <input
                        placeholder="MM/YY"
                        value={paymentDetails.expiry}
                        maxLength={5}
                        onChange={(e) =>
                          setPaymentDetails((prev) => ({
                            ...prev,
                            expiry: e.target.value,
                          }))
                        }
                      />
                      <input
                        placeholder="CVV"
                        value={paymentDetails.cvv}
                        maxLength={4}
                        onChange={(e) =>
                          setPaymentDetails((prev) => ({
                            ...prev,
                            cvv: e.target.value,
                          }))
                        }
                      />
                    </div>
                    <div className="payment-dummy-actions">
                      <button
                        type="button"
                        className="payment-dummy-btn"
                        onClick={useDummyCardDetails}
                      >
                        Use Dummy Card
                      </button>
                    </div>
                  </div>
                )}

                {paymentMethod === "ewallet" && (
                  <div className="payment-fields">
                    <p className="payment-dummy-note">
                      Dummy mode: use test wallet, no real charge.
                    </p>
                    <select
                      value={paymentDetails.walletProvider}
                      onChange={(e) =>
                        setPaymentDetails((prev) => ({
                          ...prev,
                          walletProvider: e.target.value,
                        }))
                      }
                    >
                      <option value="">Select Wallet Provider</option>
                      <option value="PhonePe">PhonePe</option>
                      <option value="Paytm">Paytm</option>
                      <option value="Google Pay">Google Pay</option>
                      <option value="PayPal">PayPal</option>
                      <option value="Apple Pay">Apple Pay</option>
                    </select>
                    <input
                      placeholder="Wallet email / number"
                      value={paymentDetails.walletId}
                      onChange={(e) =>
                        setPaymentDetails((prev) => ({
                          ...prev,
                          walletId: e.target.value,
                        }))
                      }
                    />
                    <div className="payment-dummy-actions">
                      <button
                        type="button"
                        className="payment-dummy-btn"
                        onClick={useDummyEwalletDetails}
                      >
                        Use Dummy E-Wallet
                      </button>
                    </div>
                  </div>
                )}
              </div>

              <div className="summary-lines">
                <div>
                  <span>Shipping cost</span>
                  <span>
                    {shipping === 0 ? "FREE" : formatCurrency(shipping)}
                  </span>
                </div>
                <div>
                  <span>Discount</span>
                  <span>-{formatCurrency(promoDiscount)}</span>
                </div>
                <div>
                  <span>Tax</span>
                  <span>{formatCurrency(tax)}</span>
                </div>
                <div className="summary-estimated">
                  <span>Estimated Total</span>
                  <span>{formatCurrency(estimatedTotal)}</span>
                </div>
              </div>

              <p className="shipping-tip">
                {freeShippingGap > 0
                  ? `You're ${formatCurrency(freeShippingGap)} away from free shipping!`
                  : "You unlocked free shipping."}
              </p>
              <button
                className="checkout-btn"
                type="button"
                onClick={checkoutCart}
                disabled={paymentProcessing}
              >
                {paymentProcessing ? "Processing dummy payment..." : "Checkout"}
              </button>
            </aside>
          </div>
        </section>
      )}

      {view === "servicing" && (
        <section className="servicing-wrap">
          <header className="servicing-head">
            <p className="servicing-eyebrow">Bike Care</p>
            <h2>Bike Servicing</h2>
            <p>
              Book trusted maintenance and keep your ride smooth, safe, and
              road-ready.
            </p>
          </header>

          <div className="servicing-form">
            <h3>Book a Service</h3>
            {serviceMessage && <p className="success-text">{serviceMessage}</p>}
            {serviceError && <p className="error-text">{serviceError}</p>}
            <div className="servicing-form-grid">
              <label>
                Service Type
                <select
                  value={serviceForm.priority}
                  onChange={(e) =>
                    setServiceForm((prev) => ({
                      ...prev,
                      priority: e.target.value,
                    }))
                  }
                >
                  <option value="normal">Normal Request</option>
                  <option value="emergency">
                    Emergency Breakdown (First Priority)
                  </option>
                </select>
              </label>
              {serviceForm.priority !== "emergency" && (
                <label>
                  Package
                  <div className="servicing-package-row">
                    <select
                      value={serviceForm.packageType}
                      onChange={(e) =>
                        setServiceForm((prev) => ({
                          ...prev,
                          packageType: e.target.value,
                        }))
                      }
                    >
                      {servicePackages.map((pkg) => (
                        <option key={pkg.value} value={pkg.value}>
                          {pkg.label}
                        </option>
                      ))}
                    </select>
                    <span
                      className="servicing-info-icon"
                      tabIndex={0}
                      aria-label={`Package includes ${
                        servicePackages
                          .find((pkg) => pkg.value === serviceForm.packageType)
                          ?.includes.join(", ") || ""
                      }`}
                    >
                      i
                      <span className="servicing-info-tooltip">
                        {(
                          servicePackages.find(
                            (pkg) => pkg.value === serviceForm.packageType,
                          )?.includes || []
                        ).join(" • ")}
                      </span>
                    </span>
                  </div>
                </label>
              )}
              <label>
                Bike Model
                <select
                  value={serviceForm.bikeModel}
                  onChange={(e) =>
                    setServiceForm((prev) => ({
                      ...prev,
                      bikeModel: e.target.value,
                    }))
                  }
                >
                  {SERVICE_BIKE_MODELS.map((model) => (
                    <option key={model} value={model}>
                      {model}
                    </option>
                  ))}
                </select>
              </label>
              <label>
                Preferred Date
                <input
                  type="date"
                  value={serviceForm.preferredDate}
                  min={getTodayDateValue()}
                  onChange={(e) =>
                    setServiceForm((prev) => ({
                      ...prev,
                      preferredDate: e.target.value,
                    }))
                  }
                />
              </label>
              <label>
                Preferred Time
                <input
                  type="time"
                  value={serviceForm.preferredTime}
                  onChange={(e) =>
                    setServiceForm((prev) => ({
                      ...prev,
                      preferredTime: e.target.value,
                    }))
                  }
                />
              </label>
              <label className="servicing-form-full">
                Pickup Address
                <input
                  value={serviceForm.pickupAddress}
                  onChange={(e) =>
                    setServiceForm((prev) => ({
                      ...prev,
                      pickupAddress: e.target.value,
                    }))
                  }
                  placeholder="Address for pickup/drop"
                />
              </label>
              <div className="servicing-form-full servicing-location-block">
                <button
                  type="button"
                  className="primary"
                  onClick={captureServiceLocation}
                  disabled={serviceLocationLoading}
                >
                  {serviceLocationLoading
                    ? "Capturing location..."
                    : "Use My Current Location"}
                </button>
                <p className="servicing-location-text">
                  {Number.isFinite(
                    Number(serviceForm.pickupLocation?.latitude),
                  ) &&
                  Number.isFinite(Number(serviceForm.pickupLocation?.longitude))
                    ? `Captured: ${serviceForm.pickupLocation.latitude}, ${serviceForm.pickupLocation.longitude} (${serviceForm.pickupLocation.accuracyMeters ?? "N/A"}m accuracy)`
                    : "No GPS location captured yet"}
                </p>
                {Number.isFinite(
                  Number(serviceForm.pickupLocation?.latitude),
                ) &&
                  Number.isFinite(
                    Number(serviceForm.pickupLocation?.longitude),
                  ) && (
                    <div className="servicing-map-preview">
                      <a
                        href={`https://www.google.com/maps?q=${serviceForm.pickupLocation.latitude},${serviceForm.pickupLocation.longitude}`}
                        target="_blank"
                        rel="noreferrer"
                      >
                        Open current location in Google Maps
                      </a>
                      <iframe
                        title="Current pickup location map"
                        src={`https://maps.google.com/maps?q=${serviceForm.pickupLocation.latitude},${serviceForm.pickupLocation.longitude}&z=16&output=embed`}
                        loading="lazy"
                        referrerPolicy="no-referrer-when-downgrade"
                      />
                    </div>
                  )}
              </div>
              <label>
                Contact Number
                <input
                  value={serviceForm.contactNumber}
                  onChange={(e) =>
                    setServiceForm((prev) => ({
                      ...prev,
                      contactNumber: e.target.value,
                    }))
                  }
                  placeholder="Phone number"
                />
              </label>
              {serviceForm.priority === "emergency" && (
                <label className="servicing-form-full">
                  Breakdown Issue (required for emergency)
                  <textarea
                    rows={2}
                    value={serviceForm.breakdownIssue}
                    onChange={(e) =>
                      setServiceForm((prev) => ({
                        ...prev,
                        breakdownIssue: e.target.value,
                      }))
                    }
                    placeholder="Example: Bike not starting, chain snapped, brake failed"
                  />
                </label>
              )}
              <label className="servicing-form-full">
                Notes (optional)
                <textarea
                  rows={3}
                  value={serviceForm.notes}
                  onChange={(e) =>
                    setServiceForm((prev) => ({
                      ...prev,
                      notes: e.target.value,
                    }))
                  }
                  placeholder="Any issues you want us to check"
                />
              </label>
            </div>

            <div className="servicing-cta">
              <button
                type="button"
                className="primary"
                onClick={submitServiceRequest}
                disabled={serviceSubmitting}
              >
                {serviceSubmitting ? "Submitting..." : "Book Service"}
              </button>
              <button
                type="button"
                className="primary"
                onClick={() => setView("shop")}
              >
                Explore Products
              </button>
            </div>
          </div>

          <div className="servicing-history">
            <h3>My Service Requests</h3>
            {serviceRequestsLoading && <p>Loading service requests...</p>}
            {!serviceRequestsLoading && serviceRequests.length === 0 && (
              <p className="empty">No service requests yet.</p>
            )}
            <div className="servicing-history-list">
              {serviceRequests.map((request) => (
                <article className="servicing-history-card" key={request._id}>
                  <p>
                    <strong>
                      {servicePackageLabels[request.packageType] ||
                        request.packageType}
                    </strong>
                    {String(request.priority || "normal") === "emergency" && (
                      <span className="servicing-emergency-chip">
                        Emergency Priority
                      </span>
                    )}
                  </p>
                  <p>Bike: {request.bikeModel}</p>
                  <p>
                    Slot: {request.preferredDate} at {request.preferredTime}
                  </p>
                  <p>Pickup: {request.pickupAddress}</p>
                  {request.pickupLocation?.latitude !== undefined &&
                    request.pickupLocation?.longitude !== undefined && (
                      <p>
                        GPS: {request.pickupLocation.latitude},{" "}
                        {request.pickupLocation.longitude}{" "}
                        <a
                          href={`https://www.google.com/maps?q=${request.pickupLocation.latitude},${request.pickupLocation.longitude}`}
                          target="_blank"
                          rel="noreferrer"
                        >
                          Open Map
                        </a>
                      </p>
                    )}
                  {String(request.priority || "normal") === "emergency" && (
                    <p>Breakdown: {request.breakdownIssue || "-"}</p>
                  )}
                  {request.assignedGarage?.garageProfile?.garageName && (
                    <p>
                      Assigned Garage:{" "}
                      <strong>
                        {request.assignedGarage.garageProfile.garageName}
                      </strong>
                      {Number.isFinite(Number(request.assignedGarageDistanceKm))
                        ? ` (${Number(request.assignedGarageDistanceKm).toFixed(2)} km away)`
                        : ""}
                    </p>
                  )}
                  <p>Status: {getStatusLabel(request.status || "requested")}</p>
                  {request.garageNote && (
                    <p>Garage Response: {request.garageNote}</p>
                  )}
                </article>
              ))}
            </div>
          </div>
        </section>
      )}

      {view === "notifications" && (
        <section className="profile-shell">
          <div className="profile-board">
            <div className="profile-main-area">
              <header className="profile-topbar">
                <div>
                  <h2>Notifications</h2>
                  <p>Account, order, cart, and service updates in one place</p>
                </div>
                <span className="notification-total">
                  {notificationCount} new
                </span>
              </header>

              <div className="profile-content-card notification-card">
                <div className="notification-summary">
                  <div>
                    <span>Orders</span>
                    <strong>{orderHistory.length}</strong>
                  </div>
                  <div>
                    <span>Cart Items</span>
                    <strong>{totalItems}</strong>
                  </div>
                  <div>
                    <span>Service Requests</span>
                    <strong>{serviceRequests.length}</strong>
                  </div>
                </div>

                <div className="notification-list">
                  {notifications.map((item) => (
                    <article
                      className={`notification-item notification-${item.type}`}
                      key={item.id}
                    >
                      <div className="notification-icon" aria-hidden>
                        {item.type === "success"
                          ? "OK"
                          : item.type === "warning"
                            ? "!"
                            : item.type === "danger"
                              ? "!!"
                              : "i"}
                      </div>
                      <div className="notification-copy">
                        <div className="notification-row">
                          <h3>{item.title}</h3>
                          <span>{item.meta}</span>
                        </div>
                        <p>{item.body}</p>
                        <button
                          type="button"
                          className="notification-action"
                          onClick={() => setView(item.view)}
                        >
                          {item.action}
                        </button>
                      </div>
                    </article>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </section>
      )}

      {view === "orders" && (
        <section className="profile-shell">
          <div className="profile-board">
            <div className="profile-main-area">
              <header className="profile-topbar">
                <div>
                  <h2>My Orders</h2>
                  <p>Review your order history and rate purchased products</p>
                </div>
              </header>

              <div className="profile-content-card">
                {ordersLoading && <p>Loading orders...</p>}
                {ordersError && <p className="error-text">{ordersError}</p>}
                {ratingMessage && (
                  <p className="success-text">{ratingMessage}</p>
                )}
                {ratingError && <p className="error-text">{ratingError}</p>}
                {returnMessage && (
                  <p className="success-text">{returnMessage}</p>
                )}
                {returnError && <p className="error-text">{returnError}</p>}

                {!ordersLoading && orderHistory.length === 0 && (
                  <p className="empty">No orders found yet.</p>
                )}

                <div className="orders-list">
                  {orderHistory.map((order) => (
                    <article className="order-card" key={order._id}>
                      <div className="order-card-header">
                        <p>
                          Order:{" "}
                          <strong>
                            #{String(order._id).slice(-8).toUpperCase()}
                          </strong>
                        </p>
                        <p>{formatOrderDate(order.createdAt)}</p>
                      </div>
                      <div className="order-card-summary">
                        <span>Status: {getStatusLabel(order.status)}</span>
                        <span>
                          Payment:{" "}
                          {(order.paymentMethod || "cod").toUpperCase()}
                        </span>
                        <span>
                          Payment Status:{" "}
                          {getStatusLabel(order.paymentStatus || "pending")}
                        </span>
                        <span>Total: {formatCurrency(order.total)}</span>
                        <span>Items: {order.items?.length || 0}</span>
                        <span>
                          Return:{" "}
                          {getStatusLabel(
                            order.returnRequest?.status || "none",
                          )}
                        </span>
                      </div>

                      {String(order.returnRequest?.status || "none") ===
                        "none" &&
                        String(order.status || "").toLowerCase() ===
                          "delivered" && (
                          <div className="order-return-request-wrap">
                            <textarea
                              className="order-comment-input"
                              placeholder="Reason for return"
                              value={returnReasonByOrder[order._id] || ""}
                              onChange={(e) =>
                                setReturnReasonByOrder((prev) => ({
                                  ...prev,
                                  [order._id]: e.target.value,
                                }))
                              }
                            />
                            <input
                              type="file"
                              accept="image/*,video/*"
                              multiple
                              onChange={(e) =>
                                handleReturnEvidenceChange(order._id, e)
                              }
                            />
                            <p className="order-return-proof-hint">
                              Upload defect proof (up to 4 files: images max
                              2MB, videos max 3MB)
                            </p>
                            {Array.isArray(returnEvidenceByOrder[order._id]) &&
                              returnEvidenceByOrder[order._id].length > 0 && (
                                <div className="order-return-proof-grid">
                                  {returnEvidenceByOrder[order._id].map(
                                    (file, idx) =>
                                      file.type === "video" ? (
                                        <video
                                          key={`${order._id}-proof-${idx}`}
                                          src={file.url}
                                          controls
                                        />
                                      ) : (
                                        <img
                                          key={`${order._id}-proof-${idx}`}
                                          src={file.url}
                                          alt={file.name || "Proof"}
                                          onError={applyImageFallback}
                                        />
                                      ),
                                  )}
                                </div>
                              )}
                            <button
                              type="button"
                              className="order-return-btn"
                              onClick={() => requestReturnForOrder(order._id)}
                              disabled={returnActionLoadingId === order._id}
                            >
                              {returnActionLoadingId === order._id
                                ? "Submitting..."
                                : "Request Return"}
                            </button>
                          </div>
                        )}

                      {String(order.returnRequest?.status || "none") !==
                        "none" && (
                        <div className="order-return-tracking-wrap">
                          <p className="order-return-title">
                            Return Tracking:{" "}
                            <strong>
                              {getStatusLabel(
                                order.returnRequest?.status || "none",
                              )}
                            </strong>
                          </p>
                          <div className="order-return-line-wrap">
                            <div className="order-tracking-line" />
                            {returnTrackingSteps.map((step, stepIndex) => {
                              const currentIndex = getReturnStatusIndex(
                                order.returnRequest?.status,
                              );
                              const isDone = stepIndex <= currentIndex;
                              return (
                                <div
                                  className={
                                    isDone ? "track-step done" : "track-step"
                                  }
                                  key={`${order._id}-return-${step}`}
                                >
                                  <span className="track-dot" />
                                  <span className="track-label">
                                    {getStatusLabel(step)}
                                  </span>
                                </div>
                              );
                            })}
                          </div>
                          {Array.isArray(order.returnRequest?.timeline) &&
                            order.returnRequest.timeline.length > 0 && (
                              <div className="order-return-events">
                                {order.returnRequest.timeline
                                  .slice()
                                  .reverse()
                                  .slice(0, 4)
                                  .map((event, idx) => (
                                    <p key={`${order._id}-event-${idx}`}>
                                      {new Date(event.at).toLocaleString()} •{" "}
                                      {getStatusLabel(event.status)} •{" "}
                                      {event.note || "Updated"}
                                    </p>
                                  ))}
                              </div>
                            )}
                          {Array.isArray(order.returnRequest?.evidence) &&
                            order.returnRequest.evidence.length > 0 && (
                              <div className="order-return-proof-grid">
                                {order.returnRequest.evidence.map(
                                  (file, idx) =>
                                    file.type === "video" ? (
                                      <video
                                        key={`${order._id}-saved-proof-${idx}`}
                                        src={file.url}
                                        controls
                                      />
                                    ) : (
                                      <img
                                        key={`${order._id}-saved-proof-${idx}`}
                                        src={file.url}
                                        alt={file.name || "Proof"}
                                        onError={applyImageFallback}
                                      />
                                    ),
                                )}
                              </div>
                            )}
                        </div>
                      )}

                      <div className="order-tracking-wrap">
                        <div className="order-tracking-line" />
                        {trackingSteps.map((step, stepIndex) => {
                          const currentIndex = getStatusIndex(order.status);
                          const isDone = stepIndex <= currentIndex;
                          return (
                            <div
                              className={
                                isDone ? "track-step done" : "track-step"
                              }
                              key={`${order._id}-${step}`}
                            >
                              <span className="track-dot" />
                              <span className="track-label">
                                {getStatusLabel(step)}
                              </span>
                            </div>
                          );
                        })}
                      </div>

                      <div className="order-items">
                        {(order.items || []).map((item, index) => {
                          const productKey = normalizeProductKey(
                            item.productId,
                          );
                          const preview =
                            ratingHover[productKey] ||
                            ratingInputs[productKey] ||
                            0;
                          return (
                            <div
                              className="order-item-row"
                              key={`${order._id}-${productKey}-${index}`}
                            >
                              <div className="order-item-main">
                                {item.image ? (
                                  <img
                                    src={item.image}
                                    alt={item.name}
                                    className="order-item-image"
                                    onError={applyImageFallback}
                                  />
                                ) : (
                                  <div className="order-item-image order-item-placeholder">
                                    No image
                                  </div>
                                )}
                                <div>
                                  <h4>{item.name}</h4>
                                  <p>
                                    {item.qty} x {formatCurrency(item.price)}
                                  </p>
                                </div>
                              </div>

                              <div className="order-item-rate-panel">
                                <div className="star-rating-row">
                                  {[1, 2, 3, 4, 5].map((star) => {
                                    const isFull = star <= preview;
                                    const isHalf =
                                      !isFull && star - 0.5 === preview;
                                    return (
                                      <button
                                        key={star}
                                        className={`star-btn${isFull ? " star-btn-active" : ""}${isHalf ? " star-btn-half" : ""}`}
                                        onMouseMove={(e) => {
                                          const rect =
                                            e.currentTarget.getBoundingClientRect();
                                          const isLeftHalf =
                                            e.clientX - rect.left <
                                            rect.width / 2;
                                          const nextValue = isLeftHalf
                                            ? star - 0.5
                                            : star;
                                          setRatingHover((prevState) => ({
                                            ...prevState,
                                            [productKey]: nextValue,
                                          }));
                                        }}
                                        onMouseLeave={() =>
                                          setRatingHover((prevState) => ({
                                            ...prevState,
                                            [productKey]: 0,
                                          }))
                                        }
                                        onClick={(e) => {
                                          const rect =
                                            e.currentTarget.getBoundingClientRect();
                                          const isLeftHalf =
                                            e.clientX - rect.left <
                                            rect.width / 2;
                                          const nextValue = isLeftHalf
                                            ? star - 0.5
                                            : star;
                                          setRatingInputs((prevState) => ({
                                            ...prevState,
                                            [productKey]: nextValue,
                                          }));
                                        }}
                                        disabled={
                                          ratingLoadingId === productKey
                                        }
                                        type="button"
                                      >
                                        ★
                                      </button>
                                    );
                                  })}
                                </div>
                                <textarea
                                  className="order-comment-input"
                                  placeholder="Write a short review comment (optional)"
                                  value={ratingComments[productKey] || ""}
                                  maxLength={300}
                                  onChange={(e) =>
                                    setRatingComments((prevState) => ({
                                      ...prevState,
                                      [productKey]: e.target.value,
                                    }))
                                  }
                                />
                                <button
                                  className="primary order-rate-submit"
                                  type="button"
                                  onClick={() =>
                                    submitRating(
                                      productKey,
                                      ratingInputs[productKey],
                                      ratingComments[productKey] || "",
                                    )
                                  }
                                  disabled={
                                    !ratingInputs[productKey] ||
                                    ratingLoadingId === productKey
                                  }
                                >
                                  {ratingLoadingId === productKey
                                    ? "Saving..."
                                    : "Save Rating"}
                                </button>
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    </article>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </section>
      )}

      {view === "profile" && (
        <section className="profile-shell">
          <div className="profile-board">
            <div className="profile-main-area">
              <header className="profile-topbar">
                <div>
                  <h2>Welcome, {profile.name || "User"}</h2>
                  <p>Profile settings</p>
                </div>
              </header>

              <div className="profile-content-card">
                <div className="profile-head-row">
                  <div className="profile-user-block">
                    {profileForm.avatar ? (
                      <img
                        src={profileForm.avatar}
                        alt="Profile"
                        className="avatar-preview"
                        onError={applyImageFallback}
                      />
                    ) : (
                      <div className="avatar-placeholder">No Image</div>
                    )}
                    <div>
                      <h3>{profile.name || "Your Name"}</h3>
                      <p>{profile.email}</p>
                    </div>
                  </div>
                  <button className="profile-edit-btn" onClick={saveProfile}>
                    Save
                  </button>
                </div>

                <div className="profile-form-grid">
                  <div className="field-block">
                    <label>Full Name</label>
                    <input
                      value={profileForm.name}
                      onChange={(e) =>
                        setProfileForm((prev) => ({
                          ...prev,
                          name: e.target.value,
                        }))
                      }
                      placeholder="Your full name"
                    />
                  </div>
                  <div className="field-block">
                    <label>Email</label>
                    <input value={profile.email} readOnly />
                  </div>
                  <div className="field-block">
                    <label>Contact Number</label>
                    <input
                      value={profileForm.contactNumber}
                      onChange={(e) =>
                        setProfileForm((prev) => ({
                          ...prev,
                          contactNumber: e.target.value,
                        }))
                      }
                      placeholder="+1 555 000 0000"
                    />
                  </div>
                  <div className="field-block">
                    <label>Delivery Address</label>
                    <input
                      value={profileForm.deliveryAddress}
                      onChange={(e) =>
                        setProfileForm((prev) => ({
                          ...prev,
                          deliveryAddress: e.target.value,
                        }))
                      }
                      placeholder="Street, City, State, ZIP"
                    />
                  </div>
                </div>

                <div className="profile-email-panel">
                  <h4>My Email Address</h4>
                  <p>{profile.email}</p>
                  <h4 style={{ marginTop: "12px" }}>Delivery Contact</h4>
                  <p>{profile.contactNumber || "Not added yet"}</p>
                  <p>{profile.deliveryAddress || "Address not added yet"}</p>
                  <div className="profile-upload-row">
                    <input
                      type="file"
                      accept="image/*"
                      onChange={handleImageChange}
                    />
                    <button className="profile-edit-btn" onClick={saveProfile}>
                      Update Profile
                    </button>
                  </div>
                </div>

                {profileMessage && (
                  <p className="success-text">{profileMessage}</p>
                )}
                {profileError && <p className="error-text">{profileError}</p>}
              </div>
            </div>
          </div>
        </section>
      )}
    </div>
  );
}
