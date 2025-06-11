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
} from "lucide-react";
import Navbar from "../components/Navbar";
import { fetchUserData } from "../api/auth"; 

import profileP from "../assets/profileP.jpg";

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

  useEffect(() => {
    fetchUserData()
      .then(data => {
        setUserData(data);
        setLoading(false);
      })
      .catch(err => {
        console.error("Błąd podczas ładowania profilu:", err);
        setLoading(false);
      });
  }, []);

  if (loading) return <div>Ładowanie profilu...</div>;
  if (!userData) return <div>Błąd: brak danych użytkownika</div>;


   const user = {
    name: `${userData.firstName} ${userData.lastName}`,
    rank: "Początkujący Wolontariusz",
    location: "Polska",
    profilePicture: profileP,
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
    badges: userData.badgesCount,
  };

  const achievementsEarned = userData.achievements
    .filter(a => a.completed)
    .map(a => a.achievement.name);

  const achievementsInProgress = userData.achievements
    .filter(a => !a.completed)
    .map(a => ({
      title: a.achievement.name,
      description: a.achievement.description,
      progress: a.progressPercentage,
      xp: a.achievement.xpReward,
      done: a.currentProgress,
      total: a.achievement.requiredActions,
    }));

  const donations = []; // placeholder – chyba nie ma endpointu jeszcze?
  const activity = [];

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
          <img src={user.profilePicture} alt="Zdjęcie profilowe" />
        </div>
        <div className="user-details">
          <h2 className="user-name">{user.name}</h2>
          <p className="user-rank">
            {user.rank} <span className="emoji">🌱</span>
          </p>
          <p className="user-location">
            <MapPin/> {user.location}
          </p>
        </div>
      </section>

      <section className="volunteer-cta" role="button" tabIndex={0}>
        <div className="cta-icon"><PawPrint></PawPrint></div>
        <div className="cta-text">
          <h3>Zostań Wolontariuszem</h3>
          <p>Pomóż zwierzakom w potrzebie i dołącz do naszej społeczności</p>
        </div>
        <div className="cta-arrow"><ArrowRight/></div>
      </section>


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

      <section className="achievements-earned">
  <div className="section-header">
    <h3>Zdobyte osiągnięcia</h3>
    <button className="see-all-btn">Zobacz wszystkie</button>
  </div>
  <div className="achievement-icons">
    <div className="achievement-circle-text achievement-circle">
      <ScrollText/>
    </div>
    <div className="achievement-circle-hand achievement-circle">
      <HandCoins/>
    </div>
    <div className="achievement-circle-dollar achievement-circle">
      <DollarSign/>
    </div>
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


      <section className="donations">
  <h3>Wpłaty</h3>
  <div className="donations-table">
    <div className="donations-header">
      <span>Kwota</span>
      <span>Data</span>
      <span>Cel</span>
    </div>
    {donations.map((don, i) => (
      <div key={i} className="donations-row">
        <span>{don.amount}</span>
        <span>{don.date}</span>
        <span>{don.to}</span>
      </div>
    ))}
  </div>
</section>
    </div>
    </div>
  );
}

export default Profile;
