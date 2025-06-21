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

export async function geocode(address) {
    try {
        if (!address || !address.trim()) {
            return {
                success: false,
                error: "Adres jest wymagany",
            };
        }

        try {
            const data = await apiCall("/user/location/geocode", {
                method: "POST",
                body: JSON.stringify({ cityName: address.trim() }),
            });

            if (data) {
                return {
                    success: true,
                    data: {
                        latitude: data.latitude,
                        longitude: data.longitude,
                        cityName: data.cityName,
                        displayName: data.displayName || address,
                        country: data.country || "Poland",
                    },
                };
            }
        } catch (backendError) {}

        return geocodeWithNominatim(address);
    } catch (error) {
        return geocodeWithNominatim(address);
    }
}

export async function geocodeWithNominatim(address) {
    try {
        const encodedAddress = encodeURIComponent(`${address.trim()}, Poland`);
        const nominatimUrl = `https://nominatim.openstreetmap.org/search?q=${encodedAddress}&format=json&limit=1&countrycodes=pl&addressdetails=1`;

        const response = await fetch(nominatimUrl, {
            headers: {
                "User-Agent": "Petify-App/1.0",
            },
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const data = await response.json();

        if (data && data.length > 0) {
            const result = data[0];
            return {
                success: true,
                data: {
                    latitude: parseFloat(result.lat),
                    longitude: parseFloat(result.lon),
                    cityName: extractCityName(result.address),
                    displayName: result.display_name,
                    country: result.address?.country || "Poland",
                },
            };
        } else {
            return {
                success: false,
                error: "Nie znaleziono współrzędnych dla podanego adresu",
            };
        }
    } catch (error) {
        return {
            success: false,
            error: "Błąd podczas wyszukiwania współrzędnych",
        };
    }
}

export async function validateCity(cityName) {
    try {
        if (!cityName || !cityName.trim()) {
            return {
                success: false,
                error: "Nazwa miasta jest wymagana",
            };
        }

        try {
            const data = await apiCall("/user/location/validate-city", {
                method: "POST",
                body: JSON.stringify({ cityName: cityName.trim() }),
            });

            if (data) {
                return {
                    success: true,
                    data: {
                        valid: data.valid,
                        cityName: data.cityName,
                        location: data.location,
                    },
                };
            }
        } catch (backendError) {}

        const geocodeResult = await geocode(cityName);

        if (geocodeResult.success) {
            return {
                success: true,
                data: {
                    valid: true,
                    cityName: geocodeResult.data.cityName,
                    location: geocodeResult.data,
                },
            };
        } else {
            return {
                success: true,
                data: {
                    valid: false,
                    cityName: cityName.trim(),
                },
            };
        }
    } catch (error) {
        return {
            success: false,
            error: "Błąd walidacji miasta",
        };
    }
}

export async function updateUserLocation(locationData) {
    try {
        const data = await apiCall("/user/location/", {
            method: "PUT",
            body: JSON.stringify(locationData),
        });
        return {
            success: true,
            data: data,
        };
    } catch (error) {
        return {
            success: false,
            error: "Błąd aktualizacji lokalizacji użytkownika",
        };
    }
}

export async function setUserLocationByCity(cityName) {
    try {
        const data = await apiCall("/user/location/set-by-city", {
            method: "POST",
            body: JSON.stringify({ cityName: cityName }),
        });
        return {
            success: true,
            data: data,
        };
    } catch (error) {
        return {
            success: false,
            error: "Błąd ustawiania lokalizacji użytkownika",
        };
    }
}

export async function getUserLocation() {
    try {
        const data = await apiCall("/user/location/");
        return {
            success: true,
            data: data,
        };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania lokalizacji użytkownika",
        };
    }
}

export async function searchCities(query) {
    try {
        if (!query || query.trim().length < 2) {
            return {
                success: false,
                error: "Zapytanie musi mieć co najmniej 2 znaki",
            };
        }

        const data = await apiCall(
            `/user/location/search-cities?query=${encodeURIComponent(
                query.trim()
            )}`
        );
        return {
            success: true,
            data: data,
        };
    } catch (error) {
        return {
            success: false,
            error: "Błąd wyszukiwania miast",
        };
    }
}

export async function getLocationStats() {
    try {
        const data = await apiCall("/user/location/stats");
        return {
            success: true,
            data: data,
        };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania statystyk lokalizacji",
        };
    }
}

export async function clearUserLocation() {
    try {
        const data = await apiCall("/user/location/", { method: "DELETE" });
        return {
            success: true,
            data: data,
        };
    } catch (error) {
        return {
            success: false,
            error: "Błąd czyszczenia lokalizacji użytkownika",
        };
    }
}

export function getCurrentPosition(options = {}) {
    const defaultOptions = {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 60000,
    };

    return new Promise((resolve, reject) => {
        if (!navigator.geolocation) {
            reject({
                success: false,
                error: "Geolokalizacja nie jest wspierana przez tę przeglądarkę",
                code: "NOT_SUPPORTED",
            });
            return;
        }

        navigator.geolocation.getCurrentPosition(
            (position) => {
                resolve({
                    success: true,
                    data: {
                        latitude: position.coords.latitude,
                        longitude: position.coords.longitude,
                        accuracy: position.coords.accuracy,
                        timestamp: position.timestamp,
                    },
                });
            },
            (error) => {
                let errorMessage = "Nie można pobrać lokalizacji";
                switch (error.code) {
                    case error.PERMISSION_DENIED:
                        errorMessage =
                            "Dostęp do lokalizacji został zablokowany";
                        break;
                    case error.POSITION_UNAVAILABLE:
                        errorMessage = "Lokalizacja nie jest dostępna";
                        break;
                    case error.TIMEOUT:
                        errorMessage =
                            "Przekroczono czas oczekiwania na lokalizację";
                        break;
                }

                reject({
                    success: false,
                    error: errorMessage,
                    code: error.code,
                });
            },
            { ...defaultOptions, ...options }
        );
    });
}

export async function reverseGeocode(latitude, longitude) {
    try {
        if (!isValidCoordinates(latitude, longitude)) {
            return {
                success: false,
                error: "Nieprawidłowe współrzędne",
            };
        }

        const nominatimUrl = `https://nominatim.openstreetmap.org/reverse?lat=${latitude}&lon=${longitude}&format=json&addressdetails=1&countrycodes=pl`;

        const response = await fetch(nominatimUrl, {
            headers: {
                "User-Agent": "Petify-App/1.0",
            },
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const data = await response.json();

        if (data && data.address) {
            return {
                success: true,
                data: {
                    displayName: data.display_name,
                    cityName: extractCityName(data.address),
                    country: data.address.country,
                    state: data.address.state,
                    address: data.address,
                    latitude: parseFloat(latitude),
                    longitude: parseFloat(longitude),
                },
            };
        } else {
            return {
                success: false,
                error: "Nie znaleziono adresu dla podanych współrzędnych",
            };
        }
    } catch (error) {
        return {
            success: false,
            error: "Błąd podczas wyszukiwania adresu",
        };
    }
}

export function calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const dLat = toRadians(lat2 - lat1);
    const dLon = toRadians(lon2 - lon1);

    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRadians(lat1)) *
            Math.cos(toRadians(lat2)) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

export function toRadians(degrees) {
    return degrees * (Math.PI / 180);
}

export function formatCoordinates(latitude, longitude, precision = 4) {
    return {
        latitude: parseFloat(latitude).toFixed(precision),
        longitude: parseFloat(longitude).toFixed(precision),
    };
}

export function isValidCoordinates(latitude, longitude) {
    const lat = parseFloat(latitude);
    const lon = parseFloat(longitude);

    return (
        !isNaN(lat) &&
        !isNaN(lon) &&
        lat >= -90 &&
        lat <= 90 &&
        lon >= -180 &&
        lon <= 180
    );
}

export function extractCityName(address) {
    if (!address) return "";

    const cityFields = ["city", "town", "village", "municipality"];
    for (const field of cityFields) {
        if (address[field]) {
            return address[field];
        }
    }

    if (address.county) return address.county;
    if (address.state) return address.state;

    return "";
}

export function getSearchDistances() {
    return [
        { value: 5.0, label: "5 km", description: "Bardzo blisko" },
        { value: 10.0, label: "10 km", description: "Blisko" },
        { value: 20.0, label: "20 km", description: "W okolicy (domyślne)" },
        { value: 50.0, label: "50 km", description: "W regionie" },
        { value: 100.0, label: "100 km", description: "W województwie" },
        { value: -1.0, label: "Bez ograniczeń", description: "Cała Polska" },
    ];
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
