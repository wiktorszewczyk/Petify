import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import userCircle from '../assets/default_avatar.jpg';
import logo from '../assets/logo.svg';
import { Menu, LogOut, ArrowLeft } from 'lucide-react';
import './Navbar.css';

export default function Navbar() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const navigate = useNavigate();

  const handleLogout = () => {
    localStorage.removeItem('jwt');
    localStorage.removeItem('userId');
    setIsMenuOpen(false);
    navigate('/login');
  };

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

      {/* Panel menu z animacją */}
      <div className={`offcanvas-menu ${isMenuOpen ? 'open' : ''}`}>
        <div className="close-btn" onClick={() => setIsMenuOpen(false)}>
      <ArrowLeft size={30} className="tab-icon" />
    </div>
        <div className="offcanvas-header">
          <h5 className="offcanvas-title">Menu</h5>
        </div>
        
        <div className="menu-content">
          <Link className="menu-button" to="/messages" onClick={() => setIsMenuOpen(false)}>
            Wiadomości
          </Link>
          <Link className="menu-button" to="/favourites" onClick={() => setIsMenuOpen(false)}>
            Polubione
          </Link>
          <Link className="menu-button" to="/sheltersPage" onClick={() => setIsMenuOpen(false)}>
            Schroniska
          </Link>
          
          <div className="menu-divider"></div>
          
          <button className="menu-button logout-button" onClick={handleLogout}>
            <LogOut size={18} className="logout-icon" />
            Wyloguj
          </button>
        </div>
      </div>

      {/* Overlay dla mobilnych urządzeń */}
      {isMenuOpen && <div className="menu-overlay" onClick={() => setIsMenuOpen(false)}></div>}
      
      {/* Czerwony przycisk zamykania - tylko na mobile */}
      {/* {isMenuOpen && (
        <div className="mobile-close-btn" onClick={() => setIsMenuOpen(false)}>
      <ArrowLeft size={20} className="tab-icon" />
    </div>
        
      )} */}
    </nav>
  );
}