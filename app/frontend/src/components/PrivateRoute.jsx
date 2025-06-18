import { Navigate, useLocation } from "react-router-dom";
import { isAuthenticated } from "../api/auth";

export default function PrivateRoute({ children }) {
  const location = useLocation();
  const urlParams = new URLSearchParams(location.search);
  const tokenInUrl = urlParams.get("token");

  if (!isAuthenticated() && !tokenInUrl) {
    return <Navigate to="/login" replace />;
  }

  return children;
}
