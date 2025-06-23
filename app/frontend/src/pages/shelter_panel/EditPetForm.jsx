import React, { useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { Save, ArrowLeft } from "lucide-react";
import {
    getPetById,
    updatePet,
    getPetImages,
    addPetImages,
    deletePetImage,
} from "../../api/pet";
import { getMyShelter } from "../../api/shelter";
import { getAllPets } from "../../api/pet";
import Navbar from "../../components/Navbar";
import { usePetForm, usePetImages } from "../../hooks/usePetForm";
import {
    PetBasicFields,
    PetDetailsFields,
    PetCharacteristicsFields,
    PetDescriptionField,
    PetPropertiesFields,
    ExistingImagesDisplay,
} from "../../components/shelter_panel/shared/PetFormFields";

const EditPetForm = () => {
    const navigate = useNavigate();
    const { petId } = useParams();

    const [pet, setPet] = useState(null);
    const [shelter, setShelter] = useState(null);
    const [existingImages, setExistingImages] = useState([]);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState("");

    const { formData, setFormData, handleChange, validateForm } = usePetForm();
    const {
        imageFiles: newImageFiles,
        imagePreviews: newImagePreviews,
        error: imageError,
        handleImageChange,
        removeImage: removeNewImage,
        setError: setImageError,
    } = usePetImages();

    useEffect(() => {
        if (petId) {
            loadData();
        } else {
            setError("Brak ID zwierzęcia");
            setLoading(false);
        }
    }, [petId]);

    const loadData = async () => {
        try {
            const shelterResult = await getMyShelter();
            if (!shelterResult.success) {
                setError("Nie znaleziono Twojego schroniska");
                setLoading(false);
                return;
            }
            setShelter(shelterResult.data);

            const petsResult = await getAllPets();
            if (!petsResult.success) {
                setError("Błąd podczas pobierania zwierząt ze schroniska");
                setLoading(false);
                return;
            }

            const shelterPets = petsResult.data.filter(
                (pet) => pet.shelterId === shelterResult.data.id
            );

            const targetPet = shelterPets.find(
                (p) => p.id.toString() === petId.toString()
            );
            if (!targetPet) {
                setError(
                    `Nie znaleziono zwierzęcia o ID ${petId} w Twoim schronisku`
                );
                setLoading(false);
                return;
            }

            setPet(targetPet);

            setFormData({
                name: targetPet.name || "",
                type: targetPet.type || "DOG",
                breed: targetPet.breed || "",
                age: targetPet.age?.toString() || "",
                description: targetPet.description || "",
                gender: targetPet.gender || "MALE",
                size: targetPet.size || "MEDIUM",
                vaccinated: targetPet.vaccinated || false,
                urgent: targetPet.urgent || false,
                sterilized: targetPet.sterilized || false,
                kidFriendly: targetPet.kidFriendly || false,
            });

            await loadExistingImages(targetPet);
        } catch (error) {
            setError(
                "Błąd podczas ładowania danych: " +
                    (error.message || "Nieznany błąd")
            );
        } finally {
            setLoading(false);
        }
    };

    const loadExistingImages = async (petData) => {
        const images = [];

        if (petData.imageUrl) {
            images.push({
                id: "main",
                imageUrl: petData.imageUrl,
                imageName: "Główne zdjęcie",
            });
        }

        if (petData.images?.length > 0) {
            petData.images.forEach((img) => {
                images.push({
                    id: img.id,
                    imageUrl: img.imageUrl,
                    imageName: img.imageName || "Dodatkowe zdjęcie",
                });
            });
        } else {
            try {
                const imagesResult = await getPetImages(petId);
                if (imagesResult.success && imagesResult.data) {
                    imagesResult.data.forEach((img) => {
                        images.push({
                            id: img.id,
                            imageUrl: img.imageUrl,
                            imageName: img.imageName || "Dodatkowe zdjęcie",
                        });
                    });
                }
            } catch (error) {}
        }

        setExistingImages(images);
    };

    const handleFormChange = (e) => {
        handleChange(e);
        if (error) setError("");
    };

    const removeExistingImage = async (imageId, imageIndex) => {
        if (window.confirm("Czy na pewno chcesz usunąć to zdjęcie?")) {
            try {
                if (imageId !== "main" && imageId) {
                    const result = await deletePetImage(petId, imageId);
                    if (!result.success) {
                        throw new Error(result.error);
                    }
                }
                setExistingImages((prev) =>
                    prev.filter((_, index) => index !== imageIndex)
                );
            } catch (error) {
                alert("Błąd podczas usuwania zdjęcia");
            }
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        const validationError = validateForm();
        if (validationError) {
            setError(validationError);
            return;
        }

        const totalImages = existingImages.length + newImageFiles.length;
        if (totalImages === 0) {
            setError("Zwierzę musi mieć przynajmniej jedno zdjęcie");
            return;
        }

        setSaving(true);
        setError("");

        try {
            const updateData = {
                ...formData,
                age: parseInt(formData.age),
            };

            const updateResult = await updatePet(petId, updateData);

            if (updateResult.success) {
                if (newImageFiles.length > 0) {
                    try {
                        await addPetImages(petId, newImageFiles);
                    } catch (imageError) {}
                }

                navigate("/shelter-panel", {
                    state: {
                        message: `Zwierzę "${formData.name}" zostało zaktualizowane!`,
                    },
                });
            } else {
                setError(updateResult.error || "Błąd aktualizacji zwierzęcia");
            }
        } catch (error) {
            setError("Wystąpił nieoczekiwany błąd");
        } finally {
            setSaving(false);
        }
    };

    const handleCancel = () => {
        navigate("/shelter-panel");
    };

    if (loading) {
        return (
            <div className="d-flex justify-content-center align-items-center min-vh-100">
                <div className="spinner-border text-primary" role="status">
                    <span className="visually-hidden">Ładowanie...</span>
                </div>
            </div>
        );
    }

    if (error) {
        return (
            <div className="min-vh-100" style={{ backgroundColor: "#f8f9fa" }}>
                <Navbar />
                <div className="container mt-4">
                    <div className="alert alert-danger">
                        <h5>Błąd</h5>
                        <p>{error}</p>
                        <button
                            className="btn btn-primary"
                            onClick={() => navigate("/shelter-panel")}
                        >
                            Powrót do panelu
                        </button>
                    </div>
                </div>
            </div>
        );
    }

    if (!pet) {
        return (
            <div className="min-vh-100" style={{ backgroundColor: "#f8f9fa" }}>
                <Navbar />
                <div className="container mt-4">
                    <div className="alert alert-danger">
                        Nie znaleziono zwierzęcia lub wystąpił błąd podczas
                        ładowania.
                        <button
                            className="btn btn-primary mt-2"
                            onClick={() => navigate("/shelter-panel")}
                        >
                            Powrót do panelu
                        </button>
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="min-vh-100" style={{ backgroundColor: "#f8f9fa" }}>
            <Navbar />

            <div className="container mt-4">
                <div className="d-flex align-items-center mb-4">
                    <button
                        onClick={handleCancel}
                        className="btn btn-outline-secondary me-3"
                        disabled={saving}
                    >
                        <ArrowLeft size={20} className="me-2" />
                        Powrót do panelu
                    </button>
                    <h2 className="mb-0">Edytuj zwierzę: {pet.name}</h2>
                </div>

                <div className="add-pet-form">
                    <div className="form-header mb-4">
                        <p className="text-muted">
                            Edytuj dane zwierzęcia w schronisku "{shelter?.name}
                            "
                        </p>
                    </div>

                    {error && (
                        <div className="alert alert-danger" role="alert">
                            {error}
                        </div>
                    )}

                    <form onSubmit={handleSubmit}>
                        <PetBasicFields
                            formData={formData}
                            handleChange={handleFormChange}
                            loading={saving}
                        />

                        <PetDetailsFields
                            formData={formData}
                            handleChange={handleFormChange}
                            loading={saving}
                        />

                        <PetCharacteristicsFields
                            formData={formData}
                            handleChange={handleFormChange}
                            loading={saving}
                        />

                        <PetDescriptionField
                            formData={formData}
                            handleChange={handleFormChange}
                            loading={saving}
                        />

                        <PetPropertiesFields
                            formData={formData}
                            handleChange={handleFormChange}
                            loading={saving}
                        />

                        <ExistingImagesDisplay
                            images={existingImages}
                            onRemoveImage={removeExistingImage}
                            loading={saving}
                        />

                        <div className="mb-4">
                            <label className="form-label">
                                Dodaj nowe zdjęcia
                                <span className="text-muted">
                                    {" "}
                                    (łącznie maksymalnie 5 zdjęć)
                                </span>
                            </label>
                            <input
                                type="file"
                                className="form-control"
                                accept="image/*"
                                multiple
                                onChange={handleImageChange}
                                disabled={saving}
                            />
                            <div className="form-text">
                                Maksymalny rozmiar pliku: 5MB na zdjęcie.
                                Dozwolone formaty: JPG, PNG, WEBP.
                                <br />
                                Masz obecnie{" "}
                                {existingImages.length + newImageFiles.length} z
                                5 możliwych zdjęć.
                            </div>

                            {imageError && (
                                <div className="text-danger mt-2">
                                    {imageError}
                                </div>
                            )}

                            {newImagePreviews.length > 0 && (
                                <div className="images-preview mt-3">
                                    <h6>Nowe zdjęcia do dodania:</h6>
                                    <div className="row g-2">
                                        {newImagePreviews.map(
                                            (preview, index) => (
                                                <div
                                                    key={`new-${index}`}
                                                    className="col-6 col-md-4 col-lg-3"
                                                >
                                                    <div className="position-relative">
                                                        <img
                                                            src={preview}
                                                            alt={`Nowe zdjęcie ${
                                                                index + 1
                                                            }`}
                                                            className="img-thumbnail w-100"
                                                            style={{
                                                                height: "120px",
                                                                objectFit:
                                                                    "cover",
                                                            }}
                                                        />
                                                        <span className="badge bg-success position-absolute top-0 start-0 m-1">
                                                            Nowe
                                                        </span>
                                                        <button
                                                            type="button"
                                                            className="btn btn-danger btn-sm position-absolute top-0 end-0 m-1"
                                                            onClick={() =>
                                                                removeNewImage(
                                                                    index
                                                                )
                                                            }
                                                            disabled={saving}
                                                            style={{
                                                                width: "24px",
                                                                height: "24px",
                                                                padding: "0",
                                                                fontSize:
                                                                    "12px",
                                                            }}
                                                        >
                                                            ×
                                                        </button>
                                                    </div>
                                                </div>
                                            )
                                        )}
                                    </div>
                                </div>
                            )}
                        </div>

                        <div className="form-actions d-flex justify-content-end">
                            <button
                                type="button"
                                className="btn btn-secondary me-3"
                                onClick={handleCancel}
                                disabled={saving}
                            >
                                Anuluj
                            </button>
                            <button
                                type="submit"
                                className="btn btn-primary"
                                disabled={saving}
                            >
                                {saving ? (
                                    <>
                                        <span className="spinner-border spinner-border-sm me-2" />
                                        Zapisywanie...
                                    </>
                                ) : (
                                    <>
                                        <Save size={20} className="me-2" />
                                        Zapisz zmiany
                                    </>
                                )}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default EditPetForm;
