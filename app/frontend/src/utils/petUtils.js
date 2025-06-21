export const getPetTypeLabel = (type) => {
    switch (type) {
        case "DOG":
            return "Pies";
        case "CAT":
            return "Kot";
        default:
            return "Inne";
    }
};

export const getGenderLabel = (gender) => {
    switch (gender) {
        case "MALE":
            return "Samiec";
        case "FEMALE":
            return "Samica";
        default:
            return "Nieznana";
    }
};

export const getSizeLabel = (size) => {
    switch (size) {
        case "SMALL":
            return "Mały";
        case "MEDIUM":
            return "Średni";
        case "BIG":
            return "Duży";
        case "VERY_BIG":
            return "Bardzo duży";
        default:
            return "Nieznany";
    }
};

export const getPetStatusInfo = (pet) => {
    if (pet.archived) {
        return {
            text: "Adoptowany",
            color: "success",
            icon: "CheckCircle",
        };
    }
    if (pet.urgent) {
        return {
            text: "Pilny przypadek",
            color: "danger",
            icon: "AlertCircle",
        };
    }
    return {
        text: "Dostępny do adopcji",
        color: "primary",
        icon: "PawPrint",
    };
};
