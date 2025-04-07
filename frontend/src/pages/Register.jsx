import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import './Auth.css'

export default function Register() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const navigate = useNavigate()

  const handleSubmit = (e) => {
    e.preventDefault()
    if (password !== confirmPassword) {
      alert('Hasła nie są takie same')
      return
    }
    console.log('Register:', { email, password })
    navigate('/login')
  }

  return (
    <div className="auth-bg d-flex justify-content-center align-items-center">
      <form
        onSubmit={handleSubmit}
        className="bg-white p-4 rounded shadow w-100 bg-opacity-75 auth-hidden auth-bounce-in"
        style={{ maxWidth: '400px' }}
      >
        <h2 className="mb-4 text-center">Rejestracja</h2>

        <div className="mb-3">
          <label className="form-label">Email</label>
          <input
            type="email"
            className="form-control"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
        </div>

        <div className="mb-3">
          <label className="form-label">Hasło</label>
          <input
            type="password"
            className="form-control"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
        </div>

        <div className="mb-4">
          <label className="form-label">Powtórz hasło</label>
          <input
            type="password"
            className="form-control"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            required
          />
        </div>

        <button type="submit" className="btn btn-success w-100">
          Zarejestruj się
        </button>
      </form>
    </div>
  )
}
