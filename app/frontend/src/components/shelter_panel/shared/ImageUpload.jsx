import React from "react";

export const ImageUpload = ({
    imageFiles,
    imagePreviews,
    error,
    handleImageChange,
    removeImage,
    loading,
    maxImages = 5,
    currentImageCount = 0,
}) => (
    <div className="mb-4">
        <label className="form-label">
            Zdjęcia zwierzęcia *
            <span className="text-muted"> (maksymalnie {maxImages} zdjęć)</span>
        </label>
        <input
            type="file"
            className="form-control"
            accept="image/*"
            multiple
            onChange={handleImageChange}
            disabled={loading}
        />
        <div className="form-text">
            Maksymalny rozmiar pliku: 5MB na zdjęcie. Dozwolone formaty: JPG,
            PNG, WEBP.
            {currentImageCount > 0 &&
                ` Masz obecnie ${
                    currentImageCount + imageFiles.length
                } z ${maxImages} możliwych zdjęć.`}
        </div>

        {error && <div className="text-danger mt-2">{error}</div>}

        {imagePreviews.length > 0 && (
            <div className="images-preview mt-3">
                <div className="row g-2">
                    {imagePreviews.map((preview, index) => (
                        <div key={index} className="col-6 col-md-4 col-lg-3">
                            <div className="position-relative">
                                <img
                                    src={preview}
                                    alt={`Podgląd ${index + 1}`}
                                    className="img-thumbnail w-100"
                                    style={{
                                        height: "120px",
                                        objectFit: "cover",
                                    }}
                                />
                                {index === 0 && (
                                    <span className="badge bg-primary position-absolute top-0 start-0 m-1">
                                        Główne
                                    </span>
                                )}
                                <button
                                    type="button"
                                    className="btn btn-danger btn-sm position-absolute top-0 end-0 m-1"
                                    onClick={() => removeImage(index)}
                                    disabled={loading}
                                    style={{
                                        width: "24px",
                                        height: "24px",
                                        padding: "0",
                                        fontSize: "12px",
                                    }}
                                >
                                    ×
                                </button>
                            </div>
                        </div>
                    ))}
                </div>
                <div className="form-text mt-2">
                    Dodano {imagePreviews.length} z {maxImages} możliwych zdjęć
                </div>
            </div>
        )}
    </div>
);
