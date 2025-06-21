import { useState } from "react";

export const usePetForm = (initialData = {}) => {
    const [formData, setFormData] = useState({
        name: "",
        type: "DOG",
        breed: "",
        age: "",
        description: "",
        gender: "MALE",
        size: "MEDIUM",
        vaccinated: false,
        urgent: false,
        sterilized: false,
        kidFriendly: false,
        ...initialData,
    });

    const handleChange = (e) => {
        const { name, value, type, checked } = e.target;
        setFormData((prev) => ({
            ...prev,
            [name]: type === "checkbox" ? checked : value,
        }));
    };

    const validateForm = () => {
        if (!formData.name.trim()) return "Imię zwierzęcia jest wymagane";
        if (!formData.breed.trim()) return "Rasa jest wymagana";
        if (!formData.age || formData.age < 0) return "Wiek musi być dodatni";
        if (!formData.description.trim()) return "Opis jest wymagany";
        return null;
    };

    return {
        formData,
        setFormData,
        handleChange,
        validateForm,
    };
};

export const usePetImages = (maxImages = 5) => {
    const [imageFiles, setImageFiles] = useState([]);
    const [imagePreviews, setImagePreviews] = useState([]);
    const [error, setError] = useState("");

    const handleImageChange = (e) => {
        const files = Array.from(e.target.files);

        if (files.length > maxImages) {
            setError(`Możesz dodać maksymalnie ${maxImages} zdjęć.`);
            return;
        }

        const oversizedFiles = files.filter(
            (file) => file.size > 5 * 1024 * 1024
        );
        if (oversizedFiles.length > 0) {
            setError(
                "Niektóre pliki są za duże. Maksymalny rozmiar to 5MB na plik."
            );
            return;
        }

        setImageFiles(files);
        setError("");

        const previews = [];
        files.forEach((file, index) => {
            const reader = new FileReader();
            reader.onload = (e) => {
                previews[index] = e.target.result;
                if (previews.length === files.length) {
                    setImagePreviews(previews);
                }
            };
            reader.readAsDataURL(file);
        });

        if (files.length === 0) {
            setImagePreviews([]);
        }
    };

    const removeImage = (indexToRemove) => {
        const newFiles = imageFiles.filter(
            (_, index) => index !== indexToRemove
        );
        const newPreviews = imagePreviews.filter(
            (_, index) => index !== indexToRemove
        );

        setImageFiles(newFiles);
        setImagePreviews(newPreviews);

        const fileInput = document.querySelector('input[type="file"]');
        if (fileInput) fileInput.value = "";
    };

    return {
        imageFiles,
        imagePreviews,
        error,
        handleImageChange,
        removeImage,
        setError,
    };
};
