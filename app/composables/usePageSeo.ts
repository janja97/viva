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
  const url = `${origin}${useRoute().path}`

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
