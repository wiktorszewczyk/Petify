import React, { useState, useEffect, useCallback, useMemo } from "react";
const API_URL = import.meta.env.VITE_API_URL;
import { useNavigate } from "react-router-dom";
import { getMyShelter } from "../../api/shelter";
import {
    getShelterPosts,
    getShelterEvents,
    createPost,
    createEvent,
    updatePost,
    updateEvent,
    deletePost,
    deleteEvent,
    getPostById,
    getEventById,
    getEventParticipants,
    getFundraisingById,
} from "../../api/feed";
import {
    getEntityImages,
    getImageById,
    uploadImages,
    deleteImage,
} from "../../api/image";
import Navbar from "../../components/Navbar";
import FeedItemForm from "../../components/shelter_panel/FeedItemForm";
import {
    ArrowLeft,
    Users,
    Edit,
    Trash2,
    Calendar,
    MapPin,
    Clock,
    MessageSquare,
    Eye,
    AlertCircle,
    CheckCircle,
    Image as ImageIcon,
    Loader,
    X,
    ChevronLeft,
    ChevronRight,
    Heart,
    Edit3,
} from "lucide-react";
import "./ShelterFeed.css";

const ImagesModal = ({ item, images, onClose }) => {
    const [currentImageIndex, setCurrentImageIndex] = useState(0);

    if (!item || !images) return null;

    const nextImage = () => {
        setCurrentImageIndex((prev) =>
            prev < images.length - 1 ? prev + 1 : 0
        );
    };

    const prevImage = () => {
        setCurrentImageIndex((prev) =>
            prev > 0 ? prev - 1 : images.length - 1
        );
    };

    return (
        <div
            className="modal fade show d-block"
            style={{ backgroundColor: "rgba(0,0,0,0.8)" }}
            onClick={(e) => e.target === e.currentTarget && onClose()}
        >
            <div className="modal-dialog modal-xl modal-dialog-centered">
                <div className="modal-content">
                    <div className="modal-header">
                        <h5 className="modal-title d-flex align-items-center gap-2">
                            <ImageIcon size={20} />
                            Zdjęcia: {item.title}
                        </h5>
                        <button
                            type="button"
                            className="btn-close"
                            onClick={onClose}
                        ></button>
                    </div>

                    <div className="modal-body p-0">
                        {images.length === 0 ? (
                            <div className="text-center py-5">
                                <ImageIcon
                                    size={48}
                                    className="text-muted mb-3"
                                />
                                <h5 className="text-muted">Brak zdjęć</h5>
                            </div>
                        ) : (
                            <div className="position-relative">
                                <img
                                    src={
                                        images[currentImageIndex].imageUrl ||
                                        images[currentImageIndex].url
                                    }
                                    alt={`Zdjęcie ${currentImageIndex + 1}`}
                                    className="w-100"
                                    style={{
                                        maxHeight: "70vh",
                                        objectFit: "contain",
                                        backgroundColor: "#f8f9fa",
                                    }}
                                />

                                {images.length > 1 && (
                                    <>
                                        <button
                                            className="btn btn-dark position-absolute top-50 start-0 translate-middle-y ms-3"
                                            onClick={prevImage}
                                            style={{ opacity: 0.8 }}
                                        >
                                            ‹
                                        </button>
                                        <button
                                            className="btn btn-dark position-absolute top-50 end-0 translate-middle-y me-3"
                                            onClick={nextImage}
                                            style={{ opacity: 0.8 }}
                                        >
                                            ›
                                        </button>
                                    </>
                                )}

                                <div className="position-absolute bottom-0 start-50 translate-middle-x mb-3">
                                    <span className="badge bg-dark bg-opacity-75 px-3 py-2">
                                        {currentImageIndex + 1} /{" "}
                                        {images.length}
                                    </span>
                                </div>
                            </div>
                        )}
                    </div>

                    {images.length > 1 && (
                        <div className="modal-footer justify-content-center">
                            <div
                                className="d-flex gap-2 flex-wrap justify-content-center"
                                style={{ maxWidth: "100%", overflowX: "auto" }}
                            >
                                {images.map((image, index) => (
                                    <img
                                        key={image.id}
                                        src={image.imageUrl || image.url}
                                        alt={`Miniatura ${index + 1}`}
                                        className={`img-thumbnail ${
                                            index === currentImageIndex
                                                ? "border-primary"
                                                : ""
                                        }`}
                                        style={{
                                            width: "60px",
                                            height: "60px",
                                            objectFit: "cover",
                                            cursor: "pointer",
                                            borderWidth:
                                                index === currentImageIndex
                                                    ? "3px"
                                                    : "1px",
                                        }}
                                        onClick={() =>
                                            setCurrentImageIndex(index)
                                        }
                                    />
                                ))}
                            </div>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

const getMainImageUrl = async (item) => {
    if (!item.mainImageId) return null;

    try {
        const result = await getImageById(item.mainImageId);

        if (result.success && result.data) {
            if (result.data.imageUrl) {
                return result.data.imageUrl;
            }
            if (result.data.url) {
                return result.data.url;
            }
        }
    } catch (error) {}
    return null;
};

const ShelterFeed = () => {
    const navigate = useNavigate();
    const [shelter, setShelter] = useState(null);
    const [posts, setPosts] = useState([]);
    const [events, setEvents] = useState([]);
    const [loading, setLoading] = useState(true);
    const [actionLoading, setActionLoading] = useState(false);
    const [error, setError] = useState("");
    const [successMessage, setSuccessMessage] = useState("");

    const [showPostForm, setShowPostForm] = useState(false);
    const [showEventForm, setShowEventForm] = useState(false);
    const [editingPost, setEditingPost] = useState(null);
    const [editingEvent, setEditingEvent] = useState(null);

    const [showParticipantsModal, setShowParticipantsModal] = useState(false);
    const [selectedEvent, setSelectedEvent] = useState(null);

    const [showImagesModal, setShowImagesModal] = useState(false);
    const [selectedItem, setSelectedItem] = useState(null);
    const [selectedItemImages, setSelectedItemImages] = useState([]);

    const [searchTerm, setSearchTerm] = useState("");
    const [filterType, setFilterType] = useState("all");
    const [sortOrder, setSortOrder] = useState("by_event_date");

    const [imageCache, setImageCache] = useState({});
    const [fundraisingCache, setFundraisingCache] = useState({});

    const [showDetailsModal, setShowDetailsModal] = useState(false);
    const [selectedItemForDetails, setSelectedItemForDetails] = useState(null);

    useEffect(() => {
        loadShelterData();
    }, []);

    useEffect(() => {
        loadMainImages();
        const allItems = [...posts, ...events];
        loadFundraisingData(allItems);
    }, [posts, events]);

    const handleShowDetails = async (item) => {
        setSelectedItemForDetails(item);

        try {
            let imageUrls = [];

            if (item.imageIds && item.imageIds.length > 0) {
                const imagePromises = item.imageIds.map(async (id) => {
                    try {
                        const result = await getImageById(id);
                        if (result.success && result.data) {
                            return result.data.imageUrl || result.data.url;
                        }
                        return null;
                    } catch (error) {
                        return null;
                    }
                });

                const results = await Promise.all(imagePromises);
                imageUrls = results.filter((url) => url !== null);
            } else {
            }

            setSelectedItemImages(imageUrls);
        } catch (error) {
            setSelectedItemImages([]);
        }

        setShowDetailsModal(true);
    };

    const handleCloseDetailsModal = () => {
        setShowDetailsModal(false);
        setSelectedItemForDetails(null);
    };

    const loadMainImages = async () => {
        const allItems = [...posts, ...events];
        const imagesToLoad = allItems.filter(
            (item) => item.mainImageId && !imageCache[item.mainImageId]
        );
        if (imagesToLoad.length === 0) return;

        try {
            const imagePromises = imagesToLoad.map(async (item) => {
                const url = await getMainImageUrl(item);
                return { id: item.mainImageId, url };
            });
            const imageResults = await Promise.all(imagePromises);
            const newImageCache = {};
            imageResults.forEach(({ id, url }) => {
                if (url) newImageCache[id] = url;
            });
            if (Object.keys(newImageCache).length > 0) {
                setImageCache((prev) => ({ ...prev, ...newImageCache }));
            }
        } catch (error) {}
    };

    const loadShelterData = async () => {
        setLoading(true);
        try {
            const shelterResult = await getMyShelter();
            if (!shelterResult.success) {
                if (shelterResult.notFound) {
                    navigate("/shelter-setup");
                } else {
                    setError("Nie udało się załadować danych schroniska");
                }
                return;
            }
            setShelter(shelterResult.data);
            await Promise.all([
                loadPosts(shelterResult.data.id),
                loadEvents(shelterResult.data.id),
            ]);
        } catch (err) {
            setError("Wystąpił błąd podczas ładowania danych");
        } finally {
            setLoading(false);
        }
    };

    const loadPosts = async (shelterId) => {
        const result = await getShelterPosts(shelterId);
        if (result.success) setPosts(result.data || []);
    };

    const loadEvents = async (shelterId) => {
        const result = await getShelterEvents(shelterId);

        if (result.success) {
            const events = result.data || [];

            const eventsWithImages = await Promise.all(
                events.map(async (event) => {
                    try {
                        const imageResult = await getEntityImages(
                            event.id,
                            "event"
                        );

                        if (imageResult.success && imageResult.data) {
                            const imageIds = imageResult.data.map(
                                (img) => img.id
                            );

                            return {
                                ...event,
                                imageIds: imageIds,
                            };
                        } else {
                            return {
                                ...event,
                                imageIds: [],
                            };
                        }
                    } catch (error) {
                        return {
                            ...event,
                            imageIds: [],
                        };
                    }
                })
            );

            setEvents(eventsWithImages);
        } else {
        }
    };

    const showSuccessMessage = (message) => {
        setSuccessMessage(message);
        setTimeout(() => setSuccessMessage(""), 5000);
    };

    const showErrorMessage = (message) => {
        setError(message);
        setTimeout(() => setError(""), 5000);
    };

    const handleDeletePost = async (postId, postTitle) => {
        if (window.confirm(`Czy na pewno chcesz usunąć post "${postTitle}"?`)) {
            const result = await deletePost(postId);
            if (result.success) {
                setPosts((prev) => prev.filter((p) => p.id !== postId));
                showSuccessMessage("Post został usunięty.");
            } else {
                showErrorMessage(result.error);
            }
        }
    };

    const handleDeleteEvent = async (eventId, eventTitle) => {
        if (
            window.confirm(
                `Czy na pewno chcesz usunąć wydarzenie "${eventTitle}"?`
            )
        ) {
            const result = await deleteEvent(eventId);
            if (result.success) {
                setEvents((prev) => prev.filter((e) => e.id !== eventId));
                showSuccessMessage("Wydarzenie zostało usunięte.");
            } else {
                showErrorMessage(result.error);
            }
        }
    };

    const handleCreatePost = (newPostData) => {
        setPosts((prevPosts) => [newPostData, ...prevPosts]);
        setShowPostForm(false);
        setEditingPost(null);
        showSuccessMessage("Post został utworzony pomyślnie!");
    };

    const handleUpdatePost = async (updatedPostData) => {
        try {
            const result = await getPostById(updatedPostData.id);
            if (result.success) {
                let postData = result.data;

                if (!postData.imageIds && postData.id) {
                    try {
                        const imageResult = await getEntityImages(
                            postData.id,
                            "post"
                        );
                        if (imageResult.success && imageResult.data) {
                            const imageIds = imageResult.data.map(
                                (img) => img.id
                            );
                            postData = { ...postData, imageIds: imageIds };
                        }
                    } catch (error) {
                        postData = { ...postData, imageIds: [] };
                    }
                }

                setPosts((prev) =>
                    prev.map((p) =>
                        p.id === postData.id ? { ...postData, type: "post" } : p
                    )
                );
            } else {
                setPosts((prev) =>
                    prev.map((p) =>
                        p.id === updatedPostData.id ? updatedPostData : p
                    )
                );
            }
        } catch (error) {
            setPosts((prev) =>
                prev.map((p) =>
                    p.id === updatedPostData.id ? updatedPostData : p
                )
            );
        }

        setShowPostForm(false);
        setEditingPost(null);
        showSuccessMessage("Post został zaktualizowany!");
    };

    const handleCreateEvent = (newEventData) => {
        setEvents((prevEvents) => [newEventData, ...prevEvents]);
        setShowEventForm(false);
        setEditingEvent(null);
        showSuccessMessage("Wydarzenie zostało utworzone pomyślnie!");
    };

    const handleUpdateEvent = async (updatedEventData) => {
        try {
            const result = await getEventById(updatedEventData.id);
            if (result.success) {
                let eventData = result.data;

                if (!eventData.imageIds && eventData.id) {
                    try {
                        const imageResult = await getEntityImages(
                            eventData.id,
                            "event"
                        );
                        if (imageResult.success && imageResult.data) {
                            const imageIds = imageResult.data.map(
                                (img) => img.id
                            );
                            eventData = { ...eventData, imageIds: imageIds };
                        }
                    } catch (error) {
                        eventData = { ...eventData, imageIds: [] };
                    }
                }

                setEvents((prev) =>
                    prev.map((e) =>
                        e.id === eventData.id
                            ? { ...eventData, type: "event" }
                            : e
                    )
                );
            } else {
                setEvents((prev) =>
                    prev.map((e) =>
                        e.id === updatedEventData.id ? updatedEventData : e
                    )
                );
            }
        } catch (error) {
            setEvents((prev) =>
                prev.map((e) =>
                    e.id === updatedEventData.id ? updatedEventData : e
                )
            );
        }

        setShowEventForm(false);
        setEditingEvent(null);
        showSuccessMessage("Wydarzenie zostało zaktualizowane!");
    };

    const handleEdit = async (item) => {
        if (item.type === "post") {
            setEditingPost(item);
            setShowPostForm(true);
            return;
        }

        if (item.type === "event") {
            setActionLoading(true);

            try {
                const result = await getEventById(item.id);
                if (result.success) {
                    let eventData = result.data;

                    if (!eventData.imageIds && eventData.id) {
                        try {
                            const imageResult = await getEntityImages(
                                eventData.id,
                                "event"
                            );

                            if (imageResult.success && imageResult.data) {
                                const imageIds = imageResult.data.map(
                                    (img) => img.id
                                );
                                eventData = {
                                    ...eventData,
                                    imageIds: imageIds,
                                };
                            }
                        } catch (error) {
                            eventData = { ...eventData, imageIds: [] };
                        }
                    }
                    setEditingEvent(eventData);
                    setShowEventForm(true);
                } else {
                    showErrorMessage(
                        "Nie udało się załadować szczegółów wydarzenia."
                    );
                }
            } catch (error) {
                showErrorMessage("Wystąpił błąd podczas ładowania wydarzenia.");
            } finally {
                setActionLoading(false);
            }
        }
    };

    const handleShowParticipants = (event) => {
        setSelectedEvent(event);
        setShowParticipantsModal(true);
    };

    const handleCloseParticipantsModal = () => {
        setShowParticipantsModal(false);
        setSelectedEvent(null);
    };

    const handleShowImages = async (item) => {
        setSelectedItem(item);
        if (item.imageIds && item.imageIds.length > 0) {
            const imagePromises = item.imageIds.map((id) => getImageById(id));
            const results = await Promise.all(imagePromises);
            setSelectedItemImages(
                results.filter((r) => r.success).map((r) => r.data)
            );
        } else {
            setSelectedItemImages([]);
        }
        setShowImagesModal(true);
    };

    const handleCloseImagesModal = () => {
        setShowImagesModal(false);
        setSelectedItem(null);
        setSelectedItemImages([]);
    };

    const descriptionBoxStyle = {
        backgroundColor: "#f8f9fa",
        borderRadius: "6px",
        padding: "1rem",
        marginTop: "0.5rem",
        lineHeight: "1.6",
        wordWrap: "break-word",
        wordBreak: "break-word",
        overflowWrap: "break-word",
        maxWidth: "100%",
        overflow: "hidden",
    };

    const loadFundraisingData = async (items) => {
        const fundraisingIds = items
            .filter(
                (item) =>
                    item.fundraisingId && !fundraisingCache[item.fundraisingId]
            )
            .map((item) => item.fundraisingId);

        if (fundraisingIds.length === 0) return;

        const fundraisingPromises = fundraisingIds.map((id) =>
            getFundraisingById(id)
        );
        const results = await Promise.all(fundraisingPromises);
        const newCache = {};
        results.forEach((res, index) => {
            if (res.success) {
                newCache[fundraisingIds[index]] = res.data;
            }
        });
        setFundraisingCache((prev) => ({ ...prev, ...newCache }));
    };

    const filteredAndSortedItems = useMemo(() => {
        let allItems = [
            ...(filterType === "all" || filterType === "posts"
                ? posts.map((p) => ({ ...p, type: "post" }))
                : []),
            ...(filterType === "all" || filterType === "events"
                ? events.map((e) => ({ ...e, type: "event" }))
                : []),
        ];

        if (searchTerm.trim()) {
            const term = searchTerm.toLowerCase();
            allItems = allItems.filter(
                (item) =>
                    item.title.toLowerCase().includes(term) ||
                    item.shortDescription.toLowerCase().includes(term)
            );
        }

        allItems.sort((a, b) => {
            if (sortOrder === "by_creation_date") {
                return new Date(b.createdAt) - new Date(a.createdAt);
            }

            if (sortOrder === "by_event_date") {
                const now = new Date();
                const isA_event = a.type === "event";
                const isB_event = b.type === "event";

                const dateA = new Date(isA_event ? a.startDate : a.createdAt);
                const dateB = new Date(isB_event ? b.startDate : b.createdAt);

                const isA_futureEvent = isA_event && dateA > now;
                const isB_futureEvent = isB_event && dateB > now;

                if (isA_futureEvent && !isB_futureEvent) return -1;
                if (!isA_futureEvent && isB_futureEvent) return 1;

                if (isA_futureEvent && isB_futureEvent) {
                    return dateA - dateB;
                }

                return dateB - dateA;
            }

            return new Date(b.createdAt) - new Date(a.createdAt);
        });

        return allItems;
    }, [posts, events, searchTerm, filterType, sortOrder]);

    const formatDate = (dateString) => {
        if (!dateString) return "Brak daty";

        try {
            const date = new Date(dateString);
            if (isNaN(date.getTime())) {
                return "Nieprawidłowa data";
            }

            return date.toLocaleDateString("pl-PL", {
                year: "numeric",
                month: "long",
                day: "numeric",
                hour: "2-digit",
                minute: "2-digit",
            });
        } catch (error) {
            return "Błąd daty";
        }
    };

    const formatEventDuration = (startDate, endDate) => {
        if (!startDate || !endDate) return "Brak informacji o czasie";

        try {
            const start = new Date(startDate);
            const end = new Date(endDate);

            if (isNaN(start.getTime()) || isNaN(end.getTime())) {
                return "Nieprawidłowe daty";
            }

            const diffInMs = end.getTime() - start.getTime();

            if (diffInMs <= 0) {
                return "Wydarzenie jednodniowe";
            }

            const diffInHours = Math.floor(diffInMs / (1000 * 60 * 60));
            const diffInMinutes = Math.floor(
                (diffInMs % (1000 * 60 * 60)) / (1000 * 60)
            );
            const diffInDays = Math.floor(diffInHours / 24);

            if (diffInDays > 0) {
                const remainingHours = diffInHours % 24;

                let dayText;
                if (diffInDays === 1) {
                    dayText = "dzień";
                } else if (diffInDays >= 2 && diffInDays <= 4) {
                    dayText = "dni";
                } else {
                    dayText = "dni";
                }

                if (remainingHours > 0) {
                    return `${diffInDays} ${dayText} ${remainingHours}h`;
                } else {
                    return `${diffInDays} ${dayText}`;
                }
            } else if (diffInHours > 0) {
                return `${diffInHours}h ${diffInMinutes}min`;
            } else {
                return `${diffInMinutes}min`;
            }
        } catch (error) {
            return "Błąd czasu trwania";
        }
    };

    if (loading && !shelter) {
        return (
            <>
                <Navbar />
                <div className="container mt-4 text-center py-5">
                    <div className="spinner-border text-primary" role="status">
                        <span className="visually-hidden">Ładowanie...</span>
                    </div>
                </div>
            </>
        );
    }

    if (!shelter) {
        return (
            <>
                <Navbar />
                <div className="container mt-4 text-center py-5">
                    <AlertCircle size={48} className="text-danger mb-3" />
                    <h3>Nie znaleziono schroniska</h3>
                    <p className="text-muted">
                        Musisz najpierw skonfigurować swoje schronisko.
                    </p>
                    <button
                        className="btn btn-primary"
                        onClick={() => navigate("/shelter-panel")}
                    >
                        Przejdź do panelu schroniska
                    </button>
                </div>
            </>
        );
    }

    const ImagePreviewModal = ({ imageUrl, onClose }) => {
        if (!imageUrl) return null;

        return (
            <div
                className="modal fade show d-block"
                style={{
                    backgroundColor: "rgba(0,0,0,0.9)",
                    zIndex: 9999,
                }}
                onClick={onClose}
            >
                <div className="modal-dialog modal-xl modal-dialog-centered">
                    <div className="position-relative">
                        <button
                            type="button"
                            className="btn-close btn-close-white position-absolute top-0 end-0 m-3"
                            style={{ zIndex: 10000 }}
                            onClick={onClose}
                        ></button>
                        <img
                            src={imageUrl}
                            alt="Podgląd"
                            className="w-100"
                            style={{
                                maxHeight: "90vh",
                                objectFit: "contain",
                                borderRadius: "8px",
                            }}
                            onClick={(e) => e.stopPropagation()}
                        />
                    </div>
                </div>
            </div>
        );
    };

    const PostDetailsModal = ({
        item,
        imageUrls,
        onClose,
        onEdit,
        onDelete,
        onShowParticipants,
        formatDate,
        formatEventDuration,
        fundraising,
    }) => {
        const [currentImageIndex, setCurrentImageIndex] = useState(0);
        const [showImagePreview, setShowImagePreview] = useState(false);
        const [showDescriptionModal, setShowDescriptionModal] = useState(false);
        const isEvent = item.type === "event";
        const hasImages = imageUrls && imageUrls.length > 0;

        if (!item) return null;

        const nextImage = () => {
            setCurrentImageIndex((prev) => (prev + 1) % imageUrls.length);
        };

        const prevImage = () => {
            setCurrentImageIndex(
                (prev) => (prev - 1 + imageUrls.length) % imageUrls.length
            );
        };

        const openImagePreview = () => {
            setShowImagePreview(true);
        };

        const closeImagePreview = () => {
            setShowImagePreview(false);
        };

        const openDescriptionModal = () => {
            setShowDescriptionModal(true);
        };

        const closeDescriptionModal = () => {
            setShowDescriptionModal(false);
        };

        const getDescription = () => {
            if (isEvent) {
                if (
                    item.longDescription &&
                    item.longDescription.trim() !== ""
                ) {
                    return item.longDescription;
                }
                if (
                    item.shortDescription &&
                    item.shortDescription.trim() !== ""
                ) {
                    return item.shortDescription;
                }
                return "Brak opisu";
            } else {
                if (item.content && item.content.trim() !== "") {
                    return item.content;
                }
                if (
                    item.longDescription &&
                    item.longDescription.trim() !== ""
                ) {
                    return item.longDescription;
                }
                if (
                    item.shortDescription &&
                    item.shortDescription.trim() !== ""
                ) {
                    return item.shortDescription;
                }
                return "Brak opisu";
            }
        };

        const description = getDescription();
        const isLongDescription = description && description.length > 500;

        const descriptionBoxStyle = {
            backgroundColor: "#f8f9fa",
            borderRadius: "6px",
            padding: "1rem",
            lineHeight: "1.6",
            wordWrap: "break-word",
            wordBreak: "break-word",
            overflowWrap: "break-word",
            whiteSpace: "pre-wrap",
            maxWidth: "100%",
            overflow: "hidden",
        };

        return (
            <>
                <div className="custom-modal-backdrop" onClick={onClose}>
                    <div
                        className="custom-modal-content"
                        style={{ maxWidth: "1000px", width: "90vw" }}
                        onClick={(e) => e.stopPropagation()}
                    >
                        <div className="custom-modal-header">
                            <div className="d-flex align-items-center gap-3 flex-grow-1">
                                <h4 className="d-flex align-items-center gap-2 mb-0">
                                    {isEvent ? (
                                        <Calendar size={24} />
                                    ) : (
                                        <MessageSquare size={24} />
                                    )}
                                    {item.title}
                                </h4>
                            </div>

                            <div className="d-flex align-items-center gap-2">
                                {isEvent && (
                                    <button
                                        className="btn btn-sm btn-primary users-button"
                                        onClick={() => onShowParticipants(item)}
                                    >
                                        <Users size={16} className="me-1" />
                                        Uczestnicy
                                    </button>
                                )}
                                <button
                                    className="btn-close-modal"
                                    onClick={onClose}
                                >
                                    <X size={24} />
                                </button>
                            </div>
                        </div>

                        <div
                            className="custom-modal-body"
                            style={{ padding: "0" }}
                        >
                            {hasImages && (
                                <div
                                    className="position-relative"
                                    style={{
                                        height: "300px",
                                        backgroundColor: "#f8f9fa",
                                        cursor: "pointer",
                                    }}
                                    onClick={openImagePreview}
                                >
                                    <img
                                        src={imageUrls[currentImageIndex]}
                                        alt={item.title}
                                        style={{
                                            width: "100%",
                                            height: "100%",
                                            objectFit: "contain",
                                            objectPosition: "center",
                                        }}
                                    />

                                    <div
                                        className="position-absolute top-0 start-0 w-100 h-100 d-flex align-items-center justify-content-center opacity-0 hover-overlay"
                                        style={{
                                            background: "rgba(0,0,0,0.3)",
                                            transition: "opacity 0.2s",
                                        }}
                                        onMouseEnter={(e) =>
                                            (e.target.style.opacity = "1")
                                        }
                                        onMouseLeave={(e) =>
                                            (e.target.style.opacity = "0")
                                        }
                                    >
                                        <div className="text-white text-center">
                                            <Eye size={32} className="mb-2" />
                                            <div>Kliknij aby powiększyć</div>
                                        </div>
                                    </div>

                                    {imageUrls.length > 1 && (
                                        <>
                                            <button
                                                className="btn btn-dark position-absolute top-50 start-0 translate-middle-y ms-3"
                                                style={{
                                                    borderRadius: "50%",
                                                    width: "45px",
                                                    height: "45px",
                                                    opacity: "0.8",
                                                    display: "flex",
                                                    alignItems: "center",
                                                    justifyContent: "center",
                                                    border: "none",
                                                    zIndex: "10",
                                                }}
                                                onClick={(e) => {
                                                    e.stopPropagation();
                                                    prevImage();
                                                }}
                                            >
                                                <ChevronLeft size={20} />
                                            </button>
                                            <button
                                                className="btn btn-dark position-absolute top-50 end-0 translate-middle-y me-3"
                                                style={{
                                                    borderRadius: "50%",
                                                    width: "45px",
                                                    height: "45px",
                                                    opacity: "0.8",
                                                    display: "flex",
                                                    alignItems: "center",
                                                    justifyContent: "center",
                                                    border: "none",
                                                    zIndex: "10",
                                                }}
                                                onClick={(e) => {
                                                    e.stopPropagation();
                                                    nextImage();
                                                }}
                                            >
                                                <ChevronRight size={20} />
                                            </button>
                                        </>
                                    )}

                                    {imageUrls.length > 1 && (
                                        <div
                                            className="position-absolute bottom-0 end-0 bg-dark text-white px-2 py-1 m-2"
                                            style={{
                                                borderRadius: "4px",
                                                fontSize: "0.8rem",
                                            }}
                                        >
                                            {currentImageIndex + 1} /{" "}
                                            {imageUrls.length}
                                        </div>
                                    )}
                                </div>
                            )}

                            <div
                                style={{
                                    padding: "1.5rem 1.5rem 0.5rem 1.5rem",
                                }}
                            >
                                {isEvent && (
                                    <div className="mb-4">
                                        <div className="row g-3 mb-3">
                                            {item.startDate && (
                                                <div className="col-md-6">
                                                    <div className="d-flex align-items-center gap-2 mb-2">
                                                        <Calendar
                                                            size={16}
                                                            className="text-primary"
                                                        />
                                                        <strong>
                                                            Okres trwania:
                                                        </strong>
                                                    </div>
                                                    <div className="ms-4">
                                                        {formatDate(
                                                            item.startDate
                                                        )}
                                                        {item.endDate &&
                                                            formatDate(
                                                                item.startDate
                                                            ) !==
                                                                formatDate(
                                                                    item.endDate
                                                                ) &&
                                                            ` - ${formatDate(
                                                                item.endDate
                                                            )}`}
                                                    </div>
                                                </div>
                                            )}
                                            {item.startDate && item.endDate && (
                                                <div className="col-md-6">
                                                    <div className="d-flex align-items-center gap-2 mb-2">
                                                        <Clock
                                                            size={16}
                                                            className="text-primary"
                                                        />
                                                        <strong>
                                                            Czas trwania:
                                                        </strong>
                                                    </div>
                                                    <div className="ms-4">
                                                        {formatEventDuration(
                                                            item.startDate,
                                                            item.endDate
                                                        )}
                                                    </div>
                                                </div>
                                            )}
                                        </div>

                                        <div className="row g-3">
                                            {item.address && (
                                                <div className="col-md-6">
                                                    <div className="d-flex align-items-center gap-2 mb-2">
                                                        <MapPin
                                                            size={16}
                                                            className="text-primary"
                                                        />
                                                        <strong>Adres:</strong>
                                                    </div>
                                                    <div className="ms-4">
                                                        {item.address}
                                                    </div>
                                                </div>
                                            )}
                                            {item.capacity && (
                                                <div className="col-md-6">
                                                    <div className="d-flex align-items-center gap-2 mb-2">
                                                        <Users
                                                            size={16}
                                                            className="text-primary"
                                                        />
                                                        <strong>
                                                            Maksymalna liczba
                                                            uczestników:
                                                        </strong>
                                                    </div>
                                                    <div className="ms-4">
                                                        {item.capacity}
                                                    </div>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                )}

                                <div className="mb-4">
                                    <div className="d-flex align-items-center gap-2 mb-3">
                                        <MessageSquare
                                            size={16}
                                            className="text-primary"
                                        />
                                        <strong>Opis:</strong>
                                    </div>

                                    {isLongDescription ? (
                                        <div>
                                            <div
                                                className="description-box"
                                                style={{
                                                    ...descriptionBoxStyle,
                                                    whiteSpace: "pre-wrap",
                                                    marginTop: "0",
                                                }}
                                            >
                                                <p
                                                    className="mb-0"
                                                    style={{
                                                        display: "-webkit-box",
                                                        WebkitLineClamp: 3,
                                                        WebkitBoxOrient:
                                                            "vertical",
                                                        overflow: "hidden",
                                                        textOverflow:
                                                            "ellipsis",
                                                        whiteSpace: "pre-wrap",
                                                    }}
                                                >
                                                    {description}
                                                </p>
                                            </div>
                                            <button
                                                className="btn btn-link p-0 mt-2 text-decoration-none"
                                                onClick={openDescriptionModal}
                                            >
                                                <small>
                                                    Pokaż pełny opis →
                                                </small>
                                            </button>
                                        </div>
                                    ) : (
                                        <div
                                            className="description-box"
                                            style={{
                                                ...descriptionBoxStyle,
                                                whiteSpace: "pre-wrap",
                                                marginTop: "0",
                                            }}
                                        >
                                            <p
                                                className="mb-0"
                                                style={{
                                                    whiteSpace: "pre-wrap",
                                                }}
                                            >
                                                {description}
                                            </p>
                                        </div>
                                    )}
                                </div>
                            </div>
                        </div>

                        <div
                            className="custom-modal-footer"
                            style={{ padding: "1rem 1.5rem" }}
                        >
                            <div className="d-flex justify-content-between align-items-center w-100">
                                <div className="d-flex align-items-center gap-3">
                                    {fundraising && (
                                        <button className="btn btn-success btn-sm">
                                            <Heart size={16} className="me-2" />
                                            Wesprzyj
                                        </button>
                                    )}
                                    <small className="text-muted">
                                        Opublikowano{" "}
                                        {formatDate(item.createdAt)}
                                    </small>
                                </div>

                                <div className="d-flex gap-2">
                                    <button
                                        className="btn btn-secondary"
                                        onClick={onClose}
                                    >
                                        Zamknij
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                {showImagePreview && (
                    <ImagePreviewModal
                        imageUrl={imageUrls[currentImageIndex]}
                        onClose={closeImagePreview}
                    />
                )}

                {showDescriptionModal && (
                    <div
                        className="custom-modal-backdrop"
                        onClick={closeDescriptionModal}
                    >
                        <div
                            className="custom-modal-content"
                            style={{ maxWidth: "800px", width: "90vw" }}
                            onClick={(e) => e.stopPropagation()}
                        >
                            <div className="custom-modal-header">
                                <h4 className="mb-0">Pełny opis</h4>
                                <button
                                    className="btn-close-modal"
                                    onClick={closeDescriptionModal}
                                >
                                    <X size={24} />
                                </button>
                            </div>
                            <div className="custom-modal-body">
                                <div
                                    className="scrollable-text"
                                    style={{
                                        maxHeight: "800px",
                                        overflowY: "auto",
                                        padding: "1rem",
                                        backgroundColor: "#f8f9fa",
                                        borderRadius: "6px",
                                        lineHeight: "1.6",
                                        fontSize: "1.1rem",
                                        whiteSpace: "pre-wrap",
                                    }}
                                >
                                    <p
                                        className="mb-0"
                                        style={{ whiteSpace: "pre-wrap" }}
                                    >
                                        {description}
                                    </p>
                                </div>
                            </div>
                            <div className="custom-modal-footer">
                                <button
                                    className="btn btn-secondary ms-auto"
                                    onClick={closeDescriptionModal}
                                >
                                    Zamknij
                                </button>
                            </div>
                        </div>
                    </div>
                )}
            </>
        );
    };

    return (
        <div className="shelter-panel">
            <Navbar />
            <div className="container mt-4 pb-5">
                <div className="shelter-header-card mb-4">
                    <div className="d-flex align-items-center">
                        <Users size={32} className="text-primary me-3" />
                        <div>
                            <h2 className="mb-0">Tablica społeczności</h2>
                            <p className="text-muted mb-4">
                                Zarządzaj postami i wydarzeniami
                            </p>
                        </div>
                    </div>
                    <button
                        onClick={() => navigate("/shelter-panel")}
                        className="btn btn-outline-secondary d-flex align-items-center gap-2"
                    >
                        <ArrowLeft size={20} /> Powrót do panelu
                    </button>
                </div>

                {successMessage && (
                    <div className="alert alert-success d-flex align-items-center alert-dismissible fade show">
                        <CheckCircle size={20} className="me-2" />
                        {successMessage}
                        <button
                            type="button"
                            className="btn-close"
                            onClick={() => setSuccessMessage("")}
                        ></button>
                    </div>
                )}
                {error && (
                    <div className="alert alert-danger d-flex align-items-center alert-dismissible fade show">
                        <AlertCircle size={20} className="me-2" />
                        {error}
                        <button
                            type="button"
                            className="btn-close"
                            onClick={() => setError("")}
                        ></button>
                    </div>
                )}

                <div className="card mb-4">
                    <div className="card-body">
                        <div className="d-flex flex-column gap-4">
                            <div className="d-flex justify-content-between align-items-center gap-4">
                                <input
                                    type="text"
                                    className="form-control custom-search-input"
                                    placeholder="Szukaj w postach i wydarzeniach..."
                                    value={searchTerm}
                                    onChange={(e) =>
                                        setSearchTerm(e.target.value)
                                    }
                                    style={{
                                        flex: "1 1 auto",
                                        maxWidth: "65%",
                                    }}
                                />

                                <select
                                    className="form-select custom-sort-select"
                                    value={sortOrder}
                                    onChange={(e) =>
                                        setSortOrder(e.target.value)
                                    }
                                    style={{ minWidth: "240px" }}
                                >
                                    <option value="by_event_date">
                                        Według daty wydarzenia
                                    </option>
                                    <option value="by_creation_date">
                                        Według daty dodania
                                    </option>
                                </select>
                            </div>

                            <div className="d-flex justify-content-between align-items-center flex-wrap gap-3">
                                <div className="pet-filters">
                                    <button
                                        className={`filter-btn ${
                                            filterType === "all" ? "active" : ""
                                        }`}
                                        onClick={() => setFilterType("all")}
                                    >
                                        Wszystkie
                                    </button>
                                    <button
                                        className={`filter-btn ${
                                            filterType === "posts"
                                                ? "active"
                                                : ""
                                        }`}
                                        onClick={() => setFilterType("posts")}
                                    >
                                        Posty
                                    </button>
                                    <button
                                        className={`filter-btn ${
                                            filterType === "events"
                                                ? "active"
                                                : ""
                                        }`}
                                        onClick={() => setFilterType("events")}
                                    >
                                        Wydarzenia
                                    </button>
                                </div>
                                <div className="d-flex gap-2">
                                    <button
                                        className="btn btn-outline-primary d-flex align-items-center gap-2 post-btn"
                                        onClick={() => setShowPostForm(true)}
                                        disabled={actionLoading}
                                    >
                                        Dodaj Post
                                    </button>
                                    <button
                                        className="btn btn-primary d-flex align-items-center gap-2 event-btn"
                                        onClick={() => setShowEventForm(true)}
                                        disabled={actionLoading}
                                    >
                                        Dodaj Wydarzenie
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div className="feed-items-list">
                    {filteredAndSortedItems.length > 0 ? (
                        filteredAndSortedItems.map((item) => (
                            <FeedItemCard
                                key={`${item.type}-${item.id}`}
                                item={item}
                                imageUrl={imageCache[item.mainImageId]}
                                onEdit={() => handleEdit(item)}
                                onDelete={(id, title, type) => {
                                    if (type === "post") {
                                        handleDeletePost(id, title);
                                    } else {
                                        handleDeleteEvent(id, title);
                                    }
                                }}
                                onShowParticipants={handleShowParticipants}
                                onShowImages={handleShowImages}
                                onShowDetails={handleShowDetails}
                                fundraising={
                                    item.fundraisingId
                                        ? fundraisingCache[item.fundraisingId]
                                        : null
                                }
                                formatDate={formatDate}
                                formatEventDuration={formatEventDuration}
                            />
                        ))
                    ) : (
                        <div className="text-center py-5 bg-light rounded">
                            <MessageSquare
                                size={48}
                                className="text-muted mb-3"
                            />
                            <h4 className="text-muted">
                                Brak treści do wyświetlenia
                            </h4>
                            <p className="text-muted">
                                Spróbuj zmienić filtry lub dodaj nowy
                                post/wydarzenie.
                            </p>
                        </div>
                    )}
                </div>

                <FeedItemForm
                    type="post"
                    shelterId={shelter.id}
                    isOpen={showPostForm}
                    onClose={() => {
                        setShowPostForm(false);
                        setEditingPost(null);
                    }}
                    onSave={editingPost ? handleUpdatePost : handleCreatePost}
                    editData={editingPost}
                />
                <FeedItemForm
                    type="event"
                    shelterId={shelter.id}
                    isOpen={showEventForm}
                    onClose={() => {
                        setShowEventForm(false);
                        setEditingEvent(null);
                    }}
                    onSave={
                        editingEvent ? handleUpdateEvent : handleCreateEvent
                    }
                    editData={editingEvent}
                />
                {showParticipantsModal && (
                    <ParticipantsModal
                        event={selectedEvent}
                        onClose={handleCloseParticipantsModal}
                    />
                )}
                {showImagesModal && (
                    <ImagesModal
                        item={selectedItem}
                        images={selectedItemImages}
                        onClose={handleCloseImagesModal}
                    />
                )}
                {showDetailsModal && (
                    <PostDetailsModal
                        item={selectedItemForDetails}
                        imageUrls={selectedItemImages}
                        onClose={handleCloseDetailsModal}
                        onShowParticipants={handleShowParticipants}
                        formatDate={formatDate}
                        formatEventDuration={formatEventDuration}
                        fundraising={
                            selectedItemForDetails?.fundraisingId
                                ? fundraisingCache[
                                      selectedItemForDetails.fundraisingId
                                  ]
                                : null
                        }
                    />
                )}
            </div>
        </div>
    );
};

const FeedItemCard = ({
    item,
    imageUrl,
    onEdit,
    onDelete,
    onShowParticipants,
    onShowImages,
    onShowDetails,
    fundraising,
    formatDate,
    formatEventDuration,
}) => {
    const isEvent = item.type === "event";
    const hasImage = !!imageUrl;

    return (
        <div className={`feed-item-card ${hasImage ? "with-image" : ""}`}>
            {hasImage && (
                <div className="feed-item-image-wrapper">
                    <img
                        src={imageUrl}
                        alt={item.title}
                        className="feed-item-image"
                        loading="lazy"
                        onError={(e) => {
                            e.target.style.display = "none";
                        }}
                    />
                </div>
            )}

            <div className="feed-item-content-wrapper">
                <div className="feed-item-header">
                    <div className="feed-item-title">
                        {isEvent ? (
                            <Calendar size={20} />
                        ) : (
                            <MessageSquare size={20} />
                        )}
                        <span>{item.title}</span>
                    </div>
                    <span className="feed-item-meta">
                        {formatDate(item.createdAt)}
                    </span>
                </div>

                {item.shortDescription && (
                    <div className="feed-item-short-description mb-2">
                        <small
                            className="text-muted short-description"
                            style={{
                                wordBreak: "break-word",
                            }}
                        >
                            {item.shortDescription}
                        </small>
                    </div>
                )}

                <div
                    className="feed-item-content"
                    style={{
                        display: "-webkit-box",
                        WebkitLineClamp: 2,
                        WebkitBoxOrient: "vertical",
                        overflow: "hidden",
                        marginBottom: "1rem",
                    }}
                >
                    {item.content || item.description}
                </div>

                {isEvent && (
                    <div className="event-details mb-3">
                        <div>
                            <Calendar size={16} />
                            <span>
                                {formatDate(
                                    item.startDateTime || item.startDate
                                )}
                            </span>
                        </div>
                        {item.location && (
                            <div>
                                <MapPin size={16} />
                                <span>{item.location}</span>
                            </div>
                        )}
                    </div>
                )}

                <div className="feed-item-footer">
                    <div className="d-flex gap-2">
                        <button
                            className="btn btn-sm btn-outline-primary"
                            onClick={() => onShowDetails(item)}
                        >
                            <Eye size={16} className="me-1" />
                            Szczegóły
                        </button>

                        <button
                            className="btn btn-sm btn-outline-secondary"
                            onClick={() => onEdit(item)}
                        >
                            <Edit size={16} className="me-1" />
                            Edytuj
                        </button>

                        <button
                            className="btn btn-sm btn-outline-danger"
                            onClick={() => {
                                if (item.type === "post") {
                                    onDelete(item.id, item.title, "post");
                                } else {
                                    onDelete(item.id, item.title, "event");
                                }
                            }}
                        >
                            <Trash2 size={16} className="me-1" />
                            Usuń
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

const ParticipantsModal = ({ event, onClose }) => {
    const [participants, setParticipants] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");

    useEffect(() => {
        if (event) {
            loadParticipants();
        }
    }, [event]);

    const loadParticipants = async () => {
        try {
            setLoading(true);
            const result = await getEventParticipants(event.id);
            if (result.success) {
                setParticipants(result.data || []);
            } else {
                setError(result.error || "Błąd ładowania uczestników");
            }
        } catch (err) {
            setError("Wystąpił błąd podczas ładowania uczestników");
        } finally {
            setLoading(false);
        }
    };

    if (!event) return null;

    return (
        <div
            className="modal fade show d-block"
            style={{ backgroundColor: "rgba(0,0,0,0.5)" }}
            onClick={(e) => e.target === e.currentTarget && onClose()}
        >
            <div className="modal-dialog modal-lg">
                <div className="modal-content">
                    <div className="modal-header">
                        <h5 className="modal-title d-flex align-items-center gap-2">
                            <Users size={20} />
                            Uczestnicy eventu: {event.title}
                        </h5>
                        <button
                            type="button"
                            className="btn-close"
                            onClick={onClose}
                        ></button>
                    </div>

                    <div className="modal-body">
                        {loading ? (
                            <div className="text-center py-4">
                                <Loader
                                    size={32}
                                    className="spinner-border text-primary"
                                />
                                <p className="mt-2 text-muted">
                                    Ładowanie uczestników...
                                </p>
                            </div>
                        ) : error ? (
                            <div className="alert alert-danger d-flex align-items-center">
                                <AlertCircle size={16} className="me-2" />
                                {error}
                            </div>
                        ) : participants.length === 0 ? (
                            <div className="text-center py-4">
                                <Users size={48} className="text-muted mb-3" />
                                <h5 className="text-muted">Brak uczestników</h5>
                                <p className="text-muted">
                                    Nikt jeszcze nie zapisał się na ten event.
                                </p>
                            </div>
                        ) : (
                            <div>
                                <div className="mb-3">
                                    <strong>Liczba uczestników: </strong>
                                    {participants.length}

                                    {event.capacity > 0 && (
                                        <span className="text-muted">
                                            {" "}
                                            / {event.capacity}
                                        </span>
                                    )}
                                </div>

                                <ul className="list-group participant-modal-list">
                                    {participants.map((participant, index) => (
                                        <li
                                            key={participant.id || index}
                                            className="list-group-item participant-modal-item d-flex justify-content-between align-items-center"
                                        >
                                            <div className="d-flex align-items-center">
                                                <div
                                                    className="bg-primary text-white rounded-circle d-flex align-items-center justify-content-center me-3"
                                                    style={{
                                                        width: "40px",
                                                        height: "40px",
                                                    }}
                                                >
                                                    {(
                                                        participant.username?.charAt(
                                                            0
                                                        ) ||
                                                        participant.firstName?.charAt(
                                                            0
                                                        ) ||
                                                        participant.email?.charAt(
                                                            0
                                                        ) ||
                                                        "U"
                                                    ).toUpperCase()}
                                                </div>
                                                <div>
                                                    <div className="fw-medium">
                                                        {participant.firstName &&
                                                        participant.lastName
                                                            ? `${participant.firstName} ${participant.lastName}`
                                                            : participant.username ||
                                                              participant.email ||
                                                              "Użytkownik"}
                                                    </div>
                                                    {participant.username &&
                                                        (participant.firstName ||
                                                            participant.email) && (
                                                            <small className="text-muted">
                                                                @
                                                                {
                                                                    participant.username
                                                                }
                                                            </small>
                                                        )}
                                                    {participant.email &&
                                                        !participant.firstName && (
                                                            <small className="text-muted">
                                                                {
                                                                    participant.email
                                                                }
                                                            </small>
                                                        )}
                                                </div>
                                            </div>

                                            <span className="badge bg-success">
                                                Uczestnik
                                            </span>
                                        </li>
                                    ))}
                                </ul>
                            </div>
                        )}
                    </div>

                    <div className="modal-footer">
                        <button
                            type="button"
                            className="btn btn-secondary"
                            onClick={onClose}
                        >
                            Zamknij
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ShelterFeed;
