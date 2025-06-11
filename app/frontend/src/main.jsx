import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import App from './App'
import 'bootstrap/dist/css/bootstrap.min.css'
import { GoogleOAuthProvider } from '@react-oauth/google';


ReactDOM.createRoot(document.getElementById('root')).render(
  <GoogleOAuthProvider clientId="TWÓJ_CLIENT_ID_OD_GOOGLE">
  <BrowserRouter>
    <App />
  </BrowserRouter>
  </GoogleOAuthProvider>
)
