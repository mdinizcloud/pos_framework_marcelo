// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

// Vitrine dos prompts. Lê os arquivos .md do repo pai (../) no build.
export default defineConfig({
  site: 'http://cybertron.local:8020',
  server: { port: 8020, host: true }, // host:true = bind 0.0.0.0, aceita acesso por hostname (não só localhost)
  devToolbar: { enabled: false },
  vite: {
    plugins: [tailwindcss()],
    server: {
      allowedHosts: ['cybertron.local'], // Vite 5+ bloqueia Host header desconhecido por padrão
    },
  },
});
