import React, { useState, useEffect, useRef, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import {
    ArrowLeft,
    MessageCircle,
    Send,
    PawPrint,
    User,
    Search,
    Trash2,
} from "lucide-react";
import Navbar from "../../components/Navbar";
import {
    getChatRooms,
    getChatHistory,
    createWebSocketConnection,
    subscribeToRoom,
    sendMessage,
    hideChatRoom,
    getUnreadCount,
    openChatById,
} from "../../api/chat";
import { fetchPetById } from "../../api/shelter";
import "./ShelterPanel.css";

const ShelterMessages = () => {
    const navigate = useNavigate();
    const [chatRooms, setChatRooms] = useState([]);
    const [selectedRoom, setSelectedRoom] = useState(null);
    const [messages, setMessages] = useState([]);
    const [messageInput, setMessageInput] = useState("");
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");
    const [searchTerm, setSearchTerm] = useState("");
    const [unreadCount, setUnreadCount] = useState(0);
    const [petDataCache, setPetDataCache] = useState({});

    const stompClientRef = useRef(null);
    const activeRoomSubscriptionRef = useRef(null);
    const messagesEndRef = useRef(null);
    const [currentUser, setCurrentUser] = useState(null);

    useEffect(() => {
        const userData = localStorage.getItem("petify_user");
        if (userData) {
            setCurrentUser(JSON.parse(userData));
        } else {
            setLoading(false);
        }
    }, []);

    const loadTotalUnread = useCallback(async () => {
        try {
            const result = await getUnreadCount();
            if (result.success) setUnreadCount(result.data);
        } catch (e) {
            console.warn(
                "Błąd ładowania globalnego licznika nieprzeczytanych",
                e
            );
        }
    }, []);

    useEffect(() => {
        if (!currentUser) return;

        const loadInitialData = async () => {
            setLoading(true);
            try {
                const roomsResult = await getChatRooms();
                if (roomsResult.success) {
                    setChatRooms(roomsResult.data);
                    const petIds = [
                        ...new Set(roomsResult.data.map((room) => room.petId)),
                    ];
                    const petPromises = petIds.map((id) =>
                        fetchPetById(id).catch(() => null)
                    );
                    const pets = await Promise.all(petPromises);
                    const cache = {};
                    pets.forEach((pet) => {
                        if (pet) cache[pet.id] = { pet };
                    });
                    setPetDataCache(cache);
                } else {
                    setError(roomsResult.error);
                }
                await loadTotalUnread();
            } catch (err) {
                setError("Błąd ładowania danych czatu.");
            } finally {
                setLoading(false);
            }
        };

        loadInitialData();
    }, [currentUser, loadTotalUnread]);

    useEffect(() => {
        if (!currentUser) return;

        const stompClient = createWebSocketConnection();
        stompClientRef.current = stompClient;
        const subscriptions = [];

        stompClient.connect(
            { Authorization: `Bearer ${localStorage.getItem("jwt")}` },
            () => {
                console.log("✅ WebSocket połączony dla schroniska.");

                subscriptions.push(
                    stompClient.subscribe("/user/queue/rooms", () => {
                        getChatRooms().then((result) => {
                            if (result.success) setChatRooms(result.data);
                        });
                    })
                );

                subscriptions.push(
                    stompClient.subscribe("/user/queue/unread", (message) => {
                        setUnreadCount(parseInt(message.body, 10));
                    })
                );
            }
        );

        return () => {
            subscriptions.forEach((sub) => sub.unsubscribe());
            if (stompClientRef.current?.connected) {
                stompClientRef.current.disconnect();
            }
        };
    }, [currentUser]);

    useEffect(() => {
        if (!selectedRoom) return;

        if (activeRoomSubscriptionRef.current) {
            activeRoomSubscriptionRef.current.unsubscribe();
        }

        const loadAndSubscribe = async () => {
            try {
                const historyResult = await getChatHistory(selectedRoom.id);
                setMessages(
                    historyResult.success
                        ? historyResult.data.content.reverse()
                        : []
                );
            } catch (e) {
                console.error("Błąd ładowania historii", e);
            }

            if (stompClientRef.current?.connected) {
                const subscription = subscribeToRoom(
                    stompClientRef.current,
                    selectedRoom.id,
                    (messageData) => {
                        setMessages((prev) => [...prev, messageData]);
                    }
                );
                activeRoomSubscriptionRef.current = subscription;
            }
        };

        loadAndSubscribe();

        return () => {
            if (activeRoomSubscriptionRef.current) {
                activeRoomSubscriptionRef.current.unsubscribe();
            }
        };
    }, [selectedRoom]);

    useEffect(() => {
        if (messages.length) {
            messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
        }
    }, [messages]);

    const handleRoomSelect = (room) => {
        if (selectedRoom?.id === room.id) return;
        setSelectedRoom(room);

        if (room.unreadCount > 0) {
            setChatRooms((prev) =>
                prev.map((r) =>
                    r.id === room.id ? { ...r, unreadCount: 0 } : r
                )
            );
            setUnreadCount((prev) => Math.max(0, prev - room.unreadCount));
            openChatById(room.id).catch((err) =>
                console.error(
                    "Błąd przy oznaczaniu pokoju jako przeczytany:",
                    err
                )
            );
        }
    };

    const handleSendMessage = useCallback(() => {
        if (
            !messageInput.trim() ||
            !selectedRoom ||
            !stompClientRef.current?.connected
        )
            return;
        const content = messageInput.trim();

        setMessages((prev) => [
            ...prev,
            {
                id: `temp-${Date.now()}`,
                sender: currentUser.username,
                content,
                timestamp: new Date().toISOString(),
            },
        ]);
        setMessageInput("");

        sendMessage(stompClientRef.current, selectedRoom.id, content);
    }, [messageInput, selectedRoom, currentUser]);

    const isOwnMessage = (message) => {
        return currentUser && message.sender === currentUser.username;
    };

    const filteredRooms = chatRooms.filter((room) => {
        const petData = petDataCache[room.petId];
        const petName = petData?.pet?.name || "";
        const userName = room.userName || "";
        return (
            petName.toLowerCase().includes(searchTerm.toLowerCase()) ||
            userName.toLowerCase().includes(searchTerm.toLowerCase())
        );
    });

    const handleKeyPress = (e) => {
        if (e.key === "Enter" && !e.shiftKey) {
            e.preventDefault();
            handleSendMessage();
        }
    };

    const handleBack = () => navigate("/shelter-panel");
    const handleDeleteRoom = async (roomId, e) => {
        e.stopPropagation();
        if (window.confirm("Czy na pewno chcesz ukryć tę rozmowę?")) {
            const result = await hideChatRoom(roomId);
            if (result.success) {
                setChatRooms((prev) =>
                    prev.filter((room) => room.id !== roomId)
                );
                if (selectedRoom?.id === roomId) {
                    setSelectedRoom(null);
                }
            }
        }
    };

    const formatTime = (timestamp) =>
        new Date(timestamp).toLocaleTimeString("pl-PL", {
            hour: "2-digit",
            minute: "2-digit",
        });
    const formatDate = (timestamp) => {
        if (!timestamp) return "";
        return new Date(timestamp).toLocaleDateString("pl-PL", {
            day: "numeric",
            month: "short",
        });
    };

    if (loading) {
        return (
            <div className="shelter-panel">
                <Navbar />
                <div
                    className="container mt-4 pb-5"
                    style={{ textAlign: "center" }}
                >
                    <div className="spinner-border text-primary" role="status">
                        <span className="visually-hidden">Ładowanie...</span>
                    </div>
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
                        <MessageCircle
                            size={32}
                            className="text-primary me-3"
                        />
                        <div>
                            <h2 className="mb-0">
                                Wiadomości
                                {unreadCount > 0 && (
                                    <span className="badge bg-danger ms-2">
                                        {unreadCount}
                                    </span>
                                )}
                            </h2>
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

                {error && <div className="alert alert-danger">{error}</div>}

                <div className="chat-interface">
                    <div className="rooms-panel">
                        <div className="rooms-header">
                            <h5>Rozmowy ({filteredRooms.length})</h5>
                            <div className="search-box">
                                <Search size={16} className="search-icon" />
                                <input
                                    type="text"
                                    placeholder="Szukaj rozmów..."
                                    value={searchTerm}
                                    onChange={(e) =>
                                        setSearchTerm(e.target.value)
                                    }
                                    className="search-input"
                                />
                            </div>
                        </div>
                        <div className="rooms-list">
                            {filteredRooms.length === 0 ? (
                                <div className="empty-rooms">
                                    <MessageCircle
                                        size={48}
                                        className="text-muted mb-3"
                                    />
                                    <p className="text-muted">Brak rozmów</p>
                                </div>
                            ) : (
                                filteredRooms.map((room) => {
                                    const petData = petDataCache[room.petId];
                                    const pet = petData?.pet;
                                    return (
                                        <div
                                            key={room.id}
                                            className={`room-item ${
                                                selectedRoom?.id === room.id
                                                    ? "active"
                                                    : ""
                                            }`}
                                            onClick={() =>
                                                handleRoomSelect(room)
                                            }
                                        >
                                            <div className="room-avatar">
                                                {pet?.imageUrl ? (
                                                    <img
                                                        src={pet.imageUrl}
                                                        alt={pet.name}
                                                        className="room-pet-image"
                                                    />
                                                ) : (
                                                    <PawPrint size={24} />
                                                )}
                                            </div>
                                            <div className="room-details">
                                                <div className="room-header">
                                                    <h6 className="room-title">
                                                        {pet?.name || "Zwierzę"}
                                                    </h6>
                                                    <span className="room-time">
                                                        {formatDate(
                                                            room.lastMessageTimestamp
                                                        )}
                                                    </span>
                                                </div>
                                                <div className="room-info">
                                                    <div className="room-user">
                                                        <User size={14} />
                                                        <span>
                                                            {room.userName}
                                                        </span>
                                                    </div>
                                                    {room.unreadCount > 0 && (
                                                        <span className="unread-badge">
                                                            {room.unreadCount}
                                                        </span>
                                                    )}
                                                </div>
                                            </div>
                                            <button
                                                className="room-actions"
                                                onClick={(e) =>
                                                    handleDeleteRoom(room.id, e)
                                                }
                                            >
                                                <Trash2 size={16} />
                                            </button>
                                        </div>
                                    );
                                })
                            )}
                        </div>
                    </div>

                    <div className="chat-panel">
                        {!selectedRoom ? (
                            <div className="no-room-selected">
                                <MessageCircle
                                    size={64}
                                    className="text-muted mb-3"
                                />
                                <h5>Wybierz rozmowę</h5>
                                <p className="text-muted">
                                    Kliknij na rozmowę z lewej strony, aby
                                    rozpocząć czat
                                </p>
                            </div>
                        ) : (
                            <>
                                {/* ===== PRZYWRÓCONY FRAGMENT NAGŁÓWKA ===== */}
                                <div className="chat-header">
                                    {(() => {
                                        const petData =
                                            petDataCache[selectedRoom.petId];
                                        const pet = petData?.pet;
                                        return (
                                            <div className="chat-header-info">
                                                <div className="chat-avatar">
                                                    {pet?.imageUrl ? (
                                                        <img
                                                            src={pet.imageUrl}
                                                            alt={pet.name}
                                                            className="chat-pet-image"
                                                        />
                                                    ) : (
                                                        <PawPrint size={32} />
                                                    )}
                                                </div>
                                                <div className="chat-details">
                                                    <h5>
                                                        {pet?.name ||
                                                            "Nieznane zwierzę"}
                                                    </h5>
                                                    <p>
                                                        Rozmowa z{" "}
                                                        {selectedRoom.userName}
                                                    </p>
                                                </div>
                                            </div>
                                        );
                                    })()}
                                </div>
                                {/* ===== KONIEC PRZYWRÓCONEGO FRAGMENTU ===== */}

                                <div className="messages-container">
                                    {messages.map((message, index) => (
                                        <div
                                            key={message.id || `msg-${index}`}
                                            className={`message ${
                                                isOwnMessage(message)
                                                    ? "own"
                                                    : "other"
                                            }`}
                                        >
                                            <div className="message-content">
                                                {message.content}
                                            </div>
                                            <div className="message-time">
                                                {formatTime(message.timestamp)}
                                            </div>
                                        </div>
                                    ))}
                                    <div ref={messagesEndRef} />
                                </div>
                                <div className="message-input-area">
                                    <div className="message-input-wrapper">
                                        <textarea
                                            value={messageInput}
                                            onChange={(e) =>
                                                setMessageInput(e.target.value)
                                            }
                                            onKeyPress={handleKeyPress}
                                            placeholder={`Odpowiedz ${selectedRoom.userName}...`}
                                            className="message-input"
                                            rows={1}
                                        />
                                        <button
                                            onClick={handleSendMessage}
                                            disabled={!messageInput.trim()}
                                            className="send-button"
                                        >
                                            <Send size={18} />
                                        </button>
                                    </div>
                                </div>
                            </>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ShelterMessages;
