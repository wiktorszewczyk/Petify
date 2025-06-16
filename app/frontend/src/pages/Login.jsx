import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { login, handleGoogleLogin } from '../api/auth';
import './Auth.css'

export default function Login() {
  const [username, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errors, setErrors] = useState([]);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setErrors([]); // wyczyść błędy przed nową próbą

    try {
      await login(username, password);
      navigate("/home");
    } catch (err) {
      setErrors([err.message]); // dodaj komunikat jako pojedynczy błąd
    }
  };

  return (
    <div className="auth-bg d-flex justify-content-center align-items-center min-vh-100">
      <form
        onSubmit={handleSubmit}
        className="bg-white p-4 rounded shadow w-100 bg-opacity-75 auth-hidden auth-bounce-in"
        style={{ maxWidth: '400px' }}
      >
        <h2 className="mb-4 text-center">Logowanie</h2>

        {errors.length > 0 && (
          <div className="alert alert-danger">
            <ul className="mb-0">
              {errors.map((err, i) => (
                <li key={i}>{err}</li>
              ))}
            </ul>
          </div>
        )}

        <div className="mb-3">
          <label className="form-label">Email lub nr telefonu</label>
          <input
            type="text"
            className="form-control"
            value={username}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
        </div>

        <div className="mb-4">
          <label className="form-label">Hasło</label>
          <input
            type="password"
            className="form-control"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
        </div>

        <button type="submit" className="btn btn-primary w-100">
          Zaloguj się
        </button>

        <div className="mt-3 text-center">
          <button
  className="btn btn-outline-dark w-100 mt-3"
  onClick={() => {
    window.location.href = "http://localhost:9000/auth/oauth2/google";
  }}
>
  Zaloguj się przez Google
</button>
        </div>
      </form>
    </div>
  );
}
