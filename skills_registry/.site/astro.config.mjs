// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

// Vitrine do marketplace. Lê os plugins/skills do repo pai (../) no build.
export default defineConfig({
  site: 'http://cybertron.local:8010',
  server: { port: 8010, host: true }, // host:true = bind 0.0.0.0, aceita acesso por hostname (não só localhost)
  devToolbar: { enabled: false },
  vite: {
    plugins: [tailwindcss()],
    server: {
      allowedHosts: ['cybertron.local'], // Vite 5+ bloqueia Host header desconhecido por padrão
    },
  },
});
