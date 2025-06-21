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

export async function getPetsPaginated(page = 0, size = 50) {
    try {
        const data = await apiCall(`/pets?page=${page}&size=${size}`);
        return {
            success: true,
            data: data.content,
            pageInfo: {
                currentPage: data.number,
                totalPages: data.totalPages,
                totalElements: data.totalElements,
                hasNext: !data.last,
                hasPrevious: !data.first,
            },
        };
    } catch (error) {
        return { success: false, error: "Błąd pobierania zwierząt" };
    }
}

export async function getPetById(petId) {
    try {
        const data = await apiCall(`/pets/${petId}`);
        return { success: true, data };
    } catch (error) {
        if (error.message.includes("404")) {
            return { success: false, error: "Zwierzę nie zostało znalezione" };
        }
        return { success: false, error: "Błąd pobierania zwierzęcia" };
    }
}

export async function addPet(petData, imageFile) {
    try {
        const formData = new FormData();

        const petRequest = {
            name: petData.name,
            type: petData.type,
            breed: petData.breed,
            age: petData.age,
            gender: petData.gender,
            size: petData.size,
            description: petData.description,
            vaccinated: petData.vaccinated || false,
            sterilized: petData.sterilized || false,
            kidFriendly: petData.kidFriendly || false,
            urgent: petData.urgent || false,
        };

        formData.append(
            "petRequest",
            new Blob([JSON.stringify(petRequest)], {
                type: "application/json",
            })
        );

        if (imageFile) {
            formData.append("imageFile", imageFile);
        }

        const response = await fetch(`${API_URL}/pets`, {
            method: "POST",
            headers: {
                Authorization: `Bearer ${getToken()}`,
            },
            body: formData,
        });

        if (!response.ok) {
            let errorMessage = "Błąd dodawania zwierzęcia";
            if (response.status === 400) {
                errorMessage = "Nieprawidłowe dane zwierzęcia";
            } else if (response.status === 403) {
                errorMessage = "Brak uprawnień do dodawania zwierząt";
            }
            return { success: false, error: errorMessage };
        }

        const data = await response.json();
        return { success: true, data };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

export async function updatePet(petId, petData, imageFile = null) {
    try {
        const formData = new FormData();

        const petRequest = {
            name: petData.name,
            type: petData.type,
            breed: petData.breed,
            age: petData.age,
            gender: petData.gender,
            size: petData.size,
            description: petData.description,
            vaccinated: petData.vaccinated || false,
            sterilized: petData.sterilized || false,
            kidFriendly: petData.kidFriendly || false,
            urgent: petData.urgent || false,
        };

        formData.append(
            "petRequest",
            new Blob([JSON.stringify(petRequest)], {
                type: "application/json",
            })
        );

        if (imageFile) {
            formData.append("imageFile", imageFile);
        }

        const response = await fetch(`${API_URL}/pets/${petId}`, {
            method: "PUT",
            headers: {
                Authorization: `Bearer ${getToken()}`,
            },
            body: formData,
        });

        if (!response.ok) {
            let errorMessage = "Błąd aktualizacji zwierzęcia";
            if (response.status === 400) {
                errorMessage = "Nieprawidłowe dane zwierzęcia";
            } else if (response.status === 403) {
                errorMessage = "Brak uprawnień do edycji tego zwierzęcia";
            } else if (response.status === 404) {
                errorMessage = "Zwierzę nie zostało znalezione";
            }
            return { success: false, error: errorMessage };
        }

        const data = await response.json();
        return { success: true, data };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

export async function deletePet(petId) {
    try {
        await apiCall(`/pets/${petId}`, { method: "DELETE" });
        return { success: true };
    } catch (error) {
        return { success: false, error: "Błąd usuwania zwierzęcia" };
    }
}

export async function archivePet(petId) {
    try {
        const data = await apiCall(`/pets/${petId}/archive`, {
            method: "PATCH",
        });
        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd archiwizacji zwierzęcia" };
    }
}

export async function getPetImages(petId) {
    try {
        const data = await apiCall(`/pets/${petId}/images`);
        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd pobierania zdjęć", data: [] };
    }
}

export async function addPetImages(petId, imageFiles) {
    try {
        const formData = new FormData();

        imageFiles.forEach((file) => {
            formData.append("images", file);
        });

        const response = await fetch(`${API_URL}/pets/${petId}/images`, {
            method: "POST",
            headers: {
                Authorization: `Bearer ${getToken()}`,
            },
            body: formData,
        });

        if (!response.ok) {
            return { success: false, error: "Błąd dodawania zdjęć" };
        }

        const data = await response.json();
        return { success: true, data };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

export async function deletePetImage(petId, imageId) {
    try {
        await apiCall(`/pets/${petId}/images/${imageId}`, { method: "DELETE" });
        return { success: true };
    } catch (error) {
        return { success: false, error: "Błąd usuwania zdjęcia" };
    }
}

export async function getPetAdoptions(petId) {
    try {
        const data = await apiCall(`/pets/${petId}/adoptions`);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania wniosków adopcyjnych",
        };
    }
}

export async function likePet(petId) {
    try {
        const data = await apiCall(`/pets/${petId}/like`, { method: "POST" });
        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd polubienia zwierzęcia" };
    }
}

export async function supportPet(petId) {
    try {
        const data = await apiCall(`/pets/${petId}/support`, {
            method: "POST",
        });
        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd wsparcia zwierzęcia" };
    }
}

export async function getFavoritePets() {
    try {
        const data = await apiCall("/pets/favorites");
        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd pobierania ulubionych zwierząt" };
    }
}

export async function getSupportedPets() {
    try {
        const data = await apiCall("/pets/supportedPets");
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania wspieranych zwierząt",
        };
    }
}

export async function getFilteredPets(filters = {}) {
    try {
        const params = new URLSearchParams();

        Object.entries(filters).forEach(([key, value]) => {
            if (value !== null && value !== undefined && value !== "") {
                params.append(key, value);
            }
        });

        const data = await apiCall(`/pets/filter?${params.toString()}`);
        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd filtrowania zwierząt" };
    }
}

export async function getPetsStats() {
    try {
        const result = await getAllPets();
        if (!result.success) {
            return result;
        }

        const pets = result.data;
        return {
            success: true,
            data: {
                totalPets: pets.length,
                activePets: pets.filter((pet) => !pet.archived).length,
                archivedPets: pets.filter((pet) => pet.archived).length,
            },
        };
    } catch (error) {
        return { success: false, error: "Błąd pobierania statystyk zwierząt" };
    }
}

export async function getAllPetIds() {
    try {
        const data = await apiCall("/pets/ids");
        return { success: true, data };
    } catch (error) {
        return { success: false, error: "Błąd pobierania ID zwierząt" };
    }
}

export async function getPetIdsByShelterId(shelterId) {
    try {
        const data = await apiCall(`/pets/shelter/${shelterId}/ids`);
        return { success: true, data };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania ID zwierząt ze schroniska",
        };
    }
}
