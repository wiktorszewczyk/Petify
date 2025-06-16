import { useState } from "react";
import { PawPrint, Save, Heart, User, Phone, MapPin, Home, Users, FileText } from "lucide-react";
import "./Profile.css";
import "./EditProfile.css";
import Navbar from "../components/Navbar";
import "./AdoptionForm.css"; 
import { useParams, useNavigate } from "react-router-dom";

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

export default function AdoptionForm() {
  const [form, setForm] = useState({
    motivationText: "",
    fullName: "",
    phoneNumber: "",
    address: "",
    housingType: "Apartment",
    isHouseOwner: false,
    hasYard: false,
    hasOtherPets: false,
    description: "",
  });
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const { id } = useParams();
  const navigate = useNavigate();
  const [isError, setIsError] = useState(false);
  const validateForm = () => {
  const phoneRegex = /^\+?[0-9\s\-]{7,15}$/;

  if (!form.fullName.trim()) return "Imię i nazwisko jest wymagane.";
  if (!form.phoneNumber.trim()) return "Numer telefonu jest wymagany.";
  if (!phoneRegex.test(form.phoneNumber.trim())) return "Numer telefonu jest nieprawidłowy.";
  if (!form.address.trim()) return "Adres jest wymagany.";
  if (!form.motivationText.trim()) return "Motywacja jest wymagana.";
  if (!form.description.trim()) return "Opis sytuacji domowej jest wymagany.";

  return null;
};
  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setForm({ 
      ...form, 
      [name]: type === 'checkbox' ? checked : value 
    });
  };

 const handleSubmit = async (e) => {
  e.preventDefault();
setMessage("");

const validationError = validateForm();
if (validationError) {
    setIsError(true);
  setMessage(validationError);
  return;
}

setLoading(true);
const token = localStorage.getItem("jwt");
  try {
    const response = await fetch(`http://localhost:8222/pets/${id}/adopt`, {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
  },
  body: JSON.stringify(form),
});

    if (!response.ok) {
      throw new Error("Błąd podczas wysyłania formularza");
    }
setIsError(false);
    setMessage("Formularz adopcyjny został wysłany pomyślnie!");
setTimeout(() => {
  navigate(`/petProfile/${id}`);
}, 1500); // przekieruj po 1.5 sekundy
    console.log("Adoption form submitted:", form);
  } catch (err) {
    console.error(err);
    setIsError(true);
    setMessage("Wystąpił błąd podczas wysyłania formularza.");
  } finally {
    setLoading(false);
  }
};


  if (loading) {
    return (
      <div className="profile-body">
        <div className="profile-page">
          <div className="loading-message">Wysyłanie formularza adopcyjnego...</div>
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
            <h2>Formularz Adopcyjny</h2>
          </div>
         {message && (
  <div className={`edit-message ${isError ? 'error' : 'success'}`}>
    {message}
  </div>
)}
        </section>

        <div onSubmit={handleSubmit} className="edit-profile-form">
          {/* Sekcja motywacji */}
          <section className="edit-profile-section">
            <h3 className="section-title">Motywacja</h3>
            <div className="form-group">
              <label className="form-label">
                <FileText className="label-icon" />
                Dlaczego chcesz adoptować zwierzę?
              </label>
              <textarea
                className="form-input"
                name="motivationText"
                placeholder="Opisz swoją motywację..."
                value={form.motivationText}
                onChange={handleChange}
                rows="4"
                style={{ minHeight: '100px', resize: 'vertical' }}
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
                  Imię i nazwisko
                </label>
                <input
                  className="form-input"
                  name="fullName"
                  placeholder="Wprowadź imię i nazwisko"
                  value={form.fullName}
                  onChange={handleChange}
                />
              </div>

              <div className="form-group">
                <label className="form-label">
                  <Phone className="label-icon" />
                  Numer telefonu
                </label>
                <input
                  type="tel"
                  className="form-input"
                  name="phoneNumber"
                  placeholder="Wprowadź numer telefonu"
                  value={form.phoneNumber}
                  onChange={handleChange}
                  pattern="^\+?[0-9\s\-]{7,15}$"
  required
                />
              </div>

              <div className="form-group" style={{ gridColumn: '1 / -1' }}>
                <label className="form-label">
                  <MapPin className="label-icon" />
                  Adres
                </label>
                <input
                  className="form-input"
                  name="address"
                  placeholder="Wprowadź pełny adres"
                  value={form.address}
                  onChange={handleChange}
                />
              </div>
            </div>
          </section>

          {/* Sekcja mieszkaniowa */}
          <section className="edit-profile-section housing-section">
            <h3 className="section-title">Warunki mieszkaniowe</h3>
            <div className="form-grid housing-grid">
              <div className="form-group">
                <label className="form-label">
                  <Home className="label-icon" />
                  Typ mieszkania
                </label>
                <select
                  className="form-select"
                  name="housingType"
                  value={form.housingType}
                  onChange={handleChange}
                >
                  <option value="Apartment">Mieszkanie</option>
                  <option value="House">Dom</option>
                  <option value="Studio">Kawalerka</option>
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">
                  <Home className="label-icon" />
                  Własność
                </label>
                <label style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '8px' }}>
                  <input
                    type="checkbox"
                    name="isHouseOwner"
                    checked={form.isHouseOwner}
                    onChange={handleChange}
                    style={{ width: '18px', height: '18px' }}
                  />
                  Jestem właścicielem
                </label>
              </div>

              <div className="form-group">
                <label className="form-label">
                  <Home className="label-icon" />
                  Ogród
                </label>
                <label style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '8px' }}>
                  <input
                    type="checkbox"
                    name="hasYard"
                    checked={form.hasYard}
                    onChange={handleChange}
                    style={{ width: '18px', height: '18px' }}
                  />
                  Posiadam ogród/podwórko
                </label>
              </div>

              <div className="form-group">
                <label className="form-label">
                  <Users className="label-icon" />
                  Inne zwierzęta
                </label>
                <label style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '8px' }}>
                  <input
                    type="checkbox"
                    name="hasOtherPets"
                    checked={form.hasOtherPets}
                    onChange={handleChange}
                    style={{ width: '18px', height: '18px' }}
                  />
                  Mam inne zwierzęta
                </label>
              </div>
            </div>
          </section>

          {/* Sekcja dodatkowa */}
          <section className="edit-profile-section">
            <h3 className="section-title">Dodatkowe informacje</h3>
            <div className="form-group">
              <label className="form-label">
                <FileText className="label-icon" />
                Opis sytuacji domowej
              </label>
              <textarea
                className="form-input"
                name="description"
                placeholder="Opisz swoją sytuację domową..."
                value={form.description}
                onChange={handleChange}
                rows="4"
                style={{ minHeight: '100px', resize: 'vertical' }}
              />
            </div>
          </section>

          {/* Przycisk wyślij */}
          <section className="edit-profile-actions">
            <button 
              className="save-button" 
              type="button"
              onClick={handleSubmit}
              disabled={loading}
            >
              <Save className="button-icon" />
              {loading ? 'Wysyłanie...' : 'Wyślij formularz'}
            </button>
            <button
              className="cancel-button"
              type="button"
              onClick={() => window.history.back()}
            >
              Anuluj
            </button>
          </section>
        </div>
      </div>
    </div>
  );
}