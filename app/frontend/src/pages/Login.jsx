import { useState } from "react";
import { useNavigate, useLocation, Link } from "react-router-dom";
import {
    login,
    isShelterOwner,
    initiateGoogleLogin,
    handleGoogleLogin,
} from "../api/auth";
import { Eye, EyeOff } from "lucide-react";
import "./Auth.css";

export default function Login() {
    const [formData, setFormData] = useState({
        loginIdentifier: "",
        password: "",
    });
    const [loading, setLoading] = useState(false);
    const [errors, setErrors] = useState({});
    const [showPassword, setShowPassword] = useState(false);

    const navigate = useNavigate();
    const location = useLocation();

    const urlParams = new URLSearchParams(location.search);
    const shouldRedirectToShelterPanelInitially =
        urlParams.get("redirect") === "shelter-panel";

    const from = location.state?.from?.pathname || "/home";

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData((prev) => ({
            ...prev,
            [name]: value,
        }));

        if (errors[name]) {
            setErrors((prev) => ({
                ...prev,
                [name]: null,
            }));
        }

        if (errors.general) {
            setErrors((prev) => ({
                ...prev,
                general: null,
            }));
        }
    };

    const validateForm = () => {
        const newErrors = {};

        if (!formData.loginIdentifier.trim()) {
            newErrors.loginIdentifier = "Email lub telefon jest wymagany";
        } else {
            const identifier = formData.loginIdentifier.trim();
            if (identifier.includes("@")) {
                const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                if (!emailRegex.test(identifier)) {
                    newErrors.loginIdentifier =
                        "Nieprawidłowy format adresu email";
                }
            } else {
                const phoneRegex = /^(\+\d{1,3}[- ]?)?\d{9,15}$/;
                if (!phoneRegex.test(identifier.replace(/[\s\-\(\)]/g, ""))) {
                    newErrors.loginIdentifier =
                        "Nieprawidłowy format numeru telefonu";
                }
            }
        }

        if (!formData.password) {
            newErrors.password = "Hasło jest wymagane";
        } else if (formData.password.length < 5) {
            newErrors.password = "Hasło jest za krótkie";
        }

        return newErrors;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        const validationErrors = validateForm();
        if (Object.keys(validationErrors).length > 0) {
            setErrors(validationErrors);
            return;
        }

        setLoading(true);
        setErrors({});

        try {
            const result = await login(
                formData.loginIdentifier,
                formData.password
            );

            if (result && result.jwt) {
                if (isShelterOwner()) {
                    navigate("/shelter-panel", { replace: true });
                } else {
                    navigate(from, { replace: true });
                }
            } else {
                setErrors({ general: "Błąd logowania" });
            }
        } catch (err) {
            setErrors({
                general: err.message || "Wystąpił nieoczekiwany błąd",
            });
            console.error("Login error:", err);
        } finally {
            setLoading(false);
        }
    };

    const handleGoogleLoginRedirect = () => {
        initiateGoogleLogin();
    };

    const togglePasswordVisibility = () => {
        setShowPassword(!showPassword);
    };

    return (
        <div className="auth-bg d-flex justify-content-center align-items-center min-vh-100">
            <form
                onSubmit={handleSubmit}
                className="bg-white p-4 rounded shadow w-100 bg-opacity-75 auth-hidden auth-bounce-in"
                style={{ maxWidth: "400px" }}
            >
                <h2 className="mb-4 text-center">Logowanie</h2>

                {shouldRedirectToShelterPanelInitially && !isShelterOwner() && (
                    <div className="alert alert-info mb-3" role="alert">
                        <strong>Panel Schroniska</strong>
                        <br />
                        Zaloguj się, aby przejść do panelu zarządzania
                        schroniskiem.
                    </div>
                )}

                {errors.general && (
                    <div className="alert alert-danger" role="alert">
                        {errors.general}
                    </div>
                )}

                <div className="mb-3">
                    <label className="form-label">Email lub telefon</label>
                    <input
                        type="text"
                        name="loginIdentifier"
                        className={`form-control ${
                            errors.loginIdentifier ? "is-invalid" : ""
                        }`}
                        value={formData.loginIdentifier}
                        onChange={handleChange}
                        placeholder="Wpisz email lub numer telefonu"
                        disabled={loading}
                    />
                    {errors.loginIdentifier && (
                        <div className="invalid-feedback">
                            {errors.loginIdentifier}
                        </div>
                    )}
                </div>

                <div className="mb-4">
                    <label className="form-label">Hasło</label>
                    <div className="position-relative">
                        <input
                            type={showPassword ? "text" : "password"}
                            name="password"
                            className={`form-control ${
                                errors.password ? "is-invalid" : ""
                            }`}
                            value={formData.password}
                            onChange={handleChange}
                            placeholder="Wpisz hasło"
                            disabled={loading}
                            style={{ paddingRight: "3rem" }}
                        />
                        <button
                            type="button"
                            className="btn btn-link position-absolute end-0 top-50 translate-middle-y text-muted"
                            onClick={togglePasswordVisibility}
                            disabled={loading}
                            style={{
                                border: "none",
                                background: "none",
                                zIndex: 1,
                                paddingRight: "0.75rem",
                            }}
                        >
                            {showPassword ? (
                                <EyeOff size={20} />
                            ) : (
                                <Eye size={20} />
                            )}
                        </button>
                    </div>
                    {errors.password && (
                        <div className="invalid-feedback d-block">
                            {errors.password}
                        </div>
                    )}
                </div>

                <button
                    type="submit"
                    className="btn btn-primary w-100 mb-3"
                    disabled={loading}
                >
                    {loading ? (
                        <>
                            <span
                                className="spinner-border spinner-border-sm me-2"
                                role="status"
                                aria-hidden="true"
                            ></span>
                            Logowanie...
                        </>
                    ) : (
                        "Zaloguj się"
                    )}
                </button>

                <div className="text-center mb-3">
                    <span className="text-muted">lub</span>
                </div>

                <button
                    type="button"
                    onClick={handleGoogleLoginRedirect}
                    className="btn btn-outline-danger w-100 mb-3"
                    disabled={loading}
                >
                    <svg
                        className="me-2"
                        width="18"
                        height="18"
                        viewBox="0 0 24 24"
                    >
                        <path
                            fill="#4285F4"
                            d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                        />
                        <path
                            fill="#34A853"
                            d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                        />
                        <path
                            fill="#FBBC05"
                            d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                        />
                        <path
                            fill="#EA4335"
                            d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                        />
                    </svg>
                    Zaloguj przez Google
                </button>

                <div className="text-center">
                    <span className="text-muted">Nie masz konta? </span>
                    <Link to="/register" className="text-decoration-none">
                        Zarejestruj się
                    </Link>
                </div>
            </form>
        </div>
    );
}
