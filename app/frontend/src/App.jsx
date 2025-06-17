import { Routes, Route } from 'react-router-dom'
import Landing from './pages/Landing'
import Login from './pages/Login'
import Register from './pages/Register'
import Home from './pages/Home'
import Profile from './pages/Profile'
import Shelters from './pages/Shelters'
import Favourites from './pages/Favourites'
import PetProfile from './pages/PetProfile'
import EditProfile from './pages/EditProfile'
import './variables.css'
import ShelterProfile from './pages/ShelterProfile'
import PrivateRoute from './components/PrivateRoute'
import VolunteerApplication from './pages/VolunteerApplication'
import AdoptionForm from './pages/AdoptionForm'
import PetAppointments from './pages/PetAppointments'



function App() {
  return (
    <Routes>
      <Route path="/" element={<Landing />} />
      <Route path="/login" element={<Login />} />
      <Route path="/register" element={<Register />} />

      

      <Route path="/home" element={<PrivateRoute><Home /></PrivateRoute>} />
      <Route path="/profile" element={<PrivateRoute><Profile /></PrivateRoute>} />
      <Route path="/sheltersPage" element={<PrivateRoute><Shelters /></PrivateRoute>}/>
      <Route path="/favourites" element={<PrivateRoute><Favourites /></PrivateRoute>} />
      <Route path="/petProfile/:id" element={<PrivateRoute><PetProfile/></PrivateRoute>} />
      <Route path="/shelterProfile/:id" element={<PrivateRoute><ShelterProfile/></PrivateRoute>} /> 
      <Route path="/editProfile" element={<PrivateRoute><EditProfile /></PrivateRoute>} />
      <Route path="/volunteerApplication" element={<PrivateRoute><VolunteerApplication /></PrivateRoute>} />
      <Route path="/adoptionForm/:id" element={<PrivateRoute><AdoptionForm /></PrivateRoute>} />
      <Route path="/petAppointments/:id" element={<PrivateRoute><PetAppointments /></PrivateRoute>} />
    </Routes>
  )
}

export default App
