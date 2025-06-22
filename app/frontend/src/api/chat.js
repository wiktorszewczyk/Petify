// api/chat.js - ZASTĄP CAŁY PLIK tym kodem

const API_URL = "http://localhost:8222";

export function getToken() {
    return localStorage.getItem("jwt");
}

async function apiCall(endpoint, options = {}) {
    const token = getToken();
    const response = await fetch(`${API_URL}${endpoint}`, {
        ...options,
        headers: {
            "Content-Type": "application/json",
            ...(token && { Authorization: `Bearer ${token}` }),
            ...options.headers,
        },
    });

    if (!response.ok) {
        if (response.status === 401 || response.status === 403) {
            localStorage.removeItem("jwt");
            localStorage.removeItem("petify_user");
            window.location.href = "/login";
        }
        throw new Error(`API Error: ${response.status}`);
    }

    if (
        response.status === 204 ||
        response.headers.get("content-length") === "0"
    ) {
        return null;
    }

    const contentType = response.headers.get("content-type");
    if (contentType && contentType.includes("application/json")) {
        return response.json();
    }

    return null;
}

// Open chat room for specific pet (user side)
export async function openChatForPet(petId) {
    try {
        const data = await apiCall(`/chat/room/${petId}`);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd tworzenia pokoju czatu",
        };
    }
}

// Get all chat rooms for current user
export async function getChatRooms() {
    try {
        const data = await apiCall("/chat/rooms");
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania pokojów czatu",
        };
    }
}

// Open chat room by ID
export async function openChatById(roomId) {
    try {
        const data = await apiCall(`/chat/rooms/${roomId}`);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd otwierania pokoju czatu",
        };
    }
}

// Get chat history for a room
export async function getChatHistory(roomId, page = 0, size = 40) {
    try {
        const data = await apiCall(
            `/chat/history/${roomId}?page=${page}&size=${size}`
        );
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania historii czatu",
        };
    }
}

// Hide/delete chat room
export async function hideChatRoom(roomId) {
    try {
        await apiCall(`/chat/rooms/${roomId}`, {
            method: "DELETE",
        });
        return { success: true };
    } catch (error) {
        return {
            success: false,
            error: "Błąd ukrywania pokoju czatu",
        };
    }
}

// Get total unread messages count
export async function getUnreadCount() {
    try {
        const data = await apiCall("/chat/unread/count");
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania liczby nieprzeczytanych wiadomości",
        };
    }
}

// WebSocket connection helper
export function createWebSocketConnection() {
    const token = getToken();
    if (!token) {
        throw new Error("No authentication token found");
    }

    const SockJS = window.SockJS;
    const Stomp = window.Stomp;

    if (!SockJS || !Stomp) {
        throw new Error(
            "SockJS or Stomp not loaded. Please include the required scripts."
        );
    }

    const socket = new SockJS("http://localhost:8050/ws-chat");
    const stompClient = Stomp.over(socket);
    stompClient.debug = () => {}; // Disable debug logging

    return stompClient;
}

// Subscribe to specific chat room
export function subscribeToRoom(stompClient, roomId, onMessage) {
    if (!stompClient || !stompClient.connected) {
        throw new Error("WebSocket not connected");
    }

    return stompClient.subscribe(`/user/queue/chat/${roomId}`, (message) => {
        const messageData = JSON.parse(message.body);
        if (onMessage) {
            onMessage(messageData);
        }
    });
}

// Send message to chat room
export function sendMessage(stompClient, roomId, content) {
    if (!stompClient || !stompClient.connected) {
        throw new Error("WebSocket not connected");
    }

    stompClient.send(`/app/chat/${roomId}`, {}, content);
}
