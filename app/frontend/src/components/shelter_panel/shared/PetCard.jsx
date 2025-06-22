import React from "react";
import { PawPrint } from "lucide-react";

export const PetCard = ({ pet, onClick, showShelterInfo = false }) => {
    const getStatusBadge = () => {
        if (pet.archived) {
            return <span className="badge bg-success">Adoptowany</span>;
        }
        if (pet.urgent) {
            return <span className="badge bg-danger">Pilny</span>;
        }
        return <span className="badge bg-primary">Dostępny</span>;
    };

    return (
        <div className="pet-card" onClick={onClick}>
            <div className="pet-image">
                {pet.imageUrl ? (
                    <img src={pet.imageUrl} alt={pet.name} />
                ) : (
                    <div className="no-image">
                        <PawPrint size={24} />
                    </div>
                )}
                <div className="pet-status">{getStatusBadge()}</div>
            </div>
            <div className="pet-info">
                <h5>{pet.name}</h5>
                <p className="pet-details">
                    {pet.breed} • {pet.age} {pet.age === 1 ? "rok" : "lata"}
                </p>
                <div className="pet-tags">
                    {pet.gender && (
                        <span className="tag">
                            {pet.gender === "MALE" ? "Samiec" : "Samica"}
                        </span>
                    )}
                    {pet.vaccinated && (
                        <span className="tag">Zaszczepiony</span>
                    )}
                </div>
                {showShelterInfo && pet.shelter && (
                    <p className="shelter-name">{pet.shelter.name}</p>
                )}
            </div>
        </div>
    );
};
