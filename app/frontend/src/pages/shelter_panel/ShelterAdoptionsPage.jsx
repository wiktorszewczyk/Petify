import React, { useState, useEffect, useCallback, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import {
    getMyShelter,
    getShelterAdoptions,
    updateAdoptionStatus,
    deleteAdoption,
} from "../../api/shelter";
import { getPetById } from "../../api/pet";
import Navbar from "../../components/Navbar";
import AdoptionDetailsModal from "./AdoptionDetailsModal";
import {
    ArrowLeft,
    Edit3,
    Eye,
    MoreVertical,
    Clock,
    CheckCircle,
    XCircle,
    AlertOctagon,
    PawPrint,
    Trash2,
    Building,
} from "lucide-react";
import "./ShelterAdoptionsPage.css";

const ShelterAdoptionsPage = () => {
    const [shelter, setShelter] = useState(null);
    const [applications, setApplications] = useState([]);
    const [petsDetails, setPetsDetails] = useState({});
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");
    const navigate = useNavigate();

    const [selectedApplication, setSelectedApplication] = useState(null);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [filterStatus, setFilterStatus] = useState("PENDING");

    const fetchShelterAndApplications = useCallback(async () => {
        setLoading(true);
        setError("");
        try {
            const shelterResult = await getMyShelter();
            if (shelterResult.success && shelterResult.data) {
                setShelter(shelterResult.data);

                const appsResult = await getShelterAdoptions(
                    shelterResult.data.id
                );
                if (appsResult.success) {
                    const sortedApplications = appsResult.data.sort((a, b) => {
                        const statusOrder = {
                            PENDING: 0,
                            ACCEPTED: 1,
                            REJECTED: 2,
                            CANCELLED: 3,
                        };
                        if (
                            statusOrder[a.adoptionStatus] !==
                            statusOrder[b.adoptionStatus]
                        ) {
                            return (
                                statusOrder[a.adoptionStatus] -
                                statusOrder[b.adoptionStatus]
                            );
                        }
                        return (
                            new Date(b.applicationDate || 0) -
                            new Date(a.applicationDate || 0)
                        );
                    });
                    setApplications(sortedApplications);
                    const petIds = [
                        ...new Set(sortedApplications.map((app) => app.petId)),
                    ];
                    if (petIds.length > 0) {
                        await fetchPetsDetails(petIds);
                    }
                } else {
                    setError(
                        appsResult.error ||
                            "Nie udało się załadować wniosków adopcyjnych."
                    );
                }
            } else {
                setError(
                    shelterResult.error ||
                        "Nie udało się załadować danych schroniska."
                );
                navigate("/shelter-panel");
            }
        } catch (e) {
            setError("Wystąpił błąd podczas ładowania danych.");
        } finally {
            setLoading(false);
        }
    }, [navigate]);

    const fetchPetsDetails = async (petIds) => {
        const currentPetDetails = { ...petsDetails };
        const newPetIdsToFetch = petIds.filter(
            (id) => !currentPetDetails[id] || !currentPetDetails[id].name
        );

        if (newPetIdsToFetch.length === 0) {
            return;
        }

        const detailsPromises = newPetIdsToFetch.map((id) =>
            getPetById(id)
                .then((petResult) => ({ id, ...petResult }))
                .catch((e) => ({ id, success: false, error: e.message }))
        );

        const results = await Promise.all(detailsPromises);
        const updatedDetails = { ...currentPetDetails };
        results.forEach((result) => {
            if (result.success && result.data) {
                updatedDetails[result.id] = result.data;
            } else {
                updatedDetails[result.id] = {
                    name: `Zwierzę #${result.id}`,
                    imageUrl: null,
                    breed: "Nieznana",
                    type: "Nieznany",
                };
            }
        });
        setPetsDetails(updatedDetails);
    };

    useEffect(() => {
        fetchShelterAndApplications();
    }, [fetchShelterAndApplications]);

    const handleStatusChange = async (applicationId, newStatus) => {
        const application = applications.find(
            (app) => app.id === applicationId
        );
        const petDetail = petsDetails[application.petId];

        const confirmMessage = {
            ACCEPTED: `Czy na pewno chcesz ZAAKCEPTOWAĆ ten wniosek dla ${
                petDetail?.name || "zwierzęcia"
            }? Spowoduje to automatyczne odrzucenie innych oczekujących wniosków dla tego zwierzęcia i oznaczenie go jako adoptowane.`,
            REJECTED: `Czy na pewno chcesz ODRZUCIĆ ten wniosek?`,
            CANCELLED: `Czy na pewno chcesz ANULOWAĆ ten wniosek?`,
            PENDING: `Czy na pewno chcesz cofnąć status tego wniosku na OCZEKUJĄCY?`,
        };

        const isConfirmed = window.confirm(
            confirmMessage[newStatus] || "Czy na pewno chcesz zmienić status?"
        );

        if (!isConfirmed) {
            return;
        }

        const originalApplications = JSON.parse(JSON.stringify(applications));
        setApplications((apps) =>
            apps.map((app) =>
                app.id === applicationId
                    ? { ...app, adoptionStatus: newStatus }
                    : app
            )
        );

        try {
            const result = await updateAdoptionStatus(applicationId, newStatus);
            if (!result.success) {
                setError(result.error || "Błąd aktualizacji statusu.");
                setApplications(originalApplications);
            } else {
                fetchShelterAndApplications();
            }
        } catch (e) {
            setError("Wystąpił błąd serwera podczas aktualizacji statusu.");
            setApplications(originalApplications);
        }
    };

    const handleDeleteApplication = async (applicationId) => {
        const confirmDelete = window.confirm(
            "Czy na pewno chcesz TRWALE usunąć ten wniosek? Tej operacji nie można cofnąć."
        );

        if (confirmDelete) {
            const result = await deleteAdoption(applicationId);
            if (result.success) {
                setApplications((prev) =>
                    prev.filter((app) => app.id !== applicationId)
                );
                if (selectedApplication?.id === applicationId) {
                    closeApplicationDetails();
                }
            } else {
                alert(`Błąd: ${result.error}`);
            }
        }
    };

    const openApplicationDetails = (application) => {
        setSelectedApplication(application);
        setIsModalOpen(true);
    };

    const closeApplicationDetails = () => {
        setIsModalOpen(false);
        setSelectedApplication(null);
    };

    const getStatusInfo = (status) => {
        switch (status) {
            case "PENDING":
                return {
                    text: "Oczekujący",
                    className: "status-pending",
                    Icon: Clock,
                };
            case "ACCEPTED":
                return {
                    text: "Zaakceptowany",
                    className: "status-accepted",
                    Icon: CheckCircle,
                };
            case "REJECTED":
                return {
                    text: "Odrzucony",
                    className: "status-rejected",
                    Icon: XCircle,
                };
            case "CANCELLED":
                return {
                    text: "Anulowany",
                    className: "status-cancelled",
                    Icon: AlertOctagon,
                };
            default:
                return { text: status, className: "", Icon: MoreVertical };
        }
    };

    const filteredApplications = useMemo(() => {
        if (filterStatus === "ALL") {
            return applications;
        }
        return applications.filter(
            (app) => app.adoptionStatus === filterStatus
        );
    }, [applications, filterStatus]);

    const handleBack = () => navigate("/shelter-panel");

    if (loading && applications.length === 0) {
        return (
            <div className="d-flex justify-content-center align-items-center min-vh-100">
                <div className="spinner-border text-primary" role="status">
                    <span className="visually-hidden">Ładowanie...</span>
                </div>
            </div>
        );
    }

    return (
        <div className="shelter-adoptions-page">
            <Navbar />
            <div className="container mt-4 pb-5">
                <div className="shelter-header-card mb-4">
                    <div className="d-flex align-items-center mb-3">
                        <Building size={32} className="text-primary me-3" />
                        <div>
                            <h2 className="mb-0">Wnioski adopcyjne</h2>
                            <p className="text-muted mb-0">
                                Zarządzaj wnioskami o adopcję zwierząt w
                                schronisku "{shelter?.name}"
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

                {applications.length > 0 && (
                    <div className="d-flex justify-content-start mb-4">
                        <div className="filter-pills">
                            <button
                                className={`btn ${
                                    filterStatus === "PENDING" ? "active" : ""
                                }`}
                                onClick={() => setFilterStatus("PENDING")}
                            >
                                Oczekujące (
                                {
                                    applications.filter(
                                        (a) => a.adoptionStatus === "PENDING"
                                    ).length
                                }
                                )
                            </button>
                            <button
                                className={`btn ${
                                    filterStatus === "ACCEPTED" ? "active" : ""
                                }`}
                                onClick={() => setFilterStatus("ACCEPTED")}
                            >
                                Zaakceptowane (
                                {
                                    applications.filter(
                                        (a) => a.adoptionStatus === "ACCEPTED"
                                    ).length
                                }
                                )
                            </button>
                            <button
                                className={`btn ${
                                    filterStatus === "REJECTED" ? "active" : ""
                                }`}
                                onClick={() => setFilterStatus("REJECTED")}
                            >
                                Odrzucone (
                                {
                                    applications.filter(
                                        (a) => a.adoptionStatus === "REJECTED"
                                    ).length
                                }
                                )
                            </button>
                            <button
                                className={`btn ${
                                    filterStatus === "ALL" ? "active" : ""
                                }`}
                                onClick={() => setFilterStatus("ALL")}
                            >
                                Wszystkie ({applications.length})
                            </button>
                        </div>
                    </div>
                )}

                {error && <div className="alert alert-danger">{error}</div>}

                {!loading && applications.length === 0 ? (
                    <div className="text-center py-5 rounded bg-light">
                        <Edit3 size={48} className="text-muted mb-3" />
                        <h5 className="text-muted">
                            Brak wniosków adopcyjnych
                        </h5>
                        <p className="text-muted">
                            Aktualnie nie ma żadnych złożonych wniosków.
                        </p>
                    </div>
                ) : !loading && filteredApplications.length === 0 ? (
                    <div className="text-center py-5 rounded bg-light">
                        <Edit3 size={48} className="text-muted mb-3" />
                        <h5 className="text-muted">
                            Brak wniosków pasujących do wybranego filtra
                        </h5>
                    </div>
                ) : (
                    <div className="adoption-cards-grid">
                        {filteredApplications.map((application) => {
                            const pet = petsDetails[application.petId];
                            const statusInfo = getStatusInfo(
                                application.adoptionStatus
                            );
                            return (
                                <div
                                    key={application.id}
                                    className={`adoption-card ${statusInfo.className}`}
                                >
                                    <div className="card-header">
                                        <h5 className="card-title mb-0">
                                            Wniosek adopcyjny #{application.id}
                                        </h5>
                                        <span
                                            className={`badge adoption-status-badge ${statusInfo.className}`}
                                        >
                                            <statusInfo.Icon
                                                size={16}
                                                className="me-1"
                                            />
                                            {statusInfo.text}
                                        </span>
                                    </div>
                                    <div className="card-body d-flex align-items-center">
                                        {pet?.imageUrl ? (
                                            <div className="adoption-card-pet-image-wrapper">
                                                <img
                                                    src={pet.imageUrl}
                                                    alt={pet.name}
                                                    className="adoption-card-pet-image"
                                                />
                                            </div>
                                        ) : (
                                            <div className="adoption-card-pet-image-wrapper">
                                                <div className="adoption-card-no-image">
                                                    <PawPrint size={32} />
                                                </div>
                                            </div>
                                        )}
                                        <div className="adoption-card-info">
                                            <p>
                                                <strong>
                                                    Imię i nazwisko:
                                                </strong>{" "}
                                                {application.fullName}
                                            </p>
                                            <p>
                                                <strong>Zwierzę:</strong>{" "}
                                                {pet?.name ||
                                                    `ID: ${application.petId}`}
                                            </p>
                                            <p>
                                                <strong>Email:</strong>{" "}
                                                {application.username}
                                            </p>
                                            <p>
                                                <strong>Telefon:</strong>{" "}
                                                {application.phoneNumber}
                                            </p>
                                        </div>
                                    </div>
                                    <div className="card-footer">
                                        <button
                                            className="btn btn-sm btn-outline-primary btn-details"
                                            onClick={() =>
                                                openApplicationDetails(
                                                    application
                                                )
                                            }
                                        >
                                            <Eye size={16} className="me-1" />
                                            Szczegóły
                                        </button>

                                        <div className="d-flex gap-2">
                                            {application.adoptionStatus !==
                                                "ACCEPTED" && (
                                                <button
                                                    className="btn btn-sm btn-activate"
                                                    onClick={() =>
                                                        handleStatusChange(
                                                            application.id,
                                                            "ACCEPTED"
                                                        )
                                                    }
                                                >
                                                    <CheckCircle
                                                        size={16}
                                                        className="me-1"
                                                    />
                                                    Zaakceptuj
                                                </button>
                                            )}

                                            {application.adoptionStatus !==
                                                "REJECTED" && (
                                                <button
                                                    className="btn btn-sm btn-deactivate"
                                                    onClick={() =>
                                                        handleStatusChange(
                                                            application.id,
                                                            "REJECTED"
                                                        )
                                                    }
                                                >
                                                    <XCircle
                                                        size={16}
                                                        className="me-1"
                                                    />
                                                    Odrzuć
                                                </button>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                )}
            </div>
            <AdoptionDetailsModal
                isOpen={isModalOpen}
                onClose={closeApplicationDetails}
                application={selectedApplication}
                petName={
                    selectedApplication &&
                    petsDetails[selectedApplication.petId]?.name
                }
                onDelete={handleDeleteApplication}
            />
        </div>
    );
};

export default ShelterAdoptionsPage;
