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

export async function getShelterPosts(shelterId) {
    try {
        const data = await apiCall(`/posts/shelter/${shelterId}/posts`);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania postów schroniska",
        };
    }
}

export async function getPostById(postId) {
    try {
        const data = await apiCall(`/posts/${postId}`);
        return { success: true, data };
    } catch (error) {
        if (error.message.includes("404")) {
            return { success: false, error: "Post nie został znaleziony" };
        }
        return { success: false, error: "Błąd pobierania posta" };
    }
}

export async function createPost(shelterId, postData) {
    try {
        const data = await apiCall(`/posts/shelter/${shelterId}/posts`, {
            method: "POST",
            body: JSON.stringify(postData),
        });
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd tworzenia posta",
        };
    }
}

export async function updatePost(postId, postData) {
    try {
        const data = await apiCall(`/posts/${postId}`, {
            method: "PUT",
            body: JSON.stringify(postData),
        });
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd aktualizacji posta",
        };
    }
}

export async function deletePost(postId) {
    try {
        await apiCall(`/posts/${postId}`, {
            method: "DELETE",
        });
        return { success: true };
    } catch (error) {
        return { success: false, error: "Błąd usuwania posta" };
    }
}

export async function getRecentPosts(days = 7) {
    try {
        const data = await apiCall(`/posts/recent/${days}`);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania najnowszych postów",
        };
    }
}

export async function searchRecentPosts(days, content) {
    try {
        const data = await apiCall(
            `/posts/recent/${days}/search?content=${encodeURIComponent(
                content
            )}`
        );
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd wyszukiwania postów",
        };
    }
}

export async function getShelterEvents(shelterId) {
    try {
        const data = await apiCall(`/events/shelter/${shelterId}/events`);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania wydarzeń schroniska",
        };
    }
}

export async function getEventById(eventId) {
    try {
        const data = await apiCall(`/events/${eventId}`);
        return { success: true, data };
    } catch (error) {
        if (error.message.includes("404")) {
            return {
                success: false,
                error: "Wydarzenie nie zostało znalezione",
            };
        }
        return { success: false, error: "Błąd pobierania wydarzenia" };
    }
}

export async function createEvent(shelterId, eventData) {
    try {
        const data = await apiCall(`/events/shelter/${shelterId}/events`, {
            method: "POST",
            body: JSON.stringify(eventData),
        });
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd tworzenia wydarzenia",
        };
    }
}

export async function updateEvent(eventId, eventData) {
    try {
        const data = await apiCall(`/events/${eventId}`, {
            method: "PUT",
            body: JSON.stringify(eventData),
        });
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd aktualizacji wydarzenia",
        };
    }
}

export async function deleteEvent(eventId) {
    try {
        await apiCall(`/events/${eventId}`, {
            method: "DELETE",
        });
        return { success: true };
    } catch (error) {
        return { success: false, error: "Błąd usuwania wydarzenia" };
    }
}

export async function getIncomingEvents(days = 30) {
    try {
        const data = await apiCall(`/events/incoming/${days}`);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania nadchodzących wydarzeń",
        };
    }
}

export async function searchIncomingEvents(days, content) {
    try {
        const data = await apiCall(
            `/events/incoming/${days}/search?content=${encodeURIComponent(
                content
            )}`
        );
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd wyszukiwania wydarzeń",
        };
    }
}

export async function joinEvent(eventId) {
    try {
        const data = await apiCall(`/events/${eventId}/join`, {
            method: "POST",
        });
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd dołączania do wydarzenia",
        };
    }
}

export async function leaveEvent(eventId) {
    try {
        await apiCall(`/events/${eventId}/leave`, { method: "DELETE" });
        return { success: true };
    } catch (error) {
        return {
            success: false,
            error: "Błąd opuszczania wydarzenia",
        };
    }
}

export async function getEventParticipants(eventId) {
    try {
        const data = await apiCall(`/events/${eventId}/participants`);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania uczestników wydarzenia",
        };
    }
}

export async function checkEventParticipation(eventId) {
    try {
        const data = await apiCall(`/events/${eventId}/participation-status`);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd sprawdzania uczestnictwa w wydarzeniu",
        };
    }
}

export async function getFundraisingById(fundraiserId) {
    try {
        const data = await apiCall(`/fundraisers/${fundraiserId}`);
        return { success: true, data };
    } catch (error) {
        if (error.message.includes("404")) {
            return { success: false, error: "Zbiórka nie została znaleziona" };
        }
        return { success: false, error: "Błąd pobierania zbiórki" };
    }
}

export async function getShelterFundraisers(shelterId) {
    try {
        const data = await apiCall(`/fundraisers/shelter/${shelterId}`);
        const fundraisers = data.content || data;
        return {
            success: true,
            data: Array.isArray(fundraisers) ? fundraisers : [],
        };
    } catch (error) {
        if (error.message.includes("404") || error.message.includes("405")) {
            return { success: true, data: [] };
        }
        return {
            success: false,
            error: "Błąd pobierania zbiórek schroniska",
        };
    }
}

export async function getActiveFundraisers(page = 0, size = 20) {
    try {
        const data = await apiCall(`/fundraisers?page=${page}&size=${size}`);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania aktywnych zbiórek",
        };
    }
}

export async function getMainFundraiser(shelterId) {
    try {
        const data = await apiCall(`/fundraisers/shelter/${shelterId}/main`);
        return { success: true, data };
    } catch (error) {
        if (error.message.includes("404")) {
            return { success: false, error: "Brak głównej zbiórki" };
        }
        return {
            success: false,
            error: "Błąd pobierania głównej zbiórki",
        };
    }
}

export async function createFundraiser(fundraiserData) {
    try {
        const data = await apiCall("/fundraisers", {
            method: "POST",
            body: JSON.stringify(fundraiserData),
        });
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd tworzenia zbiórki",
        };
    }
}

export async function updateFundraiser(fundraiserId, fundraiserData) {
    try {
        const data = await apiCall(`/fundraisers/${fundraiserId}`, {
            method: "PUT",
            body: JSON.stringify(fundraiserData),
        });
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd aktualizacji zbiórki",
        };
    }
}

export async function updateFundraiserStatus(fundraiserId, status) {
    try {
        const data = await apiCall(
            `/fundraisers/${fundraiserId}/status?status=${status}`,
            {
                method: "PUT",
            }
        );
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd aktualizacji statusu zbiórki",
        };
    }
}

export async function getFundraiserStats(fundraiserId) {
    try {
        const data = await apiCall(`/fundraisers/${fundraiserId}/stats`);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania statystyk zbiórki",
        };
    }
}

export async function deleteFundraiser(fundraiserId) {
    try {
        await apiCall(`/fundraisers/${fundraiserId}`, { method: "DELETE" });
        return { success: true };
    } catch (error) {
        return {
            success: false,
            error: "Błąd usuwania zbiórki",
        };
    }
}

export async function getShelterFeed(shelterId, limit = 50, offset = 0) {
    try {
        const [postsResult, eventsResult] = await Promise.all([
            getShelterPosts(shelterId),
            getShelterEvents(shelterId),
        ]);

        let feedItems = [];

        if (postsResult.success) {
            feedItems.push(
                ...postsResult.data.map((post) => ({
                    ...post,
                    type: "post",
                }))
            );
        }

        if (eventsResult.success) {
            feedItems.push(
                ...eventsResult.data.map((event) => ({
                    ...event,
                    type: "event",
                }))
            );
        }

        feedItems.sort((a, b) => {
            const dateA = new Date(a.createdAt || a.startDate);
            const dateB = new Date(b.createdAt || b.startDate);
            return dateB.getTime() - dateA.getTime();
        });

        const paginatedItems = feedItems.slice(offset, offset + limit);

        return {
            success: true,
            data: {
                items: paginatedItems,
                total: feedItems.length,
                hasMore: offset + limit < feedItems.length,
            },
        };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania aktualności schroniska",
        };
    }
}

export async function searchShelterFeed(shelterId, query, type = "all") {
    try {
        const feedResult = await getShelterFeed(shelterId, 1000);

        if (!feedResult.success) {
            return feedResult;
        }

        let items = feedResult.data.items;

        if (type !== "all") {
            items = items.filter((item) => item.type === type);
        }

        if (query && query.trim()) {
            const searchTerm = query.toLowerCase().trim();
            items = items.filter(
                (item) =>
                    item.title.toLowerCase().includes(searchTerm) ||
                    item.shortDescription.toLowerCase().includes(searchTerm) ||
                    (item.longDescription &&
                        item.longDescription
                            .toLowerCase()
                            .includes(searchTerm)) ||
                    (item.address &&
                        item.address.toLowerCase().includes(searchTerm))
            );
        }

        return {
            success: true,
            data: {
                items: items,
                total: items.length,
                query: query,
                type: type,
            },
        };
    } catch (error) {
        return {
            success: false,
            error: "Błąd wyszukiwania w aktualnościach",
        };
    }
}

export function validatePostData(postData) {
    const errors = [];

    if (!postData.title || postData.title.trim().length === 0) {
        errors.push("Tytuł jest wymagany");
    }

    if (postData.title && postData.title.length > 100) {
        errors.push("Tytuł nie może być dłuższy niż 100 znaków");
    }

    if (
        !postData.shortDescription ||
        postData.shortDescription.trim().length === 0
    ) {
        errors.push("Krótki opis jest wymagany");
    }

    if (
        postData.shortDescription &&
        (postData.shortDescription.length < 10 ||
            postData.shortDescription.length > 200)
    ) {
        errors.push("Krótki opis musi mieć między 10 a 200 znaków");
    }

    if (postData.longDescription && postData.longDescription.length > 2000) {
        errors.push("Szczegółowy opis nie może być dłuższy niż 2000 znaków");
    }

    return {
        isValid: errors.length === 0,
        errors: errors,
    };
}

export function validateEventData(eventData) {
    const errors = [];

    if (!eventData.title || eventData.title.trim().length === 0) {
        errors.push("Tytuł jest wymagany");
    }

    if (eventData.title && eventData.title.length > 100) {
        errors.push("Tytuł nie może być dłuższy niż 100 znaków");
    }

    if (
        !eventData.shortDescription ||
        eventData.shortDescription.trim().length === 0
    ) {
        errors.push("Krótki opis jest wymagany");
    }

    if (
        eventData.shortDescription &&
        (eventData.shortDescription.length < 10 ||
            eventData.shortDescription.length > 200)
    ) {
        errors.push("Krótki opis musi mieć między 10 a 200 znaków");
    }

    if (!eventData.startDate) {
        errors.push("Data rozpoczęcia jest wymagana");
    }

    if (!eventData.endDate) {
        errors.push("Data zakończenia jest wymagana");
    }

    if (eventData.startDate && eventData.endDate) {
        const start = new Date(eventData.startDate);
        const end = new Date(eventData.endDate);

        if (start >= end) {
            errors.push(
                "Data zakończenia musi być późniejsza niż data rozpoczęcia"
            );
        }

        if (start < new Date()) {
            errors.push("Data rozpoczęcia nie może być w przeszłości");
        }
    }

    if (!eventData.address || eventData.address.trim().length === 0) {
        errors.push("Adres jest wymagany");
    }

    if (eventData.capacity && eventData.capacity < 0) {
        errors.push("Pojemność nie może być ujemna");
    }

    if (eventData.longDescription && eventData.longDescription.length > 2000) {
        errors.push("Szczegółowy opis nie może być dłuższy niż 2000 znaków");
    }

    return {
        isValid: errors.length === 0,
        errors: errors,
    };
}
