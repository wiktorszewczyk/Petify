import { Link } from 'react-router-dom'

export default function Navbar() {
  return (
    <nav className="navbar navbar-expand-lg navbar-light bg-white  shadow-sm px-3">
      <div className="container-fluid">
        <Link className="navbar-brand fw-bold" to="/home">MojaAppka</Link>
        <div className="d-flex">
          <Link to="/" className="btn btn-outline-danger">Wyloguj</Link>
        </div>
      </div>
    </nav>
  )
}
