import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { login, handleGoogleLogin } from '../api/auth';
import './Auth.css' 
import { GoogleLogin } from '@react-oauth/google';

export default function Login() {
  const [username, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const navigate = useNavigate()

 
   const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await login(username, password);
      navigate("/home"); 
    } catch (err) {
      alert("Błąd logowania: " + err.message);
    }
  };

  return (
    <div className="auth-bg d-flex justify-content-center align-items-center min-vh-100 ">
      <form
        onSubmit={handleSubmit}
        className="bg-white p-4 rounded shadow w-100 bg-opacity-75 auth-hidden auth-bounce-in"
        style={{ maxWidth: '400px' }}
      >
        <h2 className="mb-4 text-center">Logowanie</h2>

        <div className="mb-3">
          <label className="form-label">Username</label>
          <input
            type="username"
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
        <GoogleLogin
  onSuccess={(credentialResponse) => {
    const idToken = credentialResponse.credential;
    handleGoogleLogin(idToken); // tu wysyłasz do backendu
  }}
  onError={() => {
    console.log('Logowanie przez Google nie powiodło się');
  }}
/>
      </form>
    </div>
  )
}
