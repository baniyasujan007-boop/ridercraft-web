import { useMemo, useState } from "react";
import { useLocation } from "react-router-dom";

const QUICK_INQUIRIES = [
  "Where is my order?",
  "How can I book bike service?",
  "Payment help",
  "Return or refund policy"
];

const buildBotReply = (text) => {
  const normalized = String(text || "").toLowerCase();

  if (normalized.includes("order") || normalized.includes("track")) {
    return "Go to My Orders in your dashboard to track status and shipment updates.";
  }
  if (normalized.includes("service") || normalized.includes("bike")) {
    return "Open the Servicing section, choose package, pickup location, and preferred slot, then submit.";
  }
  if (normalized.includes("payment") || normalized.includes("card") || normalized.includes("wallet")) {
    return "Use Card or E-Wallet and click the dummy payment buttons for test checkout.";
  }
  if (normalized.includes("return") || normalized.includes("refund")) {
    return "After delivery, request return from My Orders with proof. Admin reviews and updates refund.";
  }
  if (normalized.includes("promo") || normalized.includes("coupon")) {
    return "Apply your promo code in cart before checkout to get discount eligibility.";
  }
  if (normalized.includes("location") || normalized.includes("map")) {
    return "For servicing, click Use My Current Location. GPS and map link are saved with your request.";
  }
  return "I can help with orders, servicing, payments, returns, promos, and account support.";
};

export default function InquiryChatbot() {
  const location = useLocation();
  const [isOpen, setIsOpen] = useState(false);
  const [input, setInput] = useState("");
  const [messages, setMessages] = useState([
    {
      role: "bot",
      text: "Hi, I am your inquiry assistant. Ask about orders, service, payment, return, or promo."
    }
  ]);

  const isHiddenRoute = useMemo(() => {
    const path = location.pathname || "";
    if (path === "/" || path === "/register" || path === "/forgot-password") return true;
    if (path.startsWith("/admin")) return true;
    return false;
  }, [location.pathname]);

  if (isHiddenRoute) return null;

  const sendMessage = (value) => {
    const text = String(value || "").trim();
    if (!text) return;

    setMessages((prev) => [
      ...prev,
      { role: "user", text },
      { role: "bot", text: buildBotReply(text) }
    ]);
    setInput("");
  };

  return (
    <div className="inquiry-chatbot">
      {!isOpen && (
        <button
          type="button"
          className="inquiry-chatbot-launcher"
          onClick={() => setIsOpen(true)}
        >
          Inquiry Chat
        </button>
      )}

      {isOpen && (
        <section className="inquiry-chatbot-panel">
          <header className="inquiry-chatbot-head">
            <strong>Customer Inquiry</strong>
            <button type="button" onClick={() => setIsOpen(false)}>
              Close
            </button>
          </header>

          <div className="inquiry-chatbot-quick">
            {QUICK_INQUIRIES.map((item) => (
              <button key={item} type="button" onClick={() => sendMessage(item)}>
                {item}
              </button>
            ))}
          </div>

          <div className="inquiry-chatbot-messages">
            {messages.map((message, index) => (
              <p
                key={`${message.role}-${index}`}
                className={`inquiry-chatbot-bubble ${message.role === "user" ? "user" : "bot"}`}
              >
                {message.text}
              </p>
            ))}
          </div>

          <div className="inquiry-chatbot-input">
            <input
              placeholder="Type your inquiry"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") sendMessage(input);
              }}
            />
            <button type="button" onClick={() => sendMessage(input)}>
              Send
            </button>
          </div>
        </section>
      )}
    </div>
  );
}
