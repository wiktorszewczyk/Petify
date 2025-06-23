import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import Navbar from "../../components/Navbar";
import * as userService from "../../api/admin";
import {
    ArrowLeft,
    Users,
    Search,
    Eye,
    UserCheck,
    UserX,
    Mail,
    Phone,
    X,
    AlertCircle,
} from "lucide-react";
import "../shelter_panel/ShelterPanel.css";

const AdminUsers = () => {
    const navigate = useNavigate();
    const [users, setUsers] = useState([]);
    const [filteredUsers, setFilteredUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");
    const [searchTerm, setSearchTerm] = useState("");
    const [selectedUser, setSelectedUser] = useState(null);
    const [showUserModal, setShowUserModal] = useState(false);
    const [showDeactivateModal, setShowDeactivateModal] = useState(false);
    const [showReasonModal, setShowReasonModal] = useState(false);
    const [showActivateConfirmModal, setShowActivateConfirmModal] =
        useState(false);
    const [deactivationReason, setDeactivationReason] = useState("");
    const [userToDeactivate, setUserToDeactivate] = useState(null);
    const [userToActivate, setUserToActivate] = useState(null);
    const [roleFilter, setRoleFilter] = useState("ALL");
    const [toast, setToast] = useState(null);

    useEffect(() => {
        loadUsers();
    }, []);

    useEffect(() => {
        filterUsers();
    }, [users, searchTerm, roleFilter]);

    const loadUsers = async () => {
        try {
            setLoading(true);
            const result = await userService.getAllUsers();

            if (result.success) {
                setUsers(result.data);
                setError("");
            } else {
                setError(result.error);
            }
        } catch (error) {
            setError("Błąd podczas ładowania użytkowników");
        } finally {
            setLoading(false);
        }
    };

    const showToast = (message, type = "info") => {
        setToast({ message, type });
    };

    const hideToast = () => {
        setToast(null);
    };

    const filterUsers = () => {
        let filtered = users;

        if (searchTerm) {
            filtered = filtered.filter(
                (user) =>
                    user.firstName
                        ?.toLowerCase()
                        .includes(searchTerm.toLowerCase()) ||
                    user.lastName
                        ?.toLowerCase()
                        .includes(searchTerm.toLowerCase()) ||
                    user.email
                        ?.toLowerCase()
                        .includes(searchTerm.toLowerCase()) ||
                    user.phoneNumber?.includes(searchTerm)
            );
        }

        if (roleFilter !== "ALL") {
            filtered = filtered.filter((user) => {
                if (roleFilter === "ACTIVE") {
                    return user.active;
                }
                if (roleFilter === "INACTIVE") {
                    return !user.active;
                }
                return getUserRole(user) === roleFilter;
            });
        }

        setFilteredUsers(filtered);
    };

    const handleBack = () => {
        navigate("/admin-panel");
    };

    const handleUserClick = (user) => {
        setSelectedUser(user);
        setShowUserModal(true);
    };

    const handleCloseUserModal = () => {
        setShowUserModal(false);
        setSelectedUser(null);
    };

    const handleConfirmDeactivation = async () => {
        if (!userToDeactivate) return;

        try {
            const result = await userService.deactivateUser(
                userToDeactivate.userId,
                deactivationReason.trim() || null
            );

            if (result.success) {
                loadUsers();
                setShowDeactivateModal(false);
                setUserToDeactivate(null);
                setDeactivationReason("");
                showToast(
                    `Użytkownik ${userToDeactivate.firstName} ${userToDeactivate.lastName} został pomyślnie dezaktywowany.`,
                    "success"
                );
            } else {
                setError(result.error);
            }
        } catch (error) {
            setError("Błąd podczas dezaktywacji użytkownika");
        }
    };

    const handleCancelDeactivation = () => {
        setShowDeactivateModal(false);
        setUserToDeactivate(null);
        setDeactivationReason("");
    };

    const getUserRole = (user) => {
        if (!user.authorities || user.authorities.length === 0) return "USER";
        const roles = user.authorities.map((auth) => {
            const role = auth.authority || auth;
            return role.replace("ROLE_", "");
        });

        if (roles.some((role) => role.toUpperCase().includes("ADMIN")))
            return "ADMIN";
        if (roles.some((role) => role.toUpperCase().includes("SHELTER")))
            return "SHELTER";
        if (roles.some((role) => role.toUpperCase().includes("VOLUNTEER")))
            return "VOLUNTEER";

        return "USER";
    };

    const getRoleBadgeClass = (role) => {
        switch (role) {
            case "ADMIN":
                return {
                    backgroundColor: "#dc3545",
                    color: "white",
                };
            case "SHELTER":
                return {
                    backgroundColor: "#ffa726",
                    color: "#212529",
                };
            case "VOLUNTEER":
                return {
                    backgroundColor: "#7CAFC4",
                    color: "#212529",
                };
            default:
                return {
                    backgroundColor: "#D6C3C9",
                    color: "#212529",
                };
        }
    };

    const formatDate = (dateString) => {
        if (!dateString) return "Brak danych";
        return new Date(dateString).toLocaleDateString("pl-PL");
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

    const Toast = ({ message, type, onClose, duration = 3000 }) => {
        useEffect(() => {
            const timer = setTimeout(onClose, duration);
            return () => clearTimeout(timer);
        }, [onClose, duration]);

        const getToastClass = () => {
            switch (type) {
                case "success":
                    return "bg-success text-white";
                case "error":
                    return "bg-danger text-white";
                case "warning":
                    return "bg-warning text-dark";
                case "info":
                    return "bg-info text-white";
                default:
                    return "bg-secondary text-white";
            }
        };

        return (
            <div
                className={`toast show position-fixed ${getToastClass()}`}
                style={{
                    top: "20px",
                    right: "20px",
                    zIndex: 9999,
                    minWidth: "300px",
                    boxShadow: "0 4px 12px rgba(0,0,0,0.15)",
                }}
            >
                <div className="toast-body d-flex justify-content-between align-items-center">
                    <span>{message}</span>
                    <button
                        type="button"
                        className="btn-close btn-close-white"
                        onClick={onClose}
                    ></button>
                </div>
            </div>
        );
    };

    return (
        <div className="shelter-panel">
            <Navbar />
            <div className="container mt-4 pb-5">
                <div className="shelter-header-card mb-4">
                    <div className="d-flex align-items-center mb-3">
                        <Users size={32} className="text-primary me-3" />
                        <div>
                            <h2 className="mb-0">Użytkownicy</h2>
                            <p className="text-muted mb-0">
                                Zarządzaj kontami użytkowników systemu
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
                        ></button>
                    </div>
                )}

                <div className="pets-section">
                    <div className="d-flex justify-content-between align-items-center mb-3">
                        <h4>Lista użytkowników</h4>
                        <div className="filter-pills">
                            <button
                                type="button"
                                className={`btn ${
                                    roleFilter === "ALL" ? "active" : ""
                                }`}
                                onClick={() => setRoleFilter("ALL")}
                            >
                                Wszyscy ({users.length})
                            </button>
                            <button
                                type="button"
                                className={`btn ${
                                    roleFilter === "ACTIVE" ? "active" : ""
                                }`}
                                onClick={() => setRoleFilter("ACTIVE")}
                            >
                                Aktywni ({users.filter((u) => u.active).length})
                            </button>
                            <button
                                type="button"
                                className={`btn ${
                                    roleFilter === "INACTIVE" ? "active" : ""
                                }`}
                                onClick={() => setRoleFilter("INACTIVE")}
                            >
                                Nieaktywni (
                                {users.filter((u) => !u.active).length})
                            </button>
                        </div>
                    </div>

                    <div className="mb-4">
                        <div className="position-relative">
                            <Search
                                size={20}
                                className="position-absolute top-50 start-0 translate-middle-y ms-3 text-muted"
                            />
                            <input
                                type="text"
                                className="pet-search-input ps-5"
                                placeholder="Szukaj użytkowników po imieniu, nazwisku, email lub telefonie..."
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                            />
                        </div>
                    </div>

                    {filteredUsers.length === 0 ? (
                        <div className="text-center py-5">
                            <Users size={48} className="text-muted mb-3" />
                            <p className="text-muted">
                                {searchTerm || roleFilter !== "ALL"
                                    ? "Nie znaleziono użytkowników spełniających kryteria wyszukiwania"
                                    : "Brak użytkowników w systemie"}
                            </p>
                        </div>
                    ) : (
                        <div className="table-responsive">
                            <table className="table table-hover">
                                <thead className="table-light">
                                    <tr>
                                        <th scope="col">Użytkownik</th>
                                        <th scope="col">Email</th>
                                        <th scope="col">Rola</th>
                                        <th scope="col">Status</th>
                                        <th scope="col">Akcje</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {filteredUsers.map((user) => (
                                        <tr key={user.userId}>
                                            <td
                                                style={{
                                                    verticalAlign: "middle",
                                                }}
                                            >
                                                <div className="d-flex align-items-center">
                                                    <div className="user-avatar me-3">
                                                        <div
                                                            className="bg-primary text-white rounded-circle d-flex align-items-center justify-content-center"
                                                            style={{
                                                                width: "40px",
                                                                height: "40px",
                                                            }}
                                                        >
                                                            {(
                                                                user
                                                                    .firstName?.[0] ||
                                                                "U"
                                                            ).toUpperCase()}
                                                        </div>
                                                    </div>
                                                    <div>
                                                        <div className="fw-bold">
                                                            {user.firstName}{" "}
                                                            {user.lastName}
                                                        </div>
                                                        {user.phoneNumber && (
                                                            <small className="text-muted">
                                                                <Phone
                                                                    size={12}
                                                                    className="me-1"
                                                                />
                                                                {
                                                                    user.phoneNumber
                                                                }
                                                            </small>
                                                        )}
                                                    </div>
                                                </div>
                                            </td>
                                            <td
                                                style={{
                                                    verticalAlign: "middle",
                                                }}
                                            >
                                                <div className="d-flex align-items-center">
                                                    <Mail
                                                        size={14}
                                                        style={{
                                                            marginRight: "8px",
                                                            color: "#6c757d",
                                                            flexShrink: 0,
                                                        }}
                                                    />
                                                    <span
                                                        style={{
                                                            maxWidth: "280px",
                                                            overflow: "hidden",
                                                            textOverflow:
                                                                "ellipsis",
                                                            whiteSpace:
                                                                "nowrap",
                                                        }}
                                                        title={user.email}
                                                    >
                                                        {user.email}
                                                    </span>
                                                </div>
                                            </td>
                                            <td
                                                style={{
                                                    verticalAlign: "middle",
                                                }}
                                            >
                                                <div
                                                    style={{
                                                        display: "flex",
                                                        alignItems: "center",
                                                        gap: "8px",
                                                    }}
                                                >
                                                    <span
                                                        style={{
                                                            fontSize: "0.9rem",
                                                            padding: "8px 0",
                                                            fontWeight: "600",
                                                            borderRadius: "6px",
                                                            display:
                                                                "inline-block",
                                                            width: "100px",
                                                            textAlign: "center",
                                                            ...getRoleBadgeClass(
                                                                getUserRole(
                                                                    user
                                                                )
                                                            ),
                                                        }}
                                                    >
                                                        {getUserRole(user)}
                                                    </span>
                                                </div>
                                            </td>
                                            <td
                                                style={{
                                                    verticalAlign: "middle",
                                                }}
                                            >
                                                <span
                                                    style={{
                                                        fontSize: "0.9rem",
                                                        padding: "8px 0",
                                                        fontWeight: "600",
                                                        borderRadius: "6px",
                                                        backgroundColor:
                                                            user.active
                                                                ? "#009f59"
                                                                : "#6c757d",
                                                        color: "white",
                                                        display: "inline-block",
                                                        textTransform:
                                                            "uppercase",
                                                        width: "110px",
                                                        textAlign: "center",
                                                    }}
                                                >
                                                    {user.active
                                                        ? "Aktywny"
                                                        : "Nieaktywny"}
                                                </span>
                                            </td>
                                            <td
                                                style={{
                                                    verticalAlign: "middle",
                                                }}
                                            >
                                                <button
                                                    style={{
                                                        backgroundColor:
                                                            "white",
                                                        color: "#007bff",
                                                        border: "1px solid #007bff",
                                                        borderRadius: "4px",
                                                        fontSize: "0.9rem",
                                                        padding:
                                                            "0.45rem 0.9rem",
                                                        fontWeight: "500",
                                                        display: "inline-flex",
                                                        alignItems: "center",
                                                        cursor: "pointer",
                                                        transition:
                                                            "all 0.15s ease-in-out",
                                                        textDecoration: "none",
                                                    }}
                                                    onClick={() =>
                                                        handleUserClick(user)
                                                    }
                                                    title="Zobacz szczegóły użytkownika"
                                                    onMouseEnter={(e) => {
                                                        e.target.style.backgroundColor =
                                                            "#007bff";
                                                        e.target.style.color =
                                                            "#ffffff";
                                                        e.target.style.boxShadow =
                                                            "0 2px 8px rgba(0, 123, 255, 0.4)";
                                                    }}
                                                    onMouseLeave={(e) => {
                                                        e.target.style.backgroundColor =
                                                            "white";
                                                        e.target.style.color =
                                                            "#007bff";
                                                        e.target.style.boxShadow =
                                                            "none";
                                                    }}
                                                >
                                                    <Eye
                                                        size={16}
                                                        style={{
                                                            marginRight:
                                                                "0.35em",
                                                        }}
                                                    />
                                                    Szczegóły
                                                </button>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>
            </div>

            {showUserModal && selectedUser && (
                <div className="custom-modal-backdrop">
                    <div
                        className="custom-modal-content"
                        style={{
                            maxWidth: "1200px",
                            width: "90vw",
                            maxHeight: "85vh",
                            minHeight: "62vh",
                            height: "auto",
                        }}
                    >
                        <div className="custom-modal-header">
                            <h4 className="d-flex align-items-center">
                                <Users size={24} className="me-2" />
                                {selectedUser.firstName} {selectedUser.lastName}
                            </h4>
                            <button
                                className="btn-close-modal"
                                onClick={handleCloseUserModal}
                            >
                                <X size={24} />
                            </button>
                        </div>

                        <div
                            className="custom-modal-body"
                            style={{
                                padding: "2rem",
                                overflowY: "auto",
                                fontSize: "1.05rem",
                                lineHeight: "1.6",
                            }}
                        >
                            <div className="mb-5">
                                <h5
                                    style={{
                                        fontSize: "1.3rem",
                                        marginBottom: "1rem",
                                    }}
                                >
                                    Statystyki aktywności
                                </h5>
                                <div
                                    className="description-box"
                                    style={{ padding: "1.5rem" }}
                                >
                                    <div className="row text-center">
                                        <div className="col-3">
                                            <div
                                                className="fw-bold text-primary"
                                                style={{ fontSize: "2rem" }}
                                            >
                                                {selectedUser.likesCount || 0}
                                            </div>
                                            <div
                                                className="text-muted"
                                                style={{
                                                    fontSize: "0.95rem",
                                                    marginTop: "0.5rem",
                                                }}
                                            >
                                                Polubionych zwierząt
                                            </div>
                                        </div>
                                        <div className="col-3">
                                            <div
                                                className="fw-bold text-success"
                                                style={{ fontSize: "2rem" }}
                                            >
                                                {selectedUser.supportCount || 0}
                                            </div>
                                            <div
                                                className="text-muted"
                                                style={{
                                                    fontSize: "0.95rem",
                                                    marginTop: "0.5rem",
                                                }}
                                            >
                                                Udzielonych wsparć
                                            </div>
                                        </div>
                                        <div className="col-3">
                                            <div
                                                className="fw-bold text-warning"
                                                style={{ fontSize: "2rem" }}
                                            >
                                                {selectedUser.badgesCount || 0}
                                            </div>
                                            <div
                                                className="text-muted"
                                                style={{
                                                    fontSize: "0.95rem",
                                                    marginTop: "0.5rem",
                                                }}
                                            >
                                                Zdobytych odznak
                                            </div>
                                        </div>
                                        <div className="col-3">
                                            <div
                                                className="fw-bold text-info"
                                                style={{ fontSize: "2rem" }}
                                            >
                                                {selectedUser.level || 1}
                                            </div>
                                            <div
                                                className="text-muted"
                                                style={{
                                                    fontSize: "0.95rem",
                                                    marginTop: "0.5rem",
                                                }}
                                            >
                                                Poziom użytkownika
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div className="row g-5">
                                <div className="col-md-6">
                                    <h5
                                        style={{
                                            fontSize: "1.3rem",
                                            marginBottom: "1rem",
                                        }}
                                    >
                                        Dane osobowe
                                    </h5>
                                    <div
                                        className="description-box"
                                        style={{
                                            padding: "1.5rem",
                                            minHeight: "260px",
                                        }}
                                    >
                                        <p style={{ marginBottom: "0.8rem" }}>
                                            <strong>Imię i nazwisko:</strong>{" "}
                                            {selectedUser.firstName}{" "}
                                            {selectedUser.lastName}
                                        </p>
                                        <p style={{ marginBottom: "0.8rem" }}>
                                            <strong>Email:</strong>{" "}
                                            {selectedUser.email}
                                        </p>
                                        <p style={{ marginBottom: "0.8rem" }}>
                                            <strong>Telefon:</strong>{" "}
                                            {selectedUser.phoneNumber || "Brak"}
                                        </p>
                                        <p style={{ marginBottom: "0.8rem" }}>
                                            <strong>Username:</strong>{" "}
                                            {selectedUser.username}
                                        </p>
                                        {selectedUser.birthDate && (
                                            <p
                                                style={{
                                                    marginBottom: "0.8rem",
                                                }}
                                            >
                                                <strong>Data urodzenia:</strong>{" "}
                                                {new Date(
                                                    selectedUser.birthDate
                                                ).toLocaleDateString("pl-PL")}
                                            </p>
                                        )}
                                        <p className="mb-0">
                                            <strong>Płeć:</strong>{" "}
                                            {selectedUser.gender ||
                                                "Nie podano"}
                                        </p>
                                    </div>
                                </div>

                                <div className="col-md-6">
                                    <h5
                                        style={{
                                            fontSize: "1.3rem",
                                            marginBottom: "1rem",
                                        }}
                                    >
                                        Status konta
                                    </h5>
                                    <div
                                        className="description-box"
                                        style={{
                                            padding: "1.5rem",
                                            minHeight: "260px",
                                        }}
                                    >
                                        <p style={{ marginBottom: "0.8rem" }}>
                                            <strong>Status:</strong>{" "}
                                            <span
                                                className={
                                                    selectedUser.active
                                                        ? "text-success fw-semibold"
                                                        : "text-danger fw-semibold"
                                                }
                                            >
                                                {selectedUser.active
                                                    ? "Aktywny"
                                                    : "Nieaktywny"}
                                            </span>
                                        </p>
                                        <p style={{ marginBottom: "0.8rem" }}>
                                            <strong>Rola:</strong>{" "}
                                            <span className="fw-semibold">
                                                {getUserRole(selectedUser)}
                                            </span>
                                        </p>
                                        <p style={{ marginBottom: "0.8rem" }}>
                                            <strong>Wolontariusz:</strong>{" "}
                                            {selectedUser.volunteerStatus ===
                                            "NONE"
                                                ? "Nie"
                                                : selectedUser.volunteerStatus}
                                        </p>
                                        <p style={{ marginBottom: "0.8rem" }}>
                                            <strong>Poziom:</strong>{" "}
                                            {selectedUser.level || 1}{" "}
                                            <span className="text-muted">
                                                (XP:{" "}
                                                {selectedUser.xpPoints || 0})
                                            </span>
                                        </p>
                                        <p style={{ marginBottom: "0.8rem" }}>
                                            <strong>Dołączył:</strong>{" "}
                                            {formatDate(selectedUser.createdAt)}
                                        </p>
                                        {!selectedUser.active &&
                                            selectedUser.deactivationReason && (
                                                <p className="mb-0">
                                                    <strong>
                                                        Powód dezaktywacji:
                                                    </strong>{" "}
                                                    <button
                                                        className="btn btn-link text-danger p-0 align-baseline"
                                                        onClick={() =>
                                                            setShowReasonModal(
                                                                true
                                                            )
                                                        }
                                                    >
                                                        Zobacz powód
                                                    </button>
                                                </p>
                                            )}
                                    </div>
                                </div>

                                {selectedUser.city && (
                                    <div className="col-12">
                                        <h5
                                            style={{
                                                fontSize: "1.3rem",
                                                marginBottom: "1rem",
                                            }}
                                        >
                                            Lokalizacja
                                        </h5>
                                        <div
                                            className="description-box"
                                            style={{ padding: "1.5rem" }}
                                        >
                                            <div className="row">
                                                <div className="col-md-4">
                                                    <p
                                                        className="mb-0"
                                                        style={{
                                                            fontSize: "1.05rem",
                                                        }}
                                                    >
                                                        <strong>Miasto:</strong>{" "}
                                                        {selectedUser.city}
                                                    </p>
                                                </div>
                                                <div className="col-md-4">
                                                    <p
                                                        className="mb-0"
                                                        style={{
                                                            fontSize: "1.05rem",
                                                        }}
                                                    >
                                                        <strong>
                                                            Dystans
                                                            wyszukiwania:
                                                        </strong>{" "}
                                                        {selectedUser.preferredSearchDistanceKm ||
                                                            20}{" "}
                                                        km
                                                    </p>
                                                </div>
                                                <div className="col-md-4">
                                                    <p
                                                        className="mb-0"
                                                        style={{
                                                            fontSize: "1.05rem",
                                                        }}
                                                    >
                                                        <strong>
                                                            Auto-lokalizacja:
                                                        </strong>{" "}
                                                        {selectedUser.autoLocationEnabled
                                                            ? "Tak"
                                                            : "Nie"}
                                                    </p>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                )}
                            </div>
                        </div>

                        <div
                            className="custom-modal-footer"
                            style={{ padding: "1.5rem 2rem" }}
                        >
                            <div className="d-flex justify-content-between w-100">
                                <div>
                                    {selectedUser.active ? (
                                        <button
                                            className="btn btn-danger btn-lg"
                                            onClick={() => {
                                                setUserToDeactivate(
                                                    selectedUser
                                                );
                                                setShowDeactivateModal(true);
                                                setShowUserModal(false);
                                            }}
                                            style={{
                                                fontSize: "1.1rem",
                                                padding: "0.55rem 1.5rem",
                                            }}
                                        >
                                            <UserX size={16} className="me-2" />
                                            Dezaktywuj użytkownika
                                        </button>
                                    ) : (
                                        <button
                                            className="btn btn-success btn-lg"
                                            onClick={() => {
                                                setUserToActivate(selectedUser);
                                                setShowActivateConfirmModal(
                                                    true
                                                );
                                                setShowUserModal(false);
                                            }}
                                            style={{
                                                fontSize: "1.1rem",
                                                padding: "0.55rem 1.5rem",
                                            }}
                                        >
                                            <UserCheck
                                                size={16}
                                                className="me-2"
                                            />
                                            Aktywuj użytkownika
                                        </button>
                                    )}
                                </div>
                                <button
                                    className="btn btn-secondary btn-lg"
                                    onClick={handleCloseUserModal}
                                    style={{
                                        fontSize: "1.1rem",
                                        padding: "0.55rem 1.5rem",
                                    }}
                                >
                                    Zamknij
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {showReasonModal &&
                selectedUser &&
                selectedUser.deactivationReason && (
                    <div className="custom-modal-backdrop">
                        <div
                            className="custom-modal-content"
                            style={{ maxWidth: "700px" }}
                        >
                            <div className="custom-modal-header">
                                <h4 className="d-flex align-items-center">
                                    <AlertCircle
                                        size={24}
                                        className="me-2 text-warning"
                                    />
                                    Powód dezaktywacji
                                </h4>
                                <button
                                    className="btn-close-modal"
                                    onClick={() => setShowReasonModal(false)}
                                >
                                    <X size={24} />
                                </button>
                            </div>
                            <div className="custom-modal-body">
                                <div className="mb-3">
                                    <strong>Użytkownik:</strong>{" "}
                                    {selectedUser.firstName}{" "}
                                    {selectedUser.lastName}
                                </div>
                                <div
                                    className="description-box"
                                    style={{ wordBreak: "break-word" }}
                                >
                                    <p className="mb-0">
                                        {selectedUser.deactivationReason}
                                    </p>
                                </div>
                            </div>
                            <div className="custom-modal-footer">
                                <button
                                    className="btn btn-secondary"
                                    onClick={() => setShowReasonModal(false)}
                                >
                                    Zamknij
                                </button>
                            </div>
                        </div>
                    </div>
                )}

            {showActivateConfirmModal && userToActivate && (
                <div className="custom-modal-backdrop">
                    <div className="custom-modal-content">
                        <div className="custom-modal-header">
                            <h4 className="d-flex align-items-center">
                                <UserCheck
                                    size={24}
                                    className="me-2 text-success"
                                />
                                Aktywuj użytkownika
                            </h4>
                            <button
                                className="btn-close-modal"
                                onClick={() => {
                                    setShowActivateConfirmModal(false);
                                    setUserToActivate(null);
                                }}
                            >
                                <X size={24} />
                            </button>
                        </div>
                        <div className="custom-modal-body">
                            <p>
                                Czy na pewno chcesz aktywować użytkownika{" "}
                                <strong>
                                    {userToActivate.firstName}{" "}
                                    {userToActivate.lastName}
                                </strong>
                                ?
                            </p>
                            {userToActivate.deactivationReason && (
                                <div
                                    className="alert alert-info"
                                    style={{ wordBreak: "break-word" }}
                                >
                                    <strong>
                                        Poprzedni powód dezaktywacji:
                                    </strong>
                                    <br />
                                    {userToActivate.deactivationReason}
                                </div>
                            )}
                            <div className="alert alert-success">
                                <strong>Uwaga:</strong> Po aktywacji użytkownik
                                będzie mógł ponownie logować się do systemu.
                            </div>
                        </div>
                        <div className="custom-modal-footer">
                            <button
                                className="btn btn-secondary me-2"
                                onClick={() => {
                                    setShowActivateConfirmModal(false);
                                    setUserToActivate(null);
                                }}
                            >
                                Anuluj
                            </button>
                            <button
                                className="btn btn-success"
                                onClick={async () => {
                                    try {
                                        const result =
                                            await userService.activateUser(
                                                userToActivate.userId
                                            );
                                        if (result.success) {
                                            loadUsers();
                                            setShowActivateConfirmModal(false);
                                            setUserToActivate(null);
                                            showToast(
                                                `Użytkownik ${userToActivate.firstName} ${userToActivate.lastName} został pomyślnie aktywowany.`,
                                                "success"
                                            );
                                        } else {
                                            setError(result.error);
                                        }
                                    } catch (error) {
                                        setError(
                                            "Błąd podczas aktywacji użytkownika"
                                        );
                                    }
                                }}
                            >
                                <UserCheck size={16} className="me-2" />
                                Aktywuj użytkownika
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {showDeactivateModal && userToDeactivate && (
                <div className="custom-modal-backdrop">
                    <div className="custom-modal-content">
                        <div className="custom-modal-header">
                            <h4 className="d-flex align-items-center">
                                <UserX size={24} className="me-2" />
                                Dezaktywuj użytkownika
                            </h4>
                            <button
                                className="btn-close-modal"
                                onClick={handleCancelDeactivation}
                            >
                                <X size={24} />
                            </button>
                        </div>
                        <div className="custom-modal-body">
                            <p>
                                Czy na pewno chcesz dezaktywować użytkownika{" "}
                                <strong>
                                    {userToDeactivate.firstName}{" "}
                                    {userToDeactivate.lastName}
                                </strong>
                                ?
                            </p>
                            <div className="mb-3">
                                <label
                                    htmlFor="deactivationReason"
                                    className="form-label"
                                >
                                    Powód dezaktywacji (opcjonalnie):
                                </label>
                                <textarea
                                    id="deactivationReason"
                                    className="form-control"
                                    rows="3"
                                    value={deactivationReason}
                                    onChange={(e) =>
                                        setDeactivationReason(e.target.value)
                                    }
                                    placeholder="Wpisz powód dezaktywacji..."
                                />
                            </div>
                            <div className="alert alert-warning">
                                <strong>Uwaga:</strong> Dezaktywowany użytkownik
                                nie będzie mógł się zalogować do systemu.
                            </div>
                        </div>
                        <div className="custom-modal-footer">
                            <button
                                className="btn btn-secondary me-2"
                                onClick={handleCancelDeactivation}
                            >
                                Anuluj
                            </button>
                            <button
                                className="btn btn-danger"
                                onClick={handleConfirmDeactivation}
                            >
                                <UserX size={16} className="me-2" />
                                Dezaktywuj użytkownika
                            </button>
                        </div>
                    </div>
                </div>
            )}
            {toast && (
                <Toast
                    message={toast.message}
                    type={toast.type}
                    onClose={hideToast}
                />
            )}
        </div>
    );
};

export default AdminUsers;
