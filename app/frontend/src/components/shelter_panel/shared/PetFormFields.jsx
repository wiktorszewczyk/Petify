import React from "react";

export const PetBasicFields = ({ formData, handleChange, loading }) => (
    <div className="row">
        <div className="col-md-6 mb-3">
            <label className="form-label">Imię zwierzęcia *</label>
            <input
                type="text"
                name="name"
                className="form-control"
                value={formData.name}
                onChange={handleChange}
                disabled={loading}
                placeholder="np. Burek"
            />
        </div>
        <div className="col-md-6 mb-3">
            <label className="form-label">Typ zwierzęcia *</label>
            <select
                name="type"
                className="form-control"
                value={formData.type}
                onChange={handleChange}
                disabled={loading}
            >
                <option value="DOG">Pies</option>
                <option value="CAT">Kot</option>
                <option value="OTHER">Inne</option>
            </select>
        </div>
    </div>
);

export const PetDetailsFields = ({ formData, handleChange, loading }) => (
    <div className="row">
        <div className="col-md-6 mb-3">
            <label className="form-label">Rasa *</label>
            <input
                type="text"
                name="breed"
                className="form-control"
                value={formData.breed}
                onChange={handleChange}
                disabled={loading}
                placeholder="np. Labrador"
            />
        </div>
        <div className="col-md-6 mb-3">
            <label className="form-label">Wiek (lata) *</label>
            <input
                type="number"
                name="age"
                className="form-control"
                value={formData.age}
                onChange={handleChange}
                disabled={loading}
                min="0"
                max="30"
                placeholder="np. 3"
            />
        </div>
    </div>
);

export const PetCharacteristicsFields = ({
    formData,
    handleChange,
    loading,
}) => (
    <div className="row">
        <div className="col-md-6 mb-3">
            <label className="form-label">Płeć *</label>
            <select
                name="gender"
                className="form-control"
                value={formData.gender}
                onChange={handleChange}
                disabled={loading}
            >
                <option value="MALE">Samiec</option>
                <option value="FEMALE">Samica</option>
            </select>
        </div>
        <div className="col-md-6 mb-3">
            <label className="form-label">Rozmiar *</label>
            <select
                name="size"
                className="form-control"
                value={formData.size}
                onChange={handleChange}
                disabled={loading}
            >
                <option value="SMALL">Mały</option>
                <option value="MEDIUM">Średni</option>
                <option value="BIG">Duży</option>
                <option value="VERY_BIG">Bardzo duży</option>
            </select>
        </div>
    </div>
);

export const PetDescriptionField = ({ formData, handleChange, loading }) => (
    <div className="mb-3">
        <label className="form-label">Opis zwierzęcia *</label>
        <textarea
            name="description"
            className="form-control"
            rows="4"
            value={formData.description}
            onChange={handleChange}
            disabled={loading}
            placeholder="Opisz charakter, zachowanie, szczególne potrzeby..."
            maxLength="255"
        />
        <div className="form-text">
            {formData.description.length}/255 znaków
        </div>
    </div>
);

export const PetPropertiesFields = ({ formData, handleChange, loading }) => (
    <div className="mb-3">
        <label className="form-label">Dodatkowe informacje</label>
        <div className="row">
            <div className="col-md-3">
                <div className="form-check">
                    <input
                        type="checkbox"
                        name="vaccinated"
                        className="form-check-input"
                        id="vaccinated"
                        checked={formData.vaccinated}
                        onChange={handleChange}
                        disabled={loading}
                    />
                    <label className="form-check-label" htmlFor="vaccinated">
                        Zaszczepiony
                    </label>
                </div>
            </div>
            <div className="col-md-3">
                <div className="form-check">
                    <input
                        type="checkbox"
                        name="sterilized"
                        className="form-check-input"
                        id="sterilized"
                        checked={formData.sterilized}
                        onChange={handleChange}
                        disabled={loading}
                    />
                    <label className="form-check-label" htmlFor="sterilized">
                        Wykastrowany
                    </label>
                </div>
            </div>
            <div className="col-md-3">
                <div className="form-check">
                    <input
                        type="checkbox"
                        name="kidFriendly"
                        className="form-check-input"
                        id="kidFriendly"
                        checked={formData.kidFriendly}
                        onChange={handleChange}
                        disabled={loading}
                    />
                    <label className="form-check-label" htmlFor="kidFriendly">
                        Lubi dzieci
                    </label>
                </div>
            </div>
            <div className="col-md-3">
                <div className="form-check">
                    <input
                        type="checkbox"
                        name="urgent"
                        className="form-check-input"
                        id="urgent"
                        checked={formData.urgent}
                        onChange={handleChange}
                        disabled={loading}
                    />
                    <label className="form-check-label" htmlFor="urgent">
                        Pilny przypadek
                    </label>
                </div>
            </div>
        </div>
    </div>
);

export const ExistingImagesDisplay = ({ images, onRemoveImage, loading }) => {
    if (!images || images.length === 0) {
        return null;
    }

    return (
        <div className="mb-4">
            <label className="form-label">Obecne zdjęcia</label>
            <div className="images-preview">
                <div className="row g-2">
                    {images.map((image, index) => (
                        <div
                            key={`existing-${index}`}
                            className="col-6 col-md-4 col-lg-3"
                        >
                            <div className="position-relative">
                                <img
                                    src={image.imageUrl}
                                    alt={`Zdjęcie ${index + 1}`}
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
                                    onClick={() =>
                                        onRemoveImage(image.id, index)
                                    }
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
            </div>
        </div>
    );
};
