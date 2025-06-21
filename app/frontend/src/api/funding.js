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

export async function getShelterFundraisers(shelterId, page = 0, size = 20) {
    try {
        const data = await apiCall(
            `/fundraisers/shelter/${shelterId}?page=${page}&size=${size}&sort=createdAt,desc`
        );
        return {
            success: true,
            data: data.content || data,
        };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania zbiórek schroniska",
        };
    }
}

export async function createFundraiser(shelterId, fundraiserData) {
    try {
        if (!fundraiserData.title || !fundraiserData.title.trim()) {
            return {
                success: false,
                error: "Tytuł jest wymagany",
            };
        }

        if (
            !fundraiserData.goalAmount ||
            parseFloat(fundraiserData.goalAmount) < 1
        ) {
            return {
                success: false,
                error: "Kwota docelowa musi wynosić co najmniej 1.00",
            };
        }

        const categoryMapping = {
            MEDICAL: "MEDICAL",
            INFRASTRUCTURE: "INFRASTRUCTURE",
            EVENT_BASED: "EVENT_BASED",
            EMERGENCY: "EMERGENCY",
            GENERAL: "GENERAL",
        };

        const backendType =
            categoryMapping[fundraiserData.category] || "GENERAL";

        const fundraiserPayload = {
            shelterId: shelterId,
            title: fundraiserData.title.trim(),
            description: fundraiserData.description?.trim() || null,
            goalAmount: parseFloat(fundraiserData.goalAmount),
            type: backendType,
            endDate: fundraiserData.endDate
                ? new Date(fundraiserData.endDate).toISOString()
                : null,
            isMain: false,
            needs: fundraiserData.needs?.trim() || null,
        };

        const data = await apiCall("/fundraisers", {
            method: "POST",
            body: JSON.stringify(fundraiserPayload),
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
        if (!fundraiserData.title || !fundraiserData.title.trim()) {
            return {
                success: false,
                error: "Tytuł jest wymagany",
            };
        }

        if (
            !fundraiserData.goalAmount ||
            parseFloat(fundraiserData.goalAmount) < 1
        ) {
            return {
                success: false,
                error: "Kwota docelowa musi wynosić co najmniej 1.00",
            };
        }

        const categoryMapping = {
            MEDICAL: "MEDICAL",
            GENERAL: "GENERAL",
            EMERGENCY: "EMERGENCY",
            INFRASTRUCTURE: "INFRASTRUCTURE",
            EVENT_BASED: "EVENT_BASED",
        };

        const backendType =
            categoryMapping[fundraiserData.category] || "GENERAL";

        const fundraiserPayload = {
            shelterId:
                fundraiserData.shelterId || fundraiserData.originalShelterId,
            title: fundraiserData.title.trim(),
            description: fundraiserData.description?.trim() || null,
            goalAmount: parseFloat(fundraiserData.goalAmount),
            type: backendType,
            endDate: fundraiserData.endDate
                ? new Date(fundraiserData.endDate).toISOString()
                : null,
            isMain: fundraiserData.isMain || false,
            needs: fundraiserData.needs?.trim() || null,
        };

        const data = await apiCall(`/fundraisers/${fundraiserId}`, {
            method: "PUT",
            body: JSON.stringify(fundraiserPayload),
        });

        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd aktualizacji zbiórki",
        };
    }
}

export async function getFundraiserById(fundraiserId) {
    try {
        const data = await apiCall(`/fundraisers/${fundraiserId}`);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania zbiórki",
        };
    }
}

export async function toggleFundraiserStatus(fundraiserId, activate) {
    try {
        const status = activate ? "ACTIVE" : "PAUSED";
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
            error: "Błąd zmiany statusu zbiórki",
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

export async function getShelterDonations(shelterId, page = 0, size = 20) {
    try {
        const data = await apiCall(
            `/donations/shelter/${shelterId}?page=${page}&size=${size}&sort=donatedAt,desc`
        );
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania dotacji schroniska",
        };
    }
}

export async function getFundraiserDonations(
    fundraiserId,
    page = 0,
    size = 20
) {
    try {
        const data = await apiCall(
            `/donations/fundraiser/${fundraiserId}?page=${page}&size=${size}&sort=donatedAt,desc`
        );
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania dotacji zbiórki",
        };
    }
}

export async function createDonation(donationData) {
    try {
        const data = await apiCall("/donations", {
            method: "POST",
            body: JSON.stringify(donationData),
        });
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd tworzenia dotacji",
        };
    }
}

export async function getUserDonations(page = 0, size = 20) {
    try {
        const data = await apiCall(
            `/donations/my?page=${page}&size=${size}&sort=donatedAt,desc`
        );
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania dotacji użytkownika",
        };
    }
}

export async function getDashboardData(shelterId) {
    try {
        const donationStatsData = await apiCall(
            `/donations/shelter/${shelterId}/stats`
        );

        const fundraisersData = await apiCall(
            `/fundraisers/shelter/${shelterId}?page=0&size=1000`
        );
        const fundraisers = fundraisersData.content || fundraisersData;

        const fundraiserStats = calculateFundraiserStats(fundraisers);

        const combinedStats = {
            totalDonations: donationStatsData.totalDonations || 0,
            totalAmount: donationStatsData.totalAmount || 0,
            completedDonations: donationStatsData.completedDonations || 0,
            pendingDonations: donationStatsData.pendingDonations || 0,
            averageDonationAmount: donationStatsData.averageDonationAmount || 0,
            lastDonationDate: donationStatsData.lastDonationDate,

            totalFundraisers: fundraiserStats.total,
            activeFundraisers: fundraiserStats.active,
            completedFundraisers: fundraiserStats.completed,
            expiredFundraisers: fundraiserStats.expired,
            totalRaised: fundraiserStats.totalRaised,
            totalGoal: fundraiserStats.totalGoal,
            averageProgress: fundraiserStats.averageProgress,
        };

        return { success: true, data: combinedStats };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania danych dashboard",
        };
    }
}

function calculateFundraiserStats(fundraisers) {
    if (!fundraisers || fundraisers.length === 0) {
        return {
            total: 0,
            active: 0,
            completed: 0,
            expired: 0,
            totalRaised: 0,
            totalGoal: 0,
            averageProgress: 0,
        };
    }

    const now = new Date();
    let active = 0;
    let completed = 0;
    let expired = 0;
    let totalRaised = 0;
    let totalGoal = 0;
    let totalProgress = 0;

    fundraisers.forEach((fundraiser) => {
        totalRaised += fundraiser.currentAmount || 0;
        totalGoal += fundraiser.goalAmount || 0;

        const progress =
            fundraiser.goalAmount > 0
                ? (fundraiser.currentAmount / fundraiser.goalAmount) * 100
                : 0;
        totalProgress += progress;

        if (fundraiser.endDate && new Date(fundraiser.endDate) < now) {
            expired++;
        } else if (fundraiser.currentAmount >= fundraiser.goalAmount) {
            completed++;
        } else if (fundraiser.status === "ACTIVE") {
            active++;
        }
    });

    return {
        total: fundraisers.length,
        active,
        completed,
        expired,
        totalRaised,
        totalGoal,
        averageProgress:
            fundraisers.length > 0 ? totalProgress / fundraisers.length : 0,
    };
}
