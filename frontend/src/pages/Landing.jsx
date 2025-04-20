import { useEffect, useState, useRef } from 'react';
import './Landing.css';
import logo from '../assets/logo-placeholder.png';
import heroBg from '../assets/dogs.jpg'; 
import walk from '../assets/walk.gif';
import profile from '../assets/profile.gif';
import adoption from '../assets/adoption.gif';
import dogFood from '../assets/dog_food.gif';

export default function Landing() {
  const [loaded, setLoaded] = useState(false);
  const [showHeader, setShowHeader] = useState(false);
  const [showHeroContent, setShowHeroContent] = useState(false);
  const [showArrow, setShowArrow] = useState(false);
  const containerRef = useRef(null);
  const trackRef = useRef(null);
  const [scrollValue, setScrollValue] = useState(0);

  useEffect(() => {
    setTimeout(() => setLoaded(true), 500);
    setTimeout(() => setShowHeader(true), 1200);       // header po 300ms
  setTimeout(() => setShowHeroContent(true), 2000);
  setTimeout(() => setShowArrow(true), 4000);
  const onScroll = () => {
    if (!containerRef.current || !trackRef.current) return;

    const container = containerRef.current;
    const track = trackRef.current;

    const containerRect = container.getBoundingClientRect();
    const scrollLength = container.offsetHeight - window.innerHeight;
    const progress = Math.min(Math.max(-containerRect.top / scrollLength, 0), 1);

    const maxTranslate = track.scrollWidth - window.innerWidth;
    const translateX = -progress * maxTranslate;

    track.style.transform = `translateX(${translateX}px)`;
  };

  window.addEventListener('scroll', onScroll);
  return () => window.removeEventListener('scroll', onScroll);

  }, []);

  return (
    <div className={`landing-page ${loaded ? 'fade-in' : ''}`}>
      {/* Hero Section */}
      <section
        className="hero-section"
        style={{ backgroundImage: `url(${heroBg})` }}
      >
        <div className="overlay">
          <header className={`landing-header animated ${showHeader ? 'bounce-in' : ''}`}>
          <div className="branding">
          <img src={logo} alt="Psinder Logo" className="landing-logo" />
          <span className="logo-text">Petify</span>
        </div>
        <nav className="landing-nav">
  <a href="/register" className="btn btn--primary">Zarejestruj się</a>
  <a href="/login" className="btn btn--secondary">Zaloguj się</a>
</nav>
          </header>

          <div className={`hero-content animated ${showHeroContent ? 'bounce-in' : ''}`}>
            <h1><span>DOM ZACZYNA SIĘ OD</span> <strong>CIEBIE!</strong></h1>
            <p>Petify pomagama łączyć tych, którzy potrzebują domu, z tymi, którzy mogą go dać. Bo każde zwierzę zasługuje na miłość, bezpieczeństwo i kogoś, kto nigdy go nie zawiedzie.</p>
            <a href="#about" className="cta-button">Dowiedz się więcej</a>
          </div>
        </div>
        <a href="#gallery" className={`scroll-circle animated ${showArrow ? 'bounce-in' : ''}`}>
  ↓
</a>
      </section>

      <section id="gallery" className="scroll-gallery-outer" ref={containerRef}>
  <div className="scroll-gallery-inner">
    <div className="scroll-gallery-track" ref={trackRef}>
    <img src="/src/assets/landing_image_1.jpg" alt="Dog 1" />
    <img src="/src/assets/landing_image_2.jpg" alt="Dog 2" />
    <img src="/src/assets/landing_image_3.jpg" alt="Dog 3" />
    <img src="/src/assets/landing_image_4.jpg" alt="Dog 4" />
    <img src="/src/assets/landing_image_5.jpg" alt="Dog 5" />
    <img src="/src/assets/landing_image_6.jpg" alt="Dog 6" />
    <img src="/src/assets/landing_image_7.jpg" alt="Dog 7" />
    <div className="scroll-end-spacer" />
    </div>
  </div>
</section>

<section id="about"className="about-section">
  <div className="about-content">
    <div className="about-tekst">
    <h2>Czym jest Petify?</h2>
    <p>
    Petify to aplikacja, która promuje adopcję zwierząt ze schronisk – w nowoczesny, prosty i ludzki sposób.
Pozwala odkrywać profile psiaków i kotów czekających na dom, umawiać się na spacery adopcyjne za pomocą formularza, wypełniać dokumenty online, a także wspierać schroniska poprzez zdalne dokarmianie czy przekazywanie darowizn.

Dla zarządców schronisk to praktyczne narzędzie do zarządzania zgłoszeniami, adopcjami i kalendarzem wizyt.
Dla przyszłych opiekunów – to pierwszy krok do znalezienia lojalnego przyjaciela na cztery łapy.
    </p>
    </div>
  </div>
</section>


<section className="features-petify">
  <h2>Główne funkcjonalności</h2>
  <div className="features-grid">
    <div className="feature-card">
      <img src={profile} alt="" />
      <h3>Profil zwierzaka</h3>
      <p>Przeglądaj zdjęcia i opisy zwierząt. Swajpuj w lewo lub prawo – wszystko masz na wyciągnięcie palca.</p>
    </div>
    <div className="feature-card">
      <img src={walk} alt="" />
      <h3>Spacer z pupilem</h3>
      <p>Umów się na spacer z pupilem bezpośrednio przez aplikację – szybko i wygodnie dzięki wbudowanemu kalendarzowi.</p>
    </div>
    <div className="feature-card">
      <img src={adoption} alt="" />
      <h3>Adoptuj</h3>
      <p>Adoptuj zwierzaka – wypełnij dokumenty i umów się na wizytę bezpośrednio w aplikacji.</p>
    </div>
    <div className="feature-card">
      <img src={dogFood} alt="" />
      <h3>Dokarmiaj</h3>
      <p>Dokarmiaj zwierzaki, przekazując darowiznę przez aplikację.</p>
    </div>
  </div>
</section>

{/* Sekcja kontaktowa */}
<section className="contact-section-clean">
  <div className="contact-container">
    <h2>Kontakt</h2>
    <ul className="contact-links">
      <li><a >Email</a></li>
      <li><a >Facebook</a></li>
      <li><a >LinkedIn</a></li>
    </ul>
  </div>
</section>

{/* Sekcja footerowa */}
<footer className="footer-modern">
  <div className="footer-container">
    <img src={logo} className="footer-logo" alt="logo" />
    <p className="footer-tagline">Aplikacja wspierająca adopcję zwierząt.</p>
    <p className="footer-copy">© 2025 Petify. Wszystkie prawa zastrzeżone.</p>
  </div>
</footer>
</div>
  );
}