import { useState } from "react";

export default function AuthInput({
  type = "text",
  placeholder,
  value,
  onChange,
  isPassword = false,
}) {
  const [show, setShow] = useState(false);

  return (
    <div className="input-wrapper">
      <input
        type={isPassword ? (show ? "text" : "password") : type}
        placeholder={placeholder}
        value={value}
        onChange={onChange}
      />

      {isPassword && (
        <span
          className="eye-icon"
          onClick={() => setShow(!show)}
        >
          {show ? "🙈" : "👁"}
        </span>
      )}
    </div>
  );
}