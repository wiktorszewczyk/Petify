const API_URL = "http://localhost:8222";
import { majorPolishCities } from "../assets/cities";

const mapTypeToEnum = {
    Kot: "CAT",
    Pies: "DOG",
    Inny: "OTHER",
};

export function getToken() {
    return localStorage.getItem("jwt");
}

export const fetchFavoritePets = async () => {
    const token = getToken();
    const response = await fetch(`${API_URL}/pets/favorites`, {
        method: "GET",
        headers: {
            Authorization: `Bearer ${token}`,
        },
    });

    if (response.status === 404) {
        return [];
    }

    if (!response.ok) {
        throw new Error("Wystąpił błąd serwera.");
    }

    return await response.json();
};

export const fetchShelters = async () => {
    const token = getToken();
    const response = await fetch(`${API_URL}/shelters`, {
        method: "GET",
        headers: {
            Authorization: `Bearer ${token}`,
        },
    });

    if (response.status === 404) {
        return [];
    }

    if (!response.ok) {
        throw new Error("Błąd podczas pobierania schronisk");
    }

    const data = await response.json();
    return data.content || data;
};

export const fetchShelterById = async (shelterId) => {
    const token = getToken();
    const response = await fetch(`${API_URL}/shelters/${shelterId}`, {
        headers: {
            Authorization: `Bearer ${token}`,
        },
    });

    if (!response.ok) {
        throw new Error("Nie udało się pobrać danych schroniska");
    }

    return await response.json();
};

export const fetchImagesByPetId = async (petId) => {
    const token = getToken();
    const response = await fetch(`${API_URL}/pets/${petId}/images`, {
        headers: {
            Authorization: `Bearer ${token}`,
        },
    });

    if (!response.ok) return [];
    return await response.json();
};

export const fetchPetById = async (petId) => {
    const token = getToken();
    const response = await fetch(`${API_URL}/pets/${petId}`, {
        headers: {
            Authorization: `Bearer ${token}`,
        },
    });

    if (!response.ok) {
        throw new Error("Nie udało się pobrać danych zwierzaka.");
    }

    return await response.json();
};

export const fetchShelterProfileById = async (shelterId) => {
    const token = getToken();
    const response = await fetch(`${API_URL}/shelters/${shelterId}`, {
        headers: {
            Authorization: `Bearer ${token}`,
        },
    });

    if (!response.ok) {
        throw new Error("Nie udało się pobrać danych schroniska.");
    }

    return await response.json();
};

export const fetchFilteredAnimals = async (filters, cursor = 1) => {
    const jwt = getToken();
    const params = new URLSearchParams();

    if (filters.type && filters.type !== "Wszystkie") {
        const mappedType = mapTypeToEnum[filters.type];
        if (mappedType) {
            params.append("type", mappedType);
        }
    }
    params.append("minAge", filters.ageRange[0]);
    params.append("maxAge", filters.ageRange[1]);
    if (filters.vaccinated) params.append("vaccinated", filters.vaccinated);
    if (filters.urgent) params.append("urgent", filters.urgent);
    if (filters.city) {
        const found = majorPolishCities.find((c) => c.name === filters.city);
        if (found) {
            params.append("userLat", found.lat);
            params.append("userLng", found.lon);
        }
    }

    if (filters.distance) {
        params.append("radiusKm", filters.distance);
    }
    params.append("limit", 50);
    params.append("cursor", cursor);

    const response = await fetch(
        `${API_URL}/pets/filter?${params.toString()}`,
        {
            method: "GET",
            headers: {
                Authorization: `Bearer ${jwt}`,
                "Content-Type": "application/json",
            },
        }
    );

    if (!response.ok) {
        throw new Error("Błąd pobierania danych");
    }

    const data = await response.json();

    const petsArray = data.pets || data.content || data;

    if (!Array.isArray(petsArray)) {
        console.error("Backend response:", data);
        throw new Error("Backend nie zwrócił tablicy zwierząt");
    }

    const enrichedAnimals = await Promise.all(
        petsArray.map(async (animal, index) => {
            console.log(`🐾 Processing animal ${index + 1}:`, {
                id: animal.id,
                name: animal.name,
                imageUrl: animal.imageUrl,
                images: animal.images,
                imagesCount: animal.images?.length || 0,
            });

            let shelterName = `Schronisko #${animal.shelterId}`;
            let shelterAddress = "";

            try {
                const shelterRes = await fetch(
                    `${API_URL}/shelters/${animal.shelterId}`,
                    {
                        headers: {
                            Authorization: `Bearer ${jwt}`,
                        },
                    }
                );

                if (shelterRes.ok) {
                    const shelter = await shelterRes.json();
                    shelterName = shelter.name;
                    shelterAddress = shelter.address || "";
                }
            } catch (e) {
                console.warn(
                    `Nie udało się pobrać danych schroniska dla ID ${animal.shelterId}`
                );
            }

            const processedPhotos =
                animal.images?.map((img) => img.imageUrl) || [];

            // Dodaj główne zdjęcie na początek jeśli istnieje
            if (animal.imageUrl && !processedPhotos.includes(animal.imageUrl)) {
                processedPhotos.unshift(animal.imageUrl);
            }

            console.log(`📸 Final photos for ${animal.name}:`, processedPhotos);

            return {
                ...animal,
                photos: processedPhotos,
                characteristics: animal.characteristics || [],
                location: shelterName,
                shelterAddress,
                shelterName,
            };
        })
    );

    console.log(
        "✅ All enriched animals with photos:",
        enrichedAnimals.map((a) => ({
            name: a.name,
            photos: a.photos,
            photosCount: a.photos.length,
        }))
    );

    return enrichedAnimals;
};

export const likePet = async (petId) => {
    const jwt = getToken();
    const response = await fetch(`${API_URL}/pets/${petId}/like`, {
        method: "POST",
        headers: {
            Authorization: `Bearer ${jwt}`,
            "Content-Type": "application/json",
        },
    });

    if (!response.ok) {
        throw new Error("Nie udało się polubić zwierzaka");
    }
};

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

export async function getMyShelter() {
    try {
        const data = await apiCall("/shelters/my-shelter");
        return { success: true, data };
    } catch (error) {
        if (error.message.includes("404")) {
            return { success: true, notFound: true, data: null };
        }
        return { success: false, error: "Błąd pobierania danych schroniska" };
    }
}

export async function createShelter(shelterData, imageFile) {
    try {
        const formData = new FormData();

        const shelterRequest = {
            name: shelterData.name,
            description: shelterData.description || "",
            address: shelterData.address,
            phoneNumber: shelterData.phoneNumber,
            latitude: shelterData.latitude,
            longitude: shelterData.longitude,
        };

        formData.append(
            "shelterRequest",
            new Blob([JSON.stringify(shelterRequest)], {
                type: "application/json",
            })
        );

        if (imageFile) {
            formData.append("imageFile", imageFile);
        }

        const response = await fetch(`${API_URL}/shelters`, {
            method: "POST",
            headers: {
                Authorization: `Bearer ${getToken()}`,
            },
            body: formData,
        });

        if (!response.ok) {
            if (response.status === 409) {
                return {
                    success: false,
                    error: "Już masz przypisane schronisko",
                };
            }
            return { success: false, error: "Błąd tworzenia schroniska" };
        }

        const data = await response.json();
        return { success: true, data };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

export async function updateShelter(shelterId, shelterData, imageFile) {
    try {
        const formData = new FormData();

        const shelterRequest = {
            name: shelterData.name,
            description: shelterData.description || "",
            address: shelterData.address,
            phoneNumber: shelterData.phoneNumber,
            latitude: shelterData.latitude,
            longitude: shelterData.longitude,
        };

        formData.append(
            "shelterRequest",
            new Blob([JSON.stringify(shelterRequest)], {
                type: "application/json",
            })
        );

        if (imageFile) {
            formData.append("imageFile", imageFile);
        }

        const response = await fetch(`${API_URL}/shelters/${shelterId}`, {
            method: "PUT",
            headers: {
                Authorization: `Bearer ${getToken()}`,
            },
            body: formData,
        });

        if (!response.ok) {
            return { success: false, error: "Błąd aktualizacji schroniska" };
        }

        const data = await response.json();
        return { success: true, data };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

export async function getCoordinatesFromAddress(address) {
    try {
        const encodedAddress = encodeURIComponent(`${address}, Poland`);
        const response = await fetch(
            `https://nominatim.openstreetmap.org/search?q=${encodedAddress}&format=json&limit=1&countrycodes=pl`
        );
        const data = await response.json();

        if (data && data.length > 0) {
            return {
                success: true,
                coordinates: {
                    latitude: parseFloat(data[0].lat),
                    longitude: parseFloat(data[0].lon),
                },
            };
        }

        return {
            success: false,
            error: "Nie znaleziono współrzędnych dla podanego adresu",
        };
    } catch (error) {
        return {
            success: false,
            error: "Błąd podczas pobierania współrzędnych",
        };
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

export async function activateShelter(shelterId) {
    try {
        const response = await fetch(
            `${API_URL}/shelters/${shelterId}/activate`,
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${getToken()}`,
                },
            }
        );

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        return { success: true };
    } catch (error) {
        return { success: false, error: "Błąd podczas aktywacji schroniska" };
    }
}

export async function deactivateShelter(shelterId) {
    try {
        const response = await fetch(
            `${API_URL}/shelters/${shelterId}/deactivate`,
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${getToken()}`,
                },
            }
        );

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        return { success: true };
    } catch (error) {
        return { success: false, error: "Błąd podczas deaktywacji schroniska" };
    }
}

export async function getPetsForShelter(shelterId) {
    try {
        const data = await apiCall(`/shelters/${shelterId}/pets`);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania zwierząt schroniska.",
        };
    }
}
