import tailwindcss from '@tailwindcss/vite'

export default defineNuxtConfig({
  compatibilityDate: '2026-11-01',
  devtools: { enabled: false },
  css: ['~/assets/css/main.css'],
  // Komponente se zovu samo po imenu datoteke, bez prefiksa mape.
  components: [{ path: '~/components', pathPrefix: false }],
  vite: {
    plugins: [tailwindcss()],
  },
  app: {
    head: {
      htmlAttrs: { lang: 'hr-BA' },
      link: [
        { rel: 'icon', href: '/favicon.ico', sizes: '32x32 48x48' },
        { rel: 'icon', type: 'image/png', sizes: '48x48', href: '/favicon-48x48.png' },
        { rel: 'icon', type: 'image/png', sizes: '192x192', href: '/favicon-192x192.png' },
        { rel: 'apple-touch-icon', href: '/apple-touch-icon.png' },
        { rel: 'manifest', href: '/site.webmanifest' },
      ],
      meta: [{ name: 'theme-color', content: '#1c1915' }],
    },
  },
  runtimeConfig: {
    // Samo na serveru. Nikad ga ne premještaj u `public`.
    supabaseSecretKey: '',
    // Slanje e-maila s kodom za newsletter (Resend). Također samo na serveru.
    resendApiKey: '',
    newsletterFrom: '',
    public: {
      supabaseUrl: '',
      supabasePublishableKey: '',
      siteUrl: '',
      siteName: 'Viva',
    },
  },
  routeRules: {
    // Admin radi samo u pregledniku i ne smije u Google.
    '/admin/**': {
      ssr: false,
      headers: { 'X-Robots-Tag': 'noindex, nofollow' },
    },
  },
})
