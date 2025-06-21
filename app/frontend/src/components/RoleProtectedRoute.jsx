import { Navigate, useLocation } from "react-router-dom";
import { isAuthenticated, hasRole, getCurrentUser } from "../api/auth";

const RoleProtectedRoute = ({
    children,
    requiredRole,
    fallbackPath = "/home",
}) => {
    const location = useLocation();

    if (!isAuthenticated()) {
        return <Navigate to="/login" state={{ from: location }} replace />;
    }

    if (requiredRole && !hasRole(requiredRole)) {
        const user = getCurrentUser();

        return (
            <div className="d-flex justify-content-center align-items-center min-vh-100">
                <div
                    className="alert alert-danger text-center"
                    style={{ maxWidth: "500px" }}
                >
                    <h4>Brak uprawnień</h4>
                    <p>
                        Nie masz uprawnień do tej sekcji.
                        {requiredRole === "ADMIN" &&
                            " Panel dostępny tylko dla administratorów."}
                        {requiredRole === "SHELTER" &&
                            " Panel dostępny tylko dla właścicieli schronisk."}
                    </p>
                    <p className="small text-muted">
                        Twoje role:{" "}
                        {user?.authorities
                            ?.map((auth) => auth.authority || auth)
                            .join(", ") || "Brak ról"}
                    </p>
                    <button
                        className="btn btn-primary"
                        onClick={() => (window.location.href = fallbackPath)}
                    >
                        Wróć do strony głównej
                    </button>
                </div>
            </div>
        );
    }

    return children;
};

export default RoleProtectedRoute;
