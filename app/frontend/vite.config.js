import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173, // może być dowolny
    proxy: {
      '/api': {
        target: 'http://localhost:8222', 
        changeOrigin: true,
        rewrite: (path) => path, 
      },
    },
  },
});
