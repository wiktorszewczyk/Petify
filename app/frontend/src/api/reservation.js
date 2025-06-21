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

    return response.json();
}

export async function getAllSlots() {
    try {
        const data = await apiCall("/reservations/slots");
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania wszystkich slotów.",
        };
    }
}

export async function createBatchSlots(batchData) {
    try {
        const data = await apiCall("/reservations/slots/batch", {
            method: "POST",
            body: JSON.stringify(batchData),
        });
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd podczas tworzenia slotów.",
        };
    }
}

export async function getSlotsForPet(petId) {
    try {
        const data = await apiCall(`/reservations/slots/pet/${petId}`);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania slotów dla zwierzęcia.",
        };
    }
}

export async function deleteSlot(slotId) {
    try {
        const token = getToken();
        const response = await fetch(
            `${API_URL}/reservations/slots/${slotId}`,
            {
                method: "DELETE",
                headers: {
                    "Content-Type": "application/json",
                    ...(token && { Authorization: `Bearer ${token}` }),
                },
            }
        );

        if (!response.ok) {
            if (response.status === 401 || response.status === 403) {
                localStorage.removeItem("jwt");
                localStorage.removeItem("petify_user");
                window.location.href = "/login";
            }
            throw new Error(`API Error: ${response.status}`);
        }

        return { success: true };
    } catch (error) {
        return {
            success: false,
            error: "Błąd podczas usuwania slota.",
        };
    }
}

export async function cancelReservation(slotId) {
    try {
        const data = await apiCall(`/reservations/slots/${slotId}/cancel`, {
            method: "PATCH",
        });
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd podczas anulowania rezerwacji.",
        };
    }
}

export async function reactivateSlot(slotId) {
    try {
        const data = await apiCall(`/reservations/${slotId}/reactivate`, {
            method: "PATCH",
        });
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd podczas reaktywacji slota.",
        };
    }
}

export async function getUserReservations() {
    try {
        const data = await apiCall("/reservations/user");
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania rezerwacji użytkownika.",
        };
    }
}

export async function makeReservation(slotId) {
    try {
        const data = await apiCall(`/reservations/slots/${slotId}/reserve`, {
            method: "POST",
        });
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd podczas tworzenia rezerwacji.",
        };
    }
}

export async function cancelUserReservation(slotId) {
    try {
        const data = await apiCall(`/reservations/slots/${slotId}/unreserve`, {
            method: "POST",
        });
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd podczas anulowania rezerwacji.",
        };
    }
}
