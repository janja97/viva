// Admin se ne blokira ovdje: Google mora moći pročitati njegov noindex.
// Netlifyjev pregled grane (previewDeploy) je duplikat prave trgovine, pa ga Google ne smije pretraživati.
// /api/ nisu stranice, a košarica, lista želja i pretraga imaju vlastiti noindex.
export default defineEventHandler((event) => {
  const { siteUrl, previewDeploy } = useRuntimeConfig(event).public
  const origin = (siteUrl || getRequestURL(event).origin).replace(/\/$/, '')

  setResponseHeader(event, 'Content-Type', 'text/plain; charset=utf-8')
  if (previewDeploy) return 'User-agent: *\nDisallow: /\n'
  return `User-agent: *
Allow: /
Disallow: /api/

Sitemap: ${origin}/sitemap.xml
`
})
