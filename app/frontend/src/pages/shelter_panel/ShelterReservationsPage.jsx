import React, { useState, useEffect, useCallback, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import * as shelterService from "../../api/shelter";
import * as reservationService from "../../api/reservation";
import Navbar from "../../components/Navbar";
import {
    ArrowLeft,
    Calendar,
    ListChecks,
    Users,
    RotateCcw,
    CalendarX,
    PawPrint,
    Clock,
    CalendarClock,
    Trash2,
} from "lucide-react";
import { Calendar as BigCalendar, momentLocalizer } from "react-big-calendar";
import moment from "moment";
import "moment/locale/pl";
import "react-big-calendar/lib/css/react-big-calendar.css";
import "./ShelterReservations.css";

moment.locale("pl");
const localizer = momentLocalizer(moment);

const SearchablePetSelect = ({
    pets,
    selectedPetId,
    onSelectPet,
    disabled,
}) => {
    const [searchTerm, setSearchTerm] = useState("");
    const [isOpen, setIsOpen] = useState(false);

    const filteredPets = useMemo(() => {
        if (!Array.isArray(pets)) return [];
        return pets.filter(
            (pet) =>
                !pet.archived &&
                pet.name.toLowerCase().includes(searchTerm.toLowerCase())
        );
    }, [pets, searchTerm]);

    const selectedPetName = useMemo(() => {
        if (!selectedPetId) return "Wybierz lub wyszukaj zwierzę...";
        if (!Array.isArray(pets)) return "Wybierz zwierzę...";
        return (
            pets.find((p) => p.id.toString() === selectedPetId)?.name ||
            "Wybierz zwierzę..."
        );
    }, [pets, selectedPetId]);

    useEffect(() => {
        const closeDropdown = (e) => {
            if (!e.target.closest(".searchable-pet-select")) {
                setIsOpen(false);
            }
        };
        document.addEventListener("click", closeDropdown);
        return () => document.removeEventListener("click", closeDropdown);
    }, []);

    return (
        <div className="dropdown searchable-pet-select">
            <input
                type="text"
                className="form-control pet-search-input"
                placeholder={isOpen ? "Szukaj..." : selectedPetName}
                onFocus={() => setIsOpen(true)}
                onChange={(e) => {
                    setIsOpen(true);
                    setSearchTerm(e.target.value);
                }}
                value={searchTerm}
                disabled={disabled}
            />
            <div className={`dropdown-menu ${isOpen ? "show" : ""} w-100`}>
                <button
                    className="dropdown-item"
                    onClick={() => {
                        onSelectPet(null);
                        setIsOpen(false);
                        setSearchTerm("");
                    }}
                >
                    -- Wyczyść wybór --
                </button>
                {filteredPets.map((pet) => (
                    <button
                        key={pet.id}
                        className="dropdown-item"
                        onClick={() => {
                            onSelectPet(pet.id.toString());
                            setIsOpen(false);
                            setSearchTerm("");
                        }}
                    >
                        {pet.name}
                    </button>
                ))}
            </div>
        </div>
    );
};

const BatchCreateView = ({
    pets,
    setLoading,
    setError,
    setSuccess,
    refreshData,
}) => {
    const [formData, setFormData] = useState({
        petIds: [],
        allPets: true,
        startDate: "",
        endDate: "",
        timeWindows: [{ start: "", end: "" }],
    });
    const [searchTerm, setSearchTerm] = useState("");

    const generateTimeOptions = () => {
        const options = [];
        for (let hour = 6; hour <= 22; hour++) {
            for (let minute = 0; minute < 60; minute += 15) {
                const timeString = `${hour.toString().padStart(2, "0")}:${minute
                    .toString()
                    .padStart(2, "0")}`;
                const displayTime = `${hour
                    .toString()
                    .padStart(2, "0")}:${minute.toString().padStart(2, "0")}`;
                options.push({
                    value: timeString,
                    label: displayTime,
                });
            }
        }
        return options;
    };

    const timeOptions = generateTimeOptions();

    const filteredPets = useMemo(() => {
        if (!Array.isArray(pets)) return [];
        return pets.filter(
            (pet) =>
                !pet.archived &&
                pet.name.toLowerCase().includes(searchTerm.toLowerCase())
        );
    }, [pets, searchTerm]);

    const handleFormChange = (e) => {
        const { name, value, type, checked } = e.target;
        setFormData((prev) => ({
            ...prev,
            [name]: type === "checkbox" ? checked : value,
        }));
    };

    const handleTimeWindowChange = (index, e) => {
        const { name, value } = e.target;
        const newTimeWindows = [...formData.timeWindows];
        newTimeWindows[index][name] = value;
        setFormData((prev) => ({ ...prev, timeWindows: newTimeWindows }));
    };

    const addTimeWindow = () =>
        setFormData((prev) => ({
            ...prev,
            timeWindows: [...prev.timeWindows, { start: "", end: "" }],
        }));

    const removeTimeWindow = (index) =>
        setFormData((prev) => ({
            ...prev,
            timeWindows: prev.timeWindows.filter((_, i) => i !== index),
        }));

    const handleSelectPet = (petId) => {
        setFormData((prev) => ({
            ...prev,
            petIds: prev.petIds.includes(petId)
                ? prev.petIds.filter((id) => id !== petId)
                : [...prev.petIds, petId],
        }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError("");
        setSuccess("");
        const payload = { ...formData };
        if (formData.allPets) {
            payload.petIds = [];
        }
        try {
            const result = await reservationService.createBatchSlots(payload);
            if (result.success) {
                setSuccess("Sloty zostały pomyślnie dodane!");
                setFormData({
                    petIds: [],
                    allPets: true,
                    startDate: "",
                    endDate: "",
                    timeWindows: [{ start: "", end: "" }],
                });
                refreshData();
            } else {
                setError(result.error || "Nie udało się dodać slotów.");
            }
        } catch (err) {
            setError("Wystąpił błąd serwera.");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="batch-create-view">
            <h4 className="mb-4">Konfigurator kalendarza rezerwacji</h4>
            <form onSubmit={handleSubmit}>
                <div className="reservation-config-section">
                    <h5>
                        <Calendar size={18} className="me-2" />
                        Zakres dat
                    </h5>
                    <div className="row">
                        <div className="col-md-6 mb-3 mb-md-0">
                            <label className="form-label">Okres od *</label>
                            <input
                                type="date"
                                name="startDate"
                                value={formData.startDate}
                                onChange={handleFormChange}
                                className="form-control"
                                required
                            />
                        </div>
                        <div className="col-md-6">
                            <label className="form-label">Okres do *</label>
                            <input
                                type="date"
                                name="endDate"
                                value={formData.endDate}
                                onChange={handleFormChange}
                                className="form-control"
                                required
                            />
                        </div>
                    </div>
                </div>

                <div className="reservation-config-section">
                    <h5>
                        <Clock size={18} className="me-2" />
                        Okna czasowe
                    </h5>
                    <label className="form-label">
                        Dodaj godziny dostępności dla każdego dnia w podanym
                        wyżej zakresie. *
                    </label>
                    {formData.timeWindows.map((tw, index) => (
                        <div key={index} className="time-window-row">
                            <select
                                name="start"
                                value={tw.start}
                                onChange={(e) =>
                                    handleTimeWindowChange(index, e)
                                }
                                className="form-select time-select"
                                required
                            >
                                <option value="">
                                    Wybierz godzinę rozpoczęcia
                                </option>
                                {timeOptions.map((option) => (
                                    <option
                                        key={`start-${option.value}`}
                                        value={option.value}
                                    >
                                        {option.label}
                                    </option>
                                ))}
                            </select>
                            <span className="time-separator">–</span>
                            <select
                                name="end"
                                value={tw.end}
                                onChange={(e) =>
                                    handleTimeWindowChange(index, e)
                                }
                                className="form-select time-select"
                                required
                            >
                                <option value="">
                                    Wybierz godzinę zakończenia
                                </option>
                                {timeOptions
                                    .filter((option) => {
                                        if (!tw.start) return true;
                                        return option.value > tw.start;
                                    })
                                    .map((option) => (
                                        <option
                                            key={`end-${option.value}`}
                                            value={option.value}
                                        >
                                            {option.label}
                                        </option>
                                    ))}
                            </select>
                        </div>
                    ))}
                    <div className="time-window-actions">
                        <button
                            type="button"
                            onClick={addTimeWindow}
                            className="btn btn-add-window"
                        >
                            Dodaj pole
                        </button>
                        {formData.timeWindows.length > 1 && (
                            <button
                                type="button"
                                onClick={() =>
                                    removeTimeWindow(
                                        formData.timeWindows.length - 1
                                    )
                                }
                                className="btn btn-remove-window"
                            >
                                Usuń pole
                            </button>
                        )}
                    </div>
                </div>

                <div className="reservation-config-section">
                    <h5>
                        <PawPrint size={18} className="me-2" />
                        Wybór zwierząt
                    </h5>
                    <div className="form-check">
                        <input
                            type="checkbox"
                            name="allPets"
                            checked={formData.allPets}
                            onChange={handleFormChange}
                            className="form-check-input"
                            id="allPetsCheck"
                        />
                        <label
                            className="form-check-label"
                            htmlFor="allPetsCheck"
                        >
                            Wszystkie zwierzęta (gotowe do adopcji)
                        </label>
                    </div>
                    {!formData.allPets && (
                        <>
                            <input
                                type="text"
                                placeholder="Szukaj zwierzęcia..."
                                className="form-control pet-search-input"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                            />
                            <div className="pet-list-scrollable">
                                {filteredPets.length > 0 ? (
                                    filteredPets.map((pet) => (
                                        <div
                                            key={pet.id}
                                            className="form-check"
                                        >
                                            <input
                                                type="checkbox"
                                                id={`pet-${pet.id}`}
                                                className="form-check-input"
                                                checked={formData.petIds.includes(
                                                    pet.id
                                                )}
                                                onChange={() =>
                                                    handleSelectPet(pet.id)
                                                }
                                            />
                                            <label
                                                className="form-check-label"
                                                htmlFor={`pet-${pet.id}`}
                                            >
                                                {pet.name}
                                            </label>
                                        </div>
                                    ))
                                ) : (
                                    <small className="text-muted">
                                        Brak pasujących zwierząt.
                                    </small>
                                )}
                            </div>
                        </>
                    )}
                </div>

                <div className="form-actions d-flex justify-content-end mt-4">
                    <button type="submit" className="btn btn-primary btn-lg">
                        Dodaj godziny
                    </button>
                </div>
            </form>
        </div>
    );
};

const UserReservationsView = ({
    allSlots,
    pets,
    refreshData,
    setError,
    setSuccess,
}) => {
    const [selectedUsername, setSelectedUsername] = useState(null);

    const handleAction = async (action, slotId, successMsg, errorMsg) => {
        const confirmAction = window.confirm(
            "Czy na pewno chcesz wykonać tę akcję?"
        );
        if (!confirmAction) return;

        setError("");
        setSuccess("");
        try {
            const result = await action(slotId);
            if (result.success) {
                setSuccess(successMsg);
                refreshData();
            } else {
                setError(result.error || errorMsg);
            }
        } catch (err) {
            setError("Wystąpił błąd serwera.");
        }
    };

    const usersWithReservations = useMemo(() => {
        const usersMap = new Map();
        allSlots.forEach((slot) => {
            if (slot.reservedBy) {
                if (!usersMap.has(slot.reservedBy)) {
                    usersMap.set(slot.reservedBy, {
                        username: slot.reservedBy,
                        fullName: slot.reservedByFullName || slot.reservedBy,
                        slots: [],
                    });
                }
                usersMap.get(slot.reservedBy).slots.push(slot);
            }
        });
        return Array.from(usersMap.values()).sort(
            (a, b) => b.slots.length - a.slots.length
        );
    }, [allSlots]);

    const selectedUserData = useMemo(() => {
        return usersWithReservations.find(
            (user) => user.username === selectedUsername
        );
    }, [selectedUsername, usersWithReservations]);

    const getPetName = (petId) => {
        if (!Array.isArray(pets)) return "Nieznane zwierzę";
        return pets.find((p) => p.id === petId)?.name || "Nieznane zwierzę";
    };

    useEffect(() => {
        if (
            usersWithReservations.length > 0 &&
            !usersWithReservations.some((u) => u.username === selectedUsername)
        ) {
            setSelectedUsername(usersWithReservations[0].username);
        } else if (usersWithReservations.length === 0) {
            setSelectedUsername(null);
        }
    }, [usersWithReservations, selectedUsername]);

    return (
        <div className="user-reservations-view">
            <h4 className="mb-4">Zarządzaj rezerwacjami wolontariuszy</h4>
            {usersWithReservations.length === 0 ? (
                <div className="text-center p-5 bg-light rounded">
                    <Users size={48} className="text-muted mb-3" />
                    <h5 className="text-muted">Brak rezerwacji</h5>
                    <p>
                        Żaden wolontariusz nie ma aktualnie zaplanowanych wizyt.
                    </p>
                </div>
            ) : (
                <div className="row">
                    <div className="col-lg-4">
                        <div className="user-list-column">
                            {usersWithReservations.map((user) => (
                                <div
                                    key={user.username}
                                    className={`user-card ${
                                        selectedUsername === user.username
                                            ? "active"
                                            : ""
                                    }`}
                                    onClick={() =>
                                        setSelectedUsername(user.username)
                                    }
                                >
                                    <div className="d-flex justify-content-between align-items-center">
                                        <div>
                                            <h5 className="mb-0">
                                                {user.fullName}
                                            </h5>
                                            <small className="text-muted">
                                                {user.username}
                                            </small>
                                        </div>
                                        <span className="badge rounded-pill user-reservation-count">
                                            {user.slots.length}
                                        </span>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>

                    <div className="col-lg-8">
                        {selectedUserData && (
                            <div className="reservations-details-panel">
                                <h4 className="mb-3">
                                    Rezerwacje dla: {selectedUserData.fullName}
                                </h4>
                                <ul className="list-group list-group-flush">
                                    {selectedUserData.slots.map((slot) => (
                                        <li
                                            key={slot.id}
                                            className="list-group-item d-flex justify-content-between align-items-center"
                                        >
                                            <div className="slot-info">
                                                <span className="pet-name">
                                                    {getPetName(slot.petId)}
                                                </span>
                                                <small className="d-block text-muted">
                                                    {moment(
                                                        slot.startTime
                                                    ).format(
                                                        "dddd, D MMMM YYYY"
                                                    )}
                                                </small>
                                                <strong className="d-block time-range mt-1">
                                                    {moment(
                                                        slot.startTime
                                                    ).format("HH:mm")}{" "}
                                                    -{" "}
                                                    {moment(
                                                        slot.endTime
                                                    ).format("HH:mm")}
                                                </strong>
                                            </div>

                                            {slot.status === "RESERVED" && (
                                                <button
                                                    className="btn btn-sm btn-outline-danger action-btn"
                                                    onClick={() =>
                                                        handleAction(
                                                            reservationService.cancelReservation,
                                                            slot.id,
                                                            "Rezerwacja anulowana.",
                                                            "Błąd anulowania."
                                                        )
                                                    }
                                                >
                                                    <CalendarX
                                                        size={16}
                                                        className="me-1"
                                                    />{" "}
                                                    Anuluj
                                                </button>
                                            )}

                                            {slot.status === "CANCELLED" &&
                                                (new Date(slot.startTime) >
                                                new Date() ? (
                                                    <button
                                                        className="btn btn-sm btn-outline-info action-btn"
                                                        onClick={() =>
                                                            handleAction(
                                                                reservationService.reactivateSlot,
                                                                slot.id,
                                                                "Slot reaktywowany.",
                                                                "Błąd reaktywacji."
                                                            )
                                                        }
                                                    >
                                                        <RotateCcw
                                                            size={16}
                                                            className="me-1"
                                                        />{" "}
                                                        Reaktywuj
                                                    </button>
                                                ) : (
                                                    <span className="badge bg-light text-dark">
                                                        Termin minął
                                                    </span>
                                                ))}
                                        </li>
                                    ))}
                                </ul>
                            </div>
                        )}
                    </div>
                </div>
            )}
        </div>
    );
};

const ReservationsCalendarView = ({
    pets,
    allSlots,
    refreshData,
    setError,
    setSuccess,
}) => {
    const [selectedPetId, setSelectedPetId] = useState(null);
    const [selectedEvent, setSelectedEvent] = useState(null);

    const eventPropGetter = useCallback((event) => {
        let newClassName = `rbc-event status-${event.resource.status.toLowerCase()}`;
        return { className: newClassName };
    }, []);

    const handleSelectEvent = (event) => {
        setSelectedEvent(event);
    };

    const handleDeleteSlot = async (slotId) => {
        if (!confirm("Czy na pewno chcesz usunąć ten termin?")) return;

        try {
            const result = await reservationService.deleteSlot(slotId);
            if (result.success) {
                setSuccess("Slot został usunięty");
                refreshData();
                setSelectedEvent(null);
            } else {
                setError("Błąd podczas usuwania slota: " + result.error);
            }
        } catch (error) {
            setError("Wystąpił błąd podczas usuwania slota");
        }
    };

    const handleCancelReservation = async (slotId) => {
        if (!confirm("Czy na pewno chcesz anulować tę rezerwację?")) return;

        try {
            const result = await reservationService.cancelReservation(slotId);
            if (result.success) {
                setSuccess("Rezerwacja została anulowana");
                refreshData();
                setSelectedEvent(null);
            } else {
                setError("Błąd podczas anulowania rezerwacji: " + result.error);
            }
        } catch (error) {
            setError("Wystąpił błąd podczas anulowania rezerwacji");
        }
    };

    const calendarEvents = useMemo(() => {
        if (!selectedPetId) return [];

        const slotsToDisplay = allSlots.filter(
            (s) => s.petId.toString() === selectedPetId
        );

        return slotsToDisplay.map((slot) => {
            let title;
            if (slot.status === "RESERVED") {
                title = `Zajęte: ${
                    slot.userEmail || slot.reservedBy || "Użytkownik"
                }`;
            } else if (slot.status === "CANCELLED") {
                title = "Anulowane";
            } else {
                title = "Wolne";
            }

            return {
                id: slot.id,
                title,
                start: new Date(slot.startTime),
                end: new Date(slot.endTime),
                resource: slot,
            };
        });
    }, [allSlots, selectedPetId]);

    return (
        <>
            <div className="calendar-view-header mb-4">
                <label htmlFor="petFilter" className="form-label fw-bold">
                    Wybierz zwierzę, aby zarządzać jego grafikiem
                </label>
                <SearchablePetSelect
                    pets={pets}
                    selectedPetId={selectedPetId}
                    onSelectPet={setSelectedPetId}
                />
            </div>

            <div className="calendar-wrapper">
                {!selectedPetId ? (
                    <div className="calendar-placeholder">
                        <Calendar size={48} className="mb-3" />
                        <h4>Wybierz zwierzę z listy powyżej</h4>
                        <p>aby wyświetlić jego kalendarz rezerwacji.</p>
                    </div>
                ) : (
                    <>
                        <BigCalendar
                            localizer={localizer}
                            events={calendarEvents}
                            startAccessor="start"
                            endAccessor="end"
                            views={["month", "week", "day"]}
                            eventPropGetter={eventPropGetter}
                            onSelectEvent={handleSelectEvent}
                            messages={{
                                next: "Następny",
                                previous: "Poprzedni",
                                today: "Dziś",
                                month: "Miesiąc",
                                week: "Tydzień",
                                day: "Dzień",
                                agenda: "Agenda",
                                noEventsInRange: "Brak slotów w tym zakresie.",
                            }}
                        />

                        {selectedEvent && (
                            <div
                                className="modal fade show d-block"
                                style={{ backgroundColor: "rgba(0,0,0,0.5)" }}
                            >
                                <div className="modal-dialog">
                                    <div className="modal-content">
                                        <div className="modal-header">
                                            <h5 className="modal-title">
                                                Zarządzaj terminem
                                            </h5>
                                            <button
                                                type="button"
                                                className="btn-close"
                                                onClick={() =>
                                                    setSelectedEvent(null)
                                                }
                                            />
                                        </div>
                                        <div className="modal-body">
                                            <p>
                                                <strong>Status:</strong>{" "}
                                                {selectedEvent.resource.status}
                                            </p>
                                            <p>
                                                <strong>Data:</strong>{" "}
                                                {moment(
                                                    selectedEvent.start
                                                ).format("DD.MM.YYYY")}
                                            </p>
                                            <p>
                                                <strong>Godzina:</strong>{" "}
                                                {moment(
                                                    selectedEvent.start
                                                ).format("HH:mm")}{" "}
                                                -{" "}
                                                {moment(
                                                    selectedEvent.end
                                                ).format("HH:mm")}
                                            </p>
                                            {selectedEvent.resource
                                                .userEmail && (
                                                <p>
                                                    <strong>
                                                        Zarezerwowane przez:
                                                    </strong>{" "}
                                                    {
                                                        selectedEvent.resource
                                                            .userEmail
                                                    }
                                                </p>
                                            )}
                                        </div>
                                        <div className="modal-footer">
                                            <button
                                                type="button"
                                                className="btn btn-secondary"
                                                onClick={() =>
                                                    setSelectedEvent(null)
                                                }
                                            >
                                                Zamknij
                                            </button>
                                            {selectedEvent.resource.status ===
                                                "RESERVED" && (
                                                <button
                                                    type="button"
                                                    className="btn btn-warning"
                                                    onClick={() =>
                                                        handleCancelReservation(
                                                            selectedEvent
                                                                .resource.id
                                                        )
                                                    }
                                                >
                                                    <CalendarX
                                                        size={16}
                                                        className="me-1"
                                                    />
                                                    Anuluj rezerwację
                                                </button>
                                            )}
                                            <button
                                                type="button"
                                                className="btn btn-danger"
                                                onClick={() =>
                                                    handleDeleteSlot(
                                                        selectedEvent.resource
                                                            .id
                                                    )
                                                }
                                            >
                                                <Trash2
                                                    size={16}
                                                    className="me-1"
                                                />
                                                Usuń slot
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        )}
                    </>
                )}
            </div>
        </>
    );
};

const ShelterReservationsPage = () => {
    const navigate = useNavigate();
    const [view, setView] = useState("calendar");
    const [pets, setPets] = useState([]);
    const [allSlots, setAllSlots] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");
    const [success, setSuccess] = useState("");

    const fetchInitialData = useCallback(async () => {
        setLoading(true);
        setError("");
        try {
            const shelterResult = await shelterService.getMyShelter();
            if (!shelterResult.success || !shelterResult.data) {
                setError("Nie można znaleźć Twojego schroniska.");
                setLoading(false);
                return;
            }
            const shelterId = shelterResult.data.id;

            const petsResponse = await shelterService.getPetsForShelter(
                shelterId
            );
            if (!petsResponse.success) {
                setError(
                    petsResponse.error || "Nie udało się załadować zwierząt."
                );
                setLoading(false);
                return;
            }
            const petsData = Array.isArray(petsResponse.data)
                ? petsResponse.data
                : petsResponse.data?.content || [];
            setPets(petsData);
            const shelterPetIds = new Set(petsData.map((p) => p.id));

            const slotsResult = await reservationService.getAllSlots();
            if (slotsResult.success) {
                const shelterSlots = slotsResult.data.filter((slot) =>
                    shelterPetIds.has(slot.petId)
                );
                setAllSlots(shelterSlots);
            } else {
                setError(
                    slotsResult.error || "Nie udało się załadować rezerwacji."
                );
            }
        } catch (e) {
            setError(
                "Wystąpił krytyczny błąd serwera podczas ładowania danych."
            );
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchInitialData();
    }, [fetchInitialData]);

    const showSuccessMessage = (msg) => {
        setSuccess(msg);
        setTimeout(() => setSuccess(""), 4000);
    };

    const handleBack = () => navigate("/shelter-panel");

    const renderView = () => {
        if (loading) {
            return (
                <div className="text-center p-5">
                    <div className="spinner-border text-primary"></div>
                </div>
            );
        }

        switch (view) {
            case "calendar":
                return (
                    <ReservationsCalendarView
                        pets={pets}
                        allSlots={allSlots}
                        refreshData={fetchInitialData}
                        setError={setError}
                        setSuccess={showSuccessMessage}
                    />
                );
            case "batch":
                return (
                    <BatchCreateView
                        pets={pets}
                        setLoading={setLoading}
                        setError={setError}
                        setSuccess={showSuccessMessage}
                        refreshData={fetchInitialData}
                    />
                );
            case "users":
                return (
                    <UserReservationsView
                        allSlots={allSlots}
                        pets={pets}
                        refreshData={fetchInitialData}
                        setError={setError}
                        setSuccess={showSuccessMessage}
                    />
                );
            default:
                return (
                    <ReservationsCalendarView
                        pets={pets}
                        allSlots={allSlots}
                        refreshData={fetchInitialData}
                        setError={setError}
                        setSuccess={showSuccessMessage}
                    />
                );
        }
    };

    return (
        <div className="shelter-panel">
            <Navbar />
            <div className="container mt-4 pb-5 reservations-page">
                <div className="shelter-header-card mb-4">
                    <div className="d-flex align-items-center mb-3">
                        <CalendarClock
                            size={32}
                            className="text-primary me-3"
                        />
                        <div>
                            <h2 className="mb-0">Zarządzanie rezerwacjami</h2>
                            <p className="text-muted mb-0">
                                Twórz i przeglądaj sloty na spacery z
                                wolontariuszami
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
                        {error}{" "}
                        <button
                            type="button"
                            className="btn-close"
                            onClick={() => setError("")}
                        ></button>
                    </div>
                )}
                {success && (
                    <div
                        className="alert alert-success alert-dismissible fade show"
                        role="alert"
                    >
                        {success}{" "}
                        <button
                            type="button"
                            className="btn-close"
                            onClick={() => setSuccess("")}
                        ></button>
                    </div>
                )}

                <ul className="nav nav-pills mb-4">
                    <li className="nav-item">
                        <button
                            className={`nav-link ${
                                view === "calendar" ? "active" : ""
                            }`}
                            onClick={() => setView("calendar")}
                        >
                            <Calendar size={18} className="me-2" />
                            Kalendarz
                        </button>
                    </li>
                    <li className="nav-item">
                        <button
                            className={`nav-link ${
                                view === "batch" ? "active" : ""
                            }`}
                            onClick={() => setView("batch")}
                        >
                            <ListChecks size={18} className="me-2" />
                            Konfiguracja rezerwacji
                        </button>
                    </li>
                    <li className="nav-item">
                        <button
                            className={`nav-link ${
                                view === "users" ? "active" : ""
                            }`}
                            onClick={() => setView("users")}
                        >
                            <Users size={18} className="me-2" />
                            Rezerwacje Wolontariuszy
                        </button>
                    </li>
                </ul>
                <div className="calendar-container">{renderView()}</div>
            </div>
        </div>
    );
};

export default ShelterReservationsPage;
