import { useState, useRef, useEffect } from 'react';
import "./Profile.css";
import {
  Heart,
  PawPrint,
  HandCoins,
  MapPin,
  Trophy,
  ArrowRight,
  ScrollText,
  DollarSign,
  Clock,
} from "lucide-react";
import Navbar from "../components/Navbar";
import { fetchUserData, fetchProfileImage } from "../api/auth"; 
import { useNavigate } from 'react-router-dom';

import defaultAvatar from "../assets/default_avatar.jpg";

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



function Profile() {
 const [userData, setUserData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [profilePicture, setProfilePicture] = useState(defaultAvatar);
  const navigate = useNavigate();

useEffect(() => {
  const loadProfile = async () => {
    try {
      const data = await fetchUserData();
      setUserData(data);

      if (data.profileImageBase64) {
        setProfilePicture(`data:image/jpeg;base64,${data.profileImageBase64}`);
      } else {
        setProfilePicture(defaultAvatar);
      }
    } catch (err) {
      console.error("Błąd podczas ładowania profilu:", err);
      setProfilePicture(defaultAvatar);
    } finally {
      setLoading(false);
    }
  };

  loadProfile();
}, []);



  if (loading) {
  return (
    <div className="loading-spinner-container">
      <div className="loading-spinner" />
    </div>
  );
}
  if (!userData) return <div>Błąd: brak danych użytkownika</div>;


   const user = {
    name: `${userData.firstName} ${userData.lastName}`,
    rank: "Początkujący Wolontariusz",
    location: "Polska",
    profilePicture: profilePicture,
    volunteerStatus: userData.volunteerStatus || "NONE",
  };

  const level = {
    currentLevel: userData.level,
    currentXp: userData.xpPoints,
    xpToNext: userData.xpToNextLevel,
    progressPercent: Math.round((userData.xpPoints / (userData.xpPoints + userData.xpToNextLevel)) * 100),
  };

  const stats = {
    liked: userData.likesCount,
    supports: userData.supportCount,
    badges: userData.achievements.filter(a => a.completed).length,
  };

  const earnedAchievements = userData.achievements
  .filter(a => a.completed);

  const achievementsEarned = userData.achievements
    .filter(a => a.completed)
    .map(a => a.achievement.name);


  const achievementsInProgress = userData.achievements
    .filter(a => !a.completed)
    .sort((a, b) => a.achievement.name.localeCompare(b.achievement.name))
    .map(a => ({
      title: a.achievement.name,
      description: a.achievement.description,
      progress: a.progressPercentage,
      xp: a.achievement.xpReward,
      done: a.currentProgress,
      total: a.achievement.requiredActions,
    }));



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
    <div className="profile-page">
      

      <section className="user-info">
        <div className="user-avatar">
          <img
  src={profilePicture}
  alt="Zdjęcie profilowe"
  onError={(e) => {
    e.target.onerror = null;
    e.target.src = defaultAvatar;
  }}
/>
        </div>
        <div className="user-details">
          <h2 className="user-name">{user.name}</h2>
          {user.volunteerStatus === "APPROVED" && (
          <p className="user-rank">
            Wolontariusz <span className="emoji">🌱</span>
          </p>
          )}
        </div>
        <button
  className="edit-profile-btn"
  onClick={() => navigate('/editProfile')}
>
  Edytuj Profil
</button>
      </section>
{(user.volunteerStatus === "INACTIVE" || user.volunteerStatus === "NONE") && (
     <section
  className="volunteer-cta"
  role="button"
  tabIndex={0}
  onClick={() => navigate("/volunteerApplication")}
  onKeyDown={(e) => {
    if (e.key === "Enter") navigate("/volunteerApplication");
  }}
>
  <div className="cta-icon"><PawPrint /></div>
  <div className="cta-text">
    <h3>Zostań Wolontariuszem</h3>
    <p>Pomóż zwierzakom w potrzebie i dołącz do naszej społeczności</p>
  </div>
  <div className="cta-arrow"><ArrowRight /></div>
</section>
)}


{user.volunteerStatus === "PENDING" && (
  <section className="volunteer-pending">
    <div className="pending-icon">
      <Clock />
    </div>
    <div className="pending-content">
      <h3>Zgłoszenie na wolontariusza</h3>
      <p>Twoje zgłoszenie oczekuje na zatwierdzenie przez administratora</p>
      <div className="pending-status">
        <span className="status-indicator"></span>
        <span className="status-text">W trakcie weryfikacji</span>
      </div>
    </div>
  </section>
)}

      <section className="level-section">
        <div className="level-info">
          <span className="level-label">Poziom {level.currentLevel}</span>
          <span className="xp-pill">{level.currentXp} XP</span>
        </div>
        <div className="xp-progress">
          <div className="xp-bar">
            <div className="xp-bar-fill" style={{ width: `${level.progressPercent}%` }}></div>
          </div>
          <span className="xp-to-next">Postęp: {level.xpToNext} XP do następnego poziomu</span>
        </div>
      </section>

      <section className="user-stats">
        <div className="stat">
          <span className="stat-icon-heart"><Heart/></span>
          <span className="stat-value">{stats.liked}</span>
          <span className="stat-label">Polubione</span>
        </div>
        <div className="stat">
          <span className="stat-icon-hand"><HandCoins/></span>
          <span className="stat-value">{stats.supports}</span>
          <span className="stat-label">Wsparcia</span>
        </div>
        <div className="stat">
          <span className="stat-icon-trophy"><Trophy/></span>
          <span className="stat-value">{stats.badges}</span>
          <span className="stat-label">Odznaki</span>
        </div>
      </section>



<section className="achievements-section">
  <div className="achievements-container">
    <div className="achievements-header">
      <h3>Zdobyte osiągnięcia</h3>
      {earnedAchievements.length > 5 && (
        <span className="achievements-count">
          +{earnedAchievements.length - 5} więcej
        </span>
      )}
    </div>

    <div className="achievements-grid">
      {earnedAchievements.map((a, i) => {
        const category = a.achievement.category;
        const iconMap = {
          LIKES: <Heart className="achievement-icon" />,
          SUPPORT: <HandCoins className="achievement-icon" />,
          BADGE: <Trophy className="achievement-icon" />,
        };

        return (
          <div 
            key={i} 
            className="achievement-item"
            title={a.achievement.name}
          >
            {/* Żółte kółko z ikoną */}
            <div className="achievement-circle">
              <div className="achievement-icon-wrapper">
                {iconMap[category] || <Trophy className="achievement-icon" />}
              </div>
            </div>
            
            {/* Nazwa osiągnięcia */}
            <div className="achievement-name">
              {a.achievement.name}
            </div>
          </div>
        );
      })}
    </div>

    {/* Jeśli brak osiągnięć */}
    {earnedAchievements.length === 0 && (
      <div className="no-achievements">
        <div className="no-achievements-icon">
          <Trophy />
        </div>
        <p className="no-achievements-title">Brak zdobytych osiągnięć</p>
        <p className="no-achievements-subtitle">Kontynuuj pomaganie zwierzętom, aby zdobyć pierwsze osiągnięcie!</p>
      </div>
    )}
  </div>
</section>


      <section className="achievements-progress">
        <h3>Postępy osiągnięć</h3>
        {achievementsInProgress.map((ach, i) => (
          <div key={i} className="achievement-card">
            <div className="achiev-info">
              <h4>{ach.title}</h4>
              <p>{ach.description}</p>
            </div>
            <div className="achiev-progress">
              <div className="achiev-bar">
                <div className="achiev-bar-fill" style={{ width: `${ach.progress}%` }}></div>
              </div>
              <p className="achiev-progress-text">
                {ach.done}/{ach.total} ({ach.progress}%) – {ach.xp > 0 ? `zdobyto ${ach.xp} XP` : `do zdobycia +${500 - ach.xp} XP`}
              </p>
            </div>
          </div>
        ))}
      </section>


      
    </div>
    </div>
  );
}

export default Profile;
