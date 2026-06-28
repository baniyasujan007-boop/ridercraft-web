import axios from "axios";
import { useNavigate } from "react-router-dom";
import { PremiumLoginExperience } from "./PremiumLoginPrototype";

function getDashboardPath(role) {
  const normalizedRole = String(role || "").toLowerCase();

  if (normalizedRole === "admin") {
    return "/admin";
  }

  if (normalizedRole === "garage") {
    return "/garage";
  }

  return "/landing";
}

export default function Login() {
  const navigate = useNavigate();

  const completeLogin = (data) => {
    localStorage.setItem("token", data.token);
    navigate(getDashboardPath(data?.role));
  };

  const handleEmailLogin = async (form) => {
    const res = await axios.post(
      "https://ridercraft-api.onrender.com/auth/login",
      form
    );

    completeLogin(res.data);
  };

  return (
    <PremiumLoginExperience
      enableGoogleAuth
      onEmailLogin={handleEmailLogin}
      onGoogleSuccess={completeLogin}
    />
  );
}
