import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import userCircle from '../assets/default_avatar.jpg';
import logo from '../assets/logo.svg';
import { ArrowLeft, ArrowRight, Menu } from 'lucide-react';
import './Navbar.css';

export default function Navbar() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  const [showTabInside, setShowTabInside] = useState(false);

  useEffect(() => {
    if (isMenuOpen) {
      const timer = setTimeout(() => setShowTabInside(true), 300); // czas na animację menu
      return () => clearTimeout(timer);
    } else {
      setShowTabInside(false);
    }
  }, [isMenuOpen]);
  

  return (
    <nav className="navbar navbar-expand-lg navbar-light position-relative">
      <div className="container-fluid d-flex justify-content-between align-items-center">
        <Link className="navbar-brand mx-auto d-flex align-items-center gap-2 fw-bold" to="/home">
          
          Petify
        </Link>

        <div className="profile-icon d-flex align-items-center">
          <Link to="/profile">
            <img src={userCircle} width="50" height="50" style={{
        cursor: 'pointer',
        borderRadius: '50%',
        objectFit: 'cover',
        border: '3px solid #ffc107'
      }} alt="Profil" />
          </Link>
        </div>
      </div>

      {/* Zakładka przy zamkniętym menu */}
      {!isMenuOpen && (
        <div className="menu-tab" onClick={() => setIsMenuOpen(true)}>
          <Menu size={30} className="tab-icon" />
        </div>
      )}

{showTabInside && (
  <div className="menu-tab-inside visible" onClick={() => setIsMenuOpen(false)}>
    <ArrowLeft size={20} className="tab-icon" />
  </div>
)}
      {/* Panel menu z animacją */}
      <div className={`offcanvas-menu ${isMenuOpen ? 'open' : ''}`}>
        <div className="offcanvas-header ">
          <h5 className="offcanvas-title">Menu</h5>
        </div>
  <Link className="menu-button" to="/messages" onClick={() => setIsMenuOpen(false)}>
    Wiadomości
  </Link>
  <Link className="menu-button" to="/favourites" onClick={() => setIsMenuOpen(false)}>
    Polubione
  </Link>
  <Link className="menu-button" to="/shelters" onClick={() => setIsMenuOpen(false)}>
    Schroniska
  </Link>
</div>
    
    </nav>
  );
}
