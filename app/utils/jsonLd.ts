import { STORE } from '~/config/store'

// Podaci o trgovini za Google. Telefon i radno vrijeme ulaze tek kad su upisani.
export function storeJsonLd(name: string, url: string) {
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
    openingHoursSpecification: STORE.openingHours.map(({ days, opens, closes }) => ({
      '@type': 'OpeningHoursSpecification',
      dayOfWeek: days.map((day) => `https://schema.org/${day}`),
      opens,
      closes,
    })),
    ...(STORE.phone && { telephone: STORE.phone }),
    ...(STORE.email && { email: STORE.email }),
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
