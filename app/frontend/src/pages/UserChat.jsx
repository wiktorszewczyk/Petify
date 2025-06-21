import React, { useState, useEffect, useRef, useCallback } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { ArrowLeft, Send, Heart, MessageCircle, PawPrint } from "lucide-react";
import Navbar from "../components/Navbar";
import {
    openChatForPet,
    getChatHistory,
    createWebSocketConnection,
    subscribeToRoom,
    sendMessage,
} from "../api/chat";
import { fetchPetById, fetchShelterById } from "../api/shelter";
import "./UserChat.css";

const UserChat = () => {
    const { petId } = useParams();
    const navigate = useNavigate();
    const [chatRoom, setChatRoom] = useState(null);
    const [messages, setMessages] = useState([]);
    const [messageInput, setMessageInput] = useState("");
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");
    const [pet, setPet] = useState(null);
    const [shelter, setShelter] = useState(null);
    const stompClientRef = useRef(null);
    const subscriptionRef = useRef(null);
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

    useEffect(() => {
        if (!petId || !currentUser) return;

        const initializeChat = async () => {
            setLoading(true);
            try {
                const petData = await fetchPetById(petId);
                setPet(petData);
                if (petData.shelterId) {
                    const shelterData = await fetchShelterById(
                        petData.shelterId
                    );
                    setShelter(shelterData);
                }

                const roomResult = await openChatForPet(petId);
                if (roomResult.success) {
                    const room = roomResult.data;
                    setChatRoom(room);
                    const historyResult = await getChatHistory(room.id);
                    if (historyResult.success) {
                        setMessages(historyResult.data.content.reverse());
                    }
                } else {
                    setError(roomResult.error);
                }
            } catch (err) {
                setError("Błąd inicjalizacji czatu.");
            } finally {
                setLoading(false);
            }
        };

        initializeChat();
    }, [petId, currentUser]);

    useEffect(() => {
        if (!chatRoom) return;

        const stompClient = createWebSocketConnection();
        stompClientRef.current = stompClient;

        stompClient.connect(
            { Authorization: `Bearer ${localStorage.getItem("jwt")}` },
            () => {
                console.log("✅ WebSocket połączony dla użytkownika.");
                const subscription = subscribeToRoom(
                    stompClient,
                    chatRoom.id,
                    (messageData) => {
                        setMessages((prev) => [...prev, messageData]);
                    }
                );
                subscriptionRef.current = subscription;
            }
        );

        return () => {
            if (subscriptionRef.current) subscriptionRef.current.unsubscribe();
            if (stompClientRef.current?.connected)
                stompClientRef.current.disconnect();
        };
    }, [chatRoom]);

    useEffect(() => {
        if (messages.length) {
            messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
        }
    }, [messages]);

    const handleSendMessage = useCallback(() => {
        if (
            !messageInput.trim() ||
            !chatRoom ||
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

        sendMessage(stompClientRef.current, chatRoom.id, content);
    }, [messageInput, chatRoom, currentUser]);

    // POPRAWKA: Prosta i niezawodna funkcja do sprawdzania autora wiadomości
    const isOwnMessage = (message) => {
        return currentUser && message.sender === currentUser.username;
    };

    const handleBack = () => navigate(-1);
    const handleKeyPress = (e) => {
        if (e.key === "Enter" && !e.shiftKey) {
            e.preventDefault();
            handleSendMessage();
        }
    };
    const formatTime = (timestamp) =>
        new Date(timestamp).toLocaleTimeString("pl-PL", {
            hour: "2-digit",
            minute: "2-digit",
        });
    const formatDate = (timestamp) =>
        new Date(timestamp).toLocaleDateString("pl-PL", {
            day: "numeric",
            month: "long",
            year: "numeric",
        });

    if (loading) {
        return <div>Ładowanie...</div>;
    }

    if (error) {
        return <div>Błąd: {error}</div>;
    }

    return (
        <div className="user-chat">
            <Navbar />
            <div className="chat-container">
                <div className="chat-header">
                    <button className="btn-back" onClick={handleBack}>
                        <ArrowLeft size={24} />
                    </button>
                    {pet && (
                        <div className="chat-pet-info">
                            <div className="pet-avatar">
                                {pet.photos && pet.photos.length > 0 ? (
                                    <img
                                        src={pet.photos[0]}
                                        alt={pet.name}
                                        className="pet-image"
                                    />
                                ) : (
                                    <PawPrint size={32} />
                                )}
                            </div>
                            <div className="pet-details">
                                <h4 className="pet-name">{pet.name}</h4>
                                {shelter && (
                                    <p className="shelter-name">
                                        {shelter.name}
                                    </p>
                                )}
                            </div>
                        </div>
                    )}
                    <div className="chat-actions">
                        <button
                            className="btn-profile"
                            onClick={() => navigate(`/pet/${petId}`)}
                        >
                            <Heart size={16} className="me-1" /> Profil
                        </button>
                    </div>
                </div>

                <div className="messages-container">
                    {messages.length === 0 ? (
                        <div className="empty-chat">
                            <MessageCircle
                                size={48}
                                className="text-muted mb-3"
                            />
                            <h5>Rozpocznij rozmowę!</h5>
                            <p className="text-muted">
                                Napisz wiadomość do schroniska {shelter?.name}{" "}
                                dotyczącą {pet?.name}
                            </p>
                        </div>
                    ) : (
                        <div className="messages-list">
                            {messages.map((message, index) => {
                                const showDate =
                                    index === 0 ||
                                    formatDate(message.timestamp) !==
                                        formatDate(
                                            messages[index - 1].timestamp
                                        );
                                return (
                                    <div key={message.id || `msg-${index}`}>
                                        {showDate && (
                                            <div className="date-separator">
                                                <span>
                                                    {formatDate(
                                                        message.timestamp
                                                    )}
                                                </span>
                                            </div>
                                        )}
                                        <div
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
                                    </div>
                                );
                            })}
                            <div ref={messagesEndRef} />
                        </div>
                    )}
                </div>

                <div className="message-input-container">
                    <div className="message-input-wrapper">
                        <textarea
                            value={messageInput}
                            onChange={(e) => setMessageInput(e.target.value)}
                            onKeyPress={handleKeyPress}
                            placeholder={`Napisz wiadomość do ${shelter?.name}...`}
                            className="message-input"
                            rows={1}
                        />
                        <button
                            onClick={handleSendMessage}
                            disabled={!messageInput.trim()}
                            className="send-button"
                        >
                            <Send size={20} />
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default UserChat;
