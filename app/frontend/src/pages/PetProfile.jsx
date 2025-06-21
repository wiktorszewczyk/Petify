import { useParams } from "react-router-dom";
import { useEffect, useState } from "react";
import "./PetProfile.css";
import {
    Heart,
    PawPrint,
    HandCoins,
    MapPin,
    Trophy,
    ArrowRight,
    ScrollText,
    DollarSign,
    ChevronLeft,
    ChevronRight,
    Dog,
    MessageCircle,
    CheckCircle,
    XCircle,
    AlertCircle,
} from "lucide-react";
import Navbar from "../components/Navbar";
import {
    fetchPetById,
    fetchImagesByPetId,
    fetchShelterById,
} from "../api/shelter";

import dono5 from "../assets/pet_snack.png";
import dono10 from "../assets/pet_bowl.png";
import dono15 from "../assets/pet_toy.png";
import dono25 from "../assets/pet_food.png";
import dono50 from "../assets/pet_bed.png";

const pawSteps = [
    { top: "55vh", left: "90vw", size: "8vw", rotate: "-100deg" },
    { top: "38vh", left: "88vw", size: "8vw", rotate: "-100deg" },
    { top: "39vh", left: "78vw", size: "8vw", rotate: "-115deg" },
    { top: "25vh", left: "72vw", size: "8vw", rotate: "-120deg" },
    { top: "37vh", left: "64vw", size: "8vw", rotate: "-135deg" },
    { top: "24vh", left: "57vw", size: "8vw", rotate: "-145deg" },
    { top: "42vh", left: "51vw", size: "8vw", rotate: "-160deg" },
    { top: "30vh", left: "42vw", size: "8vw", rotate: "-165deg" },
    { top: "48vh", left: "39vw", size: "8vw", rotate: "-165deg" },
    { top: "44vh", left: "28vw", size: "8vw", rotate: "-165deg" },
    { top: "61vh", left: "25vw", size: "8vw", rotate: "-160deg" },
    { top: "52vh", left: "16vw", size: "8vw", rotate: "-150deg" },
    { top: "67vh", left: "10vw", size: "8vw", rotate: "-145deg" },
    { top: "55vh", left: "2vw", size: "8vw", rotate: "-135deg" },
    { top: "70vh", left: "-3vw", size: "8vw", rotate: "-135deg" },
];

function PetProfile() {
    const [currentPhotoIndex, setCurrentPhotoIndex] = useState(0);
    const [showDonatePopup, setShowDonatePopup] = useState(false);
    const [showAdoptPopup, setShowAdoptPopup] = useState(false);
    const [shelter, setShelter] = useState(null);
    const [petPhotos, setPetPhotos] = useState([]);
    const [selectedAmount, setSelectedAmount] = useState(null);
    const [customAmount, setCustomAmount] = useState("");

    const { id } = useParams();
    const [pet, setPet] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const fetchPet = async () => {
            try {
                const data = await fetchPetById(id);

                setPet(data);

                const imagesData = await fetchImagesByPetId(id);

                const allPhotos = [];

                if (data.imageUrl) {
                    allPhotos.push(data.imageUrl);
                }

                if (imagesData && imagesData.length > 0) {
                    const additionalPhotos = imagesData.map(
                        (img) => img.imageUrl
                    );

                    additionalPhotos.forEach((photo) => {
                        if (!allPhotos.includes(photo)) {
                            allPhotos.push(photo);
                        }
                    });
                }
                setPetPhotos(allPhotos);

                if (data.shelterId) {
                    const shelterData = await fetchShelterById(data.shelterId);
                    setShelter(shelterData);
                }
            } catch (err) {
                setError(err.message);
            } finally {
                setLoading(false);
            }
        };

        if (id) {
            fetchPet();
        }
    }, [id]);

    const handlePrev = () => {
        setCurrentPhotoIndex((prevIndex) =>
            prevIndex === 0 ? petPhotos.length - 1 : prevIndex - 1
        );
    };

    const handleNext = () => {
        setCurrentPhotoIndex((prevIndex) =>
            prevIndex === petPhotos.length - 1 ? 0 : prevIndex + 1
        );
    };

    const getSuitabilityIcon = (value) => {
        if (value === true || value === "Tak") {
            return <CheckCircle className="suitability-icon success" />;
        }
        if (value === false || value === "Nie") {
            return <XCircle className="suitability-icon danger" />;
        }
        return <AlertCircle className="suitability-icon warning" />;
    };

    if (loading) return <p>Ładowanie...</p>;
    if (error) return <p>Błąd: {error}</p>;
    if (!pet) return null;

    return (
        <div className="profile-body">
            <Navbar />
            <div className="paw-pattern-background">
                {pawSteps.map((step, i) => (
                    <div
                        key={i}
                        className="paw-wrapper"
                        style={{
                            top: step.top,
                            left: step.left,
                            width: step.size,
                            height: step.size,
                            "--rotation": step.rotate,
                            animationDelay: `${i * 0.5}s`,
                        }}
                    >
                        <PawPrint className="paw-icon" />
                    </div>
                ))}
            </div>

            {showDonatePopup && (
                <div
                    className="donation-popup-overlay"
                    onClick={() => setShowDonatePopup(false)}
                >
                    <div
                        className="donation-popup"
                        onClick={(e) => e.stopPropagation()}
                    >
                        <h2>Wesprzyj {pet.name}</h2>
                        <div className="donation-options">
                            {[
                                { amount: 5, label: "Smakołyki", img: dono5 },
                                {
                                    amount: 10,
                                    label: "Pełna miska",
                                    img: dono10,
                                },
                                { amount: 15, label: "Zabawka", img: dono15 },
                                {
                                    amount: 25,
                                    label: "Zapas karmy",
                                    img: dono25,
                                },
                                { amount: 50, label: "Legowisko", img: dono50 },
                            ].map(({ amount, label, img }) => (
                                <button
                                    key={amount}
                                    className={`donate-option ${
                                        selectedAmount === amount
                                            ? "selected"
                                            : ""
                                    }`}
                                    onClick={() => {
                                        setSelectedAmount(amount);
                                        setCustomAmount("");
                                    }}
                                >
                                    <img
                                        src={img}
                                        alt={label}
                                        className="donate-img"
                                    />
                                    <span className="donate-amount">
                                        {amount} zł
                                    </span>
                                    <span className="donate-label">
                                        {label}
                                    </span>
                                </button>
                            ))}
                        </div>

                        <input
                            type="number"
                            placeholder="Inna kwota"
                            className="donate-input"
                            value={customAmount}
                            onChange={(e) => {
                                setCustomAmount(e.target.value);
                                setSelectedAmount(null);
                            }}
                        />

                        <button
                            className="confirm-donate-btn"
                            disabled={!selectedAmount && !customAmount}
                            onClick={() => {
                                const finalAmount =
                                    selectedAmount || customAmount;
                                window.location.href = `/payment?amount=${finalAmount}`;
                            }}
                        >
                            Przejdź do płatności{" "}
                            {(selectedAmount || customAmount) &&
                                `(${selectedAmount || customAmount} zł)`}
                        </button>
                        <button
                            className="close-popup-btn"
                            onClick={() => setShowDonatePopup(false)}
                        >
                            ×
                        </button>
                    </div>
                </div>
            )}

            <div className="pet-profile-page">
                <div className="pet-picture">
                    <section className="pet-profile-picture">
                        {petPhotos?.length > 0 ? (
                            <div className="photo-slider">
                                <button
                                    className="slider-btn left"
                                    onClick={handlePrev}
                                >
                                    <ChevronLeft />
                                </button>
                                <img
                                    src={petPhotos[currentPhotoIndex]}
                                    alt={`Zdjęcie ${currentPhotoIndex + 1}`}
                                    className="slider-image"
                                />
                                <button
                                    className="slider-btn right"
                                    onClick={handleNext}
                                >
                                    <ChevronRight />
                                </button>
                            </div>
                        ) : (
                            <div className="photo-slider no-photos">
                                <p>Brak zdjęć dla tego zwierzaka</p>
                            </div>
                        )}
                        <div className="photo-thumbnails">
                            {petPhotos?.length > 0 &&
                                petPhotos.map((photo, index) => (
                                    <img
                                        key={index}
                                        src={photo}
                                        alt={`Miniatura ${index + 1}`}
                                        className={`thumbnail ${
                                            index === currentPhotoIndex
                                                ? "active"
                                                : ""
                                        }`}
                                        onClick={() =>
                                            setCurrentPhotoIndex(index)
                                        }
                                    />
                                ))}
                        </div>
                    </section>
                </div>

                <section className="pet-profile-info">
                    <div className="pet-header">
                        <h2 className="pet-name">
                            {pet.name}, {pet.age} lata
                        </h2>
                        <div className="pet-location-info">
                            <MapPin className="map-pin-pet-profile" />
                            <p className="pet-location">
                                {shelter ? (
                                    <>
                                        {shelter.name} &nbsp;
                                        {shelter.address}
                                    </>
                                ) : (
                                    "Ładowanie lokalizacji..."
                                )}
                            </p>
                        </div>
                    </div>

                    <section className="pet-action-buttons">
                        <button
                            className="action-btn btn-adopt"
                            onClick={() => setShowAdoptPopup(true)}
                        >
                            <Heart className="btn-icon" />
                            Adoptuj
                        </button>
                        <button className="action-btn btn-walk">
                            <PawPrint className="btn-icon" />
                            Wyprowadź psa
                        </button>
                        <button
                            className="action-btn btn-support"
                            onClick={() => setShowDonatePopup(true)}
                        >
                            <HandCoins className="btn-icon" />
                            Wesprzyj
                        </button>
                        <button className="action-btn btn-message">
                            <ScrollText className="btn-icon" />
                            Wiadomości
                        </button>
                    </section>

                    <div className="pet-details-grid">
                        <div className="pet-detail-item">
                            <span className="detail-label">
                                Typ zwierzęcia:
                            </span>
                            <span className="detail-value">
                                {{
                                    CAT: "Kot",
                                    DOG: "Pies",
                                    OTHER: "Inne",
                                }[pet.type] || "Nieznany"}
                            </span>
                        </div>
                        <div className="pet-detail-item">
                            <span className="detail-label">Płeć:</span>
                            <span className="detail-value">
                                {pet.gender === "Male" ? "Samiec" : "Samica"}
                            </span>
                        </div>
                        <div className="pet-detail-item">
                            <span className="detail-label">Rasa:</span>
                            <span className="detail-value">{pet.breed}</span>
                        </div>
                        <div className="pet-detail-item">
                            <span className="detail-label">Rozmiar:</span>
                            <span className="detail-value">
                                {{
                                    SMALL: "Mały",
                                    MEDIUM: "Średni",
                                    LARGE: "Duży",
                                }[pet.size] || "Nieznany"}
                            </span>
                        </div>
                    </div>

                    <section className="pet-description">
                        <h3>Opis</h3>
                        <p>{pet.description}</p>
                    </section>

                    <section className="pet-suitability">
                        <h3>Dopasowanie</h3>
                        <div className="suitability-grid">
                            <div className="suitability-item">
                                <span className="detail-label">Dzieci:</span>
                                <span className="suitability-value">
                                    {getSuitabilityIcon(pet.kidFriendly)}
                                    {pet.kidFriendly ? "Tak" : "Nie"}
                                </span>
                            </div>
                            <div className="suitability-item">
                                <span className="detail-label">
                                    Sterylizacja:
                                </span>
                                <span className="suitability-value">
                                    {getSuitabilityIcon(pet.sterilized)}
                                    {pet.sterilized ? "Tak" : "Nie"}
                                </span>
                            </div>
                            <div className="suitability-item">
                                <span className="detail-label">
                                    Szczepeienia:
                                </span>
                                <span className="suitability-value">
                                    {getSuitabilityIcon(pet.vaccinated)}
                                    {pet.vaccinated ? "Tak" : "Nie"}
                                </span>
                            </div>
                        </div>
                    </section>
                </section>
            </div>
        </div>
    );
}

export default PetProfile;
