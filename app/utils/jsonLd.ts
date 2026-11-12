import { STORE } from '~/config/store'
import type { StoreSettings } from '~/types/database'

// Podaci o trgovini za Google. Telefon, e-mail i mreže ulaze tek kad su upisani u postavkama, a zatvoreni dani se izostavljaju.
export function storeJsonLd(name: string, url: string, settings: StoreSettings) {
  const social = [settings.instagram_url, settings.facebook_url].filter(Boolean)
  return {
    '@context': 'https://schema.org',
    '@type': 'ClothingStore',
    name,
    url,
    logo: `${url}/logo/logo-square.png`,
    image: `${url}/logo/logo-square.png`,
    description: `Luksuzna svečana moda u Mostaru, ${STORE.mall}.`,
    currenciesAccepted: 'BAM',
    address: {
      '@type': 'PostalAddress',
      streetAddress: [STORE.mall, STORE.street].filter(Boolean).join(', '),
      postalCode: STORE.postalCode,
      addressLocality: STORE.city,
      addressCountry: STORE.countryCode,
    },
    hasMap: STORE.mapUrl,
    openingHoursSpecification: settings.opening_hours.filter((day) => !day.closed).map(({ day, opens, closes }) => ({
      '@type': 'OpeningHoursSpecification',
      dayOfWeek: `https://schema.org/${day}`,
      opens,
      closes,
    })),
    ...(settings.phone && { telephone: settings.phone }),
    ...(settings.email && { email: settings.email }),
    ...(social.length && { sameAs: social }),
  }
}

export function breadcrumbJsonLd(items: { name: string; url: string }[]) {
  return {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: items.map((item, index) => ({
      '@type': 'ListItem',
      position: index + 1,
      name: item.name,
      item: item.url,
    })),
  }
}
