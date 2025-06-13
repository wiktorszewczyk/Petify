import { useEffect, useState } from "react";
import { PawPrint, Save, User, Calendar, Phone, Mail, Users } from "lucide-react";
import "./Profile.css";
import "./EditProfile.css";
import Navbar from "../components/Navbar";
import { fetchUserData,  updateUserData, uploadProfileImage} from "../api/auth";
import { useNavigate } from "react-router-dom";


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

export default function EditProfile() {
  const [form, setForm] = useState({
    firstName: "",
    lastName: "",
    birthDate: "",
    gender: "MALE",
    phoneNumber: "",
    email: "",
  });
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();


 

  useEffect(() => {
  const fetchProfile = async () => {
    try {
      const data = await fetchUserData();
      setForm({
  firstName: data.firstName || "",
  lastName: data.lastName || "",
  birthDate: data.birthDate || "",
  gender: data.gender || "MALE",
  phoneNumber: data.phoneNumber || "",
  email: data.email || "",
});
    } catch (err) {
      console.error("Błąd podczas ładowania profilu:", err);
    } finally {
      setLoading(false);
    }
  };

  fetchProfile();
}, []);

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

 const handleFileChange = (e) => {
  const file = e.target.files[0];
  if (file) {
    if (file.size > 5 * 1024 * 1024) {
      alert("Plik jest zbyt duży. Maksymalny rozmiar to 5MB.");
      return;
    }
    setImageFile(file);
    setImagePreview(URL.createObjectURL(file));
  }
};

  const handleDrop = (e) => {
    e.preventDefault();
    const file = e.dataTransfer.files[0];
    if (file) {
      setImageFile(file);
      setImagePreview(URL.createObjectURL(file));
    }
  };

  

 const handleSubmit = async (e) => {
  e.preventDefault();
  setMessage("");
  setLoading(true);

  try {
    await updateUserData(form);

    if (imageFile) {
      await uploadProfileImage(imageFile);
    }

    setMessage("Dane zostały zaktualizowane.");
    navigate("/profile");
  } catch (err) {
    console.error(err);
    setMessage("Wystąpił błąd.");
  } finally {
    setLoading(false);
  }
};

  if (loading) {
    return (
      <div className="profile-body">
        <div className="profile-page">
          <div className="loading-message">Ładowanie profilu...</div>
        </div>
      </div>
    );
  }

  return (
    <div className="profile-body">
        <Navbar/>
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
        <section className="edit-profile-header">
          <div className="edit-profile-title">
            <User className="edit-profile-icon" />
            <h2>Edytuj Profil</h2>
          </div>
          {message && (
            <div className={`edit-message ${message.includes('Błąd') ? 'error' : 'success'}`}>
              {message}
            </div>
          )}
        </section>

        <div onSubmit={handleSubmit} className="edit-profile-form">
          {/* Sekcja zdjęcia profilowego */}
          <section className="edit-profile-section">
            <h3 className="section-title">Zdjęcie profilowe</h3>
            <div className="photo-upload-area" onDrop={handleDrop} onDragOver={(e) => e.preventDefault()}>
              {imagePreview ? (
                <div className="photo-preview">
                  <img src={imagePreview} alt="Podgląd" className="preview-image" />
                  <div className="photo-overlay">
                    <span>Kliknij aby zmienić</span>
                  </div>
                </div>
              ) : (
                <div className="photo-placeholder">
                  <User className="placeholder-icon" />
                  <p>Przeciągnij tutaj zdjęcie lub kliknij aby wybrać</p>
                </div>
              )}
              <input
                type="file"
                className="file-input"
                accept="image/*"
                onChange={handleFileChange}
              />
            </div>
          </section>

          {/* Sekcja danych osobowych */}
          <section className="edit-profile-section">
            <h3 className="section-title">Dane osobowe</h3>
            <div className="form-grid">
              <div className="form-group">
                <label className="form-label">
                  <User className="label-icon" />
                  Imię
                </label>
                <input
                  className="form-input"
                  name="firstName"
                  placeholder="Wprowadź imię"
                  value={form.firstName}
                  onChange={handleChange}
                />
              </div>

              <div className="form-group">
                <label className="form-label">
                  <User className="label-icon" />
                  Nazwisko
                </label>
                <input
                  className="form-input"
                  name="lastName"
                  placeholder="Wprowadź nazwisko"
                  value={form.lastName}
                  onChange={handleChange}
                />
              </div>

              <div className="form-group">
                <label className="form-label">
                  <Calendar className="label-icon" />
                  Data urodzenia
                </label>
                <input
                  className="form-input"
                  name="birthDate"
                  type="date"
                  value={form.birthDate}
                  onChange={handleChange}
                />
              </div>

              <div className="form-group">
                <label className="form-label">
                  <Users className="label-icon" />
                  Płeć
                </label>
                <select
                  className="form-select"
                  name="gender"
                  value={form.gender}
                  onChange={handleChange}
                >
                  <option value="MALE">Mężczyzna</option>
                  <option value="FEMALE">Kobieta</option>
                </select>
              </div>
            </div>
          </section>

          {/* Sekcja kontaktowa */}
          <section className="edit-profile-section">
            <h3 className="section-title">Dane kontaktowe</h3>
            <div className="form-grid">
              <div className="form-group">
                <label className="form-label">
                  <Phone className="label-icon" />
                  Numer telefonu
                </label>
                <input
                  className="form-input"
                  name="phoneNumber"
                  placeholder="Wprowadź numer telefonu"
                  value={form.phoneNumber}
                  onChange={handleChange}
                />
              </div>

              <div className="form-group">
                <label className="form-label">
                  <Mail className="label-icon" />
                  Email
                </label>
                <input
                  className="form-input"
                  name="email"
                  type="email"
                  placeholder="Wprowadź adres email"
                  value={form.email}
                  onChange={handleChange}
                />
              </div>
            </div>
          </section>

          {/* Przycisk zapisz */}
          <section className="edit-profile-actions">
            <button 
              className="save-button" 
              type="button"
              onClick={handleSubmit}
              disabled={loading}
            >
              <Save className="button-icon" />
              {loading ? 'Zapisywanie...' : 'Zapisz zmiany'}
            </button>
            <button
              className="cancel-button"
              type="button"
              onClick={() => navigate("/profile")}
            >
              Anuluj
            </button>
          </section>
        </div>
      </div>
         </div>
  );
}