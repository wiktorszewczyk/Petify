import React, { useState, useEffect, memo, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import {
    Edit,
    Trash2,
    MapPin,
    PawPrint,
    CheckCircle,
    AlertCircle,
    HeartHandshake,
} from "lucide-react";
import { getPetImages } from "../../api/pet";
import {
    getPetStatusInfo,
    getPetTypeLabel,
    getGenderLabel,
    getSizeLabel,
} from "../../utils/petUtils";

const PetDetailsModal = ({
    pet,
    shelter,
    isOpen,
    onClose,
    onDelete,
    onArchive,
    onEdit,
}) => {
    const navigate = useNavigate();
    const [currentImageIndex, setCurrentImageIndex] = useState(0);
    const [allImages, setAllImages] = useState([]);

    const loadAllImages = useCallback(async () => {
        if (!pet) return;

        const images = [];
        if (pet.imageUrl) {
            images.push({
                id: "main",
                url: pet.imageUrl,
                name: "Główne zdjęcie",
            });
        }

        try {
            const result = await getPetImages(pet.id);
            if (result.success && result.data?.length > 0) {
                result.data.forEach((img, index) => {
                    images.push({
                        id: img.id || `additional-${index}`,
                        url: img.imageUrl,
                        name: `Zdjęcie ${index + 2}`,
                    });
                });
            }
        } catch (error) {}
        setAllImages(images);
    }, [pet]);

    useEffect(() => {
        if (pet && isOpen) {
            setCurrentImageIndex(0);
            loadAllImages();
        }
    }, [pet, isOpen, loadAllImages]);

    if (!isOpen || !pet) return null;

    const handleBackdropClick = (e) => {
        if (e.target === e.currentTarget) {
            onClose();
        }
    };

    const handleEdit = () => {
        onClose();
        navigate(`/shelter-panel/edit-pet/${pet.id}`);
    };

    const handlePrevImage = () => {
        setCurrentImageIndex((prev) =>
            prev > 0 ? prev - 1 : Math.max(0, allImages.length - 1)
        );
    };

    const handleNextImage = () => {
        setCurrentImageIndex((prev) =>
            prev < allImages.length - 1 ? prev + 1 : 0
        );
    };

    const status = getPetStatusInfo(pet);
    const PetStatusIcon =
        status.icon === "CheckCircle"
            ? CheckCircle
            : status.icon === "AlertCircle"
            ? AlertCircle
            : PawPrint;

    return (
        <div className="pet-modal-backdrop" onClick={handleBackdropClick}>
            <div className="pet-modal">
                <div className="pet-modal-header">
                    <div className="d-flex align-items-center">
                        <h4 className="mb-0 me-2">{pet.name}</h4>
                        <span
                            className={`badge bg-${status.color} d-flex align-items-center`}
                        >
                            <PetStatusIcon size={14} className="me-1" />
                            {status.text}
                        </span>
                    </div>
                    <div className="d-flex gap-2">
                        <button
                            className="btn btn-outline-primary"
                            onClick={handleEdit}
                        >
                            <Edit size={18} className="me-1" />
                            Edytuj
                        </button>
                        {!pet.archived && (
                            <button
                                className="btn btn-outline-success"
                                onClick={() => onArchive(pet.id, pet.name)}
                            >
                                <HeartHandshake size={18} className="me-1" />
                                Oznacz jako adoptowany
                            </button>
                        )}
                        <button
                            className="btn btn-outline-danger"
                            onClick={() => onDelete(pet.id, pet.name)}
                        >
                            <Trash2 size={18} className="me-1" />
                            Usuń
                        </button>
                        <button
                            className="btn-close"
                            onClick={onClose}
                        ></button>
                    </div>
                </div>

                <div className="pet-modal-content">
                    <div className="row">
                        <div className="col-md-6">
                            <MemoizedImageGallery
                                images={allImages}
                                currentIndex={currentImageIndex}
                                onPrevious={handlePrevImage}
                                onNext={handleNextImage}
                                onThumbnailClick={setCurrentImageIndex}
                            />
                        </div>
                        <div className="col-md-6">
                            <MemoizedPetDetails pet={pet} shelter={shelter} />
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

const ImageGallery = ({
    images,
    currentIndex,
    onPrevious,
    onNext,
    onThumbnailClick,
}) => {
    if (images.length === 0) {
        return (
            <div className="no-image-placeholder">
                <div className="text-muted text-center py-5">
                    <PawPrint size={48} className="text-muted" />
                    <p className="mt-2">Brak zdjęcia</p>
                </div>
            </div>
        );
    }

    return (
        <div className="pet-modal-image-container">
            <div className="pet-modal-image">
                <img
                    src={images[currentIndex].url}
                    alt={images[currentIndex].name}
                    className="w-100 h-100"
                    style={{ objectFit: "cover" }}
                />
                {images.length > 1 && (
                    <>
                        <button
                            className="btn btn-light image-nav-btn prev-btn"
                            onClick={onPrevious}
                        >
                            ‹
                        </button>
                        <button
                            className="btn btn-light image-nav-btn next-btn"
                            onClick={onNext}
                        >
                            ›
                        </button>
                        <div className="image-counter">
                            {currentIndex + 1} / {images.length}
                        </div>
                    </>
                )}
            </div>
            {images.length > 1 && (
                <div className="image-thumbnails">
                    {images.map((img, index) => (
                        <div
                            key={img.id || `thumb-${index}`}
                            className={`thumbnail ${
                                index === currentIndex ? "active" : ""
                            }`}
                            onClick={() => onThumbnailClick(index)}
                        >
                            <img src={img.url} alt={img.name} />
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};
const MemoizedImageGallery = memo(ImageGallery);

const PetDetails = ({ pet, shelter }) => (
    <div className="pet-details-info">
        <DetailRow label="Typ" value={getPetTypeLabel(pet.type)} />
        <DetailRow label="Rasa" value={pet.breed} />
        <DetailRow
            label="Wiek"
            value={`${pet.age} ${
                pet.age === 1 ||
                (pet.age > 4 &&
                    pet.age % 10 > 1 &&
                    pet.age % 10 < 5 &&
                    (pet.age < 10 || pet.age > 20))
                    ? "lata"
                    : "lat"
            }`}
        />
        <DetailRow label="Płeć" value={getGenderLabel(pet.gender)} />
        <DetailRow label="Rozmiar" value={getSizeLabel(pet.size)} />
        <div className="detail-row">
            <strong>Dodatkowe informacje:</strong>
            <div className="pet-properties mt-1">
                {pet.vaccinated && (
                    <span className="property-tag">Zaszczepiony</span>
                )}
                {pet.sterilized && (
                    <span className="property-tag">Wysterylizowany</span>
                )}
                {pet.kidFriendly && (
                    <span className="property-tag">Lubi dzieci</span>
                )}
                {!pet.vaccinated && !pet.sterilized && !pet.kidFriendly && (
                    <span className="text-muted">
                        Brak dodatkowych informacji
                    </span>
                )}
            </div>
        </div>
        {pet.description && (
            <div className="detail-row">
                <strong>Opis:</strong>
                <p className="description-text mb-0">{pet.description}</p>
            </div>
        )}
        {shelter && (
            <div className="detail-row">
                <strong>Schronisko:</strong>
                <div className="shelter-info">
                    <div className="d-flex align-items-center">
                        <MapPin size={16} className="me-1" />
                        <span>{shelter.name}</span>
                    </div>
                </div>
            </div>
        )}
    </div>
);
const MemoizedPetDetails = memo(PetDetails);

const DetailRow = ({ label, value }) => (
    <div className="detail-row">
        <strong>{label}:</strong>
        <span>{value}</span>
    </div>
);

export default PetDetailsModal;
