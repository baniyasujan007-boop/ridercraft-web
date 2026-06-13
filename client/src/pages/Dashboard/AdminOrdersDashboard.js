import { useCallback, useEffect, useMemo, useState } from "react";
import axios from "axios";
import OrdersSidebar from "../../components/admin-orders/OrdersSidebar";
import OrdersHeader from "../../components/admin-orders/OrdersHeader";
import OrdersTable from "../../components/admin-orders/OrdersTable";
import OrderDetailsDrawer from "../../components/admin-orders/OrderDetailsDrawer";
import "../../styles/pages/admin-orders-dashboard.css";

function matchPriceRange(total, range) {
  if (range === "all") return true;
  const [min, max] = range.split("-").map(Number);
  return total >= min && total <= max;
}

function normalizeOrder(order, index) {
  const paymentStatus = String(order.paymentStatus || "pending").toLowerCase();
  const orderStatus = String(order.status || "placed").toLowerCase();
  let status = "pending";
  if (paymentStatus === "refunded") {
    status = "refunded";
  } else if (orderStatus === "delivered" && paymentStatus === "paid") {
    status = "completed";
  } else if (orderStatus === "delivered") {
    status = "delivered";
  } else if (paymentStatus === "paid") {
    status = "paid";
  }

  return {
    id: order._id,
    labelId: `#${String(order._id || "").slice(-6).toUpperCase()}`,
    customer: {
      name: order.user?.name || "User",
      avatar: order.user?.avatar || "",
      email: order.user?.email || "",
      phone: order.user?.contactNumber || ""
    },
    status,
    orderStatus,
    paymentStatus,
    returnRequest: order.returnRequest || { status: "none", timeline: [] },
    total: Number(order.total || 0),
    date: order.createdAt,
    promoCode: order.promoCode || "-",
    items: (order.items || []).map((item, itemIndex) => ({
      id: `${item.productId || itemIndex}`,
      name: item.name || "Item",
      price: Number(item.price || 0),
      image: item.image || "",
      qty: Number(item.qty || 1)
    })),
    _index: index
  };
}

export default function AdminOrdersDashboard() {
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false);
  const [orders, setOrders] = useState([]);
  const [selectedOrderId, setSelectedOrderId] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [actionLoading, setActionLoading] = useState(false);
  const [returnAdminNote, setReturnAdminNote] = useState("");
  const [returnTrackingStatus, setReturnTrackingStatus] = useState("in_transit");
  const [filters, setFilters] = useState({
    status: "all",
    priceRange: "all",
    dateSort: "newest",
    query: ""
  });

  const token = localStorage.getItem("token");

  const loadOrders = useCallback(async () => {
    setError("");
    try {
      if (!token) return;
      setLoading(true);
      const res = await axios.get("http://localhost:5001/orders", {
        headers: { Authorization: `Bearer ${token}` }
      });
      const next = Array.isArray(res.data)
        ? res.data.map((order, index) => normalizeOrder(order, index))
        : [];
      setOrders(next);
    } catch (err) {
      setError(err.response?.data?.error || "Failed to load orders");
      setOrders([]);
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    loadOrders();
  }, [loadOrders]);

  const filteredOrders = useMemo(() => {
    const query = filters.query.trim().toLowerCase();

    const next = orders.filter((order) => {
      const statusOk = filters.status === "all" || order.status === filters.status;
      const priceOk = matchPriceRange(order.total, filters.priceRange);
      const queryOk =
        !query ||
        order.labelId.toLowerCase().includes(query) ||
        order.customer.name.toLowerCase().includes(query) ||
        String(order.promoCode || "")
          .toLowerCase()
          .includes(query);

      return statusOk && priceOk && queryOk;
    });

    next.sort((a, b) => {
      const aTime = new Date(a.date).getTime();
      const bTime = new Date(b.date).getTime();
      return filters.dateSort === "newest" ? bTime - aTime : aTime - bTime;
    });

    return next;
  }, [filters, orders]);

  const selectedOrder = useMemo(() => {
    if (!filteredOrders.length) return null;
    return filteredOrders.find((order) => order.id === selectedOrderId) || filteredOrders[0];
  }, [filteredOrders, selectedOrderId]);

  useEffect(() => {
    if (!filteredOrders.length) {
      setSelectedOrderId("");
      return;
    }
    if (!selectedOrderId || !filteredOrders.some((order) => order.id === selectedOrderId)) {
      setSelectedOrderId(filteredOrders[0].id);
    }
  }, [filteredOrders, selectedOrderId]);

  const updateOrderStatus = async (orderId, status) => {
    if (!token) return;
    try {
      setActionLoading(true);
      await axios.put(
        `http://localhost:5001/orders/${orderId}/status`,
        { status },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      await loadOrders();
    } catch (err) {
      setError(err.response?.data?.error || "Failed to update order status");
    } finally {
      setActionLoading(false);
    }
  };

  const updatePaymentStatus = async (orderId, paymentStatus) => {
    if (!token) return;
    try {
      setActionLoading(true);
      await axios.put(
        `http://localhost:5001/orders/${orderId}/payment-status`,
        { paymentStatus },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      await loadOrders();
    } catch (err) {
      setError(err.response?.data?.error || "Failed to update payment status");
    } finally {
      setActionLoading(false);
    }
  };

  const handleTrack = async (order) => {
    const steps = ["placed", "processing", "shipped", "delivered"];
    const currentIndex = steps.indexOf(order.orderStatus);
    if (currentIndex < 0 || currentIndex >= steps.length - 1) return;
    await updateOrderStatus(order.id, steps[currentIndex + 1]);
  };

  const handleRefund = async (order) => {
    if (order.paymentStatus === "refunded") return;
    await updatePaymentStatus(order.id, "refunded");
  };
  const reviewReturn = async (orderId, action) => {
    if (!token) return;
    try {
      setActionLoading(true);
      await axios.put(
        `http://localhost:5001/orders/${orderId}/return-review`,
        { action, adminNote: returnAdminNote.trim() },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setReturnAdminNote("");
      await loadOrders();
    } catch (err) {
      setError(err.response?.data?.error || "Failed to review return request");
    } finally {
      setActionLoading(false);
    }
  };
  const handleReturnTracking = async (orderId, status) => {
    if (!token) return;
    try {
      setActionLoading(true);
      await axios.put(
        `http://localhost:5001/orders/${orderId}/return-tracking`,
        { status },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      await loadOrders();
    } catch (err) {
      setError(err.response?.data?.error || "Failed to update return tracking");
    } finally {
      setActionLoading(false);
    }
  };

  const logout = () => {
    localStorage.removeItem("token");
    window.location.href = "/";
  };

  return (
    <div className="orders-layout">
      <OrdersSidebar
        mobileOpen={mobileSidebarOpen}
        onLogout={logout}
      />

      {mobileSidebarOpen && (
        <button
          className="orders-sidebar-overlay"
          type="button"
          onClick={() => setMobileSidebarOpen(false)}
          aria-label="Close sidebar"
        />
      )}

      <main className="orders-main-area">
        <OrdersHeader
          filters={filters}
          setFilters={setFilters}
          onToggleSidebar={() => setMobileSidebarOpen((prev) => !prev)}
        />
        {loading && <p className="drawer-placeholder">Loading orders...</p>}
        {error && <p className="drawer-placeholder">{error}</p>}

        <div className="orders-content-grid">
          <OrdersTable
            orders={filteredOrders}
            selectedId={selectedOrder?.id || ""}
            onSelect={(order) => setSelectedOrderId(order.id)}
          />
          <OrderDetailsDrawer
            selectedOrder={selectedOrder}
            onClose={() => setSelectedOrderId("")}
            onTrack={handleTrack}
            onRefund={handleRefund}
            onReturnReview={reviewReturn}
            onReturnTracking={handleReturnTracking}
            returnAdminNote={returnAdminNote}
            setReturnAdminNote={setReturnAdminNote}
            returnTrackingStatus={returnTrackingStatus}
            setReturnTrackingStatus={setReturnTrackingStatus}
            actionLoading={actionLoading}
          />
        </div>
      </main>
    </div>
  );
}
