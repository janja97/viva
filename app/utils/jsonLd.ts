import { COMPANY, STORE } from '~/config/store'
import type { StoreSettings } from '~/types/database'

// Stalna oznaka trgovine u JSON-LD-u. Proizvodi je navode kao prodavatelja, pa Google zna da je to ista trgovina.
export const storeJsonLdId = (url: string) => `${url}/#store`

// Podaci o trgovini za Google. Telefon, e-mail i mreže ulaze tek kad su upisani u postavkama, a zatvoreni dani se izostavljaju.
// Koordinate, raspon cijena i fotografija ulaze tek kad su upisani u STORE.
export function storeJsonLd(name: string, url: string, settings: StoreSettings) {
  const social = [settings.instagram_url, settings.facebook_url].filter(Boolean)
  return {
    '@context': 'https://schema.org',
    '@type': 'ClothingStore',
    '@id': storeJsonLdId(url),
    name,
    url,
    logo: `${url}/logo/logo-square.png`,
    image: STORE.photo ? `${url}${STORE.photo}` : `${url}/logo/logo-square.png`,
    ...(STORE.priceRange && { priceRange: STORE.priceRange }),
    ...(STORE.geo && { geo: { '@type': 'GeoCoordinates', ...STORE.geo } }),
    // Trgovina je unutar trgovačkog centra (Google ga tako povezuje i na karti).
    containedInPlace: {
      '@type': 'ShoppingCenter',
      name: STORE.mall,
      address: {
        '@type': 'PostalAddress',
        streetAddress: STORE.street,
        postalCode: STORE.postalCode,
        addressLocality: STORE.city,
        addressCountry: STORE.countryCode,
      },
    },
    // Ponuda je samo za žene.
    audience: { '@type': 'PeopleAudience', suggestedGender: 'female' },
    description: `Butik svečane mode u Mostaru, ${STORE.mall}: svečane i maturalne haljine, haljine za svadbu, ženska odijela, štikle, čizme, torbe i nakit od nehrđajućeg čelika.`,
    currenciesAccepted: 'BAM',
    paymentAccepted: 'Gotovina, kartica, plaćanje na rate',
    // Kupci su iz BiH i iz cijele Hrvatske (dolaze u trgovinu; online narudžbe idu samo u BiH).
    areaServed: [
      { '@type': 'Country', name: 'Bosna i Hercegovina' },
      { '@type': 'Country', name: 'Hrvatska' },
    ],
    legalName: COMPANY.name,
    ...(COMPANY.jib && { taxID: COMPANY.jib }),
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
    // Mreže i Google profil trgovine, da Google poveže web s profilom.
    sameAs: [...social, STORE.businessProfileUrl],
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
