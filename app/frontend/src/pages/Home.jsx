import { useState, useRef, useEffect } from 'react';
import { Funnel, X, Heart, HandCoins, PawPrint, ArrowLeft, ArrowRight, ShieldCheck, Venus, Mars, Ruler } from 'lucide-react'
import Navbar from '../components/Navbar';
import './Home.css';

import cat_1 from '../assets/cat_1.jpg';
import cat_2 from '../assets/cat_2.jpg';
import dog1_1 from '../assets/dog1_1.jpg';
import dog1_2 from '../assets/dog1_2.jpg';
import dog2_1 from '../assets/dog2_1.jpg';
import dog2_2 from '../assets/dog2_2.jpg';
import dog2_3 from '../assets/dog2_3.jpg';
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

const animals = [
  {
    id: 1,
    name: 'Burek',
    age: 2,
    breed: 'Golden Retriever',
    gender: 'Male',
    size: 'Large',
    vaccinated: true,
    location: 'Schronisko "Cztery Łapy"',
    coordinates: { lat: 47.6062, lon: -122.3321 },
  description: 'Buddy to prawdziwy promień słońca – energiczny, łagodny i bardzo przyjazny. Uwielbia spacery, zabawę na świeżym powietrzu i towarzystwo ludzi. Jest łasy na pieszczoty i bardzo szybko się przywiązuje. Świetnie dogaduje się z innymi psami, a jego złote futerko i wiecznie merdający ogon skradną Twoje serce od pierwszego spojrzenia. Buddy szuka odpowiedzialnego domu, gdzie będzie pełnoprawnym członkiem rodziny. Idealnie sprawdzi się w domu z ogrodem, ale odnajdzie się też w mieszkaniu, jeśli zapewnisz mu odpowiednią dawkę ruchu i miłości.',
    photos: [dog1_1, dog1_2],
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
  },
  {
    id: 2,
    name: 'Mila',
    age: 3,
    breed: 'Krótkowłosy',
    gender: 'Male',
    size: 'Large',
    vaccinated: true,
    location: 'Azyl dla Zwierząt "Przystań"',
    coordinates: { lat: 41.8781, lon: -87.6298 },
  description: 'Buddy to prawdziwy promień słońca – energiczny, łagodny i bardzo przyjazny. Uwielbia spacery, zabawę na świeżym powietrzu i towarzystwo ludzi. Jest łasy na pieszczoty i bardzo szybko się przywiązuje. Świetnie dogaduje się z innymi psami, a jego złote futerko i wiecznie merdający ogon skradną Twoje serce od pierwszego spojrzenia. Buddy szuka odpowiedzialnego domu, gdzie będzie pełnoprawnym członkiem rodziny. Idealnie sprawdzi się w domu z ogrodem, ale odnajdzie się też w mieszkaniu, jeśli zapewnisz mu odpowiednią dawkę ruchu i miłości.',
    photos: [cat_1, cat_2],
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
  },
  {
    id: 3,
    name: 'Luna',
    age: 1,
    breed: 'Husky',
    gender: 'Samica',
    size: 'Medium',
    vaccinated: false,
    location: 'Schronisko "Psia Ostoja"',
    coordinates: { lat: 40.7128, lon: -74.0060 },
  description: 'Buddy to prawdziwy promień słońca – energiczny, łagodny i bardzo przyjazny. Uwielbia spacery, zabawę na świeżym powietrzu i towarzystwo ludzi. Jest łasy na pieszczoty i bardzo szybko się przywiązuje. Świetnie dogaduje się z innymi psami, a jego złote futerko i wiecznie merdający ogon skradną Twoje serce od pierwszego spojrzenia. Buddy szuka odpowiedzialnego domu, gdzie będzie pełnoprawnym członkiem rodziny. Idealnie sprawdzi się w domu z ogrodem, ale odnajdzie się też w mieszkaniu, jeśli zapewnisz mu odpowiednią dawkę ruchu i miłości.',
    photos: [dog2_1, dog2_2, dog2_3],
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
  }
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
    maxAge: '',
    gender: '',
    size: '',
    city: '',
    distance: ''
  });
  const [cityInput, setCityInput] = useState('');
  const [suggestions, setSuggestions] = useState([]);
  const [selectedCityCoords, setSelectedCityCoords] = useState(null);
  const [showFilters, setShowFilters] = useState(false);
  const [showDonatePopup, setShowDonatePopup] = useState(false);



  
  

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

  const handleSwipe = (direction) => {
    setFade(true);
    setTimeout(() => {
      const nextIndex = currentAnimalIndex < animals.length - 1 ? currentAnimalIndex + 1 : 0;
      setCurrentAnimalIndex(nextIndex);
      resetCard();
      setFade(false);
    }, 300);
  };

  // Mouse drag handlers
  const handleMouseDown = (e) => {
    if (e.button !== 0) return; // Tylko lewy przycisk myszy
    setIsDragging(true);
    setStartPos({
      x: e.clientX,
      y: e.clientY
    });
    e.preventDefault(); // Zapobiega domyślnym zdarzeniom
  };

  const handleMouseMove = (e) => {
    if (!isDragging) return;
    const newX = e.clientX - startPos.x;
    const newY = (e.clientY - startPos.y) * 0.3; // Mniejszy ruch w pionie
    
    setPosition({
      x: newX,
      y: newY
    });
  };

  const handleMouseUp = () => {
    if (!isDragging) return;
    setIsDragging(false);
    
    // Determine swipe direction based on final position
    if (position.x > 100) {
      handleSwipe('right');
    } else if (position.x < -100) {
      handleSwipe('left');
    } else {
      // Return to center if not swiped far enough
      setPosition({ x: 0, y: 0 });
    }
  };

  // Touch handlers
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

  useEffect(() => {
    const delayDebounce = setTimeout(() => {
      if (cityInput.length < 2) return;
  
      fetch(`https://nominatim.openstreetmap.org/search?city=${cityInput}&country=Poland&format=json`)
        .then((res) => res.json())
        .then((data) => {
          setSuggestions(data);
        });
    }, 500); // debounce
  
    return () => clearTimeout(delayDebounce);
  }, [cityInput]);
 
  
  return (
    <div className ="body">

      
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
{!showFilters && (
  <div className="filters-tab" onClick={() => setShowFilters(true)}>
    <Funnel size={30} className="tab-icon" />
  </div>
)}


{showDonatePopup && (
  <div className="donation-popup-overlay" onClick={() => setShowDonatePopup(false)}>
    <div className="donation-popup" onClick={(e) => e.stopPropagation()}>
      <h2>Wesprzyj {currentAnimal.name}</h2>
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



  <div className={`filters-panel ${showFilters ? 'open' : ''}`}>
    <div className="filters-tab-inside" onClick={() => setShowFilters(false)}>
      <ArrowLeft size={20} className="tab-icon" />
    </div>
    {/* ... cała reszta formularza filtrów ... */}
    <div className="filters-header">
      </div>
    <div className="filters">
    <div className="filters">
  {/* Maksymalny wiek */}
  <div className="slider-label">
    <h2>Maksymalny wiek</h2>
  </div>
  <label className="slider-label">
  Maksymalny wiek: {filters.maxAge} lat
</label>
<input
  type="range"
  min={0}
  max={20}
  value={filters.maxAge}
  onChange={(e) => setFilters({ ...filters, maxAge: e.target.value })}
  className="styled-slider"
/>

  {/* Rozmiar */}
  <div className="slider-label">
    <h2>Rozmiar</h2>
  </div>
 <div className="size-pills">
  {[
    { label: 'Mały', value: 'Small' },
    { label: 'Średni', value: 'Medium' },
    { label: 'Duży', value: 'Large' },
  ].map(({ label, value }) => (
    <button
      key={value}
      className={`pill ${filters.size === value ? 'active' : ''}`}
      onClick={() => setFilters({ ...filters, size: value })}
    >
      {label}
    </button>
  ))}
</div>

<div className="slider-label">
    <h2>Typ zwierzęcia</h2>
  </div>
   <div className="type-pills">
    {['Pies', 'Kot', 'Inny'].map((type) => (
      <button
        key={type}
        className={`pill ${filters.type === type ? 'active' : ''}`}
        onClick={() => setFilters({ ...filters, type })}
      >
        {type}
      </button>
    ))}
  </div>

  {/* Płeć */}
  <div className="slider-label">
    <h2>Płeć</h2>
  </div>
  <div className="gender-pills">
  {[
    { value: "Male", label:"Samiec" },
    { value: "Female", label:"Samica" },
  ].map((gender) => (
    <button
      key={gender.value}
      className={`pill ${filters.gender === gender.value ? "active" : ""}`}
      onClick={() => setFilters({ ...filters, gender: gender.value })}
    >
      {gender.label}
    </button>
  ))}
</div>

 

  {/* Odległość */}
  <div className="slider-label">
    <h2>Lokalizacja</h2>
  </div>
  <label className="slider-label">
    <p>Odległość: {filters.distance} km</p>
    <input
    className="styled-slider"
      type="range"
      min="1"
      max="100"
      value={filters.distance}
      onChange={(e) => setFilters({ ...filters, distance: e.target.value })}
    />
  </label>

   {/* Miasto */}
   
  <input
  type="text"
  placeholder="Wpisz miasto"
  value={cityInput}
  onChange={(e) => {
    setCityInput(e.target.value);
    setFilters({ ...filters, city: e.target.value });
  }}
/>

{suggestions.length > 0 && (
  <ul className="suggestions">
    {suggestions.map((item, index) => (
      <li
        key={index}
        onClick={() => {
          setCityInput(item.display_name);
          setFilters({ ...filters, city: item.display_name });
          setSelectedCityCoords({ lat: parseFloat(item.lat), lon: parseFloat(item.lon) });
          setSuggestions([]);
        }}
      >
        {item.display_name}
      </li>
    ))}
  </ul>
)}
</div>
    </div>
  </div>


     

 
<div className="swipe-btn-container">
        <div className="swipe-container">
        <div className="card-container">
          {animals.length > 0 ? (
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
                    {currentAnimal.photos.map((_, index) => (
                      <span 
                        key={index} 
                        className={`dot ${index === currentPhotoIndex ? 'active' : ''}`}
                      />
                    ))}
                  </div>
                  <div className="basic-info">
                    <h2>{currentAnimal.name}, {currentAnimal.age}</h2>
                    <p>{currentAnimal.location}</p>
                  </div>
                  <div className="animal-tags">
  <div className="tag">
    {currentAnimal.gender === 'Male' ? <Mars size={30} /> : <Venus size={30} />}
    <span>{currentAnimal.gender === 'Male' ? 'Samiec' : 'Samica'}</span>
  </div>
  <div className="tag">
    <Ruler size={30} />
    <span>
      {{
        Small: 'Mały',
        Medium: 'Średni',
        Large: 'Duży'
      }[currentAnimal.size]}
    </span>
  </div>
  <div className={`tag ${!currentAnimal.vaccinated ? 'invisible' : ''}`}>
    {currentAnimal.vaccinated && (
      <>
        <ShieldCheck size={30} />
        <span>Zaszczepiony</span>
      </>
    )}
  </div>
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
      <p><strong>Schronisko:</strong> {currentAnimal.location}</p>
      <p><strong>Opis:</strong> {currentAnimal.description}</p>
      <p><strong>Charakter:</strong> {currentAnimal.characteristics.join(", ")}</p>
    </div>
    </div>
    </>
              )}
            </div>
          ) : (
            <div className="no-animals">
              <h2>No more animals to show</h2>
              <p>Check back later for new arrivals!</p>
            </div>
          )}
        </div>

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

</div>

      </div>
    </div>
  );
};

export default Home;