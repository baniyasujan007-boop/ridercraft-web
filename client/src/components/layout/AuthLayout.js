import "../../styles/pages/auth.css";

export default function AuthLayout({ children, type }) {
  return (
    <div className={`auth-container ${type}`}>
      <div className="auth-left">
        {type === "login" ? (
          <>
            <h1>Welcome Back!</h1>
            <p>Don't have an account?</p>
            <a href="/register" className="white-btn">Sign Up</a>
          </>
        ) : (
          <>
            <h1>Start New Journey!</h1>
            <p>Already have an account?</p>
            <a href="/" className="white-btn">Sign In</a>
          </>
        )}
      </div>

      <div className="auth-right">
        {children}
      </div>
    </div>
  );
}