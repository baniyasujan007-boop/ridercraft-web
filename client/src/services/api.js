import axios from "axios";

const BASE_URL = "https://ridercraft-api.onrender.com";

// Centralized session handling.
//
// The rest of the app calls axios both through this instance and through the
// default `axios` export. Registering the same handling on both keeps a single
// source of truth without refactoring every call site.

const isAuthRequest = (url) =>
  String(url || "").includes("/auth/");

function attachBearerToken(config) {
  const token = localStorage.getItem("token");
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
}

let redirectingToLogin = false;

function handleUnauthorizedResponse(error) {
  const status = error.response?.status;
  const url = String(error.config?.url || "");

  // The login flow itself can return 401/400; never redirect or clear the
  // session for authentication requests, otherwise login would loop.
  if (status === 401 && !isAuthRequest(url)) {
    localStorage.removeItem("token");

    if (window.location.pathname !== "/") {
      if (!redirectingToLogin) {
        redirectingToLogin = true;
        window.location.replace("/");
      }
    } else {
      // Back on the login page; allow future redirects again.
      redirectingToLogin = false;
    }
  }

  return Promise.reject(error);
}

// Interceptors for the shared `api` instance (e.g. Register).
const api = axios.create({
  baseURL: BASE_URL,
});

// Interceptors for the default axios used across the app.
axios.interceptors.request.use(attachBearerToken);
axios.interceptors.response.use(
  (response) => response,
  handleUnauthorizedResponse
);

// Interceptors for the exported `api` instance.
api.interceptors.request.use(attachBearerToken);
api.interceptors.response.use(
  (response) => response,
  handleUnauthorizedResponse
);

export default api;