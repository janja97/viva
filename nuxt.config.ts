import tailwindcss from '@tailwindcss/vite'

// Netlify pri izgradnji postavlja CONTEXT: production, deploy-preview ili branch-deploy. Projekt nema Node tipove.
const NETLIFY_CONTEXT = (globalThis as { process?: { env: Record<string, string | undefined> } }).process?.env.CONTEXT ?? ''

export default defineNuxtConfig({
  compatibilityDate: '2026-11-01',
  devtools: { enabled: false },
  css: ['~/assets/css/main.css'],
  // Komponente se zovu samo po imenu datoteke, bez prefiksa mape.
  components: [{ path: '~/components', pathPrefix: false }],
  vite: {
    plugins: [tailwindcss()],
    // Unaprijed spojeni paketi, da razvojni server ne učitava stranicu ponovno kad ih prvi put otkrije.
    optimizeDeps: {
      include: ['@lucide/vue', '@supabase/supabase-js'],
    },
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
      // Netlifyjev pregled grane ili PR-a (ne produkcija): stranice tada imaju noindex, a robots.txt zabranjuje sve.
      // Netlify sam postavlja CONTEXT pri izgradnji.
      previewDeploy: ['branch-deploy', 'deploy-preview'].includes(NETLIFY_CONTEXT),
    },
  },
  // Keširanje javnih stranica na Netlifyjevom CDN-u (isr = sekunde). Kupac dobiva gotovu stranicu odmah,
  // a Netlify je u pozadini osvježava iz baze. Novi deploy briše sav keš. Adrese s parametrima (filtri) keširaju se zasebno.
  // Košarica, lista želja, pretraga, odjava, /api i admin se ne keširaju, jer ovise o kupcu.
  // Prijava člana tima odlučuje se u pregledniku, pa keš ne miješa kupce i tim.
  routeRules: {
    // Admin radi samo u pregledniku i ne smije u Google.
    '/admin/**': {
      ssr: false,
      headers: { 'X-Robots-Tag': 'noindex, nofollow' },
    },
    // Proizvodi, cijene i zalihe: najviše 2 minute stari podaci.
    '/': { isr: 120 },
    '/proizvodi': { isr: 120 },
    '/kategorija/**': { isr: 120 },
    '/proizvod/**': { isr: 120 },
    // Akcija ima odbrojavanje i stanje (uskoro, u tijeku), pa kraće.
    '/ciscenje-zaliha': { isr: 60 },
    // Tekstualne stranice (kontakt i radno vrijeme dolaze iz postavki): 10 minuta.
    '/o-nama': { isr: 600 },
    '/kontakt': { isr: 600 },
    '/dostava': { isr: 600 },
    '/povrat-i-zamjena': { isr: 600 },
    '/kupovina-u-mostaru': { isr: 600 },
    '/poklon-bon': { isr: 600 },
    '/uvjeti-kupnje': { isr: 600 },
    '/politika-privatnosti': { isr: 600 },
    '/blog': { isr: 600 },
    '/blog/**': { isr: 600 },
    // Sitemap i Merchant feed čitaju cijelu bazu, a Google ih dohvaća rijetko: 1 sat.
    '/sitemap.xml': { isr: 3600 },
    '/merchant-feed.xml': { isr: 3600 },
    // Sažetak trgovine za AI asistente (server/routes/llms.txt.ts).
    '/llms.txt': { isr: 3600 },
  },
})
