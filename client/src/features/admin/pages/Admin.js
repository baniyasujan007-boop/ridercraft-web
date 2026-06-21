import { useCallback, useEffect, useMemo, useState } from "react";
import axios from "axios";
import AdminSectionContent from "./AdminSectionContent";
import "../styles/admin.css";

const initialForm = {
  name: "Sample Product",
  price: "999",
  tag: "General",
  brand: "Generic",
  colorFamily: "Neutral",
  stock: "25",
  sizes: "",
  colors: "",
  image: "",
  description: "",
  isFlashSale: false,
  flashSalePrice: "",
  flashSaleEndsAt: "",
  variants: [
    {
      color: "Black",
      colorHex: "#000000",
      stock: "25",
      sku: "",
      imagesText: "",
      images: [],
    },
  ],
};
const initialPromoForm = {
  code: "",
  discountType: "percent",
  discountValue: "10",
  maxUses: "50",
  startsAt: "",
  endsAt: "",
  isActive: true,
};
const initialHeroOfferForm = {
  title: "",
  offerType: "tag",
  startsAt: "",
  endsAt: "",
  priority: "1",
  ctaQuery: "",
  isActive: true,
};
const initialFeaturedSectionForm = {
  key: "trending",
  title: "🔥 Trending Products",
  productIds: [],
  sortOrder: "1",
  countdownStartsAt: "",
  countdownEndsAt: "",
  isActive: true,
};

const toDateTimeInputValue = (value) => {
  if (!value) return "";
  const date = new Date(value);
  if (!Number.isFinite(date.getTime())) return "";
  const pad = (num) => String(num).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(
    date.getHours(),
  )}:${pad(date.getMinutes())}`;
};

const createBlankVariant = () => ({
  color: "",
  colorHex: "#111827",
  stock: "0",
  sku: "",
  imagesText: "",
  images: [],
});

const normalizeVariantForForm = (variant = {}) => {
  const images = Array.isArray(variant.images)
    ? variant.images.filter(Boolean)
    : [];
  return {
    color: variant.color || "",
    colorHex: variant.colorHex || "#111827",
    stock: String(variant.stock ?? "0"),
    sku: variant.sku || "",
    imagesText: images.join("\n"),
    images,
  };
};

const splitVariantImages = (variant) =>
  String(variant.imagesText || "")
    .split(/\n|,/)
    .map((image) => image.trim())
    .filter(Boolean);

export default function Admin() {
  const [productUrl, setProductUrl] = useState("");
  const [products, setProducts] = useState([]);
  const [promos, setPromos] = useState([]);
  const [heroOffers, setHeroOffers] = useState([]);
  const [featuredSections, setFeaturedSections] = useState([]);
  const [orders, setOrders] = useState([]);
  const [serviceRequests, setServiceRequests] = useState([]);
  const [section, setSection] = useState("products");
  const [form, setForm] = useState(initialForm);
  const [promoForm, setPromoForm] = useState(initialPromoForm);
  const [orderFilters, setOrderFilters] = useState({
    search: "",
    orderStatus: "all",
    priceRange: "all",
    sortByDate: "newest",
  });

  const [editingId, setEditingId] = useState(null);
  const [editingPromoId, setEditingPromoId] = useState(null);
  const [heroOfferForm, setHeroOfferForm] = useState(initialHeroOfferForm);
  const [editingHeroOfferId, setEditingHeroOfferId] = useState(null);
  const [featuredSectionForm, setFeaturedSectionForm] = useState(
    initialFeaturedSectionForm,
  );
  const [editingFeaturedSectionId, setEditingFeaturedSectionId] =
    useState(null);
  const [flashSaleProductIds, setFlashSaleProductIds] = useState([]);
  const [flashSaleSchedule, setFlashSaleSchedule] = useState({
    startsAt: "",
    endsAt: "",
  });
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const [selectedCustomerEmail, setSelectedCustomerEmail] = useState("");
  const [selectedOrderId, setSelectedOrderId] = useState("");
  const [selectedServiceRequestId, setSelectedServiceRequestId] = useState("");
  const [serviceFilters, setServiceFilters] = useState({
    search: "",
    packageType: "all",
    priority: "all",
    status: "all",
    sortByDate: "newest",
  });
  const [serviceTrackingStatus, setServiceTrackingStatus] =
    useState("requested");
  const [serviceAdminNote, setServiceAdminNote] = useState("");
  const [returnReviewNote, setReturnReviewNote] = useState("");
  const [returnTrackingStatus, setReturnTrackingStatus] =
    useState("in_transit");
  const sectionMeta = {
    products: {
      title: "Product Dashboard",
      subtitle: "Add, edit, and delete items shown to users.",
    },
    orders: {
      title: "Orders Dashboard",
      subtitle: "Track all order activity and update delivery status.",
    },
    promos: {
      title: "Payment & Promo Dashboard",
      subtitle: "Manage promo codes and payment discount campaigns.",
    },
    customers: {
      title: "Customers Dashboard",
      subtitle: "View your customer list and buying behavior.",
    },
    inventory: {
      title: "Inventory Alerts",
      subtitle:
        "Track low stock, out-of-stock products, and restock reminders.",
    },
    performance: {
      title: "Product Performance Insights",
      subtitle: "Monitor top performers, weak products, and rating momentum.",
    },
    featured: {
      title: "Featured Sections Dashboard",
      subtitle: "Manage top shop sections and assign products to each one.",
    },
    services: {
      title: "Service Requests Dashboard",
      subtitle:
        "Track bike servicing requests, exact location, and fulfillment status.",
    },
  };

  const token = localStorage.getItem("token");

  const logout = () => {
    localStorage.removeItem("token");
    window.location.href = "/";
  };

  const fetchProducts = useCallback(async () => {
    try {
      const res = await axios.get(
        "https://ridercraft-api.onrender.com/products",
      );
      setProducts(res.data);
    } catch {
      setError("Failed to load products");
    }
  }, []);
  const fetchPromos = useCallback(async () => {
    try {
      const headers = { Authorization: `Bearer ${token}` };
      const res = await axios.get(
        "https://ridercraft-api.onrender.com/promos",
        { headers },
      );
      setPromos(res.data);
    } catch {
      setError("Failed to load promo codes");
    }
  }, [token]);
  const fetchOrders = useCallback(async () => {
    try {
      const headers = { Authorization: `Bearer ${token}` };
      const res = await axios.get(
        "https://ridercraft-api.onrender.com/orders",
        { headers },
      );
      setOrders(res.data);
    } catch {
      setError("Failed to load orders");
    }
  }, [token]);
  const fetchServiceRequests = useCallback(async () => {
    try {
      const headers = { Authorization: `Bearer ${token}` };
      const res = await axios.get(
        "https://ridercraft-api.onrender.com/service-requests/admin",
        { headers },
      );
      setServiceRequests(Array.isArray(res.data) ? res.data : []);
    } catch {
      setError("Failed to load service requests");
    }
  }, [token]);
  const fetchHeroOffers = useCallback(async () => {
    try {
      const headers = { Authorization: `Bearer ${token}` };
      const res = await axios.get(
        "https://ridercraft-api.onrender.com/hero-offers/admin",
        { headers },
      );
      setHeroOffers(res.data);
    } catch {
      setError("Failed to load hero offers");
    }
  }, [token]);
  const fetchFeaturedSections = useCallback(async () => {
    try {
      const headers = { Authorization: `Bearer ${token}` };
      const res = await axios.get(
        "https://ridercraft-api.onrender.com/featured-sections/admin",
        { headers },
      );
      setFeaturedSections(res.data);
    } catch {
      setError("Failed to load featured sections");
    }
  }, [token]);
  const customers = useMemo(() => {
    const map = new Map();
    orders.forEach((order) => {
      const name = order.user?.name || "User";
      const email = order.user?.email || "No email";
      const key = email.toLowerCase();
      const previous = map.get(key) || {
        name,
        email,
        avatar: order.user?.avatar || "",
        contactNumber: order.user?.contactNumber || "",
        deliveryAddress: order.user?.deliveryAddress || "",
        ordersCount: 0,
        totalSpent: 0,
        lastOrderAt: "",
        orders: [],
      };
      previous.ordersCount += 1;
      previous.totalSpent += Number(order.total || 0);
      const orderTime = new Date(order.createdAt).getTime();
      const prevTime = previous.lastOrderAt
        ? new Date(previous.lastOrderAt).getTime()
        : 0;
      if (orderTime > prevTime) {
        previous.lastOrderAt = order.createdAt;
      }
      previous.orders.push({
        id: order._id,
        createdAt: order.createdAt,
        total: Number(order.total || 0),
        status: order.status || "placed",
        promoCode: order.promoCode || "-",
        itemsCount: order.items?.reduce((sum, item) => sum + item.qty, 0) || 0,
        previewImages: (order.items || [])
          .map((item) => item.image)
          .filter(Boolean)
          .slice(0, 3),
      });
      map.set(key, previous);
    });
    return Array.from(map.values())
      .map((customer) => ({
        ...customer,
        orders: [...customer.orders].sort(
          (a, b) =>
            new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
        ),
      }))
      .sort((a, b) => b.totalSpent - a.totalSpent);
  }, [orders]);
  const selectedCustomer = useMemo(() => {
    if (!customers.length) return null;
    return (
      customers.find((customer) => customer.email === selectedCustomerEmail) ||
      customers[0]
    );
  }, [customers, selectedCustomerEmail]);
  const filteredOrders = useMemo(() => {
    const query = orderFilters.search.trim().toLowerCase();
    return orders
      .filter((order) => {
        const customerName = String(
          order.user?.name || order.user?.email || "User",
        );
        const orderStatus = String(order.status || "").toLowerCase();
        const total = Number(order.total || 0);
        let matchesPrice = true;
        if (orderFilters.priceRange !== "all") {
          const [min, max] = String(orderFilters.priceRange || "")
            .split("-")
            .map(Number);
          matchesPrice =
            Number.isFinite(min) && Number.isFinite(max)
              ? total >= min && total <= max
              : true;
        }

        const matchesQuery =
          !query ||
          String(order._id || "")
            .toLowerCase()
            .includes(query) ||
          customerName.toLowerCase().includes(query) ||
          String(order.promoCode || "")
            .toLowerCase()
            .includes(query);
        const matchesOrderStatus =
          orderFilters.orderStatus === "all" ||
          orderStatus === orderFilters.orderStatus;
        return matchesQuery && matchesOrderStatus && matchesPrice;
      })
      .sort((a, b) => {
        const at = new Date(a.createdAt).getTime();
        const bt = new Date(b.createdAt).getTime();
        return orderFilters.sortByDate === "newest" ? bt - at : at - bt;
      });
  }, [orders, orderFilters]);
  const selectedOrder = useMemo(() => {
    if (!filteredOrders.length) return null;
    return (
      filteredOrders.find((order) => order._id === selectedOrderId) ||
      filteredOrders[0]
    );
  }, [filteredOrders, selectedOrderId]);
  const pendingReturnOrders = useMemo(
    () =>
      orders.filter(
        (order) =>
          String(order.returnRequest?.status || "none") === "requested",
      ),
    [orders],
  );
  const pendingServiceRequests = useMemo(
    () =>
      serviceRequests.filter(
        (request) => String(request.status || "").toLowerCase() === "requested",
      ),
    [serviceRequests],
  );
  const flashSaleSection = useMemo(
    () => featuredSections.find((row) => row.key === "flash-sale") || null,
    [featuredSections],
  );
  const inventoryInsights = useMemo(() => {
    const normalized = products.map((product) => ({
      ...product,
      stockCount: Number(product.stock ?? 0),
    }));
    const outOfStock = normalized
      .filter((product) => product.stockCount <= 0)
      .sort((a, b) => String(a.name || "").localeCompare(String(b.name || "")));
    const lowStock = normalized
      .filter((product) => product.stockCount > 0 && product.stockCount <= 5)
      .sort((a, b) => a.stockCount - b.stockCount);
    const restockReminders = normalized
      .filter((product) => product.stockCount > 0 && product.stockCount <= 10)
      .sort((a, b) => a.stockCount - b.stockCount);
    return {
      outOfStock,
      lowStock,
      restockReminders,
    };
  }, [products]);
  const productPerformance = useMemo(() => {
    const normalized = products.map((product) => {
      const rating = Number(product.ratingAverage || 0);
      const reviews = Number(product.ratingCount || 0);
      const stock = Number(product.stock ?? 0);
      const score = Number(
        (
          rating * 18 +
          Math.min(reviews, 20) * 2 +
          Math.min(stock, 20) * 0.5
        ).toFixed(1),
      );
      return {
        ...product,
        rating,
        reviews,
        stock,
        score,
      };
    });
    const ratedProducts = normalized.filter((product) => product.reviews > 0);
    const avgRating = ratedProducts.length
      ? Number(
          (
            ratedProducts.reduce((sum, product) => sum + product.rating, 0) /
            ratedProducts.length
          ).toFixed(1),
        )
      : 0;
    const topRated = [...normalized]
      .sort((a, b) => b.rating - a.rating || b.reviews - a.reviews)
      .slice(0, 5);
    const mostReviewed = [...normalized]
      .sort((a, b) => b.reviews - a.reviews || b.rating - a.rating)
      .slice(0, 5);
    const needsAttention = normalized.filter(
      (product) =>
        product.stock <= 0 ||
        (product.reviews >= 3 && product.rating > 0 && product.rating < 3.5),
    );
    const ranked = [...normalized].sort(
      (a, b) => b.score - a.score || b.rating - a.rating,
    );
    return {
      avgRating,
      ratedCount: ratedProducts.length,
      needsAttentionCount: needsAttention.length,
      topRated,
      mostReviewed,
      ranked,
    };
  }, [products]);
  const updateOrderStatus = async (orderId, status) => {
    setError("");
    setMessage("");
    try {
      const headers = { Authorization: `Bearer ${token}` };
      await axios.put(
        `https://ridercraft-api.onrender.com/orders/${orderId}/status`,
        { status },
        { headers },
      );
      setMessage("Order status updated");
      fetchOrders();
    } catch (err) {
      setError(err.response?.data?.error || "Failed to update order status");
    }
  };
  const updateOrderPaymentStatus = async (orderId, paymentStatus) => {
    setError("");
    setMessage("");
    try {
      const headers = { Authorization: `Bearer ${token}` };
      await axios.put(
        `https://ridercraft-api.onrender.com/orders/${orderId}/payment-status`,
        { paymentStatus },
        { headers },
      );
      setMessage("Payment status updated");
      fetchOrders();
    } catch (err) {
      setError(err.response?.data?.error || "Failed to update payment status");
    }
  };
  const handleTrackOrder = async (order) => {
    const steps = ["placed", "processing", "shipped", "delivered"];
    const current = String(order?.status || "").toLowerCase();
    const currentIndex = steps.indexOf(current);
    if (currentIndex < 0 || currentIndex >= steps.length - 1) {
      setMessage("Order is already at final status");
      return;
    }
    await updateOrderStatus(order._id, steps[currentIndex + 1]);
  };
  const handleRefundOrder = async (order) => {
    const payment = String(order?.paymentStatus || "").toLowerCase();
    if (payment === "refunded") {
      setMessage("Order is already refunded");
      return;
    }
    await updateOrderPaymentStatus(order._id, "refunded");
  };
  const reviewReturnRequest = async (orderId, action) => {
    setError("");
    setMessage("");
    try {
      const headers = { Authorization: `Bearer ${token}` };
      await axios.put(
        `https://ridercraft-api.onrender.com/orders/${orderId}/return-review`,
        { action, adminNote: returnReviewNote.trim() },
        { headers },
      );
      setMessage(action === "approve" ? "Return approved" : "Return rejected");
      setReturnReviewNote("");
      fetchOrders();
    } catch (err) {
      setError(err.response?.data?.error || "Failed to review return request");
    }
  };
  const updateReturnTracking = async (orderId, status) => {
    setError("");
    setMessage("");
    try {
      const headers = { Authorization: `Bearer ${token}` };
      await axios.put(
        `https://ridercraft-api.onrender.com/orders/${orderId}/return-tracking`,
        { status },
        { headers },
      );
      setMessage("Return tracking updated");
      fetchOrders();
    } catch (err) {
      setError(err.response?.data?.error || "Failed to update return tracking");
    }
  };
  const filteredServiceRequests = useMemo(() => {
    const query = serviceFilters.search.trim().toLowerCase();
    return serviceRequests
      .filter((request) => {
        const packageType = String(request.packageType || "").toLowerCase();
        const status = String(request.status || "").toLowerCase();
        const customerName = String(request.user?.name || "");
        const customerEmail = String(request.user?.email || "");
        const bikeModel = String(request.bikeModel || "");
        const contactNumber = String(request.contactNumber || "");
        const pickupAddress = String(request.pickupAddress || "");
        const breakdownIssue = String(request.breakdownIssue || "");
        const priority = String(request.priority || "normal").toLowerCase();

        const matchesQuery =
          !query ||
          customerName.toLowerCase().includes(query) ||
          customerEmail.toLowerCase().includes(query) ||
          bikeModel.toLowerCase().includes(query) ||
          contactNumber.toLowerCase().includes(query) ||
          pickupAddress.toLowerCase().includes(query) ||
          breakdownIssue.toLowerCase().includes(query) ||
          String(request._id || "")
            .toLowerCase()
            .includes(query);
        const matchesPackage =
          serviceFilters.packageType === "all" ||
          packageType === serviceFilters.packageType;
        const matchesPriority =
          serviceFilters.priority === "all" ||
          priority === serviceFilters.priority;
        const matchesStatus =
          serviceFilters.status === "all" || status === serviceFilters.status;
        return (
          matchesQuery && matchesPackage && matchesPriority && matchesStatus
        );
      })
      .sort((a, b) => {
        const aEmergency =
          String(a.priority || "normal") === "emergency" ? 1 : 0;
        const bEmergency =
          String(b.priority || "normal") === "emergency" ? 1 : 0;
        if (aEmergency !== bEmergency) return bEmergency - aEmergency;
        const at = new Date(a.createdAt).getTime();
        const bt = new Date(b.createdAt).getTime();
        return serviceFilters.sortByDate === "newest" ? bt - at : at - bt;
      });
  }, [serviceRequests, serviceFilters]);
  const selectedServiceRequest = useMemo(() => {
    if (!filteredServiceRequests.length) return null;
    return (
      filteredServiceRequests.find(
        (request) => request._id === selectedServiceRequestId,
      ) || filteredServiceRequests[0]
    );
  }, [filteredServiceRequests, selectedServiceRequestId]);
  const updateServiceStatus = async (serviceRequestId, status, adminNote) => {
    setError("");
    setMessage("");
    try {
      const headers = { Authorization: `Bearer ${token}` };
      await axios.put(
        `https://ridercraft-api.onrender.com/service-requests/${serviceRequestId}/status`,
        { status, adminNote },
        { headers },
      );
      setMessage("Service request updated");
      fetchServiceRequests();
    } catch (err) {
      setError(err.response?.data?.error || "Failed to update service request");
    }
  };

  useEffect(() => {
    fetchProducts();
    fetchPromos();
    fetchOrders();
    fetchServiceRequests();
    fetchHeroOffers();
    fetchFeaturedSections();
  }, [
    fetchProducts,
    fetchPromos,
    fetchOrders,
    fetchServiceRequests,
    fetchHeroOffers,
    fetchFeaturedSections,
  ]);

  useEffect(() => {
    if (!customers.length) {
      setSelectedCustomerEmail("");
      return;
    }
    const exists = customers.some(
      (customer) => customer.email === selectedCustomerEmail,
    );
    if (!exists) {
      setSelectedCustomerEmail(customers[0].email);
    }
  }, [customers, selectedCustomerEmail]);

  useEffect(() => {
    if (!filteredOrders.length) {
      setSelectedOrderId("");
      return;
    }
    const exists = filteredOrders.some(
      (order) => order._id === selectedOrderId,
    );
    if (!exists) {
      setSelectedOrderId(filteredOrders[0]._id);
    }
  }, [filteredOrders, selectedOrderId]);
  useEffect(() => {
    if (!filteredServiceRequests.length) {
      setSelectedServiceRequestId("");
      return;
    }
    const exists = filteredServiceRequests.some(
      (request) => request._id === selectedServiceRequestId,
    );
    if (!exists) {
      setSelectedServiceRequestId(filteredServiceRequests[0]._id);
    }
  }, [filteredServiceRequests, selectedServiceRequestId]);
  useEffect(() => {
    if (!selectedServiceRequest) {
      setServiceTrackingStatus("requested");
      setServiceAdminNote("");
      return;
    }
    setServiceTrackingStatus(
      String(selectedServiceRequest.status || "requested"),
    );
    setServiceAdminNote(String(selectedServiceRequest.adminNote || ""));
  }, [selectedServiceRequest]);

  useEffect(() => {
    if (!flashSaleSection) {
      setFlashSaleProductIds([]);
      setFlashSaleSchedule({ startsAt: "", endsAt: "" });
      return;
    }
    const selected = Array.isArray(flashSaleSection.products)
      ? flashSaleSection.products.map((item) => String(item?._id || item))
      : [];
    setFlashSaleProductIds(selected);
    setFlashSaleSchedule({
      startsAt: toDateTimeInputValue(flashSaleSection.countdownStartsAt),
      endsAt: toDateTimeInputValue(flashSaleSection.countdownEndsAt),
    });
  }, [flashSaleSection]);

  const toggleFlashSaleProduct = (productId) => {
    const id = String(productId);
    setFlashSaleProductIds((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id],
    );
  };

  const resetForm = () => {
    setForm(initialForm);
    setEditingId(null);
  };
  const resetPromoForm = () => {
    setPromoForm(initialPromoForm);
    setEditingPromoId(null);
  };
  const resetHeroOfferForm = () => {
    setHeroOfferForm(initialHeroOfferForm);
    setEditingHeroOfferId(null);
  };
  const resetFeaturedSectionForm = () => {
    setFeaturedSectionForm(initialFeaturedSectionForm);
    setEditingFeaturedSectionId(null);
  };

  const readFileAsDataUrl = (file) =>
    new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result);
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });

  const handleProductImageChange = async (e) => {
    setError("");
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      setError("Please select an image file");
      return;
    }
    if (file.size > 2 * 1024 * 1024) {
      setError("Image must be 2MB or less");
      return;
    }
    try {
      const dataUrl = await readFileAsDataUrl(file);
      setForm((prev) => ({ ...prev, image: dataUrl }));
    } catch {
      setError("Failed to read image file");
    }
  };

  const handleProductImageUrlChange = (e) => {
    setError("");
    const rawValue = String(e.target.value || "").trim();
    const nextValue =
      rawValue && /^www\./i.test(rawValue) ? `https://${rawValue}` : rawValue;
    setForm((prev) => ({ ...prev, image: nextValue }));
  };

  const updateVariantField = (index, field, value) => {
    setForm((prev) => ({
      ...prev,
      variants: prev.variants.map((variant, variantIndex) =>
        variantIndex === index ? { ...variant, [field]: value } : variant,
      ),
    }));
  };

  const addVariant = () => {
    setForm((prev) => ({
      ...prev,
      variants: [...prev.variants, createBlankVariant()],
    }));
  };

  const removeVariant = (index) => {
    setForm((prev) => ({
      ...prev,
      variants:
        prev.variants.length > 1
          ? prev.variants.filter((_, variantIndex) => variantIndex !== index)
          : prev.variants,
    }));
  };

  const handleVariantImageChange = async (index, event) => {
    setError("");
    const files = Array.from(event.target.files || []);
    if (!files.length) return;

    const invalidFile = files.find((file) => !file.type.startsWith("image/"));
    if (invalidFile) {
      setError("Variant uploads must be image files");
      return;
    }
    const oversizedFile = files.find((file) => file.size > 2 * 1024 * 1024);
    if (oversizedFile) {
      setError("Each variant image must be 2MB or less");
      return;
    }

    try {
      const dataUrls = await Promise.all(files.map(readFileAsDataUrl));
      setForm((prev) => ({
        ...prev,
        variants: prev.variants.map((variant, variantIndex) => {
          if (variantIndex !== index) return variant;
          const images = [...(variant.images || []), ...dataUrls];
          return {
            ...variant,
            images,
            imagesText: images.join("\n"),
          };
        }),
      }));
    } catch {
      setError("Failed to read variant image files");
    } finally {
      event.target.value = "";
    }
  };
  const fetchProductFromUrl = async () => {
    try {
      const headers = {
        Authorization: `Bearer ${token}`,
      };
      console.log("Sending URL:", productUrl);
      const res = await axios.post(
        "https://ridercraft-api.onrender.com/products/fetch-url",
        { url: productUrl },
        { headers },
      );

      console.log("FETCH RESPONSE:", res.data);

      setForm((prev) => ({
        ...prev,
        name: res.data.name || "",
        price: String(res.data.price || ""),
        brand: res.data.brand || "",
        image: res.data.image || "",
        description: res.data.description || "",
        sizes: (res.data.sizes || []).join(", "),
        colors: (res.data.colors || []).join(", "),
      }));
    } catch (err) {
      setError(err.response?.data?.error || "Failed to fetch product");
    }
  };
  const saveProduct = async () => {
    setError("");
    setMessage("");

    if (!form.name.trim() || form.price === "") {
      setError("Name and price are required");
      return;
    }

    try {
      const imageSource = String(form.image || "").trim();
      if (
        imageSource &&
        !/^(https?:)?\/\//i.test(imageSource) &&
        !/^data:image\//i.test(imageSource)
      ) {
        setError(
          "Image must be a valid URL (example: https://...) or uploaded image",
        );
        return;
      }

      const payload = {
        name: form.name.trim(),
        price: Number(form.price),
        tag: form.tag.trim() || "General",
        brand: form.brand.trim() || "Generic",
        colorFamily: form.colorFamily.trim() || "Neutral",
        description: form.description || "",

        sizes: form.sizes
          ? form.sizes
              .split(",")
              .map((s) => s.trim())
              .filter(Boolean)
          : [],

        stock: Number(form.stock || 0),
        image: imageSource,
        isFlashSale: form.isFlashSale,
        flashSalePrice: form.isFlashSale ? Number(form.flashSalePrice || 0) : null,
        flashSaleEndsAt: form.flashSaleEndsAt || null,
        variants: form.variants
          .map((variant) => {
            const images = splitVariantImages(variant);
            return {
              color: String(variant.color || "").trim(),
              colorHex: String(variant.colorHex || "").trim(),
              stock: Number(variant.stock || 0),
              sku: String(variant.sku || "").trim(),
              images,
            };
          })
          .filter((variant) => variant.color),
      };
      payload.colors = payload.variants.map((variant) => variant.color);
      if (payload.variants.length) {
        payload.stock = payload.variants.reduce(
          (sum, variant) => sum + Number(variant.stock || 0),
          0,
        );
        payload.image =
          payload.variants.find((variant) => variant.images.length)?.images[0] ||
          imageSource;
      } else if (form.colors) {
        payload.colors = form.colors
          .split(",")
          .map((color) => color.trim())
          .filter(Boolean);
      }
      const headers = { Authorization: `Bearer ${token}` };

      if (editingId) {
        await axios.put(
          `https://ridercraft-api.onrender.com/products/${editingId}`,
          payload,
          { headers },
        );
        setMessage("Product updated");
      } else {
        await axios.post(
          "https://ridercraft-api.onrender.com/products",
          payload,
          { headers },
        );
        setMessage("Product added");
      }

      resetForm();
      fetchProducts();
    } catch (err) {
      setError(err.response?.data?.error || "Save failed");
    }
  };

  const startEdit = (product) => {
    setEditingId(product._id);
    setForm({
      name: product.name || "",
      price: String(product.price ?? ""),
      tag: product.tag || "",
      brand: product.brand || "",
      colorFamily: product.colorFamily || "",

      sizes: Array.isArray(product.sizes) ? product.sizes.join(",") : "",

      colors: Array.isArray(product.colors) ? product.colors.join(",") : "",

      stock: String(product.stock ?? "25"),
      image: product.image || "",
      isFlashSale: product.isFlashSale || false,
      flashSalePrice: String(product.flashSalePrice ?? ""),
      flashSaleEndsAt: toDateTimeInputValue(product.flashSaleEndsAt),
      variants: Array.isArray(product.variants) && product.variants.length
        ? product.variants.map(normalizeVariantForForm)
        : [
            normalizeVariantForForm({
              color: product.colors?.[0] || product.colorFamily || "",
              colorHex: "#111827",
              stock: product.stock ?? 0,
              sku: "",
              images: product.image ? [product.image] : [],
            }),
          ],
    });
  };

  const removeProduct = async (id) => {
    setError("");
    setMessage("");
    try {
      await axios.delete(`https://ridercraft-api.onrender.com/products/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setMessage("Product deleted");
      if (editingId === id) resetForm();
      fetchProducts();
    } catch (err) {
      setError(err.response?.data?.error || "Delete failed");
    }
  };
  const createPromo = async () => {
    setError("");
    setMessage("");
    if (!promoForm.code.trim() || !promoForm.startsAt || !promoForm.endsAt) {
      setError("Promo code, start time and end time are required");
      return;
    }
    try {
      const headers = { Authorization: `Bearer ${token}` };
      const payload = {
        code: promoForm.code.trim(),
        discountType: promoForm.discountType,
        discountValue: Number(promoForm.discountValue),
        maxUses: Number(promoForm.maxUses),
        startsAt: new Date(promoForm.startsAt).toISOString(),
        endsAt: new Date(promoForm.endsAt).toISOString(),
        isActive: Boolean(promoForm.isActive),
      };
      if (editingPromoId) {
        await axios.put(
          `https://ridercraft-api.onrender.com/promos/${editingPromoId}`,
          payload,
          { headers },
        );
        setMessage("Promo code updated");
      } else {
        await axios.post(
          "https://ridercraft-api.onrender.com/promos",
          payload,
          { headers },
        );
        setMessage("Promo code created");
      }
      resetPromoForm();
      fetchPromos();
    } catch (err) {
      setError(err.response?.data?.error || "Failed to save promo code");
    }
  };
  const startEditPromo = (promo) => {
    setEditingPromoId(promo._id);
    setPromoForm({
      code: promo.code || "",
      discountType: promo.discountType || "percent",
      discountValue: String(promo.discountValue ?? "0"),
      maxUses: String(promo.maxUses ?? "1"),
      startsAt: toDateTimeInputValue(promo.startsAt),
      endsAt: toDateTimeInputValue(promo.endsAt),
      isActive: Boolean(promo.isActive),
    });
  };
  const createHeroOffer = async () => {
    setError("");
    setMessage("");
    if (!heroOfferForm.title.trim()) {
      setError("Offer title is required");
      return;
    }
    try {
      const headers = { Authorization: `Bearer ${token}` };
      const payload = {
        title: heroOfferForm.title.trim(),
        offerType: heroOfferForm.offerType,
        startsAt: heroOfferForm.startsAt
          ? new Date(heroOfferForm.startsAt).toISOString()
          : undefined,
        endsAt: heroOfferForm.endsAt
          ? new Date(heroOfferForm.endsAt).toISOString()
          : null,
        priority: Number(heroOfferForm.priority || 1),
        ctaQuery: heroOfferForm.ctaQuery.trim(),
        isActive: Boolean(heroOfferForm.isActive),
      };
      if (editingHeroOfferId) {
        await axios.put(
          `https://ridercraft-api.onrender.com/hero-offers/admin/${editingHeroOfferId}`,
          payload,
          { headers },
        );
        setMessage("Hero offer updated");
      } else {
        await axios.post(
          "https://ridercraft-api.onrender.com/hero-offers/admin",
          payload,
          { headers },
        );
        setMessage("Hero offer created");
      }
      resetHeroOfferForm();
      fetchHeroOffers();
    } catch (err) {
      setError(err.response?.data?.error || "Failed to save hero offer");
    }
  };
  const startEditHeroOffer = (offer) => {
    setEditingHeroOfferId(offer._id);
    setHeroOfferForm({
      title: offer.title || "",
      offerType: offer.offerType || "tag",
      startsAt: toDateTimeInputValue(offer.startsAt),
      endsAt: toDateTimeInputValue(offer.endsAt),
      priority: String(offer.priority ?? "1"),
      ctaQuery: offer.ctaQuery || "",
      isActive: Boolean(offer.isActive),
    });
  };
  const removeHeroOffer = async (id) => {
    setError("");
    setMessage("");
    try {
      const headers = { Authorization: `Bearer ${token}` };
      await axios.delete(
        `https://ridercraft-api.onrender.com/hero-offers/admin/${id}`,
        { headers },
      );
      setMessage("Hero offer deleted");
      if (editingHeroOfferId === id) resetHeroOfferForm();
      fetchHeroOffers();
    } catch (err) {
      setError(err.response?.data?.error || "Failed to delete hero offer");
    }
  };
  const createFeaturedSection = async () => {
    setError("");
    setMessage("");
    if (!featuredSectionForm.title.trim()) {
      setError("Section title is required");
      return;
    }
    if (!featuredSectionForm.productIds.length) {
      setError("Select at least one product");
      return;
    }
    if (
      featuredSectionForm.countdownStartsAt &&
      featuredSectionForm.countdownEndsAt &&
      new Date(featuredSectionForm.countdownStartsAt).getTime() >
        new Date(featuredSectionForm.countdownEndsAt).getTime()
    ) {
      setError("Countdown end must be after start");
      return;
    }
    try {
      const headers = { Authorization: `Bearer ${token}` };
      const payload = {
        key: featuredSectionForm.key,
        title: featuredSectionForm.title.trim(),
        products: featuredSectionForm.productIds,
        sortOrder: Number(featuredSectionForm.sortOrder || 0),
        countdownStartsAt: featuredSectionForm.countdownStartsAt || null,
        countdownEndsAt: featuredSectionForm.countdownEndsAt || null,
        isActive: Boolean(featuredSectionForm.isActive),
      };
      if (editingFeaturedSectionId) {
        await axios.put(
          `https://ridercraft-api.onrender.com/featured-sections/admin/${editingFeaturedSectionId}`,
          payload,
          { headers },
        );
        setMessage("Featured section updated");
      } else {
        await axios.post(
          "https://ridercraft-api.onrender.com/featured-sections/admin",
          payload,
          { headers },
        );
        setMessage("Featured section created");
      }
      resetFeaturedSectionForm();
      fetchFeaturedSections();
    } catch (err) {
      setError(err.response?.data?.error || "Failed to save featured section");
    }
  };
  const startEditFeaturedSection = (sectionRow) => {
    setEditingFeaturedSectionId(sectionRow._id);
    setFeaturedSectionForm({
      key: sectionRow.key || "trending",
      title: sectionRow.title || "",
      productIds: Array.isArray(sectionRow.products)
        ? sectionRow.products.map((item) => item._id || item)
        : [],
      sortOrder: String(sectionRow.sortOrder ?? "0"),
      countdownStartsAt: toDateTimeInputValue(sectionRow.countdownStartsAt),
      countdownEndsAt: toDateTimeInputValue(sectionRow.countdownEndsAt),
      isActive: Boolean(sectionRow.isActive),
    });
  };
  const removeFeaturedSection = async (id) => {
    setError("");
    setMessage("");
    try {
      const headers = { Authorization: `Bearer ${token}` };
      await axios.delete(
        `https://ridercraft-api.onrender.com/featured-sections/admin/${id}`,
        { headers },
      );
      setMessage("Featured section deleted");
      if (editingFeaturedSectionId === id) resetFeaturedSectionForm();
      fetchFeaturedSections();
    } catch (err) {
      setError(
        err.response?.data?.error || "Failed to delete featured section",
      );
    }
  };
  const saveFlashSaleProducts = async () => {
    setError("");
    setMessage("");
    if (flashSaleProductIds.length === 0) {
      setError("Select at least one product for flash sale");
      return;
    }
    if (!flashSaleSchedule.startsAt || !flashSaleSchedule.endsAt) {
      setError("Select both the Flash Sale start and end date/time");
      return;
    }
    if (
      new Date(flashSaleSchedule.startsAt).getTime() >=
      new Date(flashSaleSchedule.endsAt).getTime()
    ) {
      setError("Flash Sale end date/time must be after its start");
      return;
    }
    try {
      const headers = { Authorization: `Bearer ${token}` };
      const payload = {
        key: "flash-sale",
        title: flashSaleSection?.title || "⚡ Flash Sale",
        products: flashSaleProductIds,
        sortOrder: Number(flashSaleSection?.sortOrder ?? 1),
        countdownStartsAt: flashSaleSchedule.startsAt,
        countdownEndsAt: flashSaleSchedule.endsAt,
        isActive: true,
      };
      if (flashSaleSection?._id) {
        await axios.put(
          `https://ridercraft-api.onrender.com/featured-sections/admin/${flashSaleSection._id}`,
          payload,
          { headers },
        );
      } else {
        await axios.post(
          "https://ridercraft-api.onrender.com/featured-sections/admin",
          payload,
          { headers },
        );
      }
      setMessage("Flash sale products updated");
      fetchFeaturedSections();
    } catch (err) {
      setError(
        err.response?.data?.error || "Failed to update flash sale products",
      );
    }
  };
  const toggleProductFlashSale = async (productId) => {
    setError("");
    setMessage("");
    const id = String(productId);
    const isSelected = flashSaleProductIds.includes(id);
    const nextProductIds = isSelected
      ? flashSaleProductIds.filter((item) => item !== id)
      : [...flashSaleProductIds, id];

    try {
      const headers = { Authorization: `Bearer ${token}` };
      const payload = {
        key: "flash-sale",
        title: flashSaleSection?.title || "⚡ Flash Sale",
        products: nextProductIds,
        sortOrder: Number(flashSaleSection?.sortOrder ?? 1),
        countdownStartsAt: flashSaleSchedule.startsAt || null,
        countdownEndsAt: flashSaleSchedule.endsAt || null,
        isActive: true,
      };
      if (flashSaleSection?._id) {
        await axios.put(
          `https://ridercraft-api.onrender.com/featured-sections/admin/${flashSaleSection._id}`,
          payload,
          { headers },
        );
      } else {
        await axios.post(
          "https://ridercraft-api.onrender.com/featured-sections/admin",
          payload,
          { headers },
        );
      }
      setMessage(
        isSelected ? "Removed from flash sale" : "Added to flash sale",
      );
      fetchFeaturedSections();
    } catch (err) {
      setError(err.response?.data?.error || "Failed to update flash sale");
    }
  };

  return (
    <div className="admin-wrapper">
      <aside className="admin-sidebar">
        <h2>Admin Panel</h2>
        <ul>
          <li>
            <button
              className={
                section === "products"
                  ? "admin-side-btn active"
                  : "admin-side-btn"
              }
              onClick={() => setSection("products")}
            >
              1. Product Manager
            </button>
          </li>
          <li>
            <button
              className={
                section === "orders"
                  ? "admin-side-btn active"
                  : "admin-side-btn"
              }
              onClick={() => setSection("orders")}
            >
              2. Orders
              {pendingReturnOrders.length > 0 && (
                <span className="admin-side-count">
                  {pendingReturnOrders.length}
                </span>
              )}
            </button>
          </li>
          <li>
            <button
              className={
                section === "promos"
                  ? "admin-side-btn active"
                  : "admin-side-btn"
              }
              onClick={() => setSection("promos")}
            >
              3. Payment Promo Code
            </button>
          </li>
          <li>
            <button
              className={
                section === "customers"
                  ? "admin-side-btn active"
                  : "admin-side-btn"
              }
              onClick={() => setSection("customers")}
            >
              4. Customers
            </button>
          </li>
          <li>
            <button
              className={
                section === "services"
                  ? "admin-side-btn active"
                  : "admin-side-btn"
              }
              onClick={() => setSection("services")}
            >
              5. Service Requests
              {pendingServiceRequests.length > 0 && (
                <span className="admin-side-count">
                  {pendingServiceRequests.length}
                </span>
              )}
            </button>
          </li>
          <li>
            <button
              className={
                section === "featured"
                  ? "admin-side-btn active"
                  : "admin-side-btn"
              }
              onClick={() => setSection("featured")}
            >
              6. Featured Sections
            </button>
          </li>
          <li>
            <button
              className={
                section === "inventory"
                  ? "admin-side-btn active"
                  : "admin-side-btn"
              }
              onClick={() => setSection("inventory")}
            >
              7. Inventory Alerts
            </button>
          </li>
          <li>
            <button
              className={
                section === "performance"
                  ? "admin-side-btn active"
                  : "admin-side-btn"
              }
              onClick={() => setSection("performance")}
            >
              8. Product Performance
            </button>
          </li>
        </ul>
      </aside>

      <main className="admin-main">
        <header className="admin-header">
          <div>
            <h1>{sectionMeta[section]?.title || "Admin Dashboard"}</h1>
            <p>
              {sectionMeta[section]?.subtitle ||
                "Manage your store operations."}
            </p>
          </div>
          <button onClick={logout} className="admin-logout-btn">
            Logout
          </button>
        </header>
        {message && <p className="admin-success">{message}</p>}
        {error && <p className="admin-error">{error}</p>}
        <AdminSectionContent
          vm={{
            section,
            editingId,
            form,
            setForm,
            handleProductImageChange,
            handleProductImageUrlChange,
            updateVariantField,
            addVariant,
            removeVariant,
            handleVariantImageChange,
            saveProduct,
            resetForm,
            editingPromoId,
            promoForm,
            setPromoForm,
            createPromo,
            resetPromoForm,
            promos,
            startEditPromo,
            editingHeroOfferId,
            heroOfferForm,
            setHeroOfferForm,
            createHeroOffer,
            resetHeroOfferForm,
            heroOffers,
            startEditHeroOffer,
            removeHeroOffer,
            products,
            flashSaleProductIds,
            flashSaleSchedule,
            setFlashSaleSchedule,
            startEdit,
            toggleProductFlashSale,
            removeProduct,
            pendingReturnOrders,
            setSection,
            setSelectedOrderId,
            orderFilters,
            setOrderFilters,
            filteredOrders,
            selectedOrder,
            updateOrderStatus,
            returnReviewNote,
            setReturnReviewNote,
            reviewReturnRequest,
            returnTrackingStatus,
            setReturnTrackingStatus,
            updateReturnTracking,
            handleTrackOrder,
            handleRefundOrder,
            customers,
            selectedCustomer,
            setSelectedCustomerEmail,
            serviceFilters,
            setServiceFilters,
            filteredServiceRequests,
            selectedServiceRequest,
            setSelectedServiceRequestId,
            serviceTrackingStatus,
            setServiceTrackingStatus,
            serviceAdminNote,
            setServiceAdminNote,
            updateServiceStatus,
            inventoryInsights,
            productPerformance,
            saveFlashSaleProducts,
            toggleFlashSaleProduct,
            editingFeaturedSectionId,
            featuredSectionForm,
            setFeaturedSectionForm,
            createFeaturedSection,
            resetFeaturedSectionForm,
            featuredSections,
            startEditFeaturedSection,
            removeFeaturedSection,
            productUrl,
            setProductUrl,
            fetchProductFromUrl,
          }}
        />
      </main>
    </div>
  );
}
