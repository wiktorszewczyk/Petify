import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { register } from "../api/auth";
import { Eye, EyeOff } from "lucide-react";
import "./Auth.css";

export default function Register() {
    const [formData, setFormData] = useState({
        firstName: "",
        lastName: "",
        email: "",
        phoneNumber: "",
        password: "",
        confirmPassword: "",
        birthDate: "",
        gender: "",
        createShelter: false,
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");
    const [success, setSuccess] = useState("");
    const [showPassword, setShowPassword] = useState(false);
    const [showConfirmPassword, setShowConfirmPassword] = useState(false);

    const navigate = useNavigate();

    const handleChange = (e) => {
        const { name, value, type, checked } = e.target;
        setFormData((prev) => ({
            ...prev,
            [name]: type === "checkbox" ? checked : value,
        }));
        if (error) setError("");
        if (success) setSuccess("");
    };

    const validateForm = () => {
        if (!formData.firstName.trim()) {
            return "Imię jest wymagane";
        }

        if (!formData.lastName.trim()) {
            return "Nazwisko jest wymagane";
        }

        if (!formData.email.trim()) {
            return "Email jest wymagany";
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(formData.email)) {
            return "Nieprawidłowy format email";
        }

        if (!formData.password) {
            return "Hasło jest wymagane";
        }

        if (formData.password.length < 6) {
            return "Hasło musi mieć co najmniej 6 znaków";
        }

        if (formData.password !== formData.confirmPassword) {
            return "Hasła nie są takie same";
        }

        return null;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        const validationError = validateForm();
        if (validationError) {
            setError(validationError);
            return;
        }

        setLoading(true);
        setError("");

        try {
            const registrationData = {
                username: formData.email, // backend używa email jako username
                password: formData.password,
                firstName: formData.firstName,
                lastName: formData.lastName,
                birthDate: formData.birthDate,
                gender: formData.gender,
                phoneNumber: formData.phoneNumber,
                email: formData.email,
                createShelter: formData.createShelter,
                applyAsVolunteer: false,
            };

            const result = await register(registrationData);

            if (result) {
                setSuccess(
                    "Konto zostało utworzone pomyślnie! Możesz się teraz zalogować."
                );
                setTimeout(() => {
                    navigate("/login");
                }, 3000);
            } else {
                setError("Błąd podczas rejestracji");
            }
        } catch (err) {
            setError(err.message || "Wystąpił nieoczekiwany błąd");
            console.error("Registration error:", err);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="auth-bg d-flex justify-content-center align-items-center">
            <form
                onSubmit={handleSubmit}
                className="bg-white p-4 rounded shadow w-100 bg-opacity-75 auth-hidden auth-bounce-in"
                style={{ maxWidth: "500px" }}
            >
                <h2 className="mb-4 text-center">Rejestracja</h2>

                {error && (
                    <div className="alert alert-danger" role="alert">
                        {error}
                    </div>
                )}

                {success && (
                    <div className="alert alert-success" role="alert">
                        {success}
                    </div>
                )}

                <div className="row">
                    <div className="col-md-6 mb-3">
                        <label className="form-label">Imię *</label>
                        <input
                            type="text"
                            name="firstName"
                            className="form-control"
                            value={formData.firstName}
                            onChange={handleChange}
                            disabled={loading}
                        />
                    </div>
                    <div className="col-md-6 mb-3">
                        <label className="form-label">Nazwisko *</label>
                        <input
                            type="text"
                            name="lastName"
                            className="form-control"
                            value={formData.lastName}
                            onChange={handleChange}
                            disabled={loading}
                        />
                    </div>
                </div>

                <div className="mb-3">
                    <label className="form-label">Email *</label>
                    <input
                        type="email"
                        name="email"
                        className="form-control"
                        value={formData.email}
                        onChange={handleChange}
                        disabled={loading}
                    />
                </div>

                <div className="mb-3">
                    <label className="form-label">Numer telefonu</label>
                    <input
                        type="tel"
                        name="phoneNumber"
                        className="form-control"
                        value={formData.phoneNumber}
                        onChange={handleChange}
                        placeholder="+48 123 456 789"
                        disabled={loading}
                    />
                </div>

                <div className="row">
                    <div className="col-md-6 mb-3">
                        <label className="form-label">Data urodzenia</label>
                        <input
                            type="date"
                            name="birthDate"
                            className="form-control"
                            value={formData.birthDate}
                            onChange={handleChange}
                            disabled={loading}
                        />
                    </div>
                    <div className="col-md-6 mb-3">
                        <label className="form-label">Płeć</label>
                        <select
                            name="gender"
                            className="form-control"
                            value={formData.gender}
                            onChange={handleChange}
                            disabled={loading}
                        >
                            <option value="">Wybierz</option>
                            <option value="Mężczyzna">Mężczyzna</option>
                            <option value="Kobieta">Kobieta</option>
                            <option value="Inne">Inne</option>
                        </select>
                    </div>
                </div>

                <div className="mb-3">
                    <label className="form-label">Hasło *</label>
                    <div className="position-relative">
                        <input
                            type={showPassword ? "text" : "password"}
                            name="password"
                            className="form-control"
                            value={formData.password}
                            onChange={handleChange}
                            disabled={loading}
                            minLength="6"
                            style={{ paddingRight: "3rem" }}
                        />
                        <button
                            type="button"
                            className="btn btn-link position-absolute end-0 top-50 translate-middle-y text-muted"
                            onClick={() => setShowPassword(!showPassword)}
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
                </div>

                <div className="mb-4">
                    <label className="form-label">Powtórz hasło *</label>
                    <div className="position-relative">
                        <input
                            type={showConfirmPassword ? "text" : "password"}
                            name="confirmPassword"
                            className="form-control"
                            value={formData.confirmPassword}
                            onChange={handleChange}
                            disabled={loading}
                            style={{ paddingRight: "3rem" }}
                        />
                        <button
                            type="button"
                            className="btn btn-link position-absolute end-0 top-50 translate-middle-y text-muted"
                            onClick={() =>
                                setShowConfirmPassword(!showConfirmPassword)
                            }
                            disabled={loading}
                            style={{
                                border: "none",
                                background: "none",
                                zIndex: 1,
                                paddingRight: "0.75rem",
                            }}
                        >
                            {showConfirmPassword ? (
                                <EyeOff size={20} />
                            ) : (
                                <Eye size={20} />
                            )}
                        </button>
                    </div>
                </div>

                <div className="mb-3">
                    <div className="form-check">
                        <input
                            type="checkbox"
                            name="createShelter"
                            className="form-check-input"
                            id="shelterCheck"
                            checked={formData.createShelter}
                            onChange={handleChange}
                            disabled={loading}
                        />
                        <label
                            className="form-check-label"
                            htmlFor="shelterCheck"
                        >
                            Chcę dodać swoje schronisko
                        </label>
                    </div>
                </div>

                <button
                    type="submit"
                    className="btn btn-success w-100 mb-3"
                    disabled={loading}
                >
                    {loading ? (
                        <>
                            <span
                                className="spinner-border spinner-border-sm me-2"
                                role="status"
                                aria-hidden="true"
                            ></span>
                            Tworzenie konta...
                        </>
                    ) : (
                        "Zarejestruj się"
                    )}
                </button>

                <div className="text-center">
                    <span className="text-muted">Masz już konto? </span>
                    <Link to="/login" className="text-decoration-none">
                        Zaloguj się
                    </Link>
                </div>
            </form>
        </div>
    );
}
