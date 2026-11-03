// Admin se ne blokira ovdje: Google mora moći pročitati njegov noindex.
export default defineEventHandler((event) => {
  const { siteUrl } = useRuntimeConfig(event).public
  const origin = (siteUrl || getRequestURL(event).origin).replace(/\/$/, '')

  setResponseHeader(event, 'Content-Type', 'text/plain; charset=utf-8')
  return `User-agent: *
Allow: /

Sitemap: ${origin}/sitemap.xml
`
})
