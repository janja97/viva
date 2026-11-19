// Bilježi dolazak na web jednom po kartici preglednika (migracija 0046, server/api/visit.post.ts).
// Šalje prvu stranicu, stranicu s koje je kupac došao i oznake kampanje (utm_*). Admin se ne broji.
// Nikad ne smeta kupcu: greške se samo ispisuju u konzolu.
const SENT_KEY = 'viva-posjet'

export default defineNuxtPlugin((nuxtApp) => {
  nuxtApp.hook('app:mounted', async () => {
    const route = useRoute()
    if (route.path.startsWith('/admin')) return

    try {
      if (sessionStorage.getItem(SENT_KEY)) return
      sessionStorage.setItem(SENT_KEY, '1')
    } catch {
      // Bez sessionStorage šalje se svaki put, a baza sama spaja dolaske unutar 30 minuta.
    }

    const query = (name: string) => (typeof route.query[name] === 'string' ? route.query[name] : '')
    const clickId = ['gclid', 'fbclid'].find((name) => route.query[name] !== undefined) ?? ''

    try {
      // Prijavljeni član tima šalje token, da ga baza ne broji među kupcima.
      const { data } = await useSupabase().auth.getSession()
      const token = data.session?.access_token
      await $fetch('/api/visit', {
        method: 'POST',
        headers: token ? { Authorization: `Bearer ${token}` } : undefined,
        body: {
          session: useShopSession().sessionId(),
          path: route.path,
          referrer: document.referrer,
          utmSource: query('utm_source'),
          utmMedium: query('utm_medium'),
          utmCampaign: query('utm_campaign'),
          clickId,
        },
      })
    } catch (error) {
      console.error(error)
    }
  })
})
