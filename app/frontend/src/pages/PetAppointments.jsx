import { useState, useEffect } from 'react';
import { Calendar, Clock, User, PawPrint, CheckCircle } from 'lucide-react';
import { useParams } from 'react-router-dom';
import Navbar from '../components/Navbar';
import './PetAppointments.css';
import "./Profile.css";
import "./EditProfile.css";

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

export default function PetAppointments() {
  const { id } = useParams();
  const [loading, setLoading] = useState(true);
  const [bookingLoading, setBookingLoading] = useState(null);
  const [message, setMessage] = useState('');
  const [isError, setIsError] = useState(false);
  const [appointments, setAppointments] = useState([]);
  const [pet, setPet] = useState(null);

  useEffect(() => {
    const fetchAppointments = async () => {
      try {
        const token = localStorage.getItem("jwt");
        const res = await fetch(`http://localhost:8222/reservations/slots/pet/${id}`, {
          headers: {
            Authorization: `Bearer ${token}`
          }
        });

        if (!res.ok) throw new Error(`API error: ${res.status}`);
        const data = await res.json();

        if (Array.isArray(data)) {
          setAppointments(data);
        } else {
          console.error("Nieprawidłowy format danych (appointments):", data);
          setAppointments([]);
        }
      } catch (err) {
        console.error("Błąd podczas pobierania terminów:", err);
        setAppointments([]);
      }
    };

    const fetchPet = async () => {
      try {
        const token = localStorage.getItem("jwt");
        const res = await fetch(`http://localhost:8222/pets/${id}`, {
          headers: {
            Authorization: `Bearer ${token}`
          }
        });

        if (!res.ok) throw new Error(`API error: ${res.status}`);
        const data = await res.json();
        setPet(data);
      } catch (err) {
        console.error("Błąd podczas pobierania danych zwierzaka:", err);
      }
    };

    Promise.all([fetchAppointments(), fetchPet()]).finally(() => setLoading(false));
  }, [id]);

  const availableAppointments = appointments.filter(apt => apt.status === 'AVAILABLE');
  const reservedAppointments = appointments.filter(apt => apt.status === 'RESERVED');

  const formatDateTime = (dateTime) => {
    const date = new Date(dateTime);
    return {
      date: date.toLocaleDateString('pl-PL', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      }),
      time: date.toLocaleTimeString('pl-PL', {
        hour: '2-digit',
        minute: '2-digit'
      })
    };
  };

  const getDuration = (startTime, endTime) => {
    const start = new Date(startTime);
    const end = new Date(endTime);
    return `${(end - start) / (1000 * 60)} min`;
  };

  const handleBookAppointment = async (appointmentId) => {
    setBookingLoading(appointmentId);
    setMessage('');

    try {
      const token = localStorage.getItem("jwt");

      const response = await fetch(`http://localhost:8222/reservations/slots/${appointmentId}/reserve`, {
        method: "PATCH",
        headers: {
          Authorization: `Bearer ${token}`
        }
      });

      if (!response.ok) {
        throw new Error("Nie udało się zarezerwować terminu.");
      }

      setAppointments(prev =>
        prev.map(apt =>
          apt.id === appointmentId
            ? { ...apt, status: 'RESERVED', reservedBy: 'Ty' }
            : apt
        )
      );

      setIsError(false);
      setMessage('Pomyślnie umówiono na spacer!');
    } catch (error) {
      setIsError(true);
      setMessage('Wystąpił błąd podczas rezerwacji terminu.');
    } finally {
      setTimeout(() => setMessage(''), 3000);
      setBookingLoading(null);
    }
  };

  const groupAppointmentsByDate = (appointments) => {
    const grouped = {};
    appointments.forEach(apt => {
      const date = new Date(apt.startTime).toISOString().split('T')[0];
      if (!grouped[date]) {
        grouped[date] = [];
      }
      grouped[date].push(apt);
    });
    return grouped;
  };

  if (loading) {
    return (
      <div className="appointments-body">
        <Navbar />
        <div className="appointments-page">
          <div className="loading-message">Ładowanie terminów...</div>
        </div>
      </div>
    );
  }

  return (
    <div className="appointments-body">
      <Navbar />

      {/* Tło z łapkami */}
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

      <div className="appointments-page">
        <section className="appointments-header">
          <div className="page-title">
            <Calendar className="title-icon" />
            <h2>Dostępne terminy spacerów dla {pet?.name}</h2>
          </div>

          {message && (
            <div className={`message ${isError ? 'error' : 'success'}`}>
              {message}
            </div>
          )}
        </section>

        {/* Dostępne terminy */}
        <section className="appointments-section">
          <div className="section-header">
            <Clock className="section-icon" />
            <h3>Dostępne terminy ({availableAppointments.length})</h3>
          </div>

          {availableAppointments.length === 0 ? (
            <div className="no-appointments">
              <Calendar className="no-appointments-icon" />
              <p>Brak dostępnych terminów</p>
            </div>
          ) : (
            <div className="appointments-grid">
              {Object.entries(groupAppointmentsByDate(availableAppointments)).map(([date, dayAppointments]) => (
                <div key={date} className="day-group">
                  <h4 className="day-header">
                    {new Date(date).toLocaleDateString('pl-PL', {
                      weekday: 'long',
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric'
                    })}
                  </h4>
                  <div className="day-appointments">
                    {dayAppointments.map(appointment => {
                      const { time } = formatDateTime(appointment.startTime);
                      const duration = getDuration(appointment.startTime, appointment.endTime);
                      return (
                        <div key={appointment.id} className="appointment-card available">
                          <div className="appointment-time">
                            <Clock className="time-icon" />
                            <div className="time-details">
                              <span className="time">{time}</span>
                              <span className="duration">{duration}</span>
                            </div>
                          </div>
                          <button
                            className="book-button"
                            onClick={() => handleBookAppointment(appointment.id)}
                            disabled={bookingLoading === appointment.id}
                          >
                            {bookingLoading === appointment.id ? (
                              <span className="loading-text">Rezerwuję...</span>
                            ) : (
                              <>
                                <PawPrint className="button-icon" />
                                <span>Umów się na spacer</span>
                              </>
                            )}
                          </button>
                        </div>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
          )}
        </section>

        {/* Zarezerwowane terminy */}
        {reservedAppointments.length > 0 && (
          <section className="appointments-section reserved-section">
            <div className="section-header">
              <CheckCircle className="section-icon reserved-icon" />
              <h3>Zarezerwowane terminy ({reservedAppointments.length})</h3>
            </div>
            <div className="appointments-grid">
              {Object.entries(groupAppointmentsByDate(reservedAppointments)).map(([date, dayAppointments]) => (
                <div key={date} className="day-group">
                  <h4 className="day-header">
                    {new Date(date).toLocaleDateString('pl-PL', {
                      weekday: 'long',
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric'
                    })}
                  </h4>
                  <div className="day-appointments">
                    {dayAppointments.map(appointment => {
                      const { time } = formatDateTime(appointment.startTime);
                      const duration = getDuration(appointment.startTime, appointment.endTime);
                      return (
                        <div key={appointment.id} className="appointment-card reserved">
                          <div className="appointment-time">
                            <Clock className="time-icon" />
                            <div className="time-details">
                              <span className="time">{time}</span>
                              <span className="duration">{duration}</span>
                            </div>
                          </div>
                          <div className="reserved-info">
                            <User className="user-icon" />
                            <span className="reserved-by">
                              Zarezerwowane
                            </span>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}
      </div>
    </div>
  );
}
