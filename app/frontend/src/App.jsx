import { Routes, Route } from 'react-router-dom'
import Landing from './pages/Landing'
import Login from './pages/Login'
import Register from './pages/Register'
import Home from './pages/Home'
import Profile from './pages/Profile'
import Shelters from './pages/Shelters'
import Favourites from './pages/Favourites'
import PetProfile from './pages/PetProfile'
import './variables.css'


function App() {
  return (
    <Routes>
      <Route path="/" element={<Landing />} />
      <Route path="/login" element={<Login />} />
      <Route path="/register" element={<Register />} />
      <Route path="/home" element={<Home />} />
      <Route path="/profile" element={<Profile />} />
      <Route path="/shelters" element={<Shelters />}/>
      <Route path="/favourites" element={<Favourites />} />
      <Route path="/petProfile/:id" element={<PetProfile/>} />
    </Routes>
  )
}

export default App
