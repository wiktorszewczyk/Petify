import React, { useState, useEffect, useCallback } from "react";
import {
    X,
    Loader,
    AlertCircle,
    Calendar,
    MessageSquare,
    Plus,
} from "lucide-react";
import {
    uploadImages,
    getEntityImages,
    getImageById,
    deleteImage,
    validateImageFiles,
} from "../../api/image";
import {
    createPost,
    createEvent,
    updatePost,
    updateEvent,
    validatePostData,
    validateEventData,
} from "../../api/feed";
import { geocode } from "../../api/location";

const FeedItemForm = ({
    type,
    shelterId,
    isOpen,
    onClose,
    onSave,
    editData = null,
}) => {
    const isEvent = type === "event";
    const isEditing = !!editData;

    const getInitialFormData = useCallback(
        () => ({
            title: "",
            shortDescription: "",
            longDescription: "",
            startDate: "",
            endDate: "",
            address: "",
            capacity: 50,
            latitude: null,
            longitude: null,
            fundraisingId: null,
            imageIds: [],
        }),
        []
    );

    const [formData, setFormData] = useState(getInitialFormData());
    const [imageFiles, setImageFiles] = useState([]);
    const [existingImages, setExistingImages] = useState([]);
    const [imagePreviews, setImagePreviews] = useState([]);

    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");
    const [addressError, setAddressError] = useState("");
    const [validationErrors, setValidationErrors] = useState({});

    useEffect(() => {
        if (!isOpen) return;

        const setupForm = async () => {
            setLoading(true);
            setError("");
            setAddressError("");
            setValidationErrors({});
            setImageFiles([]);
            setImagePreviews([]);
            setExistingImages([]);

            if (isEditing && editData) {
                setFormData({
                    title: editData.title || "",
                    shortDescription: editData.shortDescription || "",
                    longDescription: editData.longDescription || "",
                    startDate: editData.startDate
                        ? new Date(editData.startDate)
                              .toISOString()
                              .slice(0, 16)
                        : "",
                    endDate: editData.endDate
                        ? new Date(editData.endDate).toISOString().slice(0, 16)
                        : "",
                    address: editData.address || "",
                    capacity: editData.capacity || 50,
                    latitude: editData.latitude,
                    longitude: editData.longitude,
                    fundraisingId: editData.fundraisingId,
                    imageIds: editData.imageIds || [],
                });

                if (editData.imageIds && editData.imageIds.length > 0) {
                    try {
                        const imagePromises = editData.imageIds.map((id) =>
                            getImageById(id)
                        );
                        const results = await Promise.all(imagePromises);
                        const loadedImages = results
                            .filter((res) => res.success)
                            .map((res) => res.data);

                        if (loadedImages.length > 0 && editData.mainImageId) {
                            const mainImage = loadedImages.find(
                                (img) => img.id === editData.mainImageId
                            );
                            if (mainImage) {
                                const otherImages = loadedImages.filter(
                                    (img) => img.id !== editData.mainImageId
                                );
                                const sortedImages = [
                                    mainImage,
                                    ...otherImages,
                                ];
                                setExistingImages(sortedImages);
                            } else {
                                setExistingImages(loadedImages);
                            }
                        } else {
                            setExistingImages(loadedImages);
                        }
                    } catch (error) {}
                }
            } else {
                setFormData(getInitialFormData());
            }
            setLoading(false);
        };

        setupForm();
    }, [editData, isEditing, isOpen, getInitialFormData]);

    const validateForm = () => {
        if (isEvent) {
            return validateEventData(formData);
        } else {
            return validatePostData(formData);
        }
    };

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData((prev) => ({ ...prev, [name]: value }));

        if (validationErrors[name]) {
            setValidationErrors((prev) => {
                const newErrors = { ...prev };
                delete newErrors[name];
                return newErrors;
            });
        }
    };

    const handleImageChange = (e) => {
        const files = Array.from(e.target.files);
        const currentTotal = existingImages.length + imagePreviews.length;

        if (currentTotal + files.length > 5) {
            setError(
                `Możesz dodać maksymalnie 5 zdjęć. Obecnie masz ${currentTotal}, próbujesz dodać ${files.length}.`
            );
            return;
        }

        const validation = validateImageFiles(files);
        if (!validation.valid) {
            setError(validation.error);
            return;
        }

        setImageFiles((prev) => [...prev, ...files]);
        const newPreviews = files.map((file) => URL.createObjectURL(file));
        setImagePreviews((prev) => [...prev, ...newPreviews]);
        setError("");
    };

    const handleRemoveExistingImage = async (idToRemove) => {
        setExistingImages((prev) =>
            prev.filter((img) => img.id !== idToRemove)
        );
        setFormData((prev) => ({
            ...prev,
            imageIds: prev.imageIds.filter((id) => id !== idToRemove),
            mainImageId:
                prev.mainImageId === idToRemove ? null : prev.mainImageId,
        }));
        setError("");

        try {
            await deleteImage(idToRemove);
        } catch (error) {
            if (!error.message?.includes("404")) {
            }
        }
    };

    const handleRemoveNewImage = (indexToRemove) => {
        setImageFiles((prev) => prev.filter((_, i) => i !== indexToRemove));
        setImagePreviews((prev) => {
            const newPreviews = prev.filter((_, i) => i !== indexToRemove);
            URL.revokeObjectURL(prev[indexToRemove]);
            updateMainImageAfterChange(existingImages, newPreviews);
            return newPreviews;
        });
    };

    const updateMainImageAfterChange = (existingImgs, previewImgs) => {
        const hasImages = existingImgs.length > 0 || previewImgs.length > 0;
        const newMainImageId =
            hasImages && existingImgs.length > 0 ? existingImgs[0].id : null;

        setFormData((prev) => ({
            ...prev,
            mainImageId: newMainImageId,
        }));
    };

    const handleDragStart = (e, index, type) => {
        e.dataTransfer.setData("text/plain", JSON.stringify({ index, type }));
        e.dataTransfer.effectAllowed = "move";
    };

    const handleDragOver = (e) => {
        e.preventDefault();
        e.dataTransfer.dropEffect = "move";
    };

    const handleDrop = (e, dropIndex, dropType) => {
        e.preventDefault();

        try {
            const dragData = JSON.parse(e.dataTransfer.getData("text/plain"));
            const { index: dragIndex, type: dragType } = dragData;

            if (dragType === dropType && dragIndex !== dropIndex) {
                if (dragType === "existing") {
                    setExistingImages((prev) => {
                        const newImages = [...prev];
                        const draggedItem = newImages[dragIndex];
                        newImages.splice(dragIndex, 1);
                        newImages.splice(dropIndex, 0, draggedItem);

                        if (newImages.length > 0) {
                            setFormData((prevForm) => ({
                                ...prevForm,
                                mainImageId: newImages[0].id,
                                imageIds: newImages.map((img) => img.id),
                            }));
                        }

                        return newImages;
                    });
                } else if (dragType === "preview") {
                    setImagePreviews((prev) => {
                        const newPreviews = [...prev];
                        const draggedItem = newPreviews[dragIndex];
                        newPreviews.splice(dragIndex, 1);
                        newPreviews.splice(dropIndex, 0, draggedItem);
                        return newPreviews;
                    });

                    setImageFiles((prev) => {
                        const newFiles = [...prev];
                        const draggedItem = newFiles[dragIndex];
                        newFiles.splice(dragIndex, 1);
                        newFiles.splice(dropIndex, 0, draggedItem);
                        return newFiles;
                    });
                }
            }
        } catch (error) {}
    };

    const handleAddressBlur = async () => {
        if (formData.address?.trim()) {
            const result = await geocode(formData.address);
            if (result.success) {
                setFormData((prev) => ({
                    ...prev,
                    latitude: result.data.latitude,
                    longitude: result.data.longitude,
                }));
                setAddressError("");
            } else {
                setAddressError(
                    result.error || "Nie znaleziono współrzędnych."
                );
            }
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        const validation = validateForm();
        if (!validation.isValid) {
            setValidationErrors(
                validation.errors.reduce((acc, error, index) => {
                    acc[`error_${index}`] = error;
                    return acc;
                }, {})
            );
            setError(validation.errors.join(", "));
            return;
        }

        setLoading(true);
        setError("");
        setValidationErrors({});

        try {
            let finalSavedData;

            if (isEditing) {
                const newImageIds = [];
                if (imageFiles.length > 0) {
                    const entityType = isEvent ? "event" : "post";
                    const imageResult = await uploadImages(
                        imageFiles,
                        entityType,
                        editData.id
                    );
                    if (imageResult.success && imageResult.data) {
                        newImageIds.push(
                            ...imageResult.data.map((img) => img.id)
                        );
                    } else {
                        throw new Error(
                            imageResult.error ||
                                "Błąd podczas przesyłania nowych zdjęć."
                        );
                    }
                }

                const finalImageIds = [...formData.imageIds, ...newImageIds];
                const finalPayload = {
                    ...formData,
                    imageIds: finalImageIds,
                    mainImageId:
                        formData.mainImageId ||
                        (finalImageIds.length > 0 ? finalImageIds[0] : null),
                };

                const updateFunction = isEvent ? updateEvent : updatePost;
                const updateResult = await updateFunction(
                    editData.id,
                    finalPayload
                );
                if (!updateResult.success) {
                    throw new Error(
                        updateResult.error || "Błąd podczas aktualizacji wpisu."
                    );
                }
                finalSavedData = updateResult.data;
            } else {
                const createFunction = isEvent ? createEvent : createPost;

                const creationResult = await createFunction(
                    shelterId,
                    formData
                );

                if (!creationResult.success) {
                    throw new Error(
                        creationResult.error || "Błąd podczas tworzenia wpisu."
                    );
                }

                let savedData = creationResult.data;
                const newItemId = savedData.id;

                if (imageFiles.length > 0 && newItemId) {
                    const entityType = isEvent ? "event" : "post";
                    const imageResult = await uploadImages(
                        imageFiles,
                        entityType,
                        newItemId
                    );

                    if (imageResult.success && imageResult.data.length > 0) {
                        const imageIds = imageResult.data.map((img) => img.id);

                        const updatePayload = {
                            ...formData,
                            imageIds: imageIds,
                            mainImageId: imageIds[0],
                        };

                        const updateFunction = isEvent
                            ? updateEvent
                            : updatePost;
                        const updateResult = await updateFunction(
                            newItemId,
                            updatePayload
                        );

                        if (updateResult.success) {
                            savedData = updateResult.data;
                        } else {
                            setError(
                                "Wpis utworzony pomyślnie, ale nie udało się powiązać wszystkich zdjęć."
                            );
                        }
                    } else {
                        setError(
                            "Wpis utworzony pomyślnie, ale nie udało się przesłać zdjęć."
                        );
                    }
                }
                finalSavedData = savedData;
            }

            onSave(finalSavedData);
            onClose();
        } catch (err) {
            setError(err.message || "Wystąpił błąd podczas zapisywania.");
        } finally {
            setLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div
            className="modal fade show d-block"
            style={{ backgroundColor: "rgba(0,0,0,0.5)" }}
        >
            <div className="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
                <div className="modal-content">
                    <div className="modal-header">
                        <h5 className="modal-title d-flex align-items-center gap-2">
                            {isEvent ? (
                                <Calendar size={20} />
                            ) : (
                                <MessageSquare size={20} />
                            )}
                            {isEditing ? "Edytuj" : "Dodaj"}{" "}
                            {isEvent ? "wydarzenie" : "post"}
                        </h5>
                        <button
                            type="button"
                            className="btn-close"
                            onClick={onClose}
                        ></button>
                    </div>
                    <div className="modal-body">
                        {error && (
                            <div className="alert alert-danger d-flex align-items-center gap-2">
                                <AlertCircle size={16} />
                                {error}
                            </div>
                        )}
                        {loading && !existingImages.length ? (
                            <div className="text-center p-5">
                                <Loader size={24} className="spinner-border" />
                            </div>
                        ) : (
                            <form onSubmit={handleSubmit} id="feed-item-form">
                                <div className="mb-3">
                                    <label className="form-label">
                                        Tytuł *{" "}
                                        <span className="text-muted">
                                            (3-50 znaków)
                                        </span>
                                    </label>
                                    <input
                                        type="text"
                                        name="title"
                                        value={formData.title}
                                        onChange={handleChange}
                                        className="form-control"
                                        required
                                        maxLength="50"
                                        minLength="3"
                                    />
                                    <div className="form-text">
                                        {formData.title.length}/50 znaków
                                    </div>
                                </div>

                                <div className="mb-3">
                                    <label className="form-label">
                                        Krótki opis *{" "}
                                        <span className="text-muted">
                                            (10-200 znaków)
                                        </span>
                                    </label>
                                    <textarea
                                        name="shortDescription"
                                        value={formData.shortDescription}
                                        onChange={handleChange}
                                        className="form-control"
                                        rows="2"
                                        required
                                        maxLength="200"
                                        minLength="10"
                                    ></textarea>
                                    <div className="form-text">
                                        {formData.shortDescription.length}/200
                                        znaków
                                    </div>
                                </div>

                                <div className="mb-3">
                                    <label className="form-label">
                                        Długi opis *{" "}
                                        <span className="text-muted">
                                            (100-5000 znaków)
                                        </span>
                                    </label>
                                    <textarea
                                        name="longDescription"
                                        value={formData.longDescription}
                                        onChange={handleChange}
                                        className="form-control"
                                        rows="4"
                                        placeholder="Szczegółowy opis..."
                                        maxLength="5000"
                                        minLength="100"
                                    ></textarea>
                                    <div className="form-text">
                                        {formData.longDescription.length}/5000
                                        znaków
                                    </div>
                                </div>

                                {isEvent && (
                                    <>
                                        <div className="row">
                                            <div className="col-md-6 mb-3">
                                                <label className="form-label">
                                                    Data rozpoczęcia *
                                                </label>
                                                <input
                                                    type="datetime-local"
                                                    name="startDate"
                                                    value={formData.startDate}
                                                    onChange={handleChange}
                                                    className="form-control"
                                                    required
                                                />
                                            </div>
                                            <div className="col-md-6 mb-3">
                                                <label className="form-label">
                                                    Data zakończenia *
                                                </label>
                                                <input
                                                    type="datetime-local"
                                                    name="endDate"
                                                    value={formData.endDate}
                                                    onChange={handleChange}
                                                    className="form-control"
                                                    required
                                                />
                                            </div>
                                        </div>
                                        <div className="mb-3">
                                            <label className="form-label">
                                                Adres *
                                            </label>
                                            <input
                                                type="text"
                                                name="address"
                                                value={formData.address}
                                                onChange={handleChange}
                                                onBlur={handleAddressBlur}
                                                className={`form-control ${
                                                    addressError
                                                        ? "is-invalid"
                                                        : ""
                                                }`}
                                                required
                                            />
                                            {addressError && (
                                                <div className="invalid-feedback">
                                                    {addressError}
                                                </div>
                                            )}
                                        </div>
                                        <div className="mb-3">
                                            <label className="form-label">
                                                Maksymalna liczba uczestników
                                            </label>
                                            <input
                                                type="number"
                                                name="capacity"
                                                value={formData.capacity}
                                                onChange={handleChange}
                                                className="form-control"
                                                min="1"
                                                max="1000"
                                            />
                                        </div>
                                    </>
                                )}

                                <div className="mb-3">
                                    <label className="form-label">
                                        Zdjęcia
                                        <span className="text-muted">
                                            (
                                            {existingImages.length +
                                                imagePreviews.length}
                                            /5)
                                        </span>
                                    </label>
                                    <input
                                        type="file"
                                        multiple
                                        onChange={handleImageChange}
                                        className="form-control"
                                        accept="image/jpeg,image/jpg,image/png,image/gif,image/webp"
                                        disabled={
                                            existingImages.length +
                                                imagePreviews.length >=
                                            5
                                        }
                                    />
                                    <div className="form-text">
                                        Maksymalnie 5 zdjęć. Dozwolone formaty:
                                        JPG, PNG, GIF, WebP. Maksymalny rozmiar:
                                        5MB per plik.
                                        <strong>
                                            {" "}
                                            Pierwsze zdjęcie będzie głównym.
                                        </strong>
                                        {existingImages.length +
                                            imagePreviews.length >=
                                            5 && (
                                            <div className="text-warning mt-1">
                                                <small>
                                                    Osiągnięto limit zdjęć. Usuń
                                                    niektóre aby dodać nowe.
                                                </small>
                                            </div>
                                        )}
                                    </div>
                                </div>

                                {(existingImages.length > 0 ||
                                    imagePreviews.length > 0) && (
                                    <div className="mb-3 p-3 border rounded bg-light">
                                        <p className="mb-2 small fw-bold text-dark">
                                            Zdjęcia
                                        </p>

                                        {existingImages.length > 0 && (
                                            <>
                                                <p className="mb-2 small fw-bold text-primary">
                                                    Obecne zdjęcia:
                                                </p>
                                                <div className="d-flex flex-wrap gap-2 mb-3">
                                                    {existingImages.map(
                                                        (image, index) => (
                                                            <div
                                                                key={image.id}
                                                                className="position-relative"
                                                                draggable
                                                                onDragStart={(
                                                                    e
                                                                ) =>
                                                                    handleDragStart(
                                                                        e,
                                                                        index,
                                                                        "existing"
                                                                    )
                                                                }
                                                                onDragOver={
                                                                    handleDragOver
                                                                }
                                                                onDrop={(e) =>
                                                                    handleDrop(
                                                                        e,
                                                                        index,
                                                                        "existing"
                                                                    )
                                                                }
                                                                style={{
                                                                    cursor: "pointer",
                                                                }}
                                                            >
                                                                <img
                                                                    src={
                                                                        image.imageUrl ||
                                                                        image.url
                                                                    }
                                                                    alt={`Zdjęcie ${
                                                                        index +
                                                                        1
                                                                    }`}
                                                                    className="img-thumbnail"
                                                                    style={{
                                                                        width: "80px",
                                                                        height: "80px",
                                                                        objectFit:
                                                                            "cover",
                                                                        border:
                                                                            index ===
                                                                            0
                                                                                ? "3px solid #28a745"
                                                                                : "2px solid #dee2e6",
                                                                        borderRadius:
                                                                            "8px",
                                                                    }}
                                                                    title={
                                                                        index ===
                                                                        0
                                                                            ? "Główne zdjęcie"
                                                                            : `Zdjęcie ${
                                                                                  index +
                                                                                  1
                                                                              }`
                                                                    }
                                                                />

                                                                {index ===
                                                                    0 && (
                                                                    <div
                                                                        className="position-absolute"
                                                                        style={{
                                                                            top: "-8px",
                                                                            left: "-8px",
                                                                            backgroundColor:
                                                                                "#28a745",
                                                                            color: "white",
                                                                            borderRadius:
                                                                                "50%",
                                                                            width: "20px",
                                                                            height: "20px",
                                                                            display:
                                                                                "flex",
                                                                            alignItems:
                                                                                "center",
                                                                            justifyContent:
                                                                                "center",
                                                                            fontSize:
                                                                                "10px",
                                                                            fontWeight:
                                                                                "bold",
                                                                            border: "2px solid white",
                                                                            zIndex: 10,
                                                                        }}
                                                                        title="Główne zdjęcie"
                                                                    >
                                                                        ★
                                                                    </div>
                                                                )}

                                                                <button
                                                                    type="button"
                                                                    className="btn btn-danger btn-sm position-absolute"
                                                                    style={{
                                                                        top: "-6px",
                                                                        right: "-6px",
                                                                        width: "20px",
                                                                        height: "20px",
                                                                        padding:
                                                                            "0",
                                                                        display:
                                                                            "flex",
                                                                        alignItems:
                                                                            "center",
                                                                        justifyContent:
                                                                            "center",
                                                                        borderRadius:
                                                                            "50%",
                                                                        border: "2px solid white",
                                                                        fontSize:
                                                                            "10px",
                                                                        zIndex: 10,
                                                                    }}
                                                                    onClick={() =>
                                                                        handleRemoveExistingImage(
                                                                            image.id
                                                                        )
                                                                    }
                                                                    title="Usuń zdjęcie"
                                                                >
                                                                    <X
                                                                        size={
                                                                            10
                                                                        }
                                                                    />{" "}
                                                                </button>
                                                            </div>
                                                        )
                                                    )}
                                                </div>
                                            </>
                                        )}

                                        {imagePreviews.length > 0 && (
                                            <>
                                                <p className="mb-2 small fw-bold text-success">
                                                    Nowe zdjęcia:
                                                </p>
                                                <div className="d-flex flex-wrap gap-2">
                                                    {imagePreviews.map(
                                                        (preview, index) => (
                                                            <div
                                                                key={index}
                                                                className="position-relative"
                                                                draggable
                                                                onDragStart={(
                                                                    e
                                                                ) =>
                                                                    handleDragStart(
                                                                        e,
                                                                        index,
                                                                        "preview"
                                                                    )
                                                                }
                                                                onDragOver={
                                                                    handleDragOver
                                                                }
                                                                onDrop={(e) =>
                                                                    handleDrop(
                                                                        e,
                                                                        index,
                                                                        "preview"
                                                                    )
                                                                }
                                                                style={{
                                                                    cursor: "pointer",
                                                                }}
                                                            >
                                                                <img
                                                                    src={
                                                                        preview
                                                                    }
                                                                    alt={`Nowe zdjęcie ${
                                                                        index +
                                                                        1
                                                                    }`}
                                                                    className="img-thumbnail"
                                                                    style={{
                                                                        width: "80px",
                                                                        height: "80px",
                                                                        objectFit:
                                                                            "cover",
                                                                        border:
                                                                            existingImages.length ===
                                                                                0 &&
                                                                            index ===
                                                                                0
                                                                                ? "3px solid #28a745"
                                                                                : "2px solid #dee2e6",
                                                                        borderRadius:
                                                                            "8px",
                                                                    }}
                                                                    title={
                                                                        existingImages.length ===
                                                                            0 &&
                                                                        index ===
                                                                            0
                                                                            ? "Główne zdjęcie"
                                                                            : `Nowe zdjęcie ${
                                                                                  index +
                                                                                  1
                                                                              }`
                                                                    }
                                                                />

                                                                {existingImages.length ===
                                                                    0 &&
                                                                    index ===
                                                                        0 && (
                                                                        <div
                                                                            className="position-absolute"
                                                                            style={{
                                                                                top: "-8px",
                                                                                left: "-8px",
                                                                                backgroundColor:
                                                                                    "#28a745",
                                                                                color: "white",
                                                                                borderRadius:
                                                                                    "50%",
                                                                                width: "20px",
                                                                                height: "20px",
                                                                                display:
                                                                                    "flex",
                                                                                alignItems:
                                                                                    "center",
                                                                                justifyContent:
                                                                                    "center",
                                                                                fontSize:
                                                                                    "10px",
                                                                                fontWeight:
                                                                                    "bold",
                                                                                border: "2px solid white",
                                                                                zIndex: 10,
                                                                            }}
                                                                            title="Główne zdjęcie"
                                                                        >
                                                                            ★
                                                                        </div>
                                                                    )}

                                                                <button
                                                                    type="button"
                                                                    className="btn btn-danger btn-sm position-absolute"
                                                                    style={{
                                                                        top: "-6px",
                                                                        right: "-6px",
                                                                        width: "20px",
                                                                        height: "20px",
                                                                        padding:
                                                                            "0",
                                                                        display:
                                                                            "flex",
                                                                        alignItems:
                                                                            "center",
                                                                        justifyContent:
                                                                            "center",
                                                                        borderRadius:
                                                                            "50%",
                                                                        border: "2px solid white",
                                                                        fontSize:
                                                                            "10px",
                                                                        zIndex: 10,
                                                                    }}
                                                                    onClick={() =>
                                                                        handleRemoveNewImage(
                                                                            index
                                                                        )
                                                                    }
                                                                    title="Usuń zdjęcie"
                                                                >
                                                                    <X
                                                                        size={
                                                                            10
                                                                        }
                                                                    />
                                                                </button>
                                                            </div>
                                                        )
                                                    )}
                                                </div>
                                            </>
                                        )}
                                    </div>
                                )}
                            </form>
                        )}
                    </div>
                    <div className="modal-footer">
                        <button
                            type="button"
                            className="btn btn-secondary"
                            onClick={onClose}
                            disabled={loading}
                        >
                            Anuluj
                        </button>
                        <button
                            type="submit"
                            form="feed-item-form"
                            className="btn btn-primary d-flex align-items-center gap-2"
                            disabled={loading}
                        >
                            {loading ? (
                                <>
                                    <Loader
                                        size={16}
                                        className="spinner-border spinner-border-sm"
                                    />
                                    <span>Zapisywanie...</span>
                                </>
                            ) : (
                                <>
                                    <Plus size={16} />
                                    {isEditing ? "Zapisz zmiany" : "Utwórz"}
                                </>
                            )}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default FeedItemForm;
