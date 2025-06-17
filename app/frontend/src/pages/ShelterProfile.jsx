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
  Phone,
  Calendar,
  Clock,
  Users,
  Image as ImageIcon
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

// Mock data for posts and events - replace with actual API calls
const mockPosts = [
  {
    "id": 1,
    "shelterId": 1,
    "title": "Unique Post",
    "shortDescription": "Description",
    "mainImageId": 4,
    "longDescription": "",
    "fundraisingId": null,
    "imageIds": [1, 2, 3],
    "createdAt": "2025-06-16T22:56:23.28235",
    "updatedAt": "2025-06-16T22:56:23.28235"
  },
  {
    "id": 4,
    "shelterId": 1,
    "title": "Unique Post 123 123",
    "shortDescription": "Description coool",
    "mainImageId": 4,
    "longDescription": "",
    "fundraisingId": null,
    "imageIds": [1, 2, 3],
    "createdAt": "2025-06-16T22:58:21.778022",
    "updatedAt": "2025-06-16T22:58:21.77902"
  }
];

const mockEvents = [
  {
    "id": 2,
    "shelterId": 1,
    "title": "Unique Event",
    "shortDescription": "A short description of the event",
    "startDate": "2025-06-30T10:00:00",
    "endDate": "2025-06-30T18:00:00",
    "address": "123 Main Street, City, Country",
    "mainImageId": 1,
    "longDescription": "A detailed description of the event",
    "fundraisingId": 1,
    "latitude": 51.7592,
    "longitude": 19.456,
    "capacity": 0,
    "createdAt": "2025-06-16T22:56:51.98893",
    "updatedAt": "2025-06-16T22:56:51.98893"
  },
  {
    "id": 3,
    "shelterId": 1,
    "title": "Unique Event lalala",
    "shortDescription": "A short description of the event COOL",
    "startDate": "2025-06-30T10:00:00",
    "endDate": "2025-06-30T18:00:00",
    "address": "123 Main Street, City, Poland",
    "mainImageId": 1,
    "longDescription": "A detailed description of the event Super ivent polecam",
    "fundraisingId": 1,
    "latitude": 51.7592,
    "longitude": 19.456,
    "capacity": 0,
    "createdAt": "2025-06-16T22:57:55.204725",
    "updatedAt": "2025-06-16T22:57:55.204725"
  }
];

function ShelterProfile() {
  const [currentPhotoIndex, setCurrentPhotoIndex] = useState(0);
  const [showDonatePopup, setShowDonatePopup] = useState(false);
  const [shelter, setShelter] = useState(null);
  const [shelterPhoto, setShelterPhoto] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [posts, setPosts] = useState(mockPosts);
  const [events, setEvents] = useState(mockEvents);
  const { id } = useParams();

  useEffect(() => {
    const loadShelter = async () => {
      try {
        const data = await fetchShelterProfileById(id);
        setShelterPhoto(data.imageUrl || null);
        setShelter(data);
        // Here you would also fetch posts and events for this shelter
        // setPosts(await fetchShelterPosts(id));
        // setEvents(await fetchShelterEvents(id));
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    loadShelter();
  }, [id]);

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('pl-PL', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  const formatTime = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString('pl-PL', {
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const handleEventSignup = (eventId) => {
    // Handle event signup logic here
    alert(`Zapisano na wydarzenie o ID: ${eventId}`);
  };

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
              ].map(({ amount, img }) => (
                <button key={amount} className="donate-option">
                  <img src={img} alt={`${amount} zł`} className="donate-img" />
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


          {/* Opis */}
          <section className="pet-description">
            <h3>Opis</h3>
            <p>{shelter.description}</p>
          </section>



          {/* Wydarzenia schroniska */}
          <section className="shelter-events">
            <h3 className="section-title">Wydarzenia schroniska</h3>
            <div className="events-list">
              {events.map((event) => (
                <div key={event.id} className="event-card">
                  <div className="event-image-container">
                    {event.mainImageId ? (
                      <img 
                        src={`/api/images/${event.mainImageId}`} 
                        alt={event.title}
                        className="event-image"
                        onError={(e) => {
                          e.target.style.display = 'none';
                          e.target.nextSibling.style.display = 'flex';
                        }}
                      />
                    ) : null}
                    <div className="event-image-placeholder" style={{ display: event.mainImageId ? 'none' : 'flex' }}>
                      <Calendar className="placeholder-icon" />
                    </div>
                  </div>
                  <div className="event-content">
                    <h4 className="event-title">{event.title}</h4>
                    <p className="event-description">{event.shortDescription}</p>
                    <div className="event-details">
                      <div className="event-detail">
                        <Calendar className="event-icon" />
                        <span>{formatDate(event.startDate)}</span>
                      </div>
                      <div className="event-detail">
                        <Clock className="event-icon" />
                        <span>{formatTime(event.startDate)} - {formatTime(event.endDate)}</span>
                      </div>
                      <div className="event-detail">
                        <MapPin className="event-icon" />
                        <span>{event.address}</span>
                      </div>
                      {event.capacity > 0 && (
                        <div className="event-detail">
                          <Users className="event-icon" />
                          <span>Miejsca: {event.capacity}</span>
                        </div>
                      )}
                    </div>
                    <button 
                      className="event-signup-button"
                      onClick={() => handleEventSignup(event.id)}
                    >
                      Zapisz się
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </section>


          {/* Posty schroniska */}
          <section className="shelter-posts">
            <h3 className="section-title">Posty schroniska</h3>
            <div className="posts-list">
              {posts.map((post) => (
                <div key={post.id} className="post-card">
                  <div className="post-image-container">
                    {post.mainImageId ? (
                      <img 
                        src={`/api/images/${post.mainImageId}`} 
                        alt={post.title}
                        className="post-image"
                        onError={(e) => {
                          e.target.style.display = 'none';
                          e.target.nextSibling.style.display = 'flex';
                        }}
                      />
                    ) : null}
                    <div className="post-image-placeholder" style={{ display: post.mainImageId ? 'none' : 'flex' }}>
                      <ImageIcon className="placeholder-icon" />
                    </div>
                  </div>
                  <div className="post-content">
                    <h4 className="post-title">{post.title}</h4>
                    <p className="post-description">{post.shortDescription}</p>
                    <div className="post-meta">
                      <span className="post-date">{formatDate(post.createdAt)}</span>
                      {post.imageIds && post.imageIds.length > 1 && (
                        <span className="post-images-count">
                          <ImageIcon className="meta-icon" />
                          {post.imageIds.length} zdjęć
                        </span>
                      )}
                    </div>
                    <button className="post-button">
                      Zobacz więcej
                    </button>
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