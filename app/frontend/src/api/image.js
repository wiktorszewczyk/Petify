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

    const contentLength = response.headers.get("content-length");
    if (
        contentLength === "0" ||
        !response.headers.get("content-type")?.includes("application/json")
    ) {
        return {};
    }

    const text = await response.text();
    if (!text) {
        return {};
    }

    try {
        return JSON.parse(text);
    } catch (error) {
        return {};
    }
}

export async function uploadImages(files, entityType = null, entityId = null) {
    try {
        const formData = new FormData();

        const validation = validateImageFiles(files);
        if (!validation.valid) {
            return { success: false, error: validation.error };
        }

        if (Array.isArray(files)) {
            files.forEach((file) => {
                formData.append("images", file);
            });
        } else {
            formData.append("images", files);
        }

        let endpoint = "/images/upload";
        if (entityType && entityId) {
            endpoint = `/images/${entityType}/${entityId}/images`;
        }

        const response = await fetch(`${API_URL}${endpoint}`, {
            method: "POST",
            headers: {
                Authorization: `Bearer ${getToken()}`,
            },
            body: formData,
        });

        if (!response.ok) {
            throw new Error(`Upload failed: ${response.status}`);
        }

        const data = await response.json();
        return { success: true, data: processImageUrls(data) };
    } catch (error) {
        return {
            success: false,
            error: "Błąd podczas przesyłania obrazów",
        };
    }
}

export async function uploadEntityImages(entityId, entityType, files) {
    return uploadImages(files, entityType, entityId);
}

export async function getEntityImages(entityId, entityType) {
    try {
        const data = await apiCall(`/images/${entityType}/${entityId}/images`);
        return { success: true, data: processImageUrls(data) };
    } catch (error) {
        if (error.message.includes("404")) {
            return { success: true, data: [] };
        }
        return {
            success: false,
            error: "Błąd pobierania obrazów",
        };
    }
}

export async function getImageById(imageId) {
    try {
        const data = await apiCall(`/images/${imageId}`);
        return { success: true, data: processImageUrls(data) };
    } catch (error) {
        return {
            success: false,
            error: "Błąd pobierania obrazu",
        };
    }
}

export async function deleteImage(imageId) {
    try {
        await apiCall(`/images/${imageId}`, { method: "DELETE" });
        return { success: true };
    } catch (error) {
        return {
            success: false,
            error: "Błąd usuwania obrazu",
        };
    }
}

export async function updateImage(imageId, imageData) {
    try {
        const data = await apiCall(`/images/${imageId}`, {
            method: "PUT",
            body: JSON.stringify(imageData),
        });
        return { success: true, data: processImageUrls(data) };
    } catch (error) {
        return {
            success: false,
            error: "Błąd aktualizacji obrazu",
        };
    }
}

export async function setMainImage(entityId, entityType, imageId) {
    try {
        const data = await apiCall(
            `/images/${entityType}/${entityId}/main/${imageId}`,
            {
                method: "PUT",
            }
        );
        return { success: true, data: processImageUrls(data) };
    } catch (error) {
        return {
            success: false,
            error: "Błąd ustawiania obrazu głównego",
        };
    }
}

export function processImageUrls(data) {
    if (!data) return data;

    const processUrl = (url) => {
        if (!url) return url;

        if (url.startsWith("http://") || url.startsWith("https://")) {
            return url;
        }

        const baseURL =
            API_URL || window.location.origin || "http://localhost:8222";

        if (url.startsWith("/")) {
            return `${baseURL}${url}`;
        }

        return `${baseURL}/${url}`;
    };

    if (Array.isArray(data)) {
        return data.map((item) => ({
            ...item,
            url: processUrl(item.url),
            imageUrl: processUrl(item.imageUrl || item.url),
            thumbnailUrl: item.thumbnailUrl
                ? processUrl(item.thumbnailUrl)
                : undefined,
        }));
    }

    if (typeof data === "object" && data !== null) {
        return {
            ...data,
            url: processUrl(data.url),
            imageUrl: processUrl(data.imageUrl || data.url),
            thumbnailUrl: data.thumbnailUrl
                ? processUrl(data.thumbnailUrl)
                : undefined,
        };
    }

    return data;
}

export function getImageUrl(imageId, size = "full") {
    if (!imageId) return null;

    const baseURL =
        API_URL || window.location.origin || "http://localhost:8222";

    switch (size) {
        case "thumbnail":
            return `${baseURL}/images/${imageId}/thumbnail`;
        case "medium":
            return `${baseURL}/images/${imageId}/medium`;
        case "full":
        default:
            return `${baseURL}/images/${imageId}`;
    }
}

export function validateImageFile(file) {
    const maxSize = 5 * 1024 * 1024;
    const allowedTypes = [
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/gif",
        "image/webp",
    ];

    if (!file || !(file instanceof File)) {
        return {
            valid: false,
            error: "Nieprawidłowy plik.",
        };
    }

    if (file.size > maxSize) {
        return {
            valid: false,
            error: "Plik jest za duży. Maksymalny rozmiar to 5MB.",
        };
    }

    if (!allowedTypes.includes(file.type)) {
        return {
            valid: false,
            error: "Nieprawidłowy format. Dozwolone: JPEG, PNG, GIF, WebP.",
        };
    }

    return { valid: true };
}

export function validateImageFiles(files) {
    if (!files) {
        return {
            valid: false,
            error: "Nie wybrano plików.",
        };
    }

    const fileArray = Array.isArray(files) ? files : [files];

    if (fileArray.length === 0) {
        return {
            valid: false,
            error: "Nie wybrano plików.",
        };
    }

    if (fileArray.length > 5) {
        return {
            valid: false,
            error: "Można przesłać maksymalnie 5 obrazów.",
        };
    }

    for (let i = 0; i < fileArray.length; i++) {
        const validation = validateImageFile(fileArray[i]);
        if (!validation.valid) {
            return {
                valid: false,
                error: `Plik ${i + 1}: ${validation.error}`,
            };
        }
    }

    return { valid: true };
}

export async function autoCompressIfNeeded(
    file,
    maxSizeBytes = 2 * 1024 * 1024
) {
    if (file.size <= maxSizeBytes) {
        return file;
    }

    return new Promise((resolve, reject) => {
        const canvas = document.createElement("canvas");
        const ctx = canvas.getContext("2d");
        const img = new Image();

        img.onload = () => {
            const maxDimension = 1920;
            let { width, height } = img;

            if (width > height) {
                if (width > maxDimension) {
                    height = (height * maxDimension) / width;
                    width = maxDimension;
                }
            } else {
                if (height > maxDimension) {
                    width = (width * maxDimension) / height;
                    height = maxDimension;
                }
            }

            canvas.width = width;
            canvas.height = height;

            ctx.drawImage(img, 0, 0, width, height);

            canvas.toBlob(
                (blob) => {
                    const compressedFile = new File([blob], file.name, {
                        type: file.type,
                        lastModified: Date.now(),
                    });
                    resolve(compressedFile);
                },
                file.type,
                0.8
            );
        };

        img.onerror = () => {
            reject(new Error("Błąd ładowania obrazu"));
        };

        img.src = URL.createObjectURL(file);
    });
}

export async function batchUpload(files, entityType, entityId, onProgress) {
    const results = [];
    let completed = 0;

    for (const file of files) {
        try {
            const result = await uploadImages([file], entityType, entityId);
            results.push({ file, result });
        } catch (error) {
            results.push({
                file,
                result: { success: false, error: error.message },
            });
        }

        completed++;
        if (onProgress) {
            onProgress(completed, files.length);
        }
    }

    return results;
}

export async function createThumbnail(file, maxWidth = 150, maxHeight = 150) {
    return new Promise((resolve, reject) => {
        const canvas = document.createElement("canvas");
        const ctx = canvas.getContext("2d");
        const img = new Image();

        img.onload = () => {
            let { width, height } = img;
            const aspectRatio = width / height;

            if (width > height) {
                width = maxWidth;
                height = maxWidth / aspectRatio;
            } else {
                height = maxHeight;
                width = maxHeight * aspectRatio;
            }

            canvas.width = width;
            canvas.height = height;

            ctx.drawImage(img, 0, 0, width, height);

            const thumbnailDataUrl = canvas.toDataURL(file.type, 0.7);
            resolve(thumbnailDataUrl);
        };

        img.onerror = () => {
            reject(new Error("Błąd tworzenia miniaturki"));
        };

        img.src = URL.createObjectURL(file);
    });
}

export const ENTITY_TYPES = {
    POST: "post",
    EVENT: "event",
    FUNDRAISER: "fundraiser",
    PET: "pet",
    SHELTER: "shelter",
    USER: "user",
};

export const ALLOWED_FORMATS = [
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/gif",
    "image/webp",
];

export const MAX_FILE_SIZE = 5 * 1024 * 1024;

export const MAX_FILES_COUNT = 5;
