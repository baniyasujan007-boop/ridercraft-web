import { useEffect, useRef } from "react";
import axios from "axios";

export default function GoogleAuthButton({ onSuccess, onError, label = "signin_with" }) {
  const googleBtnRef = useRef(null);
  const clientId = process.env.REACT_APP_GOOGLE_CLIENT_ID;

  useEffect(() => {
    if (!clientId) return;

    const handleGoogleResponse = async (response) => {
      try {
        const res = await axios.post("https://ridercraft-api.onrender.com/auth/google", {
          credential: response.credential
        });
        onSuccess(res.data);
      } catch (err) {
        onError(err.response?.data?.error || "Google login failed");
      }
    };

    const renderGoogleButton = () => {
      if (!window.google?.accounts?.id || !googleBtnRef.current) return;
      window.google.accounts.id.initialize({
        client_id: clientId,
        callback: handleGoogleResponse
      });
      googleBtnRef.current.innerHTML = "";
      window.google.accounts.id.renderButton(googleBtnRef.current, {
        theme: "outline",
        size: "large",
        width: 300,
        text: label
      });
    };

    if (window.google?.accounts?.id) {
      renderGoogleButton();
      return;
    }

    const script = document.createElement("script");
    script.src = "https://accounts.google.com/gsi/client";
    script.async = true;
    script.defer = true;
    script.onload = renderGoogleButton;
    document.body.appendChild(script);

    return () => {
      script.remove();
    };
  }, [clientId, label, onError, onSuccess]);

  if (!clientId) {
    return (
      <p className="google-missing">
        Google sign-in is not configured. Add `REACT_APP_GOOGLE_CLIENT_ID` in `client/.env`.
      </p>
    );
  }

  return (
    <div className="google-signin-wrap">
      <div ref={googleBtnRef} />
    </div>
  );
}
