import React, {
    useState,
    useEffect,
    useCallback,
    useMemo,
    Fragment,
} from "react";
import { useNavigate } from "react-router-dom";
import * as shelterService from "../../api/shelter";
import * as fundingService from "../../api/funding";
import Navbar from "../../components/Navbar";
import {
    ArrowLeft,
    Plus,
    Edit,
    DollarSign,
    TrendingUp,
    Calendar,
    Eye,
    Play,
    Pause,
    Users,
    MessageSquare,
} from "lucide-react";
import "./ShelterPanel.css";

const FundraiserForm = ({ fundraiser, onSubmit, onCancel, loading }) => {
    const [formData, setFormData] = useState({
        title: fundraiser?.title || "",
        description: fundraiser?.description || "",
        goalAmount: fundraiser?.goalAmount || "",
        endDate: fundraiser?.endDate ? fundraiser.endDate.split("T")[0] : "",
        category: fundraiser?.type || "MEDICAL",
        needs: fundraiser?.needs || "",
    });

    const categories = [
        { value: "MEDICAL", label: "Leczenie" },
        { value: "GENERAL", label: "Ogólne" },
        { value: "EMERGENCY", label: "Nagły przypadek" },
        { value: "INFRASTRUCTURE", label: "Infrastruktura schroniska" },
        { value: "EVENT_BASED", label: "Wydarzenie" },
    ];

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (
            !formData.title.trim() ||
            !formData.description.trim() ||
            !formData.goalAmount
        ) {
            alert("Tytuł, opis i kwota docelowa są wymagane!");
            return;
        }

        if (formData.goalAmount <= 0) {
            alert("Kwota docelowa musi być większa od 0!");
            return;
        }

        await onSubmit(formData);
    };

    return (
        <div
            className="modal fade show d-block"
            style={{ backgroundColor: "rgba(0,0,0,0.5)" }}
        >
            <div className="modal-dialog modal-lg">
                <div className="modal-content">
                    <div className="modal-header">
                        <h5 className="modal-title">
                            {fundraiser ? "Edytuj Zbiórkę" : "Nowa Zbiórka"}
                        </h5>
                        <button
                            type="button"
                            className="btn-close"
                            onClick={onCancel}
                        ></button>
                    </div>
                    <form onSubmit={handleSubmit}>
                        <div className="modal-body">
                            <div className="mb-3">
                                <label className="form-label">Tytuł *</label>
                                <input
                                    type="text"
                                    className="form-control"
                                    value={formData.title}
                                    onChange={(e) =>
                                        setFormData({
                                            ...formData,
                                            title: e.target.value,
                                        })
                                    }
                                    required
                                    placeholder="Wprowadź tytuł zbiórki"
                                    minLength={3}
                                    maxLength={200}
                                />
                                <small className="form-text text-muted"></small>
                            </div>
                            <div className="mb-3">
                                <label className="form-label">Opis *</label>
                                <textarea
                                    className="form-control"
                                    rows="4"
                                    value={formData.description}
                                    onChange={(e) =>
                                        setFormData({
                                            ...formData,
                                            description: e.target.value,
                                        })
                                    }
                                    required
                                    maxLength={2000}
                                    placeholder="Opisz cel zbiórki, potrzeby zwierząt, itp."
                                />
                                <small className="form-text text-muted">
                                    Maksymalnie 2000 znaków
                                </small>
                            </div>
                            <div className="row">
                                <div className="col-md-6">
                                    <div className="mb-3">
                                        <label className="form-label">
                                            Kwota docelowa (PLN) *
                                        </label>
                                        <input
                                            type="number"
                                            className="form-control"
                                            value={formData.goalAmount}
                                            onChange={(e) =>
                                                setFormData({
                                                    ...formData,
                                                    goalAmount: e.target.value,
                                                })
                                            }
                                            min="1"
                                            step="0.01"
                                            required
                                        />
                                    </div>
                                </div>
                                <div className="col-md-6">
                                    <div className="mb-3">
                                        <label className="form-label">
                                            Kategoria *
                                        </label>
                                        <select
                                            className="form-select"
                                            value={formData.category}
                                            onChange={(e) =>
                                                setFormData({
                                                    ...formData,
                                                    category: e.target.value,
                                                })
                                            }
                                            required
                                        >
                                            {categories.map((cat) => (
                                                <option
                                                    key={cat.value}
                                                    value={cat.value}
                                                >
                                                    {cat.label}
                                                </option>
                                            ))}
                                        </select>
                                    </div>
                                </div>
                            </div>
                            <div className="mb-3">
                                <label className="form-label">
                                    Szczegółowe potrzeby
                                </label>
                                <textarea
                                    className="form-control"
                                    rows="3"
                                    value={formData.needs}
                                    onChange={(e) =>
                                        setFormData({
                                            ...formData,
                                            needs: e.target.value,
                                        })
                                    }
                                    maxLength={1000}
                                    placeholder="Opisz szczegółowo na co będą przeznaczone środki..."
                                />
                                <small className="form-text text-muted">
                                    Maksymalnie 1000 znaków (opcjonalne)
                                </small>
                            </div>
                            <div className="mb-3">
                                <label className="form-label">
                                    Data zakończenia
                                </label>
                                <input
                                    type="date"
                                    className="form-control"
                                    value={formData.endDate}
                                    onChange={(e) =>
                                        setFormData({
                                            ...formData,
                                            endDate: e.target.value,
                                        })
                                    }
                                    min={new Date().toISOString().split("T")[0]}
                                />
                                <small className="form-text text-muted">
                                    Pozostaw puste dla zbiórki bez określonej
                                    daty końcowej
                                </small>
                            </div>
                        </div>
                        <div className="modal-footer">
                            <button
                                type="button"
                                className="btn btn-secondary"
                                onClick={onCancel}
                                disabled={loading}
                            >
                                Anuluj
                            </button>
                            <button
                                type="submit"
                                className="btn btn-primary"
                                disabled={loading}
                            >
                                {loading ? "Zapisywanie..." : "Zapisz"}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
};

const DonationsModal = ({
    fundraiser,
    donations,
    onClose,
    onLoadMore,
    hasMore,
    loading,
}) => {
    const formatDonorName = (donation) => {
        if (donation.anonymous) {
            return "Anonimowy darczyńca";
        }

        if (!donation.donorUsername) {
            return "Nieznany użytkownik";
        }

        if (donation.donorUsername.includes("@")) {
            const emailPart = donation.donorUsername.split("@")[0];
            return emailPart.charAt(0).toUpperCase() + emailPart.slice(1);
        }

        return (
            donation.donorUsername.charAt(0).toUpperCase() +
            donation.donorUsername.slice(1)
        );
    };

    return (
        <div
            className="modal fade show d-block"
            style={{ backgroundColor: "rgba(0,0,0,0.5)" }}
        >
            <div className="modal-dialog modal-lg">
                <div className="modal-content">
                    <div className="modal-header">
                        <h5 className="modal-title">
                            Dotacje dla: {fundraiser.title}
                        </h5>
                        <button
                            type="button"
                            className="btn-close"
                            onClick={onClose}
                        ></button>
                    </div>
                    <div className="modal-body">
                        {donations.length === 0 ? (
                            <p className="text-muted text-center">
                                Brak ukończonych dotacji dla tej zbiórki.
                            </p>
                        ) : (
                            <>
                                <div className="table-responsive">
                                    <table className="table table-hover">
                                        <thead>
                                            <tr>
                                                <th>Darczyńca</th>
                                                <th>Kwota</th>
                                                <th>Data</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {donations.map((donation) => (
                                                <tr key={donation.id}>
                                                    <td>
                                                        {formatDonorName(
                                                            donation
                                                        )}
                                                    </td>
                                                    <td>
                                                        <strong className="text-success">
                                                            {donation.amount?.toFixed(
                                                                2
                                                            ) || "0.00"}{" "}
                                                            PLN
                                                        </strong>
                                                    </td>
                                                    <td>
                                                        <small className="text-muted">
                                                            {donation.donatedAt ||
                                                            donation.createdAt
                                                                ? new Date(
                                                                      donation.donatedAt ||
                                                                          donation.createdAt
                                                                  ).toLocaleDateString(
                                                                      "pl-PL"
                                                                  )
                                                                : "Brak daty"}
                                                        </small>
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>
                                {hasMore && (
                                    <div className="text-center mt-3">
                                        <button
                                            className="btn btn-outline-primary"
                                            onClick={onLoadMore}
                                            disabled={loading}
                                        >
                                            {loading
                                                ? "Ładowanie..."
                                                : "Załaduj więcej"}
                                        </button>
                                    </div>
                                )}
                            </>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};

const ShelterFunding = () => {
    const navigate = useNavigate();

    const [shelter, setShelter] = useState(null);
    const [fundraisers, setFundraisers] = useState([]);
    const [donations, setDonations] = useState([]);
    const [statistics, setStatistics] = useState(null);
    const [loading, setLoading] = useState(true);
    const [actionLoading, setActionLoading] = useState(false);
    const [error, setError] = useState("");
    const [success, setSuccess] = useState("");
    const [searchTerm, setSearchTerm] = useState("");
    const [statusFilter, setStatusFilter] = useState("active");
    const [activeView, setActiveView] = useState("fundraisers");

    const [donationSearchTerm, setDonationSearchTerm] = useState("");
    const [donationFilter, setDonationFilter] = useState("recent");

    const [showFundraiserForm, setShowFundraiserForm] = useState(false);
    const [showDonations, setShowDonations] = useState(false);
    const [editingFundraiser, setEditingFundraiser] = useState(null);
    const [selectedFundraiser, setSelectedFundraiser] = useState(null);
    const [fundraiserDonations, setFundraiserDonations] = useState([]);
    const [hasMoreDonations, setHasMoreDonations] = useState(false);
    const [donationsPage, setDonationsPage] = useState(0);

    const [donationsCurrentPage, setDonationsCurrentPage] = useState(0);
    const [hasMoreMainDonations, setHasMoreMainDonations] = useState(false);
    const donationsPerPage = 20;

    const acceptedDonations = useMemo(() => {
        return (
            donations.filter((donation) => donation.status === "COMPLETED") ||
            []
        );
    }, [donations]);

    const formatDonorName = useCallback((donation) => {
        if (donation.anonymous) {
            return "Anonimowy darczyńca";
        }

        if (!donation.donorUsername) {
            return "Nieznany użytkownik";
        }

        if (donation.donorUsername.includes("@")) {
            const emailPart = donation.donorUsername.split("@")[0];
            return emailPart.charAt(0).toUpperCase() + emailPart.slice(1);
        }

        return (
            donation.donorUsername.charAt(0).toUpperCase() +
            donation.donorUsername.slice(1)
        );
    }, []);

    const getFundraiserStatus = useCallback((fundraiser) => {
        if (!fundraiser)
            return { status: "unknown", label: "Nieznany", color: "secondary" };

        if (fundraiser.endDate && new Date(fundraiser.endDate) < new Date()) {
            return { status: "expired", label: "Wygasła", color: "danger" };
        }

        if (fundraiser.currentAmount >= fundraiser.goalAmount) {
            return {
                status: "completed",
                label: "Cel osiągnięty",
                color: "success",
            };
        }

        switch (fundraiser.status) {
            case "ACTIVE":
                return { status: "active", label: "Aktywna", color: "primary" };
            case "COMPLETED":
                return {
                    status: "completed",
                    label: "Zakończona",
                    color: "success",
                };
            case "CANCELLED":
                return {
                    status: "cancelled",
                    label: "Anulowana",
                    color: "danger",
                };
            case "PAUSED":
                return {
                    status: "paused",
                    label: "Wstrzymana",
                    color: "warning",
                };
            case "DRAFT":
                return { status: "draft", label: "Szkic", color: "secondary" };
            default:
                return {
                    status: "unknown",
                    label: "Nieznany",
                    color: "secondary",
                };
        }
    }, []);

    const loadData = useCallback(async () => {
        setLoading(true);
        setError("");
        try {
            const shelterResult = await shelterService.getMyShelter();
            if (!shelterResult.success || !shelterResult.data) {
                setError("Nie udało się pobrać danych schroniska.");
                return;
            }
            setShelter(shelterResult.data);
            const shelterId = shelterResult.data.id;

            const [fundraisersResult, statsResult] = await Promise.all([
                fundingService.getShelterFundraisers(shelterId),
                fundingService.getDashboardData(shelterId),
            ]);

            if (fundraisersResult.success) {
                setFundraisers(fundraisersResult.data);
            } else {
            }

            if (statsResult.success) {
                setStatistics(statsResult.data);
            } else {
            }

            let allDonations = [];
            let currentPage = 0;
            let hasMore = true;

            while (hasMore && currentPage < 10) {
                const donationsResult =
                    await fundingService.getShelterDonations(
                        shelterId,
                        currentPage,
                        40
                    );

                if (donationsResult.success) {
                    const pageDonations =
                        donationsResult.data.content || donationsResult.data;
                    allDonations = [...allDonations, ...pageDonations];
                    hasMore = donationsResult.data.hasNext || false;
                    currentPage++;
                } else {
                    break;
                }
            }

            setDonations(allDonations);
            setHasMoreMainDonations(false);
            setDonationsCurrentPage(0);
        } catch (err) {
            setError("Wystąpił błąd podczas ładowania danych.");
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        loadData();
    }, [loadData]);

    const showSuccessMessage = (message) => {
        setSuccess(message);
        setTimeout(() => setSuccess(""), 4000);
    };

    const showErrorMessage = (message) => {
        setError(message);
        setTimeout(() => setError(""), 4000);
    };

    const handleLoadMoreMainDonations = async () => {
        if (!hasMoreMainDonations || !shelter || actionLoading) return;

        setActionLoading(true);
        try {
            const nextPage = donationsCurrentPage + 1;
            const result = await fundingService.getShelterDonations(
                shelter.id,
                nextPage,
                donationsPerPage
            );

            if (result.success) {
                const newDonations = result.data.content || result.data;

                setDonations((prev) => [...prev, ...newDonations]);
                setHasMoreMainDonations(result.data.hasNext || false);
                setDonationsCurrentPage(nextPage);
            } else {
                showErrorMessage(result.error);
            }
        } catch (err) {
            showErrorMessage(
                "Wystąpił błąd podczas ładowania kolejnych dotacji."
            );
        } finally {
            setActionLoading(false);
        }
    };

    const handleCreateFundraiser = async (fundraiserData) => {
        setActionLoading(true);
        try {
            const result = await fundingService.createFundraiser(
                shelter.id,
                fundraiserData
            );
            if (result.success) {
                setFundraisers((prev) => [result.data, ...prev]);
                setShowFundraiserForm(false);
                showSuccessMessage("Zbiórka została utworzona pomyślnie!");
                const statsResult = await fundingService.getDashboardData(
                    shelter.id
                );
                if (statsResult.success) {
                    setStatistics(statsResult.data);
                }
            } else {
                showErrorMessage(result.error);
            }
        } catch (err) {
            showErrorMessage("Wystąpił błąd podczas tworzenia zbiórki.");
        } finally {
            setActionLoading(false);
        }
    };

    const handleUpdateFundraiser = async (fundraiserData) => {
        setActionLoading(true);
        try {
            const dataWithShelterId = {
                ...fundraiserData,
                shelterId: shelter.id,
                isMain: editingFundraiser.isMain || false,
            };

            const result = await fundingService.updateFundraiser(
                editingFundraiser.id,
                dataWithShelterId
            );

            if (result.success) {
                setFundraisers((prev) => {
                    return prev.map((f) => {
                        if (f.id === editingFundraiser.id) {
                            return {
                                ...f,
                                ...result.data,
                                id: f.id,
                                lastUpdated: Date.now(),
                            };
                        }
                        return { ...f };
                    });
                });

                setShowFundraiserForm(false);
                setEditingFundraiser(null);
                showSuccessMessage("Zbiórka została zaktualizowana!");

                setTimeout(async () => {
                    const refreshResult =
                        await fundingService.getShelterFundraisers(shelter.id);
                    if (refreshResult.success) {
                        setFundraisers(refreshResult.data);
                    }
                }, 100);
            } else {
                showErrorMessage(result.error);
            }
        } catch (err) {
            console.error("Error updating fundraiser:", err);
            showErrorMessage("Wystąpił błąd podczas aktualizacji zbiórki.");
        } finally {
            setActionLoading(false);
        }
    };

    const handleToggleFundraiserStatus = async (fundraiserId, activate) => {
        try {
            const result = await fundingService.toggleFundraiserStatus(
                fundraiserId,
                activate
            );
            if (result.success) {
                setFundraisers((prev) =>
                    prev.map((f) =>
                        f.id === fundraiserId
                            ? { ...f, status: activate ? "ACTIVE" : "PAUSED" }
                            : f
                    )
                );
                showSuccessMessage(
                    `Zbiórka została ${activate ? "aktywowana" : "wstrzymana"}.`
                );
            } else {
                showErrorMessage(result.error);
            }
        } catch (err) {
            showErrorMessage("Wystąpił błąd podczas zmiany statusu zbiórki.");
        }
    };

    const handleViewDonations = async (fundraiser) => {
        setSelectedFundraiser(fundraiser);
        setDonationsPage(0);
        try {
            const result = await fundingService.getFundraiserDonations(
                fundraiser.id,
                0,
                20
            );
            if (result.success) {
                const allDonations = result.data.content || result.data;

                const completedDonations = allDonations.filter(
                    (donation) => donation.status === "COMPLETED"
                );

                setFundraiserDonations(completedDonations);
                setHasMoreDonations(result.data.hasNext || false);
                setShowDonations(true);
            } else {
                showErrorMessage(result.error);
            }
        } catch (err) {
            showErrorMessage("Wystąpił błąd podczas ładowania dotacji.");
        }
    };

    const handleLoadMoreDonations = async () => {
        const nextPage = donationsPage + 1;
        try {
            const result = await fundingService.getFundraiserDonations(
                selectedFundraiser.id,
                nextPage,
                20
            );
            if (result.success) {
                const allDonations = result.data.content || result.data;

                const completedDonations = allDonations.filter(
                    (donation) => donation.status === "COMPLETED"
                );

                setFundraiserDonations((prev) => [
                    ...prev,
                    ...completedDonations,
                ]);
                setHasMoreDonations(result.data.hasNext || false);
                setDonationsPage(nextPage);
            } else {
                showErrorMessage(result.error);
            }
        } catch (err) {
            showErrorMessage(
                "Wystąpił błąd podczas ładowania kolejnych dotacji."
            );
        }
    };

    const openFundraiserForm = (fundraiser = null) => {
        setEditingFundraiser(fundraiser);
        setShowFundraiserForm(true);
    };

    const closeModals = () => {
        setShowFundraiserForm(false);
        setShowDonations(false);
        setEditingFundraiser(null);
        setSelectedFundraiser(null);
        setFundraiserDonations([]);
    };

    const filteredFundraisers = useMemo(() => {
        return fundraisers.filter((fundraiser) => {
            const matchesSearch = fundraiser.title
                .toLowerCase()
                .includes(searchTerm.toLowerCase());

            if (!matchesSearch) return false;

            if (statusFilter === "all") return true;

            const status = getFundraiserStatus(fundraiser);
            return status.status === statusFilter;
        });
    }, [fundraisers, searchTerm, statusFilter, getFundraiserStatus]);

    const filteredDonations = useMemo(() => {
        if (!donations) return [];

        let filtered = donations.filter((donation) => {
            if (donation.status !== "COMPLETED") return false;

            if (donationSearchTerm) {
                const searchLower = donationSearchTerm.toLowerCase();
                const matchesDonor = formatDonorName(donation)
                    .toLowerCase()
                    .includes(searchLower);
                const matchesFundraiser = donation.fundraiserTitle
                    ?.toLowerCase()
                    .includes(searchLower);
                return matchesDonor || matchesFundraiser;
            }

            return true;
        });

        switch (donationFilter) {
            case "amount_desc":
                filtered.sort((a, b) => (b.amount || 0) - (a.amount || 0));
                break;
            case "amount_asc":
                filtered.sort((a, b) => (a.amount || 0) - (b.amount || 0));
                break;
            case "oldest":
                filtered.sort(
                    (a, b) => new Date(a.createdAt) - new Date(b.createdAt)
                );
                break;
            case "recent":
            default:
                filtered.sort(
                    (a, b) => new Date(b.createdAt) - new Date(a.createdAt)
                );
                break;
        }

        return filtered;
    }, [donations, donationSearchTerm, donationFilter, formatDonorName]);

    const handleBack = () => {
        navigate("/shelter-panel");
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
                <div className="shelter-header-card mb-4">
                    <div className="d-flex align-items-center mb-3">
                        <DollarSign size={32} className="text-primary me-3" />
                        <div>
                            <h2 className="mb-1 shelter-name-title">
                                Zarządzanie Finansami
                            </h2>
                            <p className="text-muted mb-0">
                                Monitoruj dotacje oraz twórz zbiórki dla twojego
                                schroniska
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

                    {error && (
                        <div className="alert alert-danger" role="alert">
                            {error}
                        </div>
                    )}
                    {success && (
                        <div className="alert alert-success" role="alert">
                            {success}
                        </div>
                    )}
                </div>

                {statistics && (
                    <div className="row mb-4 g-3">
                        <div className="col-xl-3 col-md-6">
                            <div className="stat-card h-100">
                                <div className="stat-value">
                                    {statistics.activeFundraisers || 0}
                                </div>
                                <div className="stat-label">
                                    Aktywne Zbiórki
                                </div>
                            </div>
                        </div>
                        <div className="col-xl-3 col-md-6">
                            <div className="stat-card h-100">
                                <div className="stat-value">
                                    {(statistics.totalAmount || 0).toFixed(2)}{" "}
                                    PLN
                                </div>
                                <div className="stat-label">
                                    Zebrano Łącznie
                                </div>
                            </div>
                        </div>
                        <div className="col-xl-3 col-md-6">
                            <div className="stat-card h-100">
                                <div className="stat-value">
                                    {acceptedDonations?.length || 0}
                                </div>
                                <div className="stat-label">
                                    Ukończone Dotacje
                                </div>
                            </div>
                        </div>
                        <div className="col-xl-3 col-md-6">
                            <div className="stat-card h-100">
                                <div className="stat-value">
                                    {(statistics.averageProgress || 0).toFixed(
                                        1
                                    )}
                                    %
                                </div>
                                <div className="stat-label">Średni Postęp</div>
                            </div>
                        </div>
                    </div>
                )}

                <div className="d-flex justify-content-between align-items-center mb-3">
                    <h4 className="mb-0">Zarządzanie Funduszami</h4>
                    <div className="mb-1 filter-pills">
                        <button
                            type="button"
                            className={`btn ${
                                activeView === "fundraisers" ? "active" : ""
                            }`}
                            onClick={() => setActiveView("fundraisers")}
                        >
                            Zbiórki ({fundraisers?.length || 0})
                        </button>
                        <button
                            type="button"
                            className={`btn ${
                                activeView === "donations" ? "active" : ""
                            }`}
                            onClick={() => setActiveView("donations")}
                        >
                            Dotacje ({acceptedDonations?.length || 0})
                        </button>
                    </div>
                </div>

                {activeView === "fundraisers" ? (
                    <div className="card border-0 shadow-sm mb-4">
                        <div className="card-header bg-white border-bottom-0 pt-4 pb-3">
                            <h4 className="mb-3">Zbiórki</h4>

                            <div className="d-flex gap-3 mb-3">
                                <div className="flex-grow-1">
                                    <input
                                        type="text"
                                        className="form-control pet-search-input"
                                        placeholder="Szukaj zbiórek..."
                                        value={searchTerm}
                                        onChange={(e) =>
                                            setSearchTerm(e.target.value)
                                        }
                                    />
                                </div>
                                <div className="flex-shrink-0">
                                    <button
                                        className="btn btn-add-fundraiser"
                                        onClick={() => openFundraiserForm()}
                                    >
                                        Dodaj Zbiórkę
                                    </button>
                                </div>
                            </div>

                            {fundraisers.length > 0 && (
                                <div className="filter-pills mb-3">
                                    <button
                                        type="button"
                                        className={`btn ${
                                            statusFilter === "active"
                                                ? "active"
                                                : ""
                                        }`}
                                        onClick={() =>
                                            setStatusFilter("active")
                                        }
                                    >
                                        Aktywne (
                                        {
                                            fundraisers.filter(
                                                (f) =>
                                                    getFundraiserStatus(f)
                                                        .status === "active"
                                            ).length
                                        }
                                        )
                                    </button>
                                    <button
                                        type="button"
                                        className={`btn ${
                                            statusFilter === "completed"
                                                ? "active"
                                                : ""
                                        }`}
                                        onClick={() =>
                                            setStatusFilter("completed")
                                        }
                                    >
                                        Zakończone (
                                        {
                                            fundraisers.filter(
                                                (f) =>
                                                    getFundraiserStatus(f)
                                                        .status === "completed"
                                            ).length
                                        }
                                        )
                                    </button>
                                    <button
                                        type="button"
                                        className={`btn ${
                                            statusFilter === "paused"
                                                ? "active"
                                                : ""
                                        }`}
                                        onClick={() =>
                                            setStatusFilter("paused")
                                        }
                                    >
                                        Wstrzymane (
                                        {
                                            fundraisers.filter(
                                                (f) =>
                                                    getFundraiserStatus(f)
                                                        .status === "paused"
                                            ).length
                                        }
                                        )
                                    </button>
                                    <button
                                        type="button"
                                        className={`btn ${
                                            statusFilter === "cancelled"
                                                ? "active"
                                                : ""
                                        }`}
                                        onClick={() =>
                                            setStatusFilter("cancelled")
                                        }
                                    >
                                        Anulowane (
                                        {
                                            fundraisers.filter(
                                                (f) =>
                                                    getFundraiserStatus(f)
                                                        .status === "cancelled"
                                            ).length
                                        }
                                        )
                                    </button>
                                    <button
                                        type="button"
                                        className={`btn ${
                                            statusFilter === "expired"
                                                ? "active"
                                                : ""
                                        }`}
                                        onClick={() =>
                                            setStatusFilter("expired")
                                        }
                                    >
                                        Wygasłe (
                                        {
                                            fundraisers.filter(
                                                (f) =>
                                                    getFundraiserStatus(f)
                                                        .status === "expired"
                                            ).length
                                        }
                                        )
                                    </button>
                                    <button
                                        type="button"
                                        className={`btn ${
                                            statusFilter === "all"
                                                ? "active"
                                                : ""
                                        }`}
                                        onClick={() => setStatusFilter("all")}
                                    >
                                        Wszystkie ({fundraisers.length})
                                    </button>
                                </div>
                            )}
                        </div>
                        <div className="card-body">
                            {filteredFundraisers.length === 0 ? (
                                <div className="text-center py-5">
                                    <DollarSign
                                        size={48}
                                        className="text-muted mb-3"
                                    />
                                    {fundraisers.length === 0 ? (
                                        <>
                                            <h5 className="text-muted">
                                                Brak zbiórek
                                            </h5>
                                            <p className="text-muted mb-3">
                                                Utwórz pierwszą zbiórkę dla
                                                swojego schroniska
                                            </p>
                                        </>
                                    ) : (
                                        <>
                                            <h5 className="text-muted">
                                                {searchTerm
                                                    ? "Nie znaleziono zbiórek"
                                                    : "Brak zbiórek w tym filtrze"}
                                            </h5>
                                            <p className="text-muted mb-0">
                                                {searchTerm
                                                    ? `Nie znaleziono zbiórek pasujących do "${searchTerm}"`
                                                    : `Brak zbiórek o takim statusie`}
                                            </p>
                                        </>
                                    )}
                                </div>
                            ) : (
                                <div className="fundraisers-list">
                                    {filteredFundraisers.map((fundraiser) => {
                                        const status =
                                            getFundraiserStatus(fundraiser);
                                        const progress =
                                            fundraiser.goalAmount > 0
                                                ? (fundraiser.currentAmount /
                                                      fundraiser.goalAmount) *
                                                  100
                                                : 0;

                                        return (
                                            <div
                                                key={fundraiser.id}
                                                className="fundraiser-row"
                                            >
                                                <div className="fundraiser-card h-100">
                                                    <div className="fundraiser-card-header">
                                                        <div className="d-flex justify-content-between align-items-center">
                                                            <div className="d-flex align-items-center gap-2">
                                                                <h5 className="fundraiser-title">
                                                                    {
                                                                        fundraiser.title
                                                                    }
                                                                </h5>
                                                            </div>
                                                            <div className="d-flex align-items-center gap-2">
                                                                <span className="fundraiser-category">
                                                                    {fundraiser.type ===
                                                                        "MEDICAL" &&
                                                                        "Leczenie"}
                                                                    {fundraiser.type ===
                                                                        "GENERAL" &&
                                                                        "Ogólne"}
                                                                    {fundraiser.type ===
                                                                        "EMERGENCY" &&
                                                                        "Nagły przypadek"}
                                                                    {fundraiser.type ===
                                                                        "INFRASTRUCTURE" &&
                                                                        "Infrastruktura"}
                                                                    {fundraiser.type ===
                                                                        "EVENT_BASED" &&
                                                                        "Wydarzenie"}
                                                                    {![
                                                                        "MEDICAL",
                                                                        "GENERAL",
                                                                        "EMERGENCY",
                                                                        "INFRASTRUCTURE",
                                                                        "EVENT_BASED",
                                                                    ].includes(
                                                                        fundraiser.type
                                                                    ) &&
                                                                        fundraiser.type}
                                                                </span>
                                                                <span
                                                                    className={`badge fundraiser-status bg-${status.color}`}
                                                                >
                                                                    {
                                                                        status.label
                                                                    }
                                                                </span>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className="fundraiser-card-body">
                                                        <div className="fundraiser-content-layout">
                                                            <div className="fundraiser-main-content">
                                                                <p className="fundraiser-description">
                                                                    {
                                                                        fundraiser.description
                                                                    }
                                                                </p>

                                                                {fundraiser.needs && (
                                                                    <div className="fundraiser-needs-section">
                                                                        <h6 className="fundraiser-needs-title">
                                                                            Szczegółowe
                                                                            potrzeby:
                                                                        </h6>
                                                                        <p className="fundraiser-needs">
                                                                            {
                                                                                fundraiser.needs
                                                                            }
                                                                        </p>
                                                                    </div>
                                                                )}

                                                                <div className="mb-3">
                                                                    <div className="d-flex justify-content-between mb-2">
                                                                        <span className="progress-label">
                                                                            Postęp
                                                                        </span>
                                                                        <span className="progress-percentage">
                                                                            {progress.toFixed(
                                                                                1
                                                                            )}
                                                                            %
                                                                        </span>
                                                                    </div>
                                                                    <div className="progress fundraiser-progress">
                                                                        <div
                                                                            className="progress-bar bg-success"
                                                                            style={{
                                                                                width: `${Math.min(
                                                                                    progress,
                                                                                    100
                                                                                )}%`,
                                                                            }}
                                                                        ></div>
                                                                    </div>
                                                                </div>

                                                                <div className="row text-center">
                                                                    <div className="col-6">
                                                                        <div className="amount-raised">
                                                                            {fundraiser.currentAmount?.toFixed(
                                                                                2
                                                                            ) ||
                                                                                "0.00"}{" "}
                                                                            PLN
                                                                        </div>
                                                                        <div className="amount-label">
                                                                            Zebrano
                                                                        </div>
                                                                    </div>
                                                                    <div className="col-6">
                                                                        <div className="amount-goal">
                                                                            {fundraiser.goalAmount?.toFixed(
                                                                                2
                                                                            ) ||
                                                                                "0.00"}{" "}
                                                                            PLN
                                                                        </div>
                                                                        <div className="amount-label">
                                                                            Cel
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            </div>

                                                            <div className="fundraiser-sidebar">
                                                                <div className="fundraiser-mini-dashboard">
                                                                    <h6 className="dashboard-title">
                                                                        Statystyki
                                                                    </h6>

                                                                    <div className="dashboard-stats">
                                                                        <div className="dashboard-stat">
                                                                            <div className="stat-icon">
                                                                                <Users
                                                                                    size={
                                                                                        18
                                                                                    }
                                                                                />
                                                                            </div>
                                                                            <div className="stat-content">
                                                                                <div className="stat-number">
                                                                                    {fundraiser.donationCount ||
                                                                                        0}
                                                                                </div>
                                                                                <div className="stat-label">
                                                                                    Dotacji
                                                                                </div>
                                                                            </div>
                                                                        </div>

                                                                        <div className="dashboard-stat">
                                                                            <div className="stat-icon">
                                                                                <TrendingUp
                                                                                    size={
                                                                                        18
                                                                                    }
                                                                                />
                                                                            </div>
                                                                            <div className="stat-content">
                                                                                <div className="stat-number">
                                                                                    {fundraiser.donationCount >
                                                                                    0
                                                                                        ? (
                                                                                              fundraiser.currentAmount /
                                                                                              fundraiser.donationCount
                                                                                          ).toFixed(
                                                                                              0
                                                                                          )
                                                                                        : "0"}{" "}
                                                                                    PLN
                                                                                </div>
                                                                                <div className="stat-label">
                                                                                    Średnia
                                                                                </div>
                                                                            </div>
                                                                        </div>

                                                                        {fundraiser.endDate && (
                                                                            <div className="dashboard-stat">
                                                                                <div className="stat-icon">
                                                                                    <Calendar
                                                                                        size={
                                                                                            18
                                                                                        }
                                                                                    />
                                                                                </div>
                                                                                <div className="stat-content">
                                                                                    <div className="stat-number">
                                                                                        {Math.max(
                                                                                            0,
                                                                                            Math.ceil(
                                                                                                (new Date(
                                                                                                    fundraiser.endDate
                                                                                                ) -
                                                                                                    new Date()) /
                                                                                                    (1000 *
                                                                                                        60 *
                                                                                                        60 *
                                                                                                        24)
                                                                                            )
                                                                                        )}
                                                                                    </div>
                                                                                    <div className="stat-label">
                                                                                        Dni
                                                                                        zostało
                                                                                    </div>
                                                                                </div>
                                                                            </div>
                                                                        )}
                                                                    </div>
                                                                </div>

                                                                <div className="d-flex flex-column gap-2">
                                                                    <button
                                                                        className="btn btn-outline-primary fundraiser-action-btn"
                                                                        onClick={() =>
                                                                            openFundraiserForm(
                                                                                fundraiser
                                                                            )
                                                                        }
                                                                    >
                                                                        <Edit
                                                                            size={
                                                                                16
                                                                            }
                                                                            className="me-2"
                                                                        />
                                                                        Edytuj
                                                                    </button>
                                                                    <button
                                                                        className="btn btn-outline-info fundraiser-action-btn"
                                                                        onClick={() =>
                                                                            handleViewDonations(
                                                                                fundraiser
                                                                            )
                                                                        }
                                                                    >
                                                                        <Eye
                                                                            size={
                                                                                16
                                                                            }
                                                                            className="me-2"
                                                                        />
                                                                        Dotacje
                                                                    </button>

                                                                    {status.status ===
                                                                        "active" && (
                                                                        <button
                                                                            className="btn btn-outline-danger fundraiser-action-btn"
                                                                            onClick={() =>
                                                                                handleToggleFundraiserStatus(
                                                                                    fundraiser.id,
                                                                                    false
                                                                                )
                                                                            }
                                                                        >
                                                                            <Pause
                                                                                size={
                                                                                    16
                                                                                }
                                                                                className="me-2"
                                                                            />
                                                                            Wstrzymaj
                                                                        </button>
                                                                    )}

                                                                    {status.status ===
                                                                        "paused" && (
                                                                        <button
                                                                            className="btn btn-outline-success fundraiser-action-btn"
                                                                            onClick={() =>
                                                                                handleToggleFundraiserStatus(
                                                                                    fundraiser.id,
                                                                                    true
                                                                                )
                                                                            }
                                                                        >
                                                                            <Play
                                                                                size={
                                                                                    16
                                                                                }
                                                                                className="me-2"
                                                                            />
                                                                            Aktywuj
                                                                        </button>
                                                                    )}
                                                                </div>
                                                            </div>
                                                        </div>

                                                        {fundraiser.endDate && (
                                                            <div className="fundraiser-footer">
                                                                <div className="fundraiser-date">
                                                                    <Calendar
                                                                        size={
                                                                            16
                                                                        }
                                                                        className="me-2"
                                                                    />
                                                                    Kończy się:{" "}
                                                                    {new Date(
                                                                        fundraiser.endDate
                                                                    ).toLocaleDateString(
                                                                        "pl-PL"
                                                                    )}
                                                                </div>
                                                            </div>
                                                        )}
                                                    </div>
                                                </div>
                                            </div>
                                        );
                                    })}
                                </div>
                            )}
                        </div>
                    </div>
                ) : (
                    <div className="card border-0 shadow-sm mb-4">
                        <div className="card-header bg-white border-bottom-0 pt-4 pb-3">
                            <h4 className="mb-3">Ostatnie Dotacje</h4>

                            <div className="d-flex gap-3 mb-3">
                                <div className="flex-grow-1">
                                    <input
                                        type="text"
                                        className="form-control pet-search-input"
                                        placeholder="Szukaj dotacji (darczyńca, zbiórka)..."
                                        value={donationSearchTerm}
                                        onChange={(e) =>
                                            setDonationSearchTerm(
                                                e.target.value
                                            )
                                        }
                                    />
                                </div>
                                <div
                                    className="flex-shrink-0"
                                    style={{ minWidth: "200px" }}
                                >
                                    <select
                                        className="form-select pet-search-input"
                                        value={donationFilter}
                                        onChange={(e) =>
                                            setDonationFilter(e.target.value)
                                        }
                                        style={{
                                            height: "100%",
                                            minHeight: "48px",
                                        }}
                                    >
                                        <option value="recent">
                                            Najnowsze
                                        </option>
                                        <option value="oldest">
                                            Najstarsze
                                        </option>
                                        <option value="amount_desc">
                                            Najwyższe kwoty
                                        </option>
                                        <option value="amount_asc">
                                            Najniższe kwoty
                                        </option>
                                    </select>
                                </div>
                            </div>
                        </div>
                        <div className="card-body">
                            {filteredDonations.length === 0 ? (
                                <div className="text-center py-5">
                                    <DollarSign
                                        size={48}
                                        className="text-muted mb-3"
                                    />
                                    <h5 className="text-muted">
                                        {donationSearchTerm
                                            ? "Nie znaleziono dotacji"
                                            : "Brak ukończonych dotacji"}
                                    </h5>
                                    <p className="text-muted mb-0">
                                        {donationSearchTerm
                                            ? "Spróbuj zmienić kryteria wyszukiwania"
                                            : "Ukończone dotacje będą wyświetlane tutaj po pierwszych wpłatach"}
                                    </p>
                                </div>
                            ) : (
                                <>
                                    <div className="mb-3">
                                        <small className="text-muted">
                                            Wyświetlono{" "}
                                            {filteredDonations.length} z{" "}
                                            {acceptedDonations.length}{" "}
                                            ukończonych dotacji
                                            {donationSearchTerm &&
                                                ` dla: "${donationSearchTerm}"`}
                                        </small>
                                    </div>
                                    <div className="table-responsive">
                                        <table className="table table-hover">
                                            <thead className="table-light">
                                                <tr>
                                                    <th scope="col">
                                                        Darczyńca
                                                    </th>
                                                    <th scope="col">Zbiórka</th>
                                                    <th scope="col">
                                                        Przedmiot
                                                    </th>
                                                    <th scope="col">Kwota</th>
                                                    <th scope="col">Data</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {filteredDonations.map(
                                                    (donation) => (
                                                        <React.Fragment
                                                            key={donation.id}
                                                        >
                                                            <tr>
                                                                <td
                                                                    style={{
                                                                        verticalAlign:
                                                                            "middle",
                                                                    }}
                                                                >
                                                                    <div className="d-flex align-items-center">
                                                                        <div className="donor-avatar me-3">
                                                                            <div
                                                                                className="bg-primary text-white rounded-circle d-flex align-items-center justify-content-center"
                                                                                style={{
                                                                                    width: "40px",
                                                                                    height: "40px",
                                                                                }}
                                                                            >
                                                                                {formatDonorName(
                                                                                    donation
                                                                                )
                                                                                    .charAt(
                                                                                        0
                                                                                    )
                                                                                    .toUpperCase()}
                                                                            </div>
                                                                        </div>
                                                                        <div>
                                                                            <div className="donor-name">
                                                                                {formatDonorName(
                                                                                    donation
                                                                                )}
                                                                            </div>
                                                                        </div>
                                                                    </div>
                                                                </td>
                                                                <td
                                                                    style={{
                                                                        verticalAlign:
                                                                            "middle",
                                                                    }}
                                                                >
                                                                    <div className="fundraiser-title-donation">
                                                                        {donation.fundraiserTitle ||
                                                                            "Ogólna dotacja"}
                                                                    </div>
                                                                </td>
                                                                <td
                                                                    style={{
                                                                        verticalAlign:
                                                                            "middle",
                                                                    }}
                                                                >
                                                                    {donation.itemName ? (
                                                                        <span className="item-name">
                                                                            {
                                                                                donation.itemName
                                                                            }
                                                                        </span>
                                                                    ) : (
                                                                        <span className="text-muted">
                                                                            -
                                                                        </span>
                                                                    )}
                                                                </td>
                                                                <td
                                                                    style={{
                                                                        verticalAlign:
                                                                            "middle",
                                                                    }}
                                                                >
                                                                    <span className="donation-amount">
                                                                        {donation.amount.toFixed(
                                                                            2
                                                                        )}{" "}
                                                                        PLN
                                                                    </span>
                                                                </td>
                                                                <td
                                                                    style={{
                                                                        verticalAlign:
                                                                            "middle",
                                                                    }}
                                                                >
                                                                    <div className="donation-date">
                                                                        {new Date(
                                                                            donation.donatedAt ||
                                                                                donation.createdAt
                                                                        ).toLocaleDateString(
                                                                            "pl-PL"
                                                                        )}
                                                                    </div>
                                                                </td>
                                                            </tr>

                                                            {donation.message && (
                                                                <tr className="donation-message-full-width-row">
                                                                    <td
                                                                        colSpan="5"
                                                                        className="p-0"
                                                                    >
                                                                        <div className="donation-message-full-width">
                                                                            <div className="d-flex align-items-start">
                                                                                <div className="message-icon me-2">
                                                                                    <MessageSquare
                                                                                        size={
                                                                                            16
                                                                                        }
                                                                                    />
                                                                                </div>
                                                                                <div className="message-text-full">
                                                                                    <span className="message-label"></span>
                                                                                    <div className="message-content-full">
                                                                                        "
                                                                                        {
                                                                                            donation.message
                                                                                        }

                                                                                        "
                                                                                    </div>
                                                                                </div>
                                                                            </div>
                                                                        </div>
                                                                    </td>
                                                                </tr>
                                                            )}
                                                        </React.Fragment>
                                                    )
                                                )}
                                            </tbody>
                                        </table>
                                    </div>
                                    {hasMoreMainDonations && (
                                        <div className="text-center mt-4">
                                            <button
                                                className="btn btn-outline-primary"
                                                onClick={
                                                    handleLoadMoreMainDonations
                                                }
                                                disabled={actionLoading}
                                            >
                                                <Plus
                                                    size={16}
                                                    className="me-2"
                                                />
                                                {actionLoading
                                                    ? "Ładowanie..."
                                                    : "Załaduj więcej dotacji"}
                                            </button>
                                        </div>
                                    )}
                                </>
                            )}
                        </div>
                    </div>
                )}

                {showFundraiserForm && (
                    <FundraiserForm
                        fundraiser={editingFundraiser}
                        onSubmit={
                            editingFundraiser
                                ? handleUpdateFundraiser
                                : handleCreateFundraiser
                        }
                        onCancel={closeModals}
                        loading={actionLoading}
                    />
                )}

                {showDonations && (
                    <DonationsModal
                        fundraiser={selectedFundraiser}
                        donations={fundraiserDonations}
                        onClose={closeModals}
                        hasMore={hasMoreDonations}
                        onLoadMore={handleLoadMoreDonations}
                        loading={actionLoading}
                    />
                )}
            </div>
        </div>
    );
};

export default ShelterFunding;
