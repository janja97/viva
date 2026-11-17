interface PageSeo {
  title: string
  description?: string
  image?: string
  imageAlt?: string
  // Vrsta za Open Graph: proizvod, članak ili obična stranica.
  type?: 'website' | 'product' | 'article'
  // Samo za proizvod: cijena za Facebook i Pinterest (product:price).
  price?: { amount: number; currency: string }
  noindex?: boolean
}

// Svaka stranica poziva ovo kako bi imala naslov, opis, canonical i Open Graph.
// Bez vlastite slike, link podijeljen na mrežama prikazuje logo.
// Netlifyjev pregled grane (previewDeploy) nikad ne ide u Google, jer bi bio duplikat prave trgovine.
export function usePageSeo({ title, description, image, imageAlt, type = 'website', price, noindex = false }: PageSeo) {
  const { siteName, siteUrl, previewDeploy } = useRuntimeConfig().public
  const origin = (siteUrl || useRequestURL().origin).replace(/\/$/, '')
  const route = useRoute()
  // Ostali parametri (filtri, poredak) ne ulaze u canonical, ali stranica popisa ulazi,
  // inače Google ne bi indeksirao proizvode s druge i daljnjih stranica.
  // Računa se iznova jer popis mijenja stranicu bez novog učitavanja.
  const url = computed(() => {
    const pageNumber = Math.floor(Number(route.query.stranica))
    return `${origin}${route.path}${pageNumber > 1 ? `?stranica=${pageNumber}` : ''}`
  })
  const hidden = noindex || Boolean(previewDeploy)

  useSeoMeta({
    title,
    description,
    robots: hidden ? 'noindex, nofollow' : 'index, follow, max-image-preview:large',
    ogTitle: title,
    ogDescription: description,
    ogImage: image ?? `${origin}/logo/og-image.png`,
    ogImageAlt: imageAlt ?? title,
    ogType: type === 'product' ? 'website' : type,
    ogUrl: url,
    ogSiteName: siteName,
    ogLocale: 'hr_BA',
    twitterCard: 'summary_large_image',
  })

  useHead({
    link: [{ rel: 'canonical', href: url }],
    // Open Graph za proizvod (og:type product i cijena). useSeoMeta ne poznaje product:*, pa idu ovako.
    meta: type === 'product'
      ? [
          { key: 'og:type', property: 'og:type', content: 'product' },
          ...(price
            ? [
                { property: 'product:price:amount', content: price.amount.toFixed(2) },
                { property: 'product:price:currency', content: price.currency },
              ]
            : []),
        ]
      : [],
  })
}
