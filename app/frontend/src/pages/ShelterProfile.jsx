import React, { useState } from "react";
import "./ShelterProfile.css";
import {
  PawPrint,
  HandCoins,
  MapPin,
  ScrollText,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";
import Navbar from "../components/Navbar";


import shelter1 from '../assets/schronisko1.jpg';
import shelter2 from '../assets/schronisko2.jpg';
import shelter3 from '../assets/schronisko3.jpg';

import dono1 from '../assets/donation_5.png';
import dono2 from '../assets/donation_10.png';
import dono3 from '../assets/donation_20.png';
import dono4 from '../assets/donation_50.png';
import dono5 from '../assets/donation_100.png'


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

const shelter = {
  id: 101,
  name: 'Schronisko na Paluchu',
  location: 'Warszawa - Mokotów ul. Spacerowa 12', 
  description: 'Schronisko dla zwierząt w Warszawie, które zapewnia opiekę i schronienie dla bezdomnych psów i kotów. Naszym celem jest znalezienie nowych domów dla naszych podopiecznych oraz edukacja społeczeństwa na temat odpowiedzialnego posiadania zwierząt.',
  photos: [shelter1, shelter2, shelter3],
};

const announcements = [
  {
    id: 1,
    title: "Dziień otwarty w schronisku",
    location: "Warszawa - Mokotów ul. Spacerowa 12",
    date: "2023-10-15",
    description: "Zapraszamy na dzień otwarty w naszym schronisku! Poznaj naszych podopiecznych i dowiedz się, jak możesz pomóc.",
    image : shelter1,
  },
  {
    id: 1,
    title: "Zbiórka na leczenie zwierząt",
    location: "Warszawa - Mokotów ul. Spacerowa 12",
    date: "2023-10-15",
    description: "Zbieramy fundusze na leczenie naszych podopiecznych. Każda złotówka się liczy!",
    image : shelter2,
  },
  // Dodaj więcej ogłoszeń w razie potrzeby
];

function ShelterProfile() {
  const [currentPhotoIndex, setCurrentPhotoIndex] = useState(0);
  const [showDonatePopup, setShowDonatePopup] = useState(false);

  const handlePrev = () => {
    setCurrentPhotoIndex((prevIndex) =>
      prevIndex === 0 ? shelter.photos.length - 1 : prevIndex - 1
    );
  };

  const handleNext = () => {
    setCurrentPhotoIndex((prevIndex) =>
      prevIndex === shelter.photos.length - 1 ? 0 : prevIndex + 1
    );
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
            <h2>Wesprzyj {shelter.name}</h2>
            <p>Każda kwota się liczy! Wybierz wysokość wsparcia:</p>
            <div className="donation-options">
              {[ 
                { amount: 5, img: dono1 },
                { amount: 10, img: dono2 },
                { amount: 20, img: dono3 },
                { amount: 50, img: dono4 },
                 { amount: 100, img: dono5 }
              ].map(({ amount, label, img }) => (
                <button key={amount} className="donate-option">
                  <img src={img} alt={label} className="donate-img" />
                  <span className="donate-amount">{amount} zł</span>
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


     

      <div className="shelter-profile-page">
        <div className="shelter-picture">
        <section className="shelter-profile-picture">
          <div className="photo-slider">
             <button className="slider-btn left" onClick={handlePrev}>
              <ChevronLeft />
            </button>
            <img
              src={shelter.photos[currentPhotoIndex]}
              alt={`Buddy zdjęcie ${currentPhotoIndex + 1}`}
              className="slider-image"
            />
            <button className="slider-btn right" onClick={handleNext}>
              <ChevronRight />
            </button>
          </div>
          <div className="photo-thumbnails">
            {shelter.photos.map((photo, index) => (
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

        <section className="shelter-profile-info">

  {/* Nagłówek imię + lokalizacja */}
  <div className="shelter-header">
    <h2 className="shelter-name">{shelter.name}</h2>  
    <div className="shelter-location-info"> 
      <MapPin className="map-pin-shelter-profile" /> 
      <p className="shelter-location">{shelter.location}</p> 
    </div>
  </div>

  {/* Przyciski akcji */}
  <section className="shelter-action-buttons">
    <button className="action-btn btn-support" onClick={() => setShowDonatePopup(true)}>
      <HandCoins className="btn-icon" />
      Wesprzyj
    </button>
    <button className="action-btn btn-message">
      <ScrollText className="btn-icon" />
      Wiadomości
    </button>
  </section>


  {/* Opis */}
  <section className="pet-description">
    <h3>Opis</h3>
    <p>{shelter.description}</p>
  </section>


   {/*liczba dotacji*/}

   {/*zbiorki*/}
<section className="shelter-announcements">
  <h3 className="section-title">Ogłoszenia</h3>
  <div className="announcements-list">
    {announcements.map((item) => (
      <div key={item.id} className="announcement-card">
        <div className="announcement-image-container">
          <img src={item.image} alt={item.title} className="announcement-image" />
        </div>
        <div className="announcement-content">
          <h4 className="announcement-title">{item.title}</h4>
          <div className="announcement-details">
            <div className="announcement-detail">
              <MapPin size={16} className="announcement-icon" />
              <span>{item.location}</span>
            </div>
            <div className="announcement-detail">
              <ScrollText size={16} className="announcement-icon" />
              <span>{item.date}</span>
            </div>
          </div>
          <p className="announcement-description">{item.description}</p>
          <button className="announcement-button">Szczegóły</button>
        </div>
      </div>
    ))}
  </div>
</section>

  

  

</section>

      </div>
    </div>
  );
}

export default ShelterProfile;