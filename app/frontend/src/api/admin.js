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

export async function getAdminStats() {
    try {
        const data = await apiCall("/admin/stats");
        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd pobierania statystyk" };
    }
}

export async function getSystemStats() {
    try {
        const data = await apiCall("/admin/system/stats");
        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd pobierania statystyk systemu" };
    }
}

export async function getAllUsers() {
    try {
        const data = await apiCall("/admin/users/");
        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd pobierania użytkowników" };
    }
}

export async function updateUserStatus(userId, status) {
    try {
        const data = await apiCall(`/admin/users/${userId}/status`, {
            method: "PUT",
            body: JSON.stringify({ status }),
        });
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd aktualizacji statusu użytkownika",
        };
    }
}

export async function deleteUser(userId) {
    try {
        await apiCall(`/admin/users/${userId}`, { method: "DELETE" });
        return { success: true };
    } catch (error) {
        return { success: false, error: "Błąd usuwania użytkownika" };
    }
}

export async function getVolunteerApplications(status = "PENDING") {
    try {
        const url = status
            ? `/volunteer/applications/status/${status}`
            : "/volunteer/applications/status/PENDING";
        const data = await apiCall(url);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania wniosków wolontariuszy",
        };
    }
}

export async function updateVolunteerApplicationStatus(
    applicationId,
    action,
    reason = null
) {
    try {
        const url = `/volunteer/applications/${applicationId}/${action}`;
        const params = reason ? `?reason=${encodeURIComponent(reason)}` : "";
        const data = await apiCall(`${url}${params}`, { method: "PUT" });
        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd aktualizacji statusu wniosku" };
    }
}

export async function getAllShelters() {
    try {
        const response = await fetch(`${API_URL}/shelters?size=10000`, {
            headers: {
                Authorization: `Bearer ${getToken()}`,
            },
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const responseData = await response.json();
        const data = responseData.content || responseData;

        if (!Array.isArray(data)) {
            return {
                success: false,
                error: "Nieprawidłowy format danych schronisk",
            };
        }

        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd pobierania schronisk" };
    }
}

export async function deactivateUser(userId, reason = null) {
    try {
        const params = reason ? `?reason=${encodeURIComponent(reason)}` : "";
        const data = await apiCall(
            `/admin/users/${userId}/deactivate${params}`,
            {
                method: "PUT",
            }
        );
        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd dezaktywacji użytkownika" };
    }
}

export async function activateUser(userId) {
    try {
        const data = await apiCall(`/admin/users/${userId}/activate`, {
            method: "PUT",
        });
        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd aktywacji użytkownika" };
    }
}

export async function getShelterAdoptions(shelterId) {
    try {
        const data = await apiCall(`/shelters/${shelterId}/adoptions`);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania wniosków adopcyjnych dla schroniska",
        };
    }
}

export async function getAllPets() {
    try {
        const response = await fetch(`${API_URL}/pets?size=10000`, {
            headers: {
                Authorization: `Bearer ${getToken()}`,
            },
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const responseData = await response.json();
        const data = responseData.content || responseData;

        if (!Array.isArray(data)) {
            return {
                success: false,
                error: "Nieprawidłowy format danych zwierząt",
            };
        }

        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd pobierania zwierząt" };
    }
}

export async function getPetsStats() {
    try {
        const petsResult = await getAllPets();
        if (petsResult.success) {
            return {
                success: true,
                data: {
                    totalPets: petsResult.data.length,
                    activePets: petsResult.data.filter((pet) => !pet.archived)
                        .length,
                    archivedPets: petsResult.data.filter((pet) => pet.archived)
                        .length,
                },
            };
        }
        return petsResult;
    } catch (error) {
        return { success: false, error: "Błąd pobierania statystyk zwierząt" };
    }
}

export async function updateAdoptionStatus(adoptionId, status) {
    try {
        const data = await apiCall(
            `/adoptions/${adoptionId}/status?status=${status}`,
            {
                method: "PATCH",
            }
        );
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd aktualizacji statusu wniosku adopcyjnego",
        };
    }
}

export async function deleteAdoption(adoptionId) {
    try {
        await apiCall(`/adoptions/${adoptionId}`, { method: "DELETE" });
        return { success: true };
    } catch (error) {
        return {
            success: false,
            error: "Błąd podczas usuwania wniosku adopcyjnego",
        };
    }
}
