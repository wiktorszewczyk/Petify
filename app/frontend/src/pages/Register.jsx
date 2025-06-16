import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { register } from '../api/auth'
import './Auth.css'

export default function Register() {
  const navigate = useNavigate()

  const [form, setForm] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    firstName: '',
    lastName: '',
    birthDate: '',
    phoneNumber: '',
    gender: 'MALE',
  })

  const [errors, setErrors] = useState([])

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value })
  }

  const validate = () => {
    const err = []

    if (!form.email.includes('@')) err.push('Nieprawidłowy adres e-mail.')
    if (form.password.length < 6) err.push('Hasło musi mieć co najmniej 6 znaków.')
    if (form.password !== form.confirmPassword) err.push('Hasła nie są takie same.')
    if (!/^\+?\d{9,15}$/.test(form.phoneNumber)) err.push('Nieprawidłowy numer telefonu.')
    if (!form.firstName.trim() || !form.lastName.trim()) err.push('Imię i nazwisko są wymagane.')
    if (!form.birthDate) err.push('Data urodzenia jest wymagana.')

    return err
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    const foundErrors = validate()
    if (foundErrors.length > 0) {
      setErrors(foundErrors)
      return
    }

    try {
      await register({
        username: form.email,
        password: form.password,
        firstName: form.firstName,
        lastName: form.lastName,
        birthDate: form.birthDate,
        gender: form.gender,
        phoneNumber: form.phoneNumber,
        email: form.email,
      })

      navigate('/login')
    } catch (error) {
      setErrors([error.message || 'Rejestracja nieudana.'])
    }
  }

  return (
    <div className="auth-bg d-flex justify-content-center align-items-center">
      <form
        onSubmit={handleSubmit}
        className="bg-white p-4 rounded shadow w-100 bg-opacity-75 auth-hidden auth-bounce-in"
        style={{ maxWidth: '400px' }}
      >
        <h2 className="mb-4 text-center">Rejestracja</h2>

        {errors.length > 0 && (
          <div className="alert alert-danger">
            <ul className="mb-0">
              {errors.map((err, i) => (
                <li key={i}>{err}</li>
              ))}
            </ul>
          </div>
        )}

        <input className="form-control mb-2" name="firstName" placeholder="Imię" value={form.firstName} onChange={handleChange} />
        <input className="form-control mb-2" name="lastName" placeholder="Nazwisko" value={form.lastName} onChange={handleChange} />
        <input className="form-control mb-2" name="birthDate" type="date" value={form.birthDate} onChange={handleChange} />
        <input className="form-control mb-2" name="phoneNumber" placeholder="Telefon" value={form.phoneNumber} onChange={handleChange} />

        <select className="form-select mb-2" name="gender" value={form.gender} onChange={handleChange}>
          <option value="MALE">Mężczyzna</option>
          <option value="FEMALE">Kobieta</option>
        </select>

        <input className="form-control mb-2" name="email" type="email" placeholder="Email" value={form.email} onChange={handleChange} />
        <input className="form-control mb-2" name="password" type="password" placeholder="Hasło" value={form.password} onChange={handleChange} />
        <input className="form-control mb-4" name="confirmPassword" type="password" placeholder="Powtórz hasło" value={form.confirmPassword} onChange={handleChange} />

        <button type="submit" className="btn btn-success w-100">Zarejestruj się</button>
      </form>
    </div>
  )
}
