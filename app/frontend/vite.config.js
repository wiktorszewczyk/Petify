import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      // Przekieruj WSZYSTKIE zapytania z frontu do backendu (gateway)
      '/pets/favorites': 'http://localhost:8222',
      '/shelters': 'http://localhost:8222',

      
    }
  }
});
