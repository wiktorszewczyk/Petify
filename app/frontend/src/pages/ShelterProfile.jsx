import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import "./ShelterProfile.css";
import {
  PawPrint,
  HandCoins,
  MapPin,
  ScrollText,
  ChevronLeft,
  ChevronRight,
  Phone
} from "lucide-react";
import Navbar from "../components/Navbar";
import { fetchShelterProfileById } from "../api/shelter";




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





function ShelterProfile() {
  const [currentPhotoIndex, setCurrentPhotoIndex] = useState(0);
  const [showDonatePopup, setShowDonatePopup] = useState(false);
  const [shelter, setShelter] = useState(null);
  const [shelterPhoto, setShelterPhoto] = useState(null);
const [loading, setLoading] = useState(true);
const [error, setError] = useState(null);
const { id } = useParams();

  

 useEffect(() => {
  const loadShelter = async () => {
    try {
      const data = await fetchShelterProfileById(id);
      setShelterPhoto(data.imageUrl || null);
      setShelter(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  loadShelter();
}, [id]);
 
  if (loading) return <p>Ładowanie...</p>;
if (error) return <p>Błąd: {error}</p>;
if (!shelter) return null;

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
          {shelterPhoto ? (
  <div className="photo-slider">
    
    <img
      src={shelterPhoto}
      alt={`Zdjęcie schroniska`}
      className="slider-image"
    />
    
  </div>
) : (
  <div className="photo-slider no-photos">
    <p>Brak zdjęć dla tego schroniska</p>
  </div>
)}    
        </section>

        </div>

        <section className="shelter-profile-info">

  {/* Nagłówek imię + lokalizacja */}
  <div className="shelter-header">
    <h2 className="shelter-name">{shelter.name}</h2>  
    <div className="shelter-location-info"> 
      <MapPin className="map-pin-shelter-profile" /> 
      <p className="shelter-location">{shelter.address}</p> 
    </div>
      <div className="shelter-location-info">
    <Phone className="map-pin-shelter-profile" />
    <p className="shelter-location">{shelter.phoneNumber}</p>
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




  
  

  

</section>

      </div>
    </div>
  );
}

export default ShelterProfile;