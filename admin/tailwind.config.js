/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        brand: {
          dark: '#0D0B14',
          card: '#161322',
          border: 'rgba(255, 255, 255, 0.08)',
          primary: '#8B5CF6',
          primaryHover: '#7C3AED',
          accent: '#EC4899',
          muted: '#9CA3AF',
        }
      }
    },
  },
  plugins: [],
}
