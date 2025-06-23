import React, { useState, useEffect, useCallback, useMemo } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import {
    getMyShelter,
    createShelter,
    updateShelter,
    getCoordinatesFromAddress,
} from "../../api/shelter";
import { getAllPets, deletePet, archivePet } from "../../api/pet";
import Navbar from "../../components/Navbar";
import { PetCard } from "../../components/shelter_panel/shared/PetCard";
import PetDetailsModal from "./PetDetailsModal";
import { MessageCircle } from "lucide-react";

import {
    Plus,
    MapPin,
    Phone,
    Building,
    CheckCircle,
    Clock,
    AlertCircle,
    PawPrint,
    Edit,
    Save,
    ArrowLeft,
    CalendarClock,
    Users,
    DollarSign,
} from "lucide-react";
import "./ShelterPanel.css";

const WelcomeScreen = ({ onCreateShelter }) => (
    <div className="welcome-screen text-center">
        <div className="welcome-content">
            <Building size={64} className="mb-4 text-primary" />
            <h2 className="mb-3">Panel Schroniska</h2>
            <p className="mb-4 text-muted">
                Witaj w panelu zarządzania schroniskiem. Aby rozpocząć, utwórz
                profil swojego schroniska.
            </p>
            <button
                className="btn btn-primary btn-lg"
                onClick={onCreateShelter}
            >
                <Plus size={20} className="me-2" />
                Utwórz Profil Schroniska
            </button>
        </div>
    </div>
);

const ShelterForm = ({
    isEditing,
    initialShelterData,
    onShelterSubmitSuccess,
    onCancel,
}) => {
    const [formData, setFormData] = useState({
        name: initialShelterData?.name || "",
        description: initialShelterData?.description || "",
        address: initialShelterData?.address || "",
        phoneNumber: initialShelterData?.phoneNumber || "",
    });
    const [imageFile, setImageFile] = useState(null);
    const [imagePreview, setImagePreview] = useState(
        initialShelterData?.imageUrl || null
    );
    const [loadingSubmit, setLoadingSubmit] = useState(false);
    const [error, setError] = useState("");
    const [coordinates, setCoordinates] = useState(
        initialShelterData
            ? {
                  latitude: initialShelterData.latitude,
                  longitude: initialShelterData.longitude,
              }
            : null
    );
    const [addressError, setAddressError] = useState("");

    useEffect(() => {
        if (isEditing && initialShelterData) {
            setFormData({
                name: initialShelterData.name || "",
                description: initialShelterData.description || "",
                address: initialShelterData.address || "",
                phoneNumber: initialShelterData.phoneNumber || "",
            });
            setCoordinates({
                latitude: initialShelterData.latitude,
                longitude: initialShelterData.longitude,
            });
            setImagePreview(initialShelterData.imageUrl || null);
        } else if (!isEditing) {
            setFormData({
                name: "",
                description: "",
                address: "",
                phoneNumber: "",
            });
            setImageFile(null);
            setImagePreview(null);
            setCoordinates(null);
        }
    }, [isEditing, initialShelterData]);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData((prev) => ({ ...prev, [name]: value }));
        if (error) setError("");
        if (name === "address" && addressError) setAddressError("");
    };

    const handleImageChange = (e) => {
        const file = e.target.files[0];
        if (file) {
            if (file.size > 5 * 1024 * 1024) {
                setError("Plik jest za duży. Maksymalny rozmiar to 5MB.");
                setImageFile(null);
                setImagePreview(initialShelterData?.imageUrl || null);
                e.target.value = null;
                return;
            }
            setImageFile(file);
            setImagePreview(URL.createObjectURL(file));
            setError("");
        } else {
            setImageFile(null);
            if (!isEditing) {
                setImagePreview(null);
            }
        }
    };

    const handleAddressBlur = async () => {
        if (formData.address.trim()) {
            setAddressError("");
            setLoadingSubmit(true);
            try {
                const result = await getCoordinatesFromAddress(
                    formData.address
                );
                if (result.success) {
                    setCoordinates(result.coordinates);
                } else {
                    setCoordinates(null);
                    setAddressError(
                        result.error ||
                            "Nie znaleziono współrzędnych dla podanego adresu"
                    );
                }
            } catch (error) {
                setCoordinates(null);
                setAddressError("Błąd podczas sprawdzania adresu");
            } finally {
                setLoadingSubmit(false);
            }
        } else {
            setCoordinates(null);
        }
    };

    const validateForm = () => {
        if (!formData.name.trim()) return "Nazwa schroniska jest wymagana.";
        if (!formData.address.trim()) return "Adres jest wymagany.";
        if (!formData.phoneNumber.trim())
            return "Numer telefonu jest wymagany.";
        if (!coordinates)
            return "Sprawdź, czy adres został poprawnie rozpoznany i znaleziono współrzędne.";

        const phoneRegex = /^(\+48\s?)?(\d{3}[\s-]?){2}\d{3}$|^\d{9}$/;
        if (!phoneRegex.test(formData.phoneNumber.replace(/\s|-/g, ""))) {
            return "Nieprawidłowy format numeru telefonu (np. +48 123 456 789 lub 123456789).";
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

        setLoadingSubmit(true);
        setError("");

        try {
            const shelterDataPayload = {
                ...formData,
                latitude: coordinates.latitude,
                longitude: coordinates.longitude,
            };

            let result;
            if (isEditing) {
                result = await updateShelter(
                    initialShelterData.id,
                    shelterDataPayload,
                    imageFile
                );
            } else {
                result = await createShelter(shelterDataPayload, imageFile);
            }

            if (result.success) {
                onShelterSubmitSuccess(
                    result.data,
                    isEditing
                        ? "Dane schroniska zaktualizowane!"
                        : "Schronisko utworzone pomyślnie!"
                );
            } else {
                setError(
                    result.error ||
                        `Błąd podczas ${
                            isEditing ? "aktualizacji" : "tworzenia"
                        } schroniska`
                );
            }
        } catch (error) {
            setError(
                `Wystąpił nieoczekiwany błąd podczas ${
                    isEditing ? "aktualizacji" : "tworzenia"
                } schroniska`
            );
        } finally {
            setLoadingSubmit(false);
        }
    };

    return (
        <div className="create-shelter-form">
            <div className="d-flex align-items-center mb-4">
                <button
                    onClick={onCancel}
                    className="btn btn-outline-secondary me-3"
                    disabled={loadingSubmit}
                >
                    <ArrowLeft size={20} className="me-2" />
                    Powrót do panelu
                </button>
                <h2 className="mb-0">
                    {isEditing
                        ? "Edytuj dane schroniska"
                        : "Dodaj swoje schronisko"}
                </h2>
            </div>
            <p className="text-muted mb-4">
                {isEditing
                    ? "Zaktualizuj informacje o swoim schronisku."
                    : "Wypełnij formularz, aby dodać swoje schronisko do systemu."}
            </p>

            {error && (
                <div className="alert alert-danger" role="alert">
                    {error}
                </div>
            )}

            <form onSubmit={handleSubmit}>
                <div className="row">
                    <div className="col-md-6 mb-3">
                        <label className="form-label">Nazwa schroniska *</label>
                        <input
                            type="text"
                            name="name"
                            className="form-control"
                            value={formData.name}
                            onChange={handleChange}
                            disabled={loadingSubmit}
                            placeholder="np. Schronisko Na Paluchu"
                        />
                    </div>
                    <div className="col-md-6 mb-3">
                        <label className="form-label">Numer telefonu *</label>
                        <input
                            type="tel"
                            name="phoneNumber"
                            className="form-control"
                            value={formData.phoneNumber}
                            onChange={handleChange}
                            disabled={loadingSubmit}
                            placeholder="np. +48 123 456 789"
                        />
                    </div>
                </div>

                <div className="mb-3">
                    <label className="form-label">Adres *</label>
                    <input
                        type="text"
                        name="address"
                        className={`form-control ${
                            addressError ? "is-invalid" : ""
                        }`}
                        value={formData.address}
                        onChange={handleChange}
                        onBlur={handleAddressBlur}
                        disabled={loadingSubmit}
                        placeholder="np. ul. Wolczanska 12, Warszawa"
                    />
                    {addressError && (
                        <div className="invalid-feedback">{addressError}</div>
                    )}
                    {coordinates && !addressError && (
                        <div className="form-text text-success mt-1">
                            <CheckCircle size={16} className="me-1" />
                            Współrzędne: {coordinates.latitude.toFixed(4)},{" "}
                            {coordinates.longitude.toFixed(4)}
                        </div>
                    )}
                </div>

                <div className="mb-3">
                    <label className="form-label">Opis schroniska</label>
                    <textarea
                        name="description"
                        className="form-control"
                        rows="3"
                        value={formData.description}
                        onChange={handleChange}
                        disabled={loadingSubmit}
                        placeholder="Opisz swoje schronisko, jego historię, misję..."
                        maxLength="150"
                    />
                    <div className="form-text text-end">
                        {formData.description.length}/150 znaków
                    </div>
                </div>

                <div className="mb-4">
                    <label className="form-label">
                        Zdjęcie schroniska{" "}
                        {isEditing && initialShelterData?.imageData
                            ? "(pozostaw puste, aby zachować obecne)"
                            : ""}
                    </label>
                    <input
                        type="file"
                        className="form-control"
                        accept="image/jpeg, image/png, image/webp"
                        onChange={handleImageChange}
                        disabled={loadingSubmit}
                    />
                    <div className="form-text">
                        Maksymalny rozmiar pliku: 5MB. Dozwolone formaty: JPG,
                        PNG, WEBP.
                    </div>
                    {imagePreview && (
                        <div className="mt-2 text-center shelter-form-image-preview-container">
                            <img
                                src={imagePreview}
                                alt="Podgląd zdjęcia"
                                className="img-thumbnail shelter-form-image-preview"
                            />
                        </div>
                    )}
                </div>

                <div className="form-actions d-flex justify-content-end">
                    <button
                        type="button"
                        className="btn btn-secondary me-3"
                        onClick={onCancel}
                        disabled={loadingSubmit}
                    >
                        Anuluj
                    </button>
                    <button
                        type="submit"
                        className="btn btn-primary"
                        disabled={
                            loadingSubmit ||
                            (formData.address.trim() &&
                                !coordinates &&
                                !addressError)
                        }
                    >
                        {loadingSubmit ? (
                            <>
                                <span className="spinner-border spinner-border-sm me-2" />
                                {isEditing ? "Zapisywanie..." : "Tworzenie..."}
                            </>
                        ) : (
                            <>
                                <Save size={20} className="me-2" />
                                {isEditing
                                    ? "Zapisz zmiany"
                                    : "Utwórz Schronisko"}
                            </>
                        )}
                    </button>
                </div>
            </form>
        </div>
    );
};

const ShelterDashboard = ({
    shelter,
    pets,
    onAddPet,
    onPetClick,
    onEditShelter,
    onNavigateToAdoptions,
    onNavigateToReservations,
    onNavigateToChat,
    onNavigateToFeed,
    onNavigateToFunding,
    petFilter,
    setPetFilter,
    filteredPets,
}) => {
    const getStatusBadge = () => {
        if (shelter.isActive) {
            return (
                <span className="badge shelter-status-badge bg-success d-inline-flex align-items-center">
                    <CheckCircle size={16} className="me-1" />
                    Aktywne
                </span>
            );
        } else {
            return (
                <span className="badge shelter-status-badge bg-warning text-dark d-inline-flex align-items-center">
                    <Clock size={16} className="me-1" />
                    Oczekuje na aktywację
                </span>
            );
        }
    };

    return (
        <div className="shelter-dashboard">
            <div className="shelter-header-card mb-4">
                <div className="row align-items-center">
                    <div className="col-md-3 col-lg-2 text-center text-md-start mb-3 mb-md-0">
                        <div className="shelter-dashboard-image-wrapper">
                            {shelter.imageUrl ? (
                                <img
                                    src={shelter.imageUrl}
                                    alt={shelter.name}
                                    className="shelter-profile-image img-fluid rounded"
                                />
                            ) : (
                                <div className="shelter-image-placeholder rounded d-flex align-items-center justify-content-center">
                                    <Building
                                        size={64}
                                        className="text-muted"
                                    />
                                </div>
                            )}
                        </div>
                    </div>
                    <div className="col-md-9 col-lg-10">
                        <div className="d-flex align-items-center mb-2">
                            <h2 className="mb-0 shelter-name-title me-3">
                                {shelter.name}
                            </h2>
                            {getStatusBadge()}
                            <button
                                className="btn btn-outline-primary d-inline-flex align-items-center ms-auto"
                                onClick={onEditShelter}
                            >
                                <Edit size={16} className="me-1" />
                                Edytuj
                            </button>
                        </div>

                        <p className="text-muted mb-1 shelter-detail d-flex align-items-center">
                            <MapPin size={16} className="me-2 flex-shrink-0" />
                            <span>{shelter.address}</span>
                        </p>
                        <p className="text-muted mb-0 shelter-detail d-flex align-items-center">
                            <Phone size={16} className="me-2 flex-shrink-0" />
                            <span>{shelter.phoneNumber}</span>
                        </p>
                        {shelter.description && (
                            <div className="row">
                                <div className="col-lg-10">
                                    <p className="mt-3 mb-0 shelter-description">
                                        {shelter.description}
                                    </p>
                                </div>
                            </div>
                        )}
                    </div>
                </div>

                {!shelter.isActive && (
                    <div className="alert alert-info mt-3 mb-0">
                        <AlertCircle size={20} className="me-2" />
                        Twoje schronisko oczekuje na aktywację przez
                        administratora. Po aktywacji będzie widoczne dla innych
                        użytkowników.
                    </div>
                )}
            </div>

            <div className="row mb-4 g-3">
                <div className="col-md-3 col-6">
                    <div className="stat-card h-100">
                        <div className="stat-value">{pets.length}</div>
                        <div className="stat-label">Wszystkie Zwierzęta</div>
                    </div>
                </div>
                <div className="col-md-3 col-6">
                    <div className="stat-card h-100">
                        <div className="stat-value">
                            {pets.filter((pet) => !pet.archived).length}
                        </div>
                        <div className="stat-label">Do adopcji</div>
                    </div>
                </div>
                <div className="col-md-3 col-6">
                    <div className="stat-card h-100">
                        <div className="stat-value">
                            {
                                pets.filter(
                                    (pet) => pet.urgent && !pet.archived
                                ).length
                            }
                        </div>
                        <div className="stat-label">Pilne</div>
                    </div>
                </div>
                <div className="col-md-3 col-6">
                    <div className="stat-card h-100">
                        <div className="stat-value">
                            {pets.filter((pet) => pet.archived).length}
                        </div>
                        <div className="stat-label">Adoptowane</div>
                    </div>
                </div>
            </div>

            {shelter.isActive && (
                <div className="actions-section mb-4">
                    <h4>Zarządzanie</h4>
                    <div className="row g-3">
                        <div className="col-md-6 col-lg-4">
                            <div
                                className="action-card h-100"
                                onClick={onAddPet}
                                role="button"
                                tabIndex={0}
                            >
                                <PawPrint size={28} className="action-icon" />
                                <div>
                                    <h5>Dodaj zwierzę</h5>
                                    <p className="mb-0">
                                        Stwórz profil dla nowego podopiecznego.
                                    </p>
                                </div>
                            </div>
                        </div>
                        <div className="col-md-6 col-lg-4">
                            <div
                                className="action-card h-100"
                                onClick={onNavigateToAdoptions}
                                role="button"
                                tabIndex={0}
                            >
                                <CalendarClock
                                    size={28}
                                    className="action-icon"
                                />
                                <div>
                                    <h5>Wnioski adopcyjne</h5>
                                    <p className="mb-0">
                                        Przeglądaj i zarządzaj wnioskami o
                                        adopcję.
                                    </p>
                                </div>
                            </div>
                        </div>
                        <div className="col-md-4">
                            <div
                                className="action-card h-100"
                                onClick={onNavigateToReservations}
                                role="button"
                                tabIndex={0}
                            >
                                <CalendarClock
                                    size={28}
                                    className="action-icon"
                                />
                                <div>
                                    <h5>Zarządzaj rezerwacjami</h5>
                                    <p className="mb-0">
                                        Twórz i przeglądaj sloty na spacery.
                                    </p>
                                </div>
                            </div>
                        </div>
                        <div className="col-md-4">
                            <div
                                className="action-card h-100"
                                onClick={onNavigateToChat}
                                role="button"
                                tabIndex={0}
                            >
                                <MessageCircle
                                    size={28}
                                    className="action-icon"
                                />
                                <div>
                                    <h5>Wiadomości</h5>
                                    <p className="mb-0">
                                        Zarządzaj rozmowami z użytkownikami.
                                    </p>
                                </div>
                            </div>
                        </div>
                        <div className="col-md-4">
                            <div
                                className="action-card h-100"
                                onClick={onNavigateToFeed}
                                role="button"
                                tabIndex={0}
                            >
                                <Users size={28} className="action-icon" />
                                <div>
                                    <h5>Społeczność</h5>
                                    <p className="mb-0">
                                        Zarządzaj wydarzeniami.
                                    </p>
                                </div>
                            </div>
                        </div>
                        <div className="col-md-4">
                            <div
                                className="action-card h-100"
                                onClick={onNavigateToFunding}
                                role="button"
                                tabIndex={0}
                            >
                                <DollarSign size={28} className="action-icon" />
                                <div>
                                    <h5>Fundusze</h5>
                                    <p className="mb-0">
                                        Zarządzaj funduszami schroniska.
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            <div className="pets-section">
                <div className="d-flex justify-content-between align-items-center mb-3">
                    <h4>Zwierzęta w schronisku</h4>

                    <div className="filter-pills">
                        <button
                            type="button"
                            className={`btn ${
                                petFilter === "ACTIVE" ? "active" : ""
                            }`}
                            onClick={() => setPetFilter("ACTIVE")}
                        >
                            Do adopcji ({pets.filter((p) => !p.archived).length}
                            )
                        </button>
                        <button
                            type="button"
                            className={`btn ${
                                petFilter === "ADOPTED" ? "active" : ""
                            }`}
                            onClick={() => setPetFilter("ADOPTED")}
                        >
                            Adoptowane ({pets.filter((p) => p.archived).length})
                        </button>
                        <button
                            type="button"
                            className={`btn ${
                                petFilter === "ALL" ? "active" : ""
                            }`}
                            onClick={() => setPetFilter("ALL")}
                        >
                            Wszystkie ({pets.length})
                        </button>
                    </div>
                </div>

                {filteredPets.length === 0 ? (
                    <div className="text-center py-5 rounded bg-light">
                        <PawPrint size={48} className="text-muted mb-3" />
                        <h5 className="text-muted">
                            Brak zwierząt pasujących do tego filtra
                        </h5>
                    </div>
                ) : (
                    <div className="pets-grid">
                        {filteredPets.map((pet) => (
                            <PetCard
                                key={pet.id}
                                pet={pet}
                                onClick={() => onPetClick(pet)}
                            />
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
};

const ShelterPanel = () => {
    const [shelter, setShelter] = useState(null);
    const [loading, setLoading] = useState(true);
    const [showCreateForm, setShowCreateForm] = useState(false);
    const [showEditForm, setShowEditForm] = useState(false);
    const [pets, setPets] = useState([]);
    const [showSuccessMessage, setShowSuccessMessage] = useState(false);
    const [successMessage, setSuccessMessage] = useState("");
    const [selectedPet, setSelectedPet] = useState(null);
    const [showPetModal, setShowPetModal] = useState(false);
    const [petFilter, setPetFilter] = useState("ACTIVE");

    const navigate = useNavigate();
    const location = useLocation();

    const checkShelterExists = useCallback(async () => {
        setLoading(true);
        try {
            const result = await getMyShelter();
            if (result.success && result.data) {
                setShelter(result.data);
                loadPets(result.data.id);
            } else if (result.notFound) {
                setShelter(null);
            } else {
                setShelter(null);
            }
        } catch (error) {
            setShelter(null);
        } finally {
            setLoading(false);
        }
    }, []);

    const loadPets = async (shelterId) => {
        if (!shelterId) return;
        try {
            const result = await getAllPets();
            if (result.success) {
                const shelterPets = result.data.filter(
                    (pet) => pet.shelterId === shelterId
                );
                setPets(shelterPets);
            }
        } catch (error) {}
    };

    useEffect(() => {
        checkShelterExists();
    }, [checkShelterExists]);

    useEffect(() => {
        if (location.state?.message) {
            setSuccessMessage(location.state.message);
            setShowSuccessMessage(true);
            navigate(location.pathname, { state: {}, replace: true });
            setTimeout(() => setShowSuccessMessage(false), 5000);
        }
    }, [location, navigate]);

    const handleShelterFormSuccess = (updatedShelter, message) => {
        setShelter(updatedShelter);
        setShowCreateForm(false);
        setShowEditForm(false);
        setSuccessMessage(message);
        setShowSuccessMessage(true);
        setTimeout(() => setShowSuccessMessage(false), 5000);
        if (updatedShelter.id) {
            loadPets(updatedShelter.id);
        }
    };

    const handleAddPet = () => {
        navigate("/shelter-panel/add-pet");
    };

    const handlePetClick = (pet) => {
        setSelectedPet(pet);
        setShowPetModal(true);
    };

    const handleClosePetModal = () => {
        setShowPetModal(false);
        setSelectedPet(null);
    };

    const handleEditPet = (petId) => {
        setShowPetModal(false);
        navigate(`/shelter-panel/edit-pet/${petId}`);
    };

    const handleDeletePet = async (petId, petName) => {
        if (
            window.confirm(
                `Czy na pewno chcesz usunąć zwierzę "${petName}"? Ta operacja jest nieodwracalna.`
            )
        ) {
            try {
                const result = await deletePet(petId);
                if (result.success) {
                    setPets(pets.filter((pet) => pet.id !== petId));
                    setShowPetModal(false);
                    setSuccessMessage(`Zwierzę "${petName}" zostało usunięte.`);
                    setShowSuccessMessage(true);
                    setTimeout(() => setShowSuccessMessage(false), 5000);
                } else {
                    alert(
                        "Błąd podczas usuwania zwierzęcia: " +
                            (result.error || "Nieznany błąd")
                    );
                }
            } catch (error) {
                alert("Wystąpił błąd podczas usuwania zwierzęcia");
            }
        }
    };

    const handleMarkAsAdopted = async (petId, petName) => {
        if (
            window.confirm(
                `Czy chcesz oznaczyć zwierzę "${petName}" jako adoptowane? Zostanie ono ukryte na liście zwierząt do adopcji.`
            )
        ) {
            try {
                const result = await archivePet(petId);
                if (result.success) {
                    const updatedPets = pets.map((pet) =>
                        pet.id === petId ? { ...pet, archived: true } : pet
                    );
                    setPets(updatedPets);
                    setSelectedPet((prev) =>
                        prev && prev.id === petId
                            ? { ...prev, archived: true }
                            : prev
                    );
                    setSuccessMessage(
                        `Zwierzę "${petName}" zostało oznaczone jako adoptowane.`
                    );
                    setShowSuccessMessage(true);
                    setTimeout(() => setShowSuccessMessage(false), 5000);
                } else {
                    alert("Błąd: " + (result.error || "Nieznany błąd"));
                }
            } catch (error) {
                alert("Wystąpił błąd serwera.");
            }
        }
    };

    const handleTrueArchive = (petId, petName) => {
        alert(
            `Funkcjonalność archiwizacji dla "${petName}" (ID: ${petId}) zostanie zaimplementowana w przyszłości.`
        );
    };

    const handleNavigateToAdoptions = () => {
        navigate("/shelter-panel/adoptions");
    };

    const handleNavigateToReservations = () => {
        navigate("/shelter-panel/reservations");
    };

    const handleNavigateToChat = () => {
        navigate("/shelter-panel/messages");
    };

    const handleNavigateToFeed = () => {
        navigate("/shelter-panel/feed");
    };

    const handleNavigateToFunding = () => {
        navigate("/shelter-panel/funding");
    };

    const filteredPets = useMemo(() => {
        switch (petFilter) {
            case "ADOPTED":
                return pets.filter((pet) => pet.archived);
            case "ACTIVE":
                return pets.filter((pet) => !pet.archived);
            case "ALL":
            default:
                return pets;
        }
    }, [pets, petFilter]);

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
                {showSuccessMessage && (
                    <div
                        className="alert alert-success alert-dismissible fade show"
                        role="alert"
                    >
                        {successMessage}
                        <button
                            type="button"
                            className="btn-close"
                            onClick={() => setShowSuccessMessage(false)}
                            aria-label="Close"
                        ></button>
                    </div>
                )}

                {!shelter && !showCreateForm && !showEditForm ? (
                    <WelcomeScreen
                        onCreateShelter={() => {
                            setShowCreateForm(true);
                            setShowEditForm(false);
                        }}
                    />
                ) : showCreateForm || showEditForm ? (
                    <ShelterForm
                        isEditing={showEditForm}
                        initialShelterData={showEditForm ? shelter : null}
                        onShelterSubmitSuccess={handleShelterFormSuccess}
                        onCancel={() => {
                            setShowCreateForm(false);
                            setShowEditForm(false);
                            checkShelterExists();
                        }}
                    />
                ) : (
                    <>
                        <ShelterDashboard
                            shelter={shelter}
                            pets={pets}
                            onAddPet={handleAddPet}
                            onPetClick={handlePetClick}
                            onEditShelter={() => {
                                setShowEditForm(true);
                                setShowCreateForm(false);
                            }}
                            onNavigateToAdoptions={handleNavigateToAdoptions}
                            onNavigateToReservations={
                                handleNavigateToReservations
                            }
                            onNavigateToChat={handleNavigateToChat}
                            onNavigateToFeed={handleNavigateToFeed}
                            onNavigateToFunding={handleNavigateToFunding}
                            petFilter={petFilter}
                            setPetFilter={setPetFilter}
                            filteredPets={filteredPets}
                        />
                        <PetDetailsModal
                            pet={selectedPet}
                            shelter={shelter}
                            isOpen={showPetModal}
                            onClose={handleClosePetModal}
                            onEdit={handleEditPet}
                            onDelete={handleDeletePet}
                            onArchive={handleMarkAsAdopted}
                            onTrueArchive={handleTrueArchive}
                        />
                    </>
                )}
            </div>
        </div>
    );
};

export default ShelterPanel;
