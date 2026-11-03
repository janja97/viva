export default defineEventHandler((event) => {
  const { siteName } = useRuntimeConfig(event).public

  setHeader(event, 'content-type', 'application/manifest+json')
  return {
    name: siteName,
    short_name: siteName,
    start_url: '/',
    display: 'browser',
    background_color: '#000000',
    theme_color: '#4a4742',
    icons: [
      { src: '/favicon-192x192.png', sizes: '192x192', type: 'image/png' },
      { src: '/logo/logo-square.png', sizes: '512x512', type: 'image/png' },
    ],
  }
})
