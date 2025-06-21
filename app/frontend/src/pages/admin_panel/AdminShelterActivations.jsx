import React, { useState, useEffect, useCallback, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import * as shelterService from "../../api/shelter";
import Navbar from "../../components/Navbar";
import {
    ArrowLeft,
    Building,
    Eye,
    Clock,
    ShieldCheck,
    XCircle,
    CheckCircle,
} from "lucide-react";
import "../shelter_panel/ShelterAdoptionsPage.css";

const ShelterDetailsModal = ({ isOpen, onClose, shelter }) => {
    if (!isOpen || !shelter) return null;
    return (
        <div className="custom-modal-backdrop" onClick={onClose}>
            <div
                className="custom-modal-content"
                onClick={(e) => e.stopPropagation()}
            >
                <div className="custom-modal-header">
                    <h4 className="mb-0">Szczegóły schroniska</h4>
                    <button
                        onClick={onClose}
                        className="btn-close-modal"
                    ></button>
                </div>
                <div className="custom-modal-body">
                    {shelter.imageUrl && (
                        <div className="mb-3 text-center">
                            <img
                                src={shelter.imageUrl}
                                alt={shelter.name}
                                style={{
                                    maxHeight: "250px",
                                    width: "auto",
                                    objectFit: "contain",
                                    borderRadius: "8px",
                                }}
                            />
                        </div>
                    )}
                    <p>
                        <strong>Nazwa:</strong> {shelter.name}
                    </p>
                    <p>
                        <strong>Właściciel:</strong> {shelter.ownerUsername}
                    </p>
                    <p>
                        <strong>Adres:</strong> {shelter.address}
                    </p>
                    <p>
                        <strong>Telefon:</strong> {shelter.phoneNumber}
                    </p>
                    <p>
                        <strong>Status:</strong>{" "}
                        {shelter.isActive ? (
                            <span className="text-success">Aktywne</span>
                        ) : (
                            <span className="text-warning">
                                Oczekuje na aktywację
                            </span>
                        )}
                    </p>

                    {shelter.description && (
                        <>
                            <hr className="my-3" />
                            <div>
                                <h5>Opis Schroniska:</h5>
                                <div className="description-box">
                                    <p className="text-muted mb-0">
                                        {shelter.description}
                                    </p>
                                </div>
                            </div>
                        </>
                    )}
                </div>
                <div className="custom-modal-footer">
                    <button
                        className="btn btn-outline-secondary"
                        onClick={onClose}
                    >
                        Zamknij
                    </button>
                </div>
            </div>
        </div>
    );
};

const AdminShelterActivations = () => {
    const [shelters, setShelters] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");
    const [selectedShelter, setSelectedShelter] = useState(null);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [filterStatus, setFilterStatus] = useState("ALL");
    const navigate = useNavigate();

    const fetchShelters = useCallback(async () => {
        setLoading(true);
        setError("");
        try {
            const result = await shelterService.getAllShelters();
            if (result.success) {
                const sorted = result.data.sort(
                    (a, b) => Number(a.isActive) - Number(b.isActive)
                );
                setShelters(sorted);
            } else {
                setError(result.error || "Nie udało się załadować danych.");
            }
        } catch (e) {
            setError("Wystąpił błąd podczas ładowania danych.");
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchShelters();
    }, [fetchShelters]);

    const handleActivate = async (shelterId) => {
        if (!window.confirm("Czy na pewno chcesz AKTYWOWAĆ to schronisko?"))
            return;
        const result = await shelterService.activateShelter(shelterId);
        if (result.success) fetchShelters();
        else alert(result.error || "Błąd aktywacji");
    };

    const handleDeactivate = async (shelterId) => {
        if (!window.confirm("Czy na pewno chcesz DEZAKTYWOWAĆ to schronisko?"))
            return;
        const result = await shelterService.deactivateShelter(shelterId);
        if (result.success) fetchShelters();
        else alert(result.error || "Błąd dezaktywacji");
    };

    const handleBack = () => navigate("/admin-panel");
    const openDetailsModal = (shelter) => {
        setSelectedShelter(shelter);
        setIsModalOpen(true);
    };
    const closeDetailsModal = () => setIsModalOpen(false);

    const getStatusInfo = (isActive) => {
        if (isActive) {
            return {
                text: "Aktywne",
                className: "status-accepted",
                icon: <ShieldCheck size={18} className="me-1" />,
            };
        } else {
            return {
                text: "Oczekujący",
                className: "status-pending",
                icon: <Clock size={16} className="me-1" />,
            };
        }
    };

    const filteredShelters = useMemo(
        () =>
            shelters.filter((s) => {
                if (filterStatus === "ALL") return true;
                if (filterStatus === "ACTIVE") return s.isActive;
                if (filterStatus === "INACTIVE") return !s.isActive;
                return true;
            }),
        [shelters, filterStatus]
    );

    return (
        <div className="shelter-adoptions-page">
            <Navbar />
            <div className="container mt-4 pb-5">
                <div className="shelter-header-card mb-4">
                    <div className="d-flex align-items-center mb-3">
                        <Building size={32} className="text-primary me-3" />
                        <div>
                            <h2 className="mb-0">Aktywacja schronisk</h2>
                            <p className="text-muted mb-0">
                                Weryfikuj i aktywuj nowe schroniska
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

                {shelters.length > 0 && (
                    <div className="d-flex justify-content-start mb-4">
                        <div className="filter-pills">
                            <button
                                className={`btn ${
                                    filterStatus === "ALL" ? "active" : ""
                                }`}
                                onClick={() => setFilterStatus("ALL")}
                            >
                                Wszystkie ({shelters.length})
                            </button>
                            <button
                                className={`btn ${
                                    filterStatus === "INACTIVE" ? "active" : ""
                                }`}
                                onClick={() => setFilterStatus("INACTIVE")}
                            >
                                Oczekujące (
                                {shelters.filter((s) => !s.isActive).length})
                            </button>
                            <button
                                className={`btn ${
                                    filterStatus === "ACTIVE" ? "active" : ""
                                }`}
                                onClick={() => setFilterStatus("ACTIVE")}
                            >
                                Aktywne (
                                {shelters.filter((s) => s.isActive).length})
                            </button>
                        </div>
                    </div>
                )}

                {error && <div className="alert alert-danger">{error}</div>}

                {loading ? (
                    <div className="text-center py-5">
                        <div className="spinner-border text-primary"></div>
                    </div>
                ) : !shelters.length ? (
                    <div className="text-center py-5 rounded bg-light">
                        <Building size={48} className="text-muted mb-3" />
                        <h5 className="text-muted">
                            Brak schronisk do weryfikacji
                        </h5>
                    </div>
                ) : !filteredShelters.length ? (
                    <div className="text-center py-5 rounded bg-light">
                        <Building size={48} className="text-muted mb-3" />
                        <h5 className="text-muted">
                            Brak schronisk pasujących do filtra
                        </h5>
                    </div>
                ) : (
                    <div className="adoption-cards-grid">
                        {filteredShelters.map((shelter) => {
                            const statusInfo = getStatusInfo(shelter.isActive);
                            return (
                                <div
                                    key={shelter.id}
                                    className={`adoption-card ${statusInfo.className}`}
                                >
                                    <div className="card-header">
                                        <h5 className="card-title mb-0">
                                            Wniosek o aktywację #{shelter.id}
                                        </h5>
                                        <span
                                            className={`badge adoption-status-badge ${statusInfo.className}`}
                                        >
                                            {statusInfo.icon}
                                            {statusInfo.text}
                                        </span>
                                    </div>
                                    <div className="card-body d-flex align-items-center">
                                        <div className="adoption-card-pet-image-wrapper me-4">
                                            {shelter.imageUrl ? (
                                                <img
                                                    src={shelter.imageUrl}
                                                    alt={shelter.name}
                                                    className="adoption-card-pet-image"
                                                    style={{
                                                        objectFit: "contain",
                                                    }}
                                                />
                                            ) : (
                                                <div className="adoption-card-no-image">
                                                    <Building size={40} />
                                                </div>
                                            )}
                                        </div>
                                        <div className="adoption-card-info flex-grow-1">
                                            <p>
                                                <strong>
                                                    Nazwa schroniska:
                                                </strong>{" "}
                                                {shelter.name}
                                            </p>
                                            <p>
                                                <strong>Właściciel:</strong>{" "}
                                                {shelter.ownerUsername}
                                            </p>
                                            <p>
                                                <strong>Adres:</strong>{" "}
                                                {shelter.address}
                                            </p>
                                            <p>
                                                <strong>Telefon:</strong>{" "}
                                                {shelter.phoneNumber}
                                            </p>
                                        </div>
                                    </div>
                                    <div className="card-footer">
                                        <button
                                            className="btn btn-details"
                                            onClick={() =>
                                                openDetailsModal(shelter)
                                            }
                                        >
                                            <Eye size={16} />
                                            Szczegóły
                                        </button>
                                        {!shelter.isActive ? (
                                            <button
                                                className="btn btn-sm btn-activate"
                                                onClick={() =>
                                                    handleActivate(shelter.id)
                                                }
                                            >
                                                <CheckCircle
                                                    size={16}
                                                    className="me-1"
                                                />
                                                Aktywuj
                                            </button>
                                        ) : (
                                            <button
                                                className="btn btn-sm btn-deactivate"
                                                onClick={() =>
                                                    handleDeactivate(shelter.id)
                                                }
                                            >
                                                <XCircle
                                                    size={16}
                                                    className="me-1"
                                                />
                                                Dezaktywuj
                                            </button>
                                        )}
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                )}
            </div>
            <ShelterDetailsModal
                isOpen={isModalOpen}
                onClose={closeDetailsModal}
                shelter={selectedShelter}
            />
        </div>
    );
};

export default AdminShelterActivations;
