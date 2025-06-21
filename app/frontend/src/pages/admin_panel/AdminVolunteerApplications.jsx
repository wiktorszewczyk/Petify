import React, { useState, useEffect, useCallback, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import * as authService from "../../api/admin";
import Navbar from "../../components/Navbar";
import {
    ArrowLeft,
    FileText,
    Eye,
    MoreVertical,
    Clock,
    CheckCircle,
    XCircle,
    UserCheck,
    X,
} from "lucide-react";
import "./../shelter_panel/ShelterAdoptionsPage.css";
import "./../shelter_panel/AdoptionDetailsModal.css";

const VolunteerDetailsModal = ({ isOpen, onClose, application }) => {
    if (!isOpen || !application) {
        return null;
    }

    const getStatusText = (status) => {
        switch (status) {
            case "PENDING":
                return "Oczekujący";
            case "APPROVED":
                return "Zatwierdzony";
            case "REJECTED":
                return "Odrzucony";
            default:
                return status;
        }
    };

    return (
        <div className="custom-modal-backdrop" onClick={onClose}>
            <div
                className="custom-modal-content"
                onClick={(e) => e.stopPropagation()}
            >
                <div className="custom-modal-header">
                    <h4 className="mb-0">
                        Szczegóły Wniosku Wolontariusza #{application.id}
                    </h4>
                    <button onClick={onClose} className="btn-close-modal">
                        <X size={24} />
                    </button>
                </div>
                <div className="custom-modal-body">
                    <div className="row">
                        <div className="col-md-6">
                            <p>
                                <strong>Wnioskujący:</strong>{" "}
                                {application.user?.firstName}{" "}
                                {application.user?.lastName}
                            </p>
                            <p>
                                <strong>Email:</strong>{" "}
                                {application.user?.email}
                            </p>
                            <p>
                                <strong>Telefon:</strong>{" "}
                                {application.user?.phoneNumber || "-"}
                            </p>
                            <p>
                                <strong>Status:</strong>{" "}
                                {getStatusText(application.status)}
                            </p>
                            <p>
                                <strong>Data złożenia:</strong>{" "}
                                {application.applicationDate
                                    ? new Date(
                                          application.applicationDate
                                      ).toLocaleDateString()
                                    : "-"}
                            </p>
                        </div>
                        <div className="col-md-6">
                            <div>
                                <strong>Dostępność:</strong>
                                <div className="volunteer-field-box">
                                    {application.availability ||
                                        "Brak informacji"}
                                </div>
                            </div>
                            <div className="mt-3">
                                <strong>Umiejętności:</strong>
                                <div className="volunteer-field-box">
                                    {application.skills || "Brak informacji"}
                                </div>
                            </div>
                        </div>
                    </div>
                    <hr className="my-3" />
                    <div>
                        <h5>Doświadczenie:</h5>
                        <div className="description-box">
                            <p>{application.experience || "Brak informacji"}</p>
                        </div>
                    </div>
                    <div className="mt-3">
                        <h5>Motywacja:</h5>
                        <div className="description-box">
                            <p>{application.motivation || "Brak informacji"}</p>
                        </div>
                    </div>
                    {application.rejectionReason && (
                        <div className="mt-3">
                            <h5>Powód odrzucenia:</h5>
                            <div className="description-box">
                                <p>{application.rejectionReason}</p>
                            </div>
                        </div>
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

const AdminVolunteerApplications = () => {
    const [applications, setApplications] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");
    const [selectedApplication, setSelectedApplication] = useState(null);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [filterStatus, setFilterStatus] = useState("ALL");
    const navigate = useNavigate();

    const fetchApplications = useCallback(async () => {
        setLoading(true);
        setError("");
        try {
            const result = await authService.getVolunteerApplications();
            if (result.success) {
                const sortedApplications = result.data.sort((a, b) => {
                    const statusOrder = {
                        PENDING: 0,
                        APPROVED: 1,
                        REJECTED: 2,
                    };
                    if (statusOrder[a.status] !== statusOrder[b.status]) {
                        return statusOrder[a.status] - statusOrder[b.status];
                    }
                    return (
                        new Date(b.applicationDate || 0) -
                        new Date(a.applicationDate || 0)
                    );
                });
                setApplications(sortedApplications);
            } else {
                setError(result.error || "Nie udało się załadować wniosków.");
            }
        } catch (e) {
            setError("Wystąpił błąd podczas ładowania danych.");
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchApplications();
    }, [fetchApplications]);

    const handleBack = () => {
        navigate("/admin-panel");
    };

    const handleStatusChange = async (applicationId, action) => {
        const application = applications.find(
            (app) => app.id === applicationId
        );

        let confirmMessage = "";
        let reason = null;

        if (action === "approve") {
            confirmMessage = `Czy na pewno chcesz ZATWIERDZIĆ wniosek użytkownika ${application.user?.firstName} ${application.user?.lastName}? Użytkownik otrzyma status wolontariusza.`;
        } else if (action === "reject") {
            confirmMessage = `Czy na pewno chcesz ODRZUCIĆ wniosek użytkownika ${application.user?.firstName} ${application.user?.lastName}?`;
            reason = prompt("Podaj powód odrzucenia wniosku (opcjonalnie):");
        }

        const isConfirmed = window.confirm(confirmMessage);
        if (!isConfirmed) {
            return;
        }

        try {
            const result = await authService.updateVolunteerApplicationStatus(
                applicationId,
                action,
                reason
            );
            if (result.success) {
                fetchApplications();
            } else {
                setError(result.error || "Błąd aktualizacji statusu.");
            }
        } catch (e) {
            setError("Wystąpił błąd podczas aktualizacji statusu.");
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
            case "APPROVED":
                return {
                    text: "Zatwierdzony",
                    className: "status-accepted",
                    Icon: CheckCircle,
                };
            case "REJECTED":
                return {
                    text: "Odrzucony",
                    className: "status-rejected",
                    Icon: XCircle,
                };
            default:
                return { text: status, className: "", Icon: FileText };
        }
    };

    const filteredApplications = useMemo(() => {
        if (filterStatus === "ALL") {
            return applications;
        }
        return applications.filter((app) => app.status === filterStatus);
    }, [applications, filterStatus]);

    return (
        <div className="shelter-adoptions-page">
            <Navbar />
            <div className="container mt-4 pb-5">
                <div className="shelter-header-card mb-4">
                    <div className="d-flex align-items-center mb-3">
                        <FileText size={32} className="text-primary me-3" />
                        <div>
                            <h2 className="mb-0">Wnioski wolontariuszy</h2>
                            <p className="text-muted mb-0">
                                Przeglądaj i zatwierdzaj wnioski o status
                                wolontariusza
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
                                    filterStatus === "ALL" ? "active" : ""
                                }`}
                                onClick={() => setFilterStatus("ALL")}
                            >
                                Wszystkie ({applications.length})
                            </button>
                            <button
                                className={`btn ${
                                    filterStatus === "PENDING" ? "active" : ""
                                }`}
                                onClick={() => setFilterStatus("PENDING")}
                            >
                                Oczekujące (
                                {
                                    applications.filter(
                                        (a) => a.status === "PENDING"
                                    ).length
                                }
                                )
                            </button>
                            <button
                                className={`btn ${
                                    filterStatus === "APPROVED" ? "active" : ""
                                }`}
                                onClick={() => setFilterStatus("APPROVED")}
                            >
                                Zatwierdzone (
                                {
                                    applications.filter(
                                        (a) => a.status === "APPROVED"
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
                                        (a) => a.status === "REJECTED"
                                    ).length
                                }
                                )
                            </button>
                        </div>
                    </div>
                )}

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

                {loading ? (
                    <div className="d-flex justify-content-center align-items-center min-vh-100">
                        <div
                            className="spinner-border text-primary"
                            role="status"
                        >
                            <span className="visually-hidden">
                                Ładowanie...
                            </span>
                        </div>
                    </div>
                ) : applications.length === 0 ? (
                    <div className="text-center py-5 rounded bg-light">
                        <UserCheck size={48} className="text-muted mb-3" />
                        <h5 className="text-muted">
                            Brak wniosków wolontariuszy
                        </h5>
                        <p className="text-muted">
                            Aktualnie nie ma żadnych złożonych wniosków.
                        </p>
                    </div>
                ) : filteredApplications.length === 0 ? (
                    <div className="text-center py-5 rounded bg-light">
                        <UserCheck size={48} className="text-muted mb-3" />
                        <h5 className="text-muted">
                            Brak wniosków pasujących do wybranego filtra
                        </h5>
                    </div>
                ) : (
                    <div className="adoption-cards-grid">
                        {filteredApplications.map((app) => {
                            const statusInfo = getStatusInfo(app.status);
                            const isFinalStatus =
                                app.status === "APPROVED" ||
                                app.status === "REJECTED";

                            return (
                                <div
                                    key={app.id}
                                    className={`adoption-card ${statusInfo.className}`}
                                >
                                    <div className="card-header">
                                        <h5 className="card-title mb-0">
                                            Wniosek #{app.id}
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
                                    <div className="card-body">
                                        <div className="adoption-card-info">
                                            <p>
                                                <strong>Wnioskujący:</strong>{" "}
                                                {app.user?.firstName}{" "}
                                                {app.user?.lastName}
                                            </p>
                                            <p>
                                                <strong>Email:</strong>{" "}
                                                {app.user?.email}
                                            </p>
                                            <p>
                                                <strong>Data złożenia:</strong>{" "}
                                                {app.applicationDate
                                                    ? new Date(
                                                          app.applicationDate
                                                      ).toLocaleDateString()
                                                    : "-"}
                                            </p>
                                            <p>
                                                <strong>Telefon:</strong>{" "}
                                                {app.user?.phoneNumber || "-"}
                                            </p>
                                        </div>
                                    </div>
                                    <div className="card-footer">
                                        <button
                                            className="btn btn-details"
                                            onClick={() =>
                                                openApplicationDetails(app)
                                            }
                                        >
                                            <Eye size={16} className="me-1" />
                                            Szczegóły
                                        </button>

                                        <div className="d-flex gap-2">
                                            {app.status === "PENDING" && (
                                                <>
                                                    <button
                                                        className="btn btn-sm btn-activate"
                                                        onClick={() =>
                                                            handleStatusChange(
                                                                app.id,
                                                                "approve"
                                                            )
                                                        }
                                                    >
                                                        <CheckCircle
                                                            size={16}
                                                            className="me-1"
                                                        />
                                                        Zatwierdź
                                                    </button>
                                                    <button
                                                        className="btn btn-sm btn-deactivate"
                                                        onClick={() =>
                                                            handleStatusChange(
                                                                app.id,
                                                                "reject"
                                                            )
                                                        }
                                                    >
                                                        <XCircle
                                                            size={16}
                                                            className="me-1"
                                                        />
                                                        Odrzuć
                                                    </button>
                                                </>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                )}
            </div>

            <VolunteerDetailsModal
                isOpen={isModalOpen}
                onClose={closeApplicationDetails}
                application={selectedApplication}
            />
        </div>
    );
};

export default AdminVolunteerApplications;
