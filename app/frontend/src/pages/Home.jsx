import { useState, useRef, useEffect } from 'react';
import {
  Funnel, X, Heart, HandCoins, PawPrint,
  ArrowLeft, ShieldCheck, Venus, Mars, Ruler
} from 'lucide-react';
import Navbar from '../components/Navbar';
import './Home.css';
import Slider from 'rc-slider';
import 'rc-slider/assets/index.css';
import { useLocation, useNavigate } from "react-router-dom";
import { majorPolishCities } from '../assets/cities';
import dono5 from '../assets/pet_snack.png';
import dono10 from '../assets/pet_bowl.png';
import dono15 from '../assets/pet_toy.png';
import dono25 from '../assets/pet_food.png';
import dono50 from '../assets/pet_bed.png';

import { fetchFilteredAnimals, likePet } from '../api/shelter';

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

const Home = () => {
  const [currentAnimalIndex, setCurrentAnimalIndex] = useState(0);
  const [currentPhotoIndex, setCurrentPhotoIndex] = useState(0);
  const [showInfo, setShowInfo] = useState(false);
  const [fade, setFade] = useState(false);
  const [isDragging, setIsDragging] = useState(false);
  const [position, setPosition] = useState({ x: 0, y: 0 });
  const [startPos, setStartPos] = useState({ x: 0, y: 0 });
  const cardRef = useRef(null);
  const [filters, setFilters] = useState({
  ageRange: [0, 20],
  city: '',
  distance: 100,
  type: 'Wszystkie',
  vaccinated: false,
  urgent: false 
});
const [cursor, setCursor] = useState(1);
const [isLoadingMore, setIsLoadingMore] = useState(false);

  const [selectedCityCoords, setSelectedCityCoords] = useState(null);
  const [showFilters, setShowFilters] = useState(false);
  const [showDonatePopup, setShowDonatePopup] = useState(false);
  const [animals, setAnimals] = useState([]);
  const location = useLocation();
  const navigate = useNavigate();
  const [selectedAmount, setSelectedAmount] = useState(null);
const [customAmount, setCustomAmount] = useState('');

 useEffect(() => {
  const query = new URLSearchParams(location.search);
  const token = query.get("token");
  const userId = query.get("userId");

  if (token) {
    localStorage.setItem("jwt", token);
    localStorage.setItem("userId", userId);
    navigate("/home", { replace: true });
  }
}, [location, navigate]);

useEffect(() => {
  const timeout = setTimeout(() => {
    fetchAnimals();
  }, 400); 

  return () => clearTimeout(timeout);
}, [filters, selectedCityCoords]);
  const fetchAnimals = async (isNextPage = false) => {
  try {
    setIsLoadingMore(true);
    const nextCursor = isNextPage ? cursor + 1 : 1;
    const newAnimals = await fetchFilteredAnimals(filters, nextCursor);
    setAnimals((prev) => isNextPage ? [...prev, ...newAnimals] : newAnimals);
    if (!isNextPage) {
      setCurrentAnimalIndex(0); 
      setCursor(1);
    } else {
      setCursor(nextCursor);
    }
  } catch (err) {
    console.error("Błąd API:", err);
  } finally {
    setIsLoadingMore(false);
  }
};


  const currentAnimal = animals[currentAnimalIndex];

  const handleNextPhoto = () => {
    if (currentPhotoIndex < currentAnimal.photos.length - 1) {
      setCurrentPhotoIndex(currentPhotoIndex + 1);
    } else if (!showInfo) {
      setShowInfo(true);
    }
  };

  const resetCard = () => {
    setCurrentPhotoIndex(0);
    setShowInfo(false);
    setPosition({ x: 0, y: 0 });
  };

const handleSwipe = async (direction) => {
  setFade(true);

  const current = animals[currentAnimalIndex];

  if (direction === 'right' && current) {
    try {
      await likePet(current.id);
    } catch (err) {
      console.error('Błąd podczas lajka:', err);
    }
  }

  const nextIndex = currentAnimalIndex + 1;

  if (nextIndex >= animals.length - 1 && !isLoadingMore) {
    await fetchAnimals(true);
  }

  setTimeout(() => {
    setCurrentAnimalIndex((prev) => prev + 1);
    resetCard();
    setFade(false);
  }, 300);
};

  const handleMouseDown = (e) => {
    if (e.button !== 0) return;
    setIsDragging(true);
    setStartPos({ x: e.clientX, y: e.clientY });
    e.preventDefault();
  };

  const handleMouseMove = (e) => {
    if (!isDragging) return;
    const newX = e.clientX - startPos.x;
    const newY = (e.clientY - startPos.y) * 0.3;
    setPosition({ x: newX, y: newY });
  };

  const handleMouseUp = () => {
    if (!isDragging) return;
    setIsDragging(false);
    if (position.x > 100) handleSwipe('right');
    else if (position.x < -100) handleSwipe('left');
    else setPosition({ x: 0, y: 0 });
  };

  const handleTouchStart = (e) => {
    const touch = e.touches[0];
    setIsDragging(true);
    setStartPos({
      x: touch.clientX - position.x,
      y: touch.clientY - position.y
    });
  };

  const handleTouchMove = (e) => {
    if (!isDragging) return;
    const touch = e.touches[0];
    setPosition({
      x: touch.clientX - startPos.x,
      y: touch.clientY - startPos.y
    });
  };

  useEffect(() => {
    if (isDragging) {
      document.addEventListener('mousemove', handleMouseMove);
      document.addEventListener('mouseup', handleMouseUp);
      return () => {
        document.removeEventListener('mousemove', handleMouseMove);
        document.removeEventListener('mouseup', handleMouseUp);
      };
    }
  }, [isDragging, position, startPos]);

const donationOptions = [
  { amount: 5, label: "Smakołyki", img: dono5, donationType: "MATERIAL", itemName: "Smakołyki" },
  { amount: 10, label: "Pełna miska", img: dono10, donationType: "MATERIAL", itemName: "Pełna miska" },
  { amount: 15, label: "Zabawka", img: dono15, donationType: "MATERIAL", itemName: "Zabawka" },
  { amount: 25, label: "Zapas karmy", img: dono25, donationType: "MATERIAL", itemName: "Zapas karmy" },
  { amount: 50, label: "Legowisko", img: dono50, donationType: "MATERIAL", itemName: "Legowisko" }
];

const handleDonate = async (provider) => {
  const jwt = localStorage.getItem("jwt");
  const amount = Number(selectedAmount || customAmount);

  const selectedOption = donationOptions.find(opt => opt.amount === selectedAmount);

  const donationIntentBody = {
    shelterId: currentAnimal?.shelterId,
    petId: currentAnimal.id,
    donationType: selectedOption ? selectedOption.donationType : "MONEY",
    message: "Wsparcie przez stronę",
    anonymous: false,
    itemName: selectedOption ? selectedOption.itemName : "Wpłata pieniężna",
    unitPrice: amount,
    quantity: 1
  };

  try {
    const intentRes = await fetch("http://localhost:8020/donations/intent", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${jwt}`
      },
      body: JSON.stringify(donationIntentBody)
    });

    const intentData = await intentRes.json();
    const donationId = intentData.donationId;
    const sessionToken = intentData.sessionToken;

    // 🔁 Initialize payment
    const paymentRes = await fetch(`http://localhost:8020/donations/${donationId}/payment/initialize`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${jwt}`,
        "Session-Token": sessionToken
      },
      body: JSON.stringify({ provider }) 
    });

    const paymentData = await paymentRes.json();
const redirectUrl = paymentData?.redirectUrl || paymentData?.payment?.checkoutUrl;

if (redirectUrl) {
  window.open(redirectUrl, "_blank"); // otwórz w nowej karcie
} else {
  alert("Nie udało się pobrać linku do płatności.");
}

  } catch (err) {
    console.error("Błąd płatności:", err);
    alert("Nie udało się zainicjować płatności");
  }
};

  


  return (
    <div className="body">
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

      <Navbar />

      
            {showDonatePopup && (
        <div className="donation-popup-overlay" onClick={() => setShowDonatePopup(false)}>
          <div className="donation-popup" onClick={(e) => e.stopPropagation()}>
            <h2>Wesprzyj {currentAnimal.name}</h2>
            <div className="donation-options">
              {[
                { amount: 5, label: "Smakołyki", img: dono5 },
                { amount: 10, label: "Pełna miska", img: dono10 },
                { amount: 15, label: "Zabawka", img: dono15 },
                { amount: 25, label: "Zapas karmy", img: dono25 },
                { amount: 50, label: "Legowisko", img: dono50 }
              ].map(({ amount, label, img }) => (
                <button 
                  key={amount} 
                  className={`donate-option ${selectedAmount === amount ? 'selected' : ''}`}
                  onClick={() => {
                    setSelectedAmount(amount);
                    setCustomAmount(''); // Wyczyść custom amount gdy wybierasz predefiniowaną kwotę
                  }}
                >
                  <img src={img} alt={label} className="donate-img" />
                  <span className="donate-amount">{amount} zł</span>
                  <span className="donate-label">{label}</span>
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
                setSelectedAmount(null); // Wyczyść wybór predefiniowanej kwoty
              }}
            />
            
           <button
  className="confirm-donate-btn"
  disabled={!selectedAmount && !customAmount}
  onClick={() => handleDonate("PAYU", currentAnimal, selectedAmount, customAmount, setShowDonatePopup)}
>
  PayU ({selectedAmount || customAmount} zł)
</button>


            <button className="close-popup-btn" onClick={() => setShowDonatePopup(false)}>×</button>
          </div>
        </div>
      )}

    {!showFilters && (
  <div
    className="filters-tab"
    onClick={(e) => {
      e.stopPropagation();
      requestAnimationFrame(() => setShowFilters(true));
    }}
  >
    <Funnel size={30} className="tab-icon" />
  </div>
)}



{showFilters && (
  <div className={`filters-panel ${showFilters ? 'open' : ''}`}>
    <div className="filters-tab-inside" onClick={() => setShowFilters(false)}>
      <ArrowLeft size={40} className="tab-icon" />
    </div>
    
    <div className="filters-header">
      <h2>Filtry</h2>
    </div>
    
    <div className="filters">
      <div className="filter-group">
  <div className="slider-label">
    <h3>Wiek</h3>
    <span>{filters.ageRange[0]} - {filters.ageRange[1]} lat</span>
  </div>
  <div className="range-wrapper">
    <Slider
      range
      min={0}
      max={20}
      value={filters.ageRange}
      onChange={(newRange) => setFilters({ ...filters, ageRange: newRange })}
    />
  </div>
</div>

      <div className="filter-group">
  <div className="slider-label">
    <h3>Zaszczepione</h3>
  </div>
  <label className="checkbox-label">
    <input
      type="checkbox"
      checked={filters.vaccinated}
      onChange={(e) => setFilters({ ...filters, vaccinated: e.target.checked })}
    />
    <span>Tylko zaszczepione zwierzęta</span>
  </label>
</div>


      <div className="filter-group">
  <div className="slider-label">
    <h3>Pilne</h3>
  </div>
  <label className="checkbox-label">
    <input
      type="checkbox"
      checked={filters.urgent}
      onChange={(e) => setFilters({ ...filters, urgent: e.target.checked })}
    />
    <span>Tylko Pilne przypadki</span>
  </label>
</div>

      <div className="filter-group">
        <div className="slider-label">
          <h3>Typ zwierzęcia</h3>
        </div>
        <div className="type-pills">
          {['Pies', 'Kot', 'Inny', 'Wszystkie'].map((type) => (
            <button
              key={type}
              className={`pill ${filters.type === type ? 'active' : ''}`}
              onClick={() => setFilters({ ...filters, type })}
            >
              {type}
            </button>
          ))}
        </div>
      </div>

      

      <div className="filter-group">
        <div className="slider-label">
          <h3>Lokalizacja</h3>
          <span>{filters.distance} km</span>
        </div>
        <Slider
  min={1}
  max={100}
  value={Number(filters.distance)}
  onChange={(value) => setFilters({ ...filters, distance: value })}
  trackStyle={{ backgroundColor: '#ffa600', height: 6 }}
  handleStyle={{
    borderColor: '#ffa600',
    height: 18,
    width: 18,
    marginTop: -6,
    backgroundColor: '#fff',
  }}
  railStyle={{ backgroundColor: '#ccc', height: 6 }}
/>
        
        <div className="city-input-container">
          <select
  value={filters.city}
  onChange={(e) => {
    const selected = majorPolishCities.find(c => c.name === e.target.value);
    if (selected) {
      setFilters({ ...filters, city: selected.name });
      setSelectedCityCoords({ lat: selected.lat, lon: selected.lon });
    }
  }}
>
  <option value="">Wybierz miasto</option>
  {majorPolishCities.map((city) => (
    <option key={city.name} value={city.name}>
      {city.name}
    </option>
  ))}
</select>
        </div>
      </div>
    </div>
  </div>
)}
     

 
<div className="swipe-btn-container">
        <div className="swipe-container">
        <div className="card-container">
          {currentAnimal ? (
            <div 
              className={`animal-card ${fade ? 'fade-out' : 'fade-in'}`}
              ref={cardRef}
              onMouseDown={handleMouseDown}
              onClick={!isDragging ? handleNextPhoto : undefined}
              onTouchStart={handleTouchStart}
              onTouchMove={handleTouchMove}
              onTouchEnd={handleMouseUp}
              style={{
                transform: `translate(${position.x}px, ${position.y}px) rotate(${position.x / 20}deg)`,
                transition: isDragging ? 'none' : 'transform 0.3s ease'
              }}
            >
              {!(showInfo && currentPhotoIndex === currentAnimal.photos.length - 1) ? (

                <>
                  <img 
  src={currentAnimal.photos[currentPhotoIndex]} 
  alt={currentAnimal.name} 
  className="animal-image"
/>
                  <div className="photo-indicator">
                    {currentAnimal.photos?.map((_, index) => (
                      <span 
                        key={index} 
                        className={`dot ${index === currentPhotoIndex ? 'active' : ''}`}
                      />
                    ))}
                  </div>
                  <div className="basic-info">
                    <h2>{currentAnimal.name}, {currentAnimal.age}</h2>
                    <p>{currentAnimal.shelterName}&nbsp;{currentAnimal.shelterAddress}</p>
                  </div>
                  <div className="animal-tags">

 <div className="tag">
  <PawPrint size={30} />
  <span>
    {{
      DOG: 'Pies',
      CAT: 'Kot',
      OTHER: 'Inne'
    }[currentAnimal.type] || 'Nieznany'}
  </span>
</div>

<div className="tag">
  {currentAnimal.gender === 'Male' ? <Mars size={30} /> : <Venus size={30} />}
  <span>{currentAnimal.gender === 'Male' ? 'Samiec' : 'Samica'}</span>
</div>

{currentAnimal.vaccinated && (
  <div className="tag">
    <span>Zaszczepiony</span>
  </div>
)}
</div>
                </>
              ) : (
                <>
                <div
  className="animal-info-full"
  onClick={() => resetCard()}
>
                <div
      className="animal-info-blurred"
      style={{ backgroundImage: `url(${currentAnimal.photos[currentPhotoIndex]})` }}
    />
    <div className="animal-info-blurred-content">
      <h2>{currentAnimal.name}, {currentAnimal.age}</h2>
      <p><strong>Rasa:</strong> {currentAnimal.breed}</p>
      <p><strong>Zaszczepiony:</strong> {currentAnimal.vaccinated ? 'Tak' : 'Nie'}</p>
<p><strong>Przyjazny dzieciom:</strong> {currentAnimal.childFriendly ? 'Tak' : 'Nie'}</p>
<p><strong>Wykastrowany:</strong> {currentAnimal.neutered ? 'Tak' : 'Nie'}</p>
      <p><strong>Schronisko:</strong> {currentAnimal.shelterName}&nbsp; {currentAnimal.shelterAddress}</p>
      <p><strong>Opis:</strong> {currentAnimal.description}</p>
    </div>
    </div>
    </>
              )}
            </div>
          ) : (
            <div className="no-animals">
              <h2>Brak zwierząt spełniających podane filtry</h2>
              <p>Wróć za chwile może dodamy nowe zwierzaki!</p>
            </div>
          )}
        </div>

       {animals.length > 0 && (
  <div className="action-buttons">
    <button className="dislike-btn" onClick={() => handleSwipe('left')}>
      <X size={50} color="#fff" />
    </button>
    <button className="donate-btn" onClick={() => setShowDonatePopup(true)}>
      <HandCoins size={50} color="#fff" />
    </button>
    <button className="like-btn" onClick={() => handleSwipe('right')}>
      <Heart size={50} color="#fff" />
    </button>
  </div>
)}

</div>

      </div>
    </div>
  );
};

export default Home;