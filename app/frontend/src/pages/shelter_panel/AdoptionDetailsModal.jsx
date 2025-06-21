import React from "react";
import { X, Trash2 } from "lucide-react";
import "./AdoptionDetailsModal.css";

const AdoptionDetailsModal = ({
    isOpen,
    onClose,
    application,
    petName,
    onDelete,
}) => {
    if (!isOpen || !application) {
        return null;
    }

    const getBooleanText = (value) => (value ? "Tak" : "Nie");
    const getStatusText = (status) => {
        switch (status) {
            case "PENDING":
                return "Oczekujący";
            case "ACCEPTED":
                return "Zaakceptowany";
            case "REJECTED":
                return "Odrzucony";
            case "CANCELLED":
                return "Anulowany";
            default:
                return status;
        }
    };

    return (
        <div className="custom-modal-backdrop" onClick={onClose}>
            <div
                className="custom-modal-content"
                onClick={(e) => e.stopPropagation()}
            >
                <div className="custom-modal-header">
                    <h4 className="mb-0">
                        Szczegóły Wniosku Adopcyjnego #{application.id}
                    </h4>
                    <button onClick={onClose} className="btn-close-modal">
                        <X size={24} />
                    </button>
                </div>
                <div className="custom-modal-body">
                    <div className="row">
                        <div className="col-md-6">
                            <p>
                                <strong>Zwierzę:</strong>{" "}
                                {petName || `ID: ${application.petId}`}
                            </p>
                            <p>
                                <strong>Wnioskujący:</strong>{" "}
                                {application.fullName} ({application.username})
                            </p>
                            <p>
                                <strong>Status:</strong>{" "}
                                {getStatusText(application.adoptionStatus)}
                            </p>
                            <p>
                                <strong>Numer telefonu:</strong>{" "}
                                {application.phoneNumber}
                            </p>
                            <p>
                                <strong>Adres:</strong> {application.address}
                            </p>
                        </div>
                        <div className="col-md-6">
                            <p>
                                <strong>Rodzaj mieszkania:</strong>{" "}
                                {application.housingType}
                            </p>
                            <p>
                                <strong>Właściciel mieszkania:</strong>{" "}
                                {getBooleanText(application.isHouseOwner)}
                            </p>
                            <p>
                                <strong>Posiada podwórko:</strong>{" "}
                                {getBooleanText(application.hasYard)}
                            </p>
                            <p>
                                <strong>Posiada inne zwierzęta:</strong>{" "}
                                {getBooleanText(application.hasOtherPets)}
                            </p>
                        </div>
                    </div>
                    <hr className="my-3" />
                    <div>
                        <h5>Motywacja:</h5>
                        <div className="description-box">
                            <p>{application.motivationText}</p>
                        </div>
                    </div>
                    {application.description && (
                        <div className="mt-3">
                            <h5>Dodatkowy opis od użytkownika:</h5>
                            <div className="description-box">
                                <p>{application.description}</p>
                            </div>
                        </div>
                    )}
                </div>
                <div className="custom-modal-footer">
                    {application?.adoptionStatus === "REJECTED" && onDelete && (
                        <button
                            className="btn btn-danger me-2"
                            onClick={() => {
                                onDelete(application.id);
                                onClose();
                            }}
                        >
                            <Trash2 size={16} className="me-1" />
                            Usuń trwale
                        </button>
                    )}
                    <button
                        className="btn btn-outline-secondary"
                        onClick={onClose}
                    >
                        Zamknij
                    </button>
                </div>
            </div>
        </div>
    );
};

export default AdoptionDetailsModal;
