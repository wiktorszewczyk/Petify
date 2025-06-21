const API_URL = "http://localhost:8222";

export async function login(loginIdentifier, password) {
    const response = await fetch(`${API_URL}/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ loginIdentifier, password }),
    });

    let data;
    try {
        data = await response.json();
    } catch (err) {
        throw new Error("Nie znaleziono konta.");
    }

    if (response.ok) {
        if (data?.jwt) {
            localStorage.setItem("jwt", data.jwt);

            if (data.user) {
                localStorage.setItem("petify_user", JSON.stringify(data.user));
            } else {
            }

            return data;
        } else {
            throw new Error("Brak tokenu w odpowiedzi.");
        }
    } else {
        if (response.status === 401 || response.status === 403) {
            throw new Error("Nieprawidłowe hasło.");
        }
        throw new Error("Logowanie nieudane.");
    }
}

export async function register(userData) {
    const response = await fetch(`${API_URL}/auth/register`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            username: userData.email,
            password: userData.password,
            firstName: userData.firstName,
            lastName: userData.lastName,
            birthDate: userData.birthDate,
            gender: userData.gender,
            phoneNumber: userData.phoneNumber,
            email: userData.email,
        }),
    });

    const data = await response.json();

    if (response.ok) {
        return data;
    } else {
        throw new Error(data.error || "Rejestracja nieudana");
    }
}

export async function fetchUserData() {
    const token = getToken();

    const response = await fetch(`${API_URL}/user`, {
        headers: {
            Authorization: `Bearer ${token}`,
        },
    });

    if (!response.ok) {
        throw new Error("Nie udało się pobrać danych użytkownika");
    }

    const user = await response.json();

    return {
        firstName: user.firstName,
        lastName: user.lastName,
        birthDate: user.birthDate,
        gender: user.gender,
        phoneNumber: user.phoneNumber,
        email: user.email,
        city: user.city,
        volunteerStatus: user.volunteerStatus,
        level: user.level,
        xpPoints: user.xpPoints,
        xpToNextLevel: user.xpToNextLevel,
        likesCount: user.likesCount,
        supportCount: user.supportCount,
        badgesCount: user.badgesCount,
        achievements: user.achievements || [],
        profileImageBase64: user.profileImage,
    };
}

export async function uploadProfileImage(file) {
    const token = getToken();
    const formData = new FormData();
    formData.append("image", file);

    const response = await fetch(`${API_URL}/user/profile-image`, {
        method: "POST",
        headers: {
            Authorization: `Bearer ${token}`,
        },
        body: formData,
    });

    if (!response.ok) {
        throw new Error("Błąd podczas wysyłania zdjęcia");
    }

    return await response.json();
}

export async function fetchProfileImage() {
    const token = getToken();

    const response = await fetch(`${API_URL}/user/profile-image`, {
        method: "GET",
        headers: {
            Authorization: `Bearer ${token}`,
        },
    });

    if (!response.ok) {
        throw new Error("Nie udało się pobrać zdjęcia profilowego");
    }

    const data = await response.json();

    if (data.hasImage === "true" && data.image) {
        return data.image;
    } else {
        throw new Error("Brak zdjęcia profilowego");
    }
}

export async function deleteProfileImage() {
    const token = getToken();

    const response = await fetch(`${API_URL}/user/profile-image`, {
        method: "DELETE",
        headers: {
            Authorization: `Bearer ${token}`,
        },
    });

    if (!response.ok) {
        throw new Error("Nie udało się usunąć zdjęcia profilowego");
    }

    return await response.json();
}

export const updateUserData = async (data) => {
    const response = await fetch(`${API_URL}/user`, {
        method: "PUT",
        headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify(data),
    });

    if (!response.ok) {
        throw new Error("Błąd podczas aktualizacji danych użytkownika");
    }

    return await response.json();
};

export function getToken() {
    return localStorage.getItem("jwt");
}

export function isAuthenticated() {
    const token = localStorage.getItem("jwt");
    return !!token;
}

export async function handleGoogleLogin(idToken) {
    const res = await fetch(`${API_URL}/auth/oauth2/exchange`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            provider: "google",
            access_token: idToken,
        }),
    });

    const data = await res.json();

    if (res.ok && data?.jwt) {
        localStorage.setItem("jwt", data.jwt);
        if (data.user) {
            localStorage.setItem("petify_user", JSON.stringify(data.user));
        }
        return data;
    } else {
        throw new Error(data?.error || "Błąd logowania przez Google");
    }
}

export function logout() {
    localStorage.removeItem("jwt");
    localStorage.removeItem("petify_user");
    window.location.href = "/login";
}

export function getCurrentUser() {
    try {
        const userData = localStorage.getItem("petify_user");
        return userData ? JSON.parse(userData) : null;
    } catch (error) {
        return null;
    }
}

export function hasRole(role) {
    const user = getCurrentUser();

    if (!user || !user.authorities) {
        return false;
    }

    const hasRole = user.authorities.some((auth) => {
        const authority = auth.authority || auth;
        const matches = authority === `ROLE_${role}` || authority === role;
        return matches;
    });
    return hasRole;
}

export function isShelterOwner() {
    return hasRole("SHELTER");
}

export function isAdmin() {
    return hasRole("ADMIN");
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
            logout();
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

export async function getAllUsers() {
    try {
        const data = await apiCall("/admin/users/");
        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd pobierania użytkowników" };
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

export async function getSystemStats() {
    try {
        const data = await apiCall("/admin/system/stats");
        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd pobierania statystyk systemu" };
    }
}

export async function validateToken() {
    try {
        const token = getToken();
        if (!token) return false;

        const data = await apiCall("/auth/token/validate", { method: "POST" });
        return data.valid;
    } catch (error) {
        return false;
    }
}

export async function refreshUserData() {
    try {
        const userData = await fetchUserData();
        if (userData) {
            localStorage.setItem("petify_user", JSON.stringify(userData));
            return userData;
        }
    } catch (error) {}
    return null;
}

export function initiateGoogleLogin() {
    window.location.href = `${API_URL}/oauth2/authorization/google`;
}

export async function handleOAuth2Success(token) {
    try {
        localStorage.setItem("jwt", token);
        const user = await fetchUserData();
        if (user) {
            localStorage.setItem("petify_user", JSON.stringify(user));
        }
        return user;
    } catch (error) {
        return null;
    }
}
