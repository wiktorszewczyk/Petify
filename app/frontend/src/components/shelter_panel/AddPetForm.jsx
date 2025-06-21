import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { ArrowLeft, PawPrint } from "lucide-react";
import { addPet, addPetImages } from "../../api/pet";
import { getMyShelter } from "../../api/shelter";
import Navbar from "../Navbar";
import { usePetForm, usePetImages } from "../../hooks/usePetForm";
import {
    PetBasicFields,
    PetDetailsFields,
    PetCharacteristicsFields,
    PetDescriptionField,
    PetPropertiesFields,
} from "./shared/PetFormFields";
import { ImageUpload } from "./shared/ImageUpload";
import "../../pages/shelter_panel/ShelterPanel.css";

const AddPetForm = () => {
    const navigate = useNavigate();
    const [shelter, setShelter] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");

    const { formData, handleChange, validateForm } = usePetForm();
    const {
        imageFiles,
        imagePreviews,
        error: imageError,
        handleImageChange,
        removeImage,
        setError: setImageError,
    } = usePetImages();

    useEffect(() => {
        loadShelter();
    }, []);

    const loadShelter = async () => {
        const result = await getMyShelter();
        if (result.success) {
            setShelter(result.data);
        } else {
            setError("Nie znaleziono schroniska");
        }
    };

    const handleFormChange = (e) => {
        handleChange(e);
        if (error) setError("");
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        const validationError = validateForm();
        if (validationError) {
            setError(validationError);
            return;
        }

        if (imageFiles.length === 0) {
            setError("Przynajmniej jedno zdjęcie zwierzęcia jest wymagane");
            return;
        }

        setLoading(true);
        setError("");

        try {
            const result = await addPet(formData, imageFiles[0]);

            if (result.success) {
                if (imageFiles.length > 1) {
                    try {
                        await addPetImages(result.data.id, imageFiles.slice(1));
                    } catch (imageError) {}
                }

                navigate("/shelter-panel", {
                    state: { message: "Zwierzę zostało pomyślnie dodane!" },
                });
            } else {
                setError(result.error || "Błąd dodawania zwierzęcia");
            }
        } catch (error) {
            setError("Wystąpił nieoczekiwany błąd");
        } finally {
            setLoading(false);
        }
    };

    const handleCancel = () => {
        navigate("/shelter-panel");
    };

    return (
        <div className="min-vh-100" style={{ backgroundColor: "#f8f9fa" }}>
            <Navbar />

            <div className="container mt-4">
                <div className="shelter-header-card mb-4">
                    <div className="d-flex align-items-center mb-3">
                        <PawPrint size={32} className="text-primary me-3" />
                        <div>
                            <h2 className="mb-0">Dodaj nowe zwierzę</h2>
                            <p className="text-muted mb-0">
                                Stwórz profil dla nowego podopiecznego w
                                schronisku "{shelter?.name}"
                            </p>
                        </div>
                    </div>
                    <button
                        onClick={handleCancel}
                        className="btn btn-outline-secondary"
                        disabled={loading}
                    >
                        <ArrowLeft size={20} className="me-2" />
                        Powrót do panelu
                    </button>
                </div>

                <div className="add-pet-form">
                    {error && (
                        <div className="alert alert-danger" role="alert">
                            {error}
                        </div>
                    )}

                    <form onSubmit={handleSubmit}>
                        <PetBasicFields
                            formData={formData}
                            handleChange={handleFormChange}
                            loading={loading}
                        />

                        <PetDetailsFields
                            formData={formData}
                            handleChange={handleFormChange}
                            loading={loading}
                        />

                        <PetCharacteristicsFields
                            formData={formData}
                            handleChange={handleFormChange}
                            loading={loading}
                        />

                        <PetDescriptionField
                            formData={formData}
                            handleChange={handleFormChange}
                            loading={loading}
                        />

                        <PetPropertiesFields
                            formData={formData}
                            handleChange={handleFormChange}
                            loading={loading}
                        />

                        <ImageUpload
                            imageFiles={imageFiles}
                            imagePreviews={imagePreviews}
                            error={imageError}
                            handleImageChange={handleImageChange}
                            removeImage={removeImage}
                            loading={loading}
                        />

                        <div className="form-actions d-flex justify-content-end">
                            <button
                                type="button"
                                className="btn btn-secondary me-3"
                                onClick={handleCancel}
                                disabled={loading}
                            >
                                Anuluj
                            </button>
                            <button
                                type="submit"
                                className="btn btn-primary"
                                disabled={loading}
                            >
                                {loading ? (
                                    <>
                                        <span className="spinner-border spinner-border-sm me-2" />
                                        Dodawanie...
                                    </>
                                ) : (
                                    <>Dodaj Zwierzę</>
                                )}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default AddPetForm;
