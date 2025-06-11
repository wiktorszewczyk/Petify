import React, { useState } from "react";
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
  AlertCircle 
} from "lucide-react";
import Navbar from "../components/Navbar";

import dog1 from '../assets/dog2_1.jpg';
import dog2 from '../assets/dog2_2.jpg';
import dog3 from '../assets/dog2_3.jpg';

import dono5 from '../assets/pet_snack.png';
import dono10 from '../assets/pet_bowl.png';
import dono15 from '../assets/pet_toy.png';
import dono25 from '../assets/pet_food.png';
import dono50 from '../assets/pet_bed.png';

const pawSteps = [
  { top: '55vh', left: '90vw', size: '8vw', rotate: '-100deg' },
  { top: '38vh', left: '88vw', size: '8vw', rotate: '-100deg' },
  { top: '39vh', left: '78vw', size: '8vw', rotate: '-115deg' },
  { top: '25vh', left: '72vw', size: '8vw', rotate: '-120deg' },
  { top: '37vh', left: '64vw', size: '8vw', rotate: '-135deg' },
  { top: '24vh', left: '57vw', size: '8vw', rotate: '-145deg' },
  { top: '42vh', left: '51vw', size: '8vw', rotate: '-160deg' },
  { top: '30vh', left: '42vw', size: '8vw', rotate: '-165deg' },
  { top: '48vh', left: '39vw', size: '8vw', rotate: '-165deg' },
  { top: '44vh', left: '28vw', size: '8vw', rotate: '-165deg' },
  { top: '61vh', left: '25vw', size: '8vw', rotate: '-160deg' },
  { top: '52vh', left: '16vw', size: '8vw', rotate: '-150deg' },
  { top: '67vh', left: '10vw', size: '8vw', rotate: '-145deg' },
  { top: '55vh', left: '2vw', size: '8vw', rotate: '-135deg' },
  { top: '70vh', left: '-3vw', size: '8vw', rotate: '-135deg' },
];

const pet = {
  id: 101,
  name: 'Luna',
  age: 2,
  breed: 'Husky',
  gender: 'Female',
  size: 'Large',
  vaccinated: true,
  neuteredOrSpayed: true,
  location: 'Schronisko "Cztery Łapy"',
  address: '1234 Dog Lane, Seattle, WA',
  coordinates: { lat: 47.6062, lon: -122.3321 },
  description: 'Buddy to prawdziwy promień słońca – energiczny, łagodny i bardzo przyjazny. Uwielbia spacery, zabawę na świeżym powietrzu i towarzystwo ludzi. Jest łasy na pieszczoty i bardzo szybko się przywiązuje. Świetnie dogaduje się z innymi psami, a jego złote futerko i wiecznie merdający ogon skradną Twoje serce od pierwszego spojrzenia. Buddy szuka odpowiedzialnego domu, gdzie będzie pełnoprawnym członkiem rodziny. Idealnie sprawdzi się w domu z ogrodem, ale odnajdzie się też w mieszkaniu, jeśli zapewnisz mu odpowiednią dawkę ruchu i miłości.',
  photos: [dog1, dog2, dog3],
  characteristics: [
    'Lubi dzieci',
    'Przyjazny wobec innych psów',
    'Energiczny',
    'Bardzo towarzyski',
    'Uwielbia zabawy na świeżym powietrzu'
  ],
  healthInfo: {
    vaccines: 'Wszystkie aktualne',
    medicalChecks: 'Przebadany',
    specialNeeds: 'Brak',
  },
  trainingLevel: 'Podstawowe posłuszeństwo',
  goodWith: {
    children: true,
    otherDogs: true,
    cats: 'Nieznane',
  }
};

function PetProfile() {
  const [currentPhotoIndex, setCurrentPhotoIndex] = useState(0);
  const [showDonatePopup, setShowDonatePopup] = useState(false);
  const [showAdoptPopup, setShowAdoptPopup] = useState(false);
  const [motivationText, setMotivationText] = useState('');
const [fullName, setFullName] = useState('');
const [phoneNumber, setPhoneNumber] = useState('');
const [address, setAddress] = useState('');
const [housingType, setHousingType] = useState('');
const [isHouseOwner, setIsHouseOwner] = useState(false);
const [hasYard, setHasYard] = useState(false);
const [hasOtherPets, setHasOtherPets] = useState(false);
const [description, setDescription] = useState('');


  const handlePrev = () => {
    setCurrentPhotoIndex((prevIndex) =>
      prevIndex === 0 ? pet.photos.length - 1 : prevIndex - 1
    );
  };

  const handleNext = () => {
    setCurrentPhotoIndex((prevIndex) =>
      prevIndex === pet.photos.length - 1 ? 0 : prevIndex + 1
    );
    };

  const getSuitabilityIcon = (value) => {
  if (value === true || value === 'Tak') {
    return <CheckCircle className="suitability-icon success" />;
  }
  if (value === false || value === 'Nie') {
    return <XCircle className="suitability-icon danger" />;
  }
  return <AlertCircle className="suitability-icon warning" />;
};
  

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
              '--rotation': step.rotate,
              animationDelay: `${i * 0.5}s`,
            }}
          >
            <PawPrint className="paw-icon" />
          </div>
        ))}
      </div>

      
      {showDonatePopup && (
        <div className="donation-popup-overlay" onClick={() => setShowDonatePopup(false)}>
          <div className="donation-popup" onClick={(e) => e.stopPropagation()}>
            <h2>Wesprzyj {pet.name}</h2>
            <p>Każda kwota się liczy! Wybierz wysokość wsparcia:</p>
            <div className="donation-options">
              {[ 
                { amount: 5, label: "Smakołyki", img: dono5 },
                { amount: 10, label: "Pełna miska", img: dono10 },
                { amount: 15, label: "Zabawka", img: dono15 },
                { amount: 25, label: "Zapas karmy", img: dono25 },
                 { amount: 50, label: "Legowisko", img: dono50 }
              ].map(({ amount, label, img }) => (
                <button key={amount} className="donate-option">
                  <img src={img} alt={label} className="donate-img" />
                  <span className="donate-amount">{amount} zł</span>
                  <span className="donate-label">{label}</span>
                </button>
              ))}
            </div>
      
            <input type="number" placeholder="Inna kwota" className="donate-input" />
            
            <button className="confirm-donate-btn" onClick={() => window.location.href = '/payment'}>
              Przejdź do płatności
            </button>
            <button className="close-popup-btn" onClick={() => setShowDonatePopup(false)}>X</button>
          </div>
        </div>
      )}


      {showAdoptPopup && (
  <div className="donation-popup-overlay" onClick={() => setShowAdoptPopup(false)}>
    <div className="donation-popup" onClick={(e) => e.stopPropagation()}>
      <h2>Formularz Adopcyjny – {pet.name}</h2>

      <form
        onSubmit={async (e) => {
          e.preventDefault();

          const payload = {
            motivationText,
            fullName,
            phoneNumber,
            address,
            housingType,
            isHouseOwner,
            hasYard,
            hasOtherPets,
            description,
          };

          try {
            const res = await fetch(`http://localhost:9000/pets/${pet.id}/adopt`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${localStorage.getItem("jwt")}`,
              },
              body: JSON.stringify(payload),
            });

            if (res.ok) {
              alert("Formularz wysłany pomyślnie!");
              setShowAdoptPopup(false);
            } else {
              alert("Błąd podczas wysyłania formularza.");
            }
          } catch (err) {
            console.error("Adoption error:", err);
            alert("Wystąpił błąd.");
          }
        }}
      >
        <input type="text" placeholder="Imię i nazwisko" required value={fullName} onChange={e => setFullName(e.target.value)} />
        <input type="text" placeholder="Telefon" required value={phoneNumber} onChange={e => setPhoneNumber(e.target.value)} />
        <input type="text" placeholder="Adres" required value={address} onChange={e => setAddress(e.target.value)} />
        <input type="text" placeholder="Rodzaj mieszkania (np. Apartment)" required value={housingType} onChange={e => setHousingType(e.target.value)} />
        
        <textarea placeholder="Dlaczego chcesz adoptować?" required value={motivationText} onChange={e => setMotivationText(e.target.value)} />
        <textarea placeholder="Dodatkowe informacje o sobie" value={description} onChange={e => setDescription(e.target.value)} />

        <label>
          <input type="checkbox" checked={isHouseOwner} onChange={e => setIsHouseOwner(e.target.checked)} />
          Właściciel nieruchomości
        </label>
        <label>
          <input type="checkbox" checked={hasYard} onChange={e => setHasYard(e.target.checked)} />
          Posiada ogród
        </label>
        <label>
          <input type="checkbox" checked={hasOtherPets} onChange={e => setHasOtherPets(e.target.checked)} />
          Ma inne zwierzęta
        </label>

        <button type="submit" className="confirm-donate-btn">Wyślij formularz</button>
        <button type="button" className="close-popup-btn" onClick={() => setShowAdoptPopup(false)}>X</button>
      </form>
    </div>
  </div>
)}

      <div className="pet-profile-page">
        <div className="pet-picture">
        <section className="pet-profile-picture">
          <div className="photo-slider">
             <button className="slider-btn left" onClick={handlePrev}>
              <ChevronLeft />
            </button>
            <img
              src={pet.photos[currentPhotoIndex]}
              alt={`Buddy zdjęcie ${currentPhotoIndex + 1}`}
              className="slider-image"
            />
            <button className="slider-btn right" onClick={handleNext}>
              <ChevronRight />
            </button>
          </div>
          <div className="photo-thumbnails">
            {pet.photos.map((photo, index) => (
              <img
                key={index}
                src={photo}
                alt={`Miniatura ${index + 1}`}
                className={`thumbnail ${index === currentPhotoIndex ? 'active' : ''}`}
                onClick={() => setCurrentPhotoIndex(index)}
              />
            ))}
          </div>
        </section>

        </div>

        <section className="pet-profile-info">

  {/* Nagłówek imię + lokalizacja */}
  <div className="pet-header">
    <h2 className="pet-name">{pet.name}, {pet.age} lata</h2>  
    <div className="pet-location-info"> 
      <MapPin className="map-pin-pet-profile" /> 
      <p className="pet-location">{pet.location}</p> 
    </div>
  </div>

  {/* Przyciski akcji */}
  <section className="pet-action-buttons">
    <button className="action-btn btn-adopt" onClick={() => setShowAdoptPopup(true)}>
      <Heart className="btn-icon" />
      Adoptuj
    </button>
    <button className="action-btn btn-walk">
      <PawPrint className="btn-icon" />
      Wyprowadź psa
    </button>
    <button className="action-btn btn-support" onClick={() => setShowDonatePopup(true)}>
      <HandCoins className="btn-icon" />
      Wesprzyj
    </button>
    <button className="action-btn btn-message">
      <ScrollText className="btn-icon" />
      Wiadomości
    </button>
  </section>


  {/* Szczegóły podstawowe */}
  <div className="pet-details-grid">
    <div className="pet-detail-item">
      <span className="detail-label">Płeć:</span>
      <span className="detail-value">{pet.gender === 'Male' ? 'Samiec' : 'Samica'}</span>
    </div>
    <div className="pet-detail-item">
      <span className="detail-label">Rasa:</span>
      <span className="detail-value">{pet.breed}</span>
    </div>
    <div className="pet-detail-item">
      <span className="detail-label">Rozmiar:</span>
      <span className="detail-value">
        {pet.size === 'Large' ? 'Duży' : pet.size === 'Medium' ? 'Średni' : 'Mały'}
      </span>
    </div>
    <div className="pet-detail-item">
      <span className="detail-label">Kastracja:</span>
      <span className="detail-value">
        {pet.neuteredOrSpayed ? 'Tak' : 'Nie'}
      </span>
    </div>
    <div className="pet-detail-item">
      <span className="detail-label">Szczepienia:</span>
      <span className="detail-value">
        {pet.vaccinated ? 'Tak' : 'Nie'}
      </span>
    </div>
  </div>

  {/* Opis */}
  <section className="pet-description">
    <h3>Opis</h3>
    <p>{pet.description}</p>
  </section>

  {/* Charakterystyka */}
  <section className="pet-characteristics">
    <h3>Charakterystyka</h3>
    <ul>
      {pet.characteristics.map((char, index) => (
        <li key={index}>{char}</li>
      ))}
    </ul>
  </section>

  {/* Informacje zdrowotne */}
  <section className="pet-health-info">
    <h3>Informacje Zdrowotne</h3>
    <div className="pet-detail-item">
      <span className="detail-label">Szczepienia:</span>
      <span className="detail-value">{pet.healthInfo.vaccines}</span>
    </div>
    <div className="pet-detail-item">
      <span className="detail-label">Badania:</span>
      <span className="detail-value">{pet.healthInfo.medicalChecks}</span>
    </div>
    <div className="pet-detail-item">
      <span className="detail-label">Specjalne potrzeby:</span>
      <span className="detail-value">{pet.healthInfo.specialNeeds}</span>
    </div>
  </section>

  {/* Dopasowanie */}
  <section className="pet-suitability">
  <h3>Czy nadaje się do...</h3>
  <div className="suitability-grid">
    <div className="suitability-item">
      <span className="detail-label">Dzieci:</span>
      <span className="suitability-value">
        {getSuitabilityIcon(pet.goodWith.children)}
        {pet.goodWith.children ? 'Tak' : 'Nie'}
      </span>
    </div>
    <div className="suitability-item">
      <span className="detail-label">Inne psy:</span>
      <span className="suitability-value">
        {getSuitabilityIcon(pet.goodWith.otherDogs)}
        {pet.goodWith.otherDogs ? 'Tak' : 'Nie'}
      </span>
    </div>
    <div className="suitability-item">
      <span className="detail-label">Koty:</span>
      <span className="suitability-value">
        {getSuitabilityIcon(pet.goodWith.cats)}
        {pet.goodWith.cats}
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