import { Routes, Route } from "react-router-dom";
import Landing from "./pages/Landing";
import Login from "./pages/Login";
import Register from "./pages/Register";
import Home from "./pages/Home";
import Profile from "./pages/Profile";
import Shelters from "./pages/Shelters";
import Favourites from "./pages/Favourites";
import PetProfile from "./pages/PetProfile";
import EditProfile from "./pages/EditProfile";
import ShelterProfile from "./pages/ShelterProfile";
import PrivateRoute from "./components/PrivateRoute";
import RoleProtectedRoute from "./components/RoleProtectedRoute";

import ShelterPanel from "./pages/shelter_panel/ShelterPanel";
import AddPetForm from "./components/shelter_panel/AddPetForm";
import EditPetForm from "./pages/shelter_panel/EditPetForm";
import ShelterAdoptionsPage from "./pages/shelter_panel/ShelterAdoptionsPage";
import ShelterReservationsPage from "./pages/shelter_panel/ShelterReservationsPage";
import ShelterMessages from "./pages/shelter_panel/ShelterMessages";
import ShelterFeed from "./pages/shelter_panel/ShelterFeed";
import ShelterFunding from "./pages/shelter_panel/ShelterFunding";

import AdminPanel from "./pages/admin_panel/AdminPanel";
import AdminUsers from "./pages/admin_panel/AdminUsers";
import AdminShelterActivations from "./pages/admin_panel/AdminShelterActivations";
import AdminVolunteerApplications from "./pages/admin_panel/AdminVolunteerApplications";

import "./variables.css";

function App() {
    return (
        <Routes>
            <Route path="/" element={<Landing />} />
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route
                path="/home"
                element={
                    <PrivateRoute>
                        <Home />
                    </PrivateRoute>
                }
            />
            <Route
                path="/profile"
                element={
                    <PrivateRoute>
                        <Profile />
                    </PrivateRoute>
                }
            />
            <Route
                path="/sheltersPage"
                element={
                    <PrivateRoute>
                        <Shelters />
                    </PrivateRoute>
                }
            />
            <Route
                path="/favourites"
                element={
                    <PrivateRoute>
                        <Favourites />
                    </PrivateRoute>
                }
            />
            <Route
                path="/petProfile/:id"
                element={
                    <PrivateRoute>
                        <PetProfile />
                    </PrivateRoute>
                }
            />
            <Route
                path="/shelterProfile/:id"
                element={
                    <PrivateRoute>
                        <ShelterProfile />
                    </PrivateRoute>
                }
            />
            <Route
                path="/editProfile"
                element={
                    <PrivateRoute>
                        <EditProfile />
                    </PrivateRoute>
                }
            />
            <Route
                path="/shelter-panel"
                element={
                    <RoleProtectedRoute requiredRole="SHELTER">
                        <ShelterPanel />
                    </RoleProtectedRoute>
                }
            />
            <Route
                path="/shelter-panel/add-pet"
                element={
                    <RoleProtectedRoute requiredRole="SHELTER">
                        <AddPetForm />
                    </RoleProtectedRoute>
                }
            />
            <Route
                path="/shelter-panel/edit-pet/:petId"
                element={
                    <RoleProtectedRoute requiredRole="SHELTER">
                        <EditPetForm />
                    </RoleProtectedRoute>
                }
            />
            <Route
                path="/shelter-panel/adoptions"
                element={
                    <RoleProtectedRoute requiredRole="SHELTER">
                        <ShelterAdoptionsPage />
                    </RoleProtectedRoute>
                }
            />
            <Route
                path="/shelter-panel/reservations"
                element={
                    <RoleProtectedRoute requiredRole="SHELTER">
                        <ShelterReservationsPage />
                    </RoleProtectedRoute>
                }
            />
            <Route
                path="/shelter-panel/messages"
                element={
                    <RoleProtectedRoute requiredRole="SHELTER">
                        <ShelterMessages />
                    </RoleProtectedRoute>
                }
            />
            <Route
                path="/shelter-panel/feed"
                element={
                    <RoleProtectedRoute requiredRole="SHELTER">
                        <ShelterFeed />
                    </RoleProtectedRoute>
                }
            />
            <Route
                path="/shelter-panel/funding"
                element={
                    <RoleProtectedRoute requiredRole="SHELTER">
                        <ShelterFunding />
                    </RoleProtectedRoute>
                }
            />
            <Route
                path="/admin-panel"
                element={
                    <RoleProtectedRoute requiredRole="ADMIN">
                        <AdminPanel />
                    </RoleProtectedRoute>
                }
            />
            <Route
                path="/admin-panel/users"
                element={
                    <RoleProtectedRoute requiredRole="ADMIN">
                        <AdminUsers />
                    </RoleProtectedRoute>
                }
            />
            <Route
                path="/admin-panel/shelter-activations"
                element={
                    <RoleProtectedRoute requiredRole="ADMIN">
                        <AdminShelterActivations />
                    </RoleProtectedRoute>
                }
            />
            <Route
                path="/admin-panel/volunteer-applications"
                element={
                    <RoleProtectedRoute requiredRole="ADMIN">
                        <AdminVolunteerApplications />
                    </RoleProtectedRoute>
                }
            />
        </Routes>
    );
}

export default App;
