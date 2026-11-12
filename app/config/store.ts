import type { StoreSettings, WeekDay } from '~/types/database'

// Stalni podaci o trgovini (adresa i karta). Telefon, e-mail, mreže, radno vrijeme, poštarinu
// i obavijest na vrhu weba admin mijenja na /admin/postavke (tablica store_settings, migracija 0029).
export const STORE = {
  mall: 'Mepas Mall',
  street: 'Kneza Branimira 2b',
  postalCode: '88000',
  city: 'Mostar',
  countryCode: 'BA',
  country: 'Bosna i Hercegovina',
  mapUrl: 'https://www.google.com/maps/search/?api=1&query=Mepas+Mall+Mostar',
  // Karta u sekciji "Posjetite nas". Ne treba API ključ.
  mapEmbedUrl: 'https://www.google.com/maps?q=Mepas+Mall,+Kneza+Branimira+2b,+88000+Mostar&z=16&output=embed',
}

// Dostava i plaćanje (stranica /dostava i Product JSON-LD). Cijena poštarine je u postavkama trgovine.
export const DELIVERY = {
  // Šalje se samo unutar BiH.
  countryCode: 'BA',
  minDays: 3,
  maxDays: 5,
  // Online plaćanja nema: kupac plaća kuriru pri preuzimanju (pouzećem).
  payment: 'pouzećem',
}

// Zamjena (stranica /povrat-i-zamjena i Product JSON-LD). Povrata novca nema, samo zamjena.
export const EXCHANGE = {
  days: 15,
}

export const WEEK_DAYS: { value: WeekDay; label: string; short: string }[] = [
  { value: 'Monday', label: 'Ponedjeljak', short: 'Pon' },
  { value: 'Tuesday', label: 'Utorak', short: 'Uto' },
  { value: 'Wednesday', label: 'Srijeda', short: 'Sri' },
  { value: 'Thursday', label: 'Četvrtak', short: 'Čet' },
  { value: 'Friday', label: 'Petak', short: 'Pet' },
  { value: 'Saturday', label: 'Subota', short: 'Sub' },
  { value: 'Sunday', label: 'Nedjelja', short: 'Ned' },
]

// Rezerva dok se postavke ne učitaju ili ako baza ne odgovori. Iste vrijednosti upisuje migracija 0029.
export const DEFAULT_STORE_SETTINGS: StoreSettings = {
  id: true,
  phone: '',
  whatsapp: '',
  viber: '',
  email: '',
  instagram_url: '',
  facebook_url: '',
  tiktok_url: '',
  opening_hours: WEEK_DAYS.map(({ value }) => ({
    day: value,
    closed: false,
    opens: value === 'Sunday' ? '12:00' : '09:00',
    closes: value === 'Sunday' ? '20:00' : '21:00',
  })),
  shipping_price: 9,
  free_shipping_above: 150,
  announcement_enabled: false,
  announcement_text: '',
  // Rezerva je obrazac na webu, kako bi narudžbe radile i prije migracije 0035.
  order_channel: 'web',
  updated_at: '',
  updated_by_email: null,
}

// Poštarina je besplatna za narudžbe veće od praga. Isto pravilo ima shipping_for u bazi.
export const shippingFor = (subtotal: number, settings: Pick<StoreSettings, 'shipping_price' | 'free_shipping_above'>) =>
  (subtotal > Number(settings.free_shipping_above) ? 0 : Number(settings.shipping_price))
