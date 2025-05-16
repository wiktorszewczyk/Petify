import React from 'react';
import { useNavigate } from 'react-router-dom';
import Navbar from '../components/Navbar';
import './Favourites.css';
import {MapPin, Heart,PawPrint} from 'lucide-react';

// Import images
import cat_1 from '../assets/cat_1.jpg';

import dog1_1 from '../assets/dog1_1.jpg';

import dog2_1 from '../assets/dog2_1.jpg';

import dog3_1 from '../assets/dog1.jpg';

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


// Mock data
const favorites = [
  {
    id: 101,
    name: 'Mila',
    breed: 'Siberian Husky',
    image: cat_1,
    age: '2',
    location: 'Warszawa',
    shortDescription: 'Energiczna i przyjazna'
  },
  {
    id: 105,
    name: 'Luna',
    breed: 'Siberian Husky',
    image: dog2_1,
    age: '2',
    location: 'Warszawa',
    shortDescription: 'Energiczna i przyjazna'
  },
  {
    id: 102,
    name: 'Burek',
    breed: 'Labrador Retriever',
    image: dog1_1,
    age: '3',
    location: 'Kraków',
    shortDescription: 'Spokojny i łagodny'
  },
  {
    id: 103,
    name: 'Bella',
    breed: 'Golden Retriever',
    image: dog3_1,
    age: '1',
    location: 'Poznań',
    shortDescription: 'Pełna miłości i radości'
  }
];

const Favorites = () => {
  const navigate = useNavigate();

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
              '--rotation': step.rotate,
              animationDelay: `${i * 0.5}s`,
            }}
          >
            <PawPrint className="paw-icon" />
          </div>
        ))}
      </div>
      <div className="favorites-container">
        <div className="favorites-header">
          <h1>Twoje ulubione zwierzęta</h1>
          <p>Zwierzaki, które śledzisz i którym kibicujesz</p>
        </div>

        <div className="favorites-grid">
          {favorites.map((animal) => (
            <div
              key={animal.id}
              className="animal-card-favourites"
              onClick={() => navigate(`/petProfile/${animal.id}`)}
            >
              <div className="animal-card-image">
                <img src={animal.image} alt={animal.name} />
                <div className="animal-heart-icon">
                  <Heart className="heart-icon" />
                </div>
              </div>
              <div className="animal-card-content-favourites">
                <h3>{animal.name}, {animal.age}</h3>
                <div className="animal-details-favourites">
                 
                  <span className="animal-location">
                    <MapPin className="detail-icon" />
                    <span className="detail-icon"></span> {animal.location}
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default Favorites;