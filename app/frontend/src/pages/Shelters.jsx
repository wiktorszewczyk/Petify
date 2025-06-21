import React from "react";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import Navbar from "../components/Navbar";
import "./Shelters.css";
import { MapPin, PawPrint } from "lucide-react";
import { fetchShelters } from "../api/shelter";

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

const Shelters = () => {
    const navigate = useNavigate();
    const [shelters, setShelters] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const load = async () => {
            try {
                const data = await fetchShelters();
                setShelters(data);
            } catch (err) {
                setError(err.message);
            } finally {
                setLoading(false);
            }
        };

        load();
    }, []);

    if (loading)
        return <div className="loading-spinner">Ładowanie schronisk...</div>;
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

            <div className="shelter-container">
                <div className="shelter-header">
                    <h1>Nasze schroniska</h1>
                    <p>Schroniska, które z nami współpracuja</p>
                </div>

                <div className="shelter-grid">
                    {shelters.map((shelter) => (
                        <div
                            key={shelter.id}
                            className="shelter-card"
                            onClick={() => navigate(`/shelter/${shelter.id}`)}
                        >
                            <div className="shelter-card-image">
                                <img
                                    src={shelter.imageUrl}
                                    alt={shelter.name}
                                />
                            </div>
                            <div className="shelter-card-content">
                                <h3>{shelter.name}</h3>
                                <div className="shelter-details">
                                    <MapPin className="detail-icon" />{" "}
                                    {shelter.address}
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
};

export default Shelters;
