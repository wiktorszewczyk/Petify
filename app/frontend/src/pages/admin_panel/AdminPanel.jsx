import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import * as adminService from "../../api/admin";
import Navbar from "../../components/Navbar";
import {
    Shield,
    Users,
    Building,
    PawPrint,
    UserCheck,
    FileText,
    CheckCircle,
    MapPin,
    Phone,
} from "lucide-react";
import "../shelter_panel/ShelterPanel.css";

const AdminPanel = () => {
    const [loading, setLoading] = useState(true);
    const [stats, setStats] = useState({
        totalShelters: 0,
        totalPets: 0,
        totalUsers: 0,
        totalVolunteers: 0,
    });
    const [shelters, setShelters] = useState([]);
    const [selectedShelter, setSelectedShelter] = useState(null);
    const [showShelterModal, setShowShelterModal] = useState(false);
    const [error, setError] = useState("");
    const navigate = useNavigate();

    useEffect(() => {
        loadAdminData();
    }, []);

    const loadAdminData = async () => {
        setLoading(true);
        setError("");
        try {
            const usersResult = await adminService.getAllUsers();
            let totalUsers = 0;
            let totalVolunteers = 0;
            if (usersResult.success) {
                totalUsers = usersResult.data.length;
                totalVolunteers = usersResult.data.filter(
                    (user) => user.volunteerStatus === "ACTIVE"
                ).length;
            } else {
            }

            const sheltersResult = await adminService.getAllShelters();
            let totalShelters = 0;
            if (sheltersResult.success) {
                setShelters(sheltersResult.data);
                totalShelters = sheltersResult.data.length;
            } else {
            }

            const petsResult = await adminService.getPetsStats();
            let totalPets = 0;
            if (petsResult.success) {
                totalPets = petsResult.data.totalPets;
            } else {
            }

            setStats({
                totalShelters,
                totalPets,
                totalUsers,
                totalVolunteers,
            });
        } catch (error) {
            setError("Błąd podczas ładowania danych");
        } finally {
            setLoading(false);
        }
    };

    const handleNavigateToVolunteerApplications = () => {
        navigate("/admin-panel/volunteer-applications");
    };

    const handleNavigateToUsers = () => {
        navigate("/admin-panel/users");
    };

    const handleNavigateToShelterActivations = () => {
        navigate("/admin-panel/shelter-activations");
    };

    const handleShelterClick = (shelter) => {
        setSelectedShelter(shelter);
        setShowShelterModal(true);
    };

    const handleCloseShelterModal = () => {
        setShowShelterModal(false);
        setSelectedShelter(null);
    };

    if (loading) {
        return (
            <div className="d-flex justify-content-center align-items-center min-vh-100">
                <div className="spinner-border text-primary" role="status">
                    <span className="visually-hidden">Ładowanie...</span>
                </div>
            </div>
        );
    }

    return (
        <div className="shelter-panel">
            <Navbar />
            <div className="container mt-4 pb-5">
                {error && (
                    <div
                        className="alert alert-danger alert-dismissible fade show"
                        role="alert"
                    >
                        {error}
                        <button
                            type="button"
                            className="btn-close"
                            onClick={() => setError("")}
                            aria-label="Close"
                        ></button>
                    </div>
                )}

                <div className="shelter-header-card mb-4">
                    <div className="d-flex align-items-center">
                        <Shield size={48} className="text-primary me-3" />
                        <div>
                            <h2 className="mb-0">Panel Administracyjny</h2>
                            <p className="text-muted mb-0">
                                Zarządzaj systemem Petify
                            </p>
                        </div>
                    </div>
                </div>

                <div className="row mb-4 g-3">
                    <div className="col-md-3 col-6">
                        <div className="stat-card h-100">
                            <Building size={32} className="text-primary mb-2" />
                            <div className="stat-value">
                                {stats.totalShelters}
                            </div>
                            <div className="stat-label">Schroniska</div>
                        </div>
                    </div>
                    <div className="col-md-3 col-6">
                        <div className="stat-card h-100">
                            <PawPrint size={32} className="text-primary mb-2" />
                            <div className="stat-value">{stats.totalPets}</div>
                            <div className="stat-label">Zwierzęta</div>
                        </div>
                    </div>
                    <div className="col-md-3 col-6">
                        <div className="stat-card h-100">
                            <Users size={32} className="text-primary mb-2" />
                            <div className="stat-value">{stats.totalUsers}</div>
                            <div className="stat-label">Użytkownicy</div>
                        </div>
                    </div>
                    <div className="col-md-3 col-6">
                        <div className="stat-card h-100">
                            <UserCheck
                                size={32}
                                className="text-primary mb-2"
                            />
                            <div className="stat-value">
                                {stats.totalVolunteers}
                            </div>
                            <div className="stat-label">Wolontariusze</div>
                        </div>
                    </div>
                </div>

                <div className="actions-section mb-4">
                    <h4>Zarządzanie systemem</h4>
                    <div className="row g-3">
                        <div className="col-md-4">
                            <div
                                className="action-card h-100"
                                onClick={handleNavigateToVolunteerApplications}
                                role="button"
                                tabIndex={0}
                            >
                                <FileText size={28} className="action-icon" />
                                <div>
                                    <h5>Wnioski wolontariuszy</h5>
                                    <p className="mb-0">
                                        Przeglądaj i zatwierdzaj wnioski o
                                        status wolontariusza
                                    </p>
                                </div>
                            </div>
                        </div>
                        <div className="col-md-4">
                            <div
                                className="action-card h-100"
                                onClick={handleNavigateToUsers}
                                role="button"
                                tabIndex={0}
                            >
                                <Users size={28} className="action-icon" />
                                <div>
                                    <h5>Użytkownicy</h5>
                                    <p className="mb-0">
                                        Zarządzaj kontami użytkowników systemu
                                    </p>
                                </div>
                            </div>
                        </div>
                        <div className="col-md-4">
                            <div
                                className="action-card h-100"
                                onClick={handleNavigateToShelterActivations}
                                role="button"
                                tabIndex={0}
                            >
                                <Building size={28} className="action-icon" />
                                <div>
                                    <h5>Aktywacja schronisk</h5>
                                    <p className="mb-0">
                                        Weryfikuj i aktywuj nowe schroniska
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div className="pets-section">
                    <h4>Wszystkie schroniska</h4>
                    {shelters.length === 0 ? (
                        <div className="text-center py-5 rounded bg-light">
                            <Building size={48} className="text-muted mb-3" />
                            <h5 className="text-muted">
                                Brak zarejestrowanych schronisk
                            </h5>
                        </div>
                    ) : (
                        <div className="pets-grid">
                            {shelters.map((shelter) => (
                                <ShelterCard
                                    key={shelter.id}
                                    shelter={shelter}
                                    onClick={() => handleShelterClick(shelter)}
                                />
                            ))}
                        </div>
                    )}
                </div>

                {showShelterModal && selectedShelter && (
                    <ShelterDetailsModal
                        shelter={selectedShelter}
                        isOpen={showShelterModal}
                        onClose={handleCloseShelterModal}
                    />
                )}
            </div>
        </div>
    );
};

const ShelterCard = ({ shelter, onClick }) => {
    const getStatusBadge = () => {
        if (shelter.isActive) {
            return <span className="badge bg-success">Aktywne</span>;
        }
        return <span className="badge bg-warning text-dark">Oczekuje</span>;
    };

    return (
        <div className="pet-card" onClick={onClick}>
            <div className="pet-image">
                {shelter.imageUrl ? (
                    <img
                        src={shelter.imageUrl}
                        alt={shelter.name}
                        style={{ objectFit: "contain" }}
                    />
                ) : (
                    <div className="no-image">
                        <Building size={48} />
                    </div>
                )}
                <div className="pet-status">{getStatusBadge()}</div>
            </div>
            <div className="pet-info">
                <h5>{shelter.name}</h5>
                <p className="pet-details">
                    <MapPin size={14} className="me-1" />
                    {shelter.address}
                </p>
                <div className="pet-tags">
                    <span className="tag">{shelter.ownerUsername}</span>
                </div>
            </div>
        </div>
    );
};

const ShelterDetailsModal = ({ shelter, isOpen, onClose }) => {
    if (!isOpen || !shelter) return null;

    const handleBackdropClick = (e) => {
        if (e.target === e.currentTarget) {
            onClose();
        }
    };

    const getStatusBadge = () => {
        if (shelter.isActive) {
            return (
                <span className="badge bg-success d-flex align-items-center">
                    Aktywne
                </span>
            );
        }
        return (
            <span className="badge bg-warning text-dark d-flex align-items-center waiting-badge">
                Oczekuje na aktywację
            </span>
        );
    };

    return (
        <div className="pet-modal-backdrop" onClick={handleBackdropClick}>
            <div className="pet-modal">
                <div className="pet-modal-header">
                    <div className="d-flex align-items-center">
                        <h4 className="mb-0 me-2">{shelter.name}</h4>
                        {getStatusBadge()}
                    </div>
                    <button className="btn-close" onClick={onClose}></button>
                </div>

                <div className="pet-modal-content">
                    <div className="row">
                        <div className="col-md-6">
                            <div className="pet-modal-image">
                                {shelter.imageUrl ? (
                                    <img
                                        src={shelter.imageUrl}
                                        alt={shelter.name}
                                        className="w-100 h-100"
                                        style={{ objectFit: "contain" }}
                                    />
                                ) : (
                                    <div className="no-image-placeholder">
                                        <div className="text-muted text-center py-5">
                                            <Building
                                                size={48}
                                                className="text-muted"
                                            />
                                            <p className="mt-2">Brak zdjęcia</p>
                                        </div>
                                    </div>
                                )}
                            </div>
                        </div>
                        <div className="col-md-6">
                            <div className="pet-details-info">
                                <div className="detail-row">
                                    <strong>Właściciel:</strong>
                                    <span>{shelter.ownerUsername}</span>
                                </div>
                                <div className="detail-row">
                                    <strong>Adres:</strong>
                                    <span>{shelter.address}</span>
                                </div>
                                <div className="detail-row">
                                    <strong>Telefon:</strong>
                                    <span>{shelter.phoneNumber}</span>
                                </div>
                                {shelter.description && (
                                    <div className="detail-row">
                                        <strong>Opis:</strong>
                                        <p className="description-text mb-0">
                                            {shelter.description}
                                        </p>
                                    </div>
                                )}
                                <div className="detail-row">
                                    <strong>Status:</strong>
                                    <span
                                        className={
                                            shelter.isActive
                                                ? "text-success"
                                                : "text-warning"
                                        }
                                    >
                                        {shelter.isActive
                                            ? "Aktywne"
                                            : "Oczekuje na aktywację"}
                                    </span>
                                </div>
                                {shelter.latitude && shelter.longitude && (
                                    <div className="detail-row">
                                        <strong>Współrzędne:</strong>
                                        <span>
                                            {shelter.latitude.toFixed(4)},{" "}
                                            {shelter.longitude.toFixed(4)}
                                        </span>
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default AdminPanel;
