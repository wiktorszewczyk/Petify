import React from "react";
import { useNavigate } from "react-router-dom";
import Navbar from "../../components/Navbar";
import { ArrowLeft, MessageCircle } from "lucide-react";
import "./ShelterPanel.css";

const ShelterMessages = () => {
    const navigate = useNavigate();

    const handleBack = () => {
        navigate("/shelter-panel");
    };

    return (
        <div className="shelter-panel">
            <Navbar />
            <div className="container mt-4 pb-5">
                <div className="shelter-header-card mb-4">
                    <div className="d-flex align-items-center mb-3">
                        <MessageCircle
                            size={32}
                            className="text-primary me-3"
                        />
                        <div>
                            <h2 className="mb-0">Wiadomości</h2>
                            <p className="text-muted mb-0">
                                Zarządzaj rozmowami z użytkownikami
                            </p>
                        </div>
                    </div>
                    <button
                        onClick={handleBack}
                        className="btn btn-outline-secondary"
                    >
                        <ArrowLeft size={20} className="me-2" />
                        Powrót do panelu
                    </button>
                </div>

                <div className="pets-section">
                    <p className="text-center text-muted py-5">
                        Funkcjonalność w przygotowaniu...
                    </p>
                </div>
            </div>
        </div>
    );
};

export default ShelterMessages;
