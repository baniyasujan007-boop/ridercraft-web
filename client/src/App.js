import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import AdminRoute from "./routes/AdminRoute";
import GarageRoute from "./routes/GarageRoute";
import ProtectedRoute from "./routes/ProtectedRoute";
import Admin from "./features/admin/pages/Admin";
import AdminOrdersDashboard from "./features/admin/pages/AdminOrdersDashboard";
import GarageDashboard from "./features/admin/pages/GarageDashboard";
import About from "./features/about/pages/About";
import ForgotPassword from "./features/auth/pages/ForgotPassword";
import Landing from "./features/shop/pages/Landing";
import Login from "./features/auth/pages/Login";
import ProductDetails from "./features/product-details/pages/ProductDetails";
import Register from "./features/auth/pages/Register";
import SiteFooter from "./components/layout/SiteFooter";
import SiteHeader from "./components/layout/SiteHeader";
import InquiryChatbot from "./components/layout/InquiryChatbot";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import "./styles/layout/site-chrome.css";
import "./styles/layout/inquiry-chatbot.css";

function AppShell() {
  return (
    <>
      <SiteHeader />
      <Routes>
        <Route path="/" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/forgot-password" element={<ForgotPassword />} />
        <Route path="/about" element={<About />} />
        <Route
          path="/landing"
          element={
            <ProtectedRoute>
              <Landing />
            </ProtectedRoute>
          }
        />
        <Route
          path="/products/:id"
          element={
            <ProtectedRoute>
              <ProductDetails />
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin"
          element={
            <AdminRoute>
              <Admin />
            </AdminRoute>
          }
        />
        <Route
          path="/admin/orders-dashboard"
          element={
            <AdminRoute>
              <AdminOrdersDashboard />
            </AdminRoute>
          }
        />
        <Route
          path="/garage"
          element={
            <GarageRoute>
              <GarageDashboard />
            </GarageRoute>
          }
        />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
      <SiteFooter />
      <InquiryChatbot />
      <ToastContainer position="top-right" autoClose={2000} />
    </>
  );
}

function App() {
  return (
    <BrowserRouter>
      <AppShell />
    </BrowserRouter>
  );
}

export default App;
