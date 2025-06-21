import React from "react";
import { useNavigate } from "react-router-dom";
import Navbar from "../components/Navbar";
import "./Favourites.css";
import { MapPin, Heart, PawPrint } from "lucide-react";
import {
    fetchFavoritePets,
    fetchShelterById,
    fetchImagesByPetId,
} from "../api/shelter";
import { useEffect, useState } from "react";

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

const Favorites = () => {
    const navigate = useNavigate();
    const [favorites, setFavorites] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const loadFavorites = async () => {
            try {
                console.log("💖 Loading favorite pets...");
                const pets = await fetchFavoritePets();
                console.log("💖 Favorite pets received:", pets);

                const favoritesWithShelter = await Promise.all(
                    pets.map(async (pet) => {
                        console.log(
                            `🐾 Processing favorite pet: ${pet.name} (ID: ${pet.id})`
                        );
                        console.log(`🖼️ Pet imageUrl:`, pet.imageUrl);

                        let shelterName = "Nieznane schronisko";
                        let imageUrl = null;

                        // Najpierw sprawdź czy pet ma główne zdjęcie
                        if (pet.imageUrl) {
                            imageUrl = pet.imageUrl;
                            console.log(
                                `✅ Using main image for ${pet.name}:`,
                                imageUrl
                            );
                        } else {
                            // Jeśli nie ma głównego zdjęcia, spróbuj pobrać dodatkowe
                            try {
                                console.log(
                                    `🔍 Fetching additional images for ${pet.name}...`
                                );
                                const imageData = await fetchImagesByPetId(
                                    pet.id
                                );
                                imageUrl = imageData[0]?.imageUrl || null;
                                console.log(
                                    `📸 Found additional image for ${pet.name}:`,
                                    imageUrl
                                );
                            } catch (err) {
                                console.warn(
                                    `⚠️ No additional images for ${pet.name}:`,
                                    err
                                );
                            }
                        }

                        // Pobierz dane schroniska
                        try {
                            const shelter = await fetchShelterById(
                                pet.shelterId
                            );
                            shelterName = shelter.name;
                        } catch (err) {
                            console.warn(
                                `⚠️ Could not fetch shelter for ${pet.name}:`,
                                err
                            );
                        }

                        return {
                            ...pet,
                            shelterName,
                            image: imageUrl,
                        };
                    })
                );

                console.log(
                    "💖 Final favorites with images:",
                    favoritesWithShelter
                );
                setFavorites(favoritesWithShelter);
            } catch (err) {
                console.error("❌ Error loading favorites:", err);
                setError(err.message);
            } finally {
                setLoading(false);
            }
        };

        loadFavorites();
    }, []);

    if (loading) return <div className="loading-spinner"></div>;
    if (error) return <div className="error-message">{error}</div>;

    return (
        <div>
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
            <div className="favorites-container">
                <div className="favorites-header">
                    <h1>Twoje ulubione zwierzęta</h1>
                    <p>Zwierzaki, które śledzisz i którym kibicujesz</p>
                </div>
                {favorites.length === 0 ? (
                    <p className="no-favorites">
                        Nie masz jeszcze żadnych ulubionych zwierząt
                    </p>
                ) : (
                    <div className="favorites-grid">
                        {favorites.map((animal) => (
                            <div
                                key={animal.id}
                                className="animal-card-favourites"
                                onClick={() =>
                                    navigate(`/petProfile/${animal.id}`)
                                }
                            >
                                <div className="animal-card-image">
                                    <img src={animal.image} alt={animal.name} />
                                    <div className="animal-heart-icon">
                                        <Heart className="heart-icon" />
                                    </div>
                                </div>
                                <div className="animal-card-content-favourites">
                                    <h3>
                                        {animal.name}, {animal.age}
                                    </h3>
                                    <div className="animal-details-favourites">
                                        <span className="animal-location">
                                            <MapPin className="detail-icon" />
                                            <span className="detail-icon"></span>{" "}
                                            {animal.shelterName}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
};

export default Favorites;
