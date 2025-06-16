
import { useState } from "react";
import { PawPrint, Save, Heart, Clock, Award, FileText, User, Calendar } from "lucide-react";
import { useNavigate } from "react-router-dom";
import Navbar from "../components/Navbar";
import "./VolunteerApplication.css";


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

export default function VolunteerApplication() {
  const [form, setForm] = useState({
    experience: "",
    motivation: "",
    availability: "",
    skills: "",
  });
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
  e.preventDefault();
  setMessage("");
  setLoading(true);

  try {
    if (!form.experience || !form.motivation || !form.availability || !form.skills) {
      setMessage("Proszę wypełnić wszystkie pola.");
      setLoading(false);
      return;
    }

    const token = localStorage.getItem("jwt"); // zakładam, że autoryzacja wymaga tokena

    const response = await fetch("http://localhost:9000/volunteer/apply", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(form),
    });

    if (!response.ok) {
      throw new Error("Wystąpił błąd podczas wysyłania zgłoszenia.");
    }

    setMessage("Zgłoszenie zostało wysłane pomyślnie!");

    setTimeout(() => {
      setForm({
        experience: "",
        motivation: "",
        availability: "",
        skills: "",
      });
      setMessage("");
      navigate("/profile");
    }, 2000);
  } catch (err) {
    console.error(err);
    setMessage("Wystąpił błąd podczas wysyłania zgłoszenia.");
  } finally {
    setLoading(false);
  }
};

  if (loading) {
    return (
      <div className="profile-body">
        <div className="profile-page">
          <div className="loading-message">Wysyłanie zgłoszenia...</div>
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
            <h2>Zostań Wolontariuszem</h2>
          </div>
          
          {message && (
            <div className={`edit-message ${message.includes('błąd') || message.includes('Proszę') ? 'error' : 'success'}`}>
              {message}
            </div>
          )}
        </section>

        <div className="edit-profile-form">
          {/* Sekcja doświadczenia */}
          <section className="edit-profile-section">
            <h3 className="section-title">
              <Award className="section-icon" />
              Doświadczenie
            </h3>
            <div className="form-group">
              <label className="form-label">
                <User className="label-icon" />
                Opisz swoje doświadczenie w pracy ze zwierzętami
              </label>
              <textarea
                className="form-textarea"
                name="experience"
               
                value={form.experience}
                onChange={handleChange}
                rows={5}
              />
            </div>
          </section>

          {/* Sekcja motywacji */}
          <section className="edit-profile-section">
            <h3 className="section-title">
              <Heart className="section-icon" />
              Motywacja
            </h3>
            <div className="form-group">
              <label className="form-label">
                <Heart className="label-icon" />
                Dlaczego chcesz zostać wolontariuszem?
              </label>
              <textarea
                className="form-textarea"
                name="motivation"
               
                value={form.motivation}
                onChange={handleChange}
                rows={5}
              />
            </div>
          </section>

          {/* Sekcja dostępności */}
          <section className="edit-profile-section">
            <h3 className="section-title">
              <Clock className="section-icon" />
              Dostępność
            </h3>
            <div className="form-group">
              <label className="form-label">
                <Calendar className="label-icon" />
                Kiedy możesz pomagać?
              </label>
              <textarea
                className="form-textarea"
                name="availability"
                value={form.availability}
                onChange={handleChange}
                rows={5}
              />
            </div>
          </section>

          {/* Sekcja umiejętności */}
          <section className="edit-profile-section">
            <h3 className="section-title">
              <FileText className="section-icon" />
              Umiejętności
            </h3>
            <div className="form-group">
              <label className="form-label">
                <Award className="label-icon" />
                Jakie umiejętności posiadasz?
              </label>
              <textarea
                className="form-textarea"
                name="skills"
                
                value={form.skills}
                onChange={handleChange}
                rows={5}
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
              {loading ? 'Wysyłanie...' : 'Wyślij Zgłoszenie'}
            </button>

            <button 
    className="cancel-button"
    type="button"
    onClick={() => navigate('/profile')} 
  > Anuluj </button>
          </section>
        </div>
      </div>
        </div>
  );
}