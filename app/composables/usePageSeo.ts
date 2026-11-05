interface PageSeo {
  title: string
  description?: string
  image?: string
  noindex?: boolean
}

// Svaka stranica poziva ovo kako bi imala naslov, opis, canonical i Open Graph.
// Bez vlastite slike, link podijeljen na mrežama prikazuje logo.
export function usePageSeo({ title, description, image, noindex = false }: PageSeo) {
  const { siteName, siteUrl } = useRuntimeConfig().public
  const origin = (siteUrl || useRequestURL().origin).replace(/\/$/, '')
  const route = useRoute()
  // Ostali parametri (filtri, poredak) ne ulaze u canonical, ali stranica popisa ulazi,
  // inače Google ne bi indeksirao proizvode s druge i daljnjih stranica.
  // Računa se iznova jer popis mijenja stranicu bez novog učitavanja.
  const url = computed(() => {
    const pageNumber = Math.floor(Number(route.query.stranica))
    return `${origin}${route.path}${pageNumber > 1 ? `?stranica=${pageNumber}` : ''}`
  })

  useSeoMeta({
    title,
    description,
    robots: noindex ? 'noindex, nofollow' : 'index, follow',
    ogTitle: title,
    ogDescription: description,
    ogImage: image ?? `${origin}/logo/og-image.png`,
    ogType: 'website',
    ogUrl: url,
    ogSiteName: siteName,
    ogLocale: 'hr_BA',
    twitterCard: 'summary_large_image',
  })

  useHead({ link: [{ rel: 'canonical', href: url }] })
}
