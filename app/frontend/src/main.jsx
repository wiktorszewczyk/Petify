import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import "bootstrap/dist/css/bootstrap.min.css";
import "bootstrap/dist/js/bootstrap.bundle.min.js";
import "react-big-calendar/lib/css/react-big-calendar.css";
import "./index.css";
import { GoogleOAuthProvider } from "@react-oauth/google";

const clientId = import.meta.env.VITE_GOOGLE_CLIENT_ID;

ReactDOM.createRoot(document.getElementById("root")).render(
    <GoogleOAuthProvider clientId={clientId}>
        <BrowserRouter>
            <App />
        </BrowserRouter>
    </GoogleOAuthProvider>
);
