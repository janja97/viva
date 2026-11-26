import type { StoreSettings, WeekDay } from '~/types/database'

// Stalni podaci o trgovini (adresa i karta). Telefon, e-mail, mreže, radno vrijeme, poštarinu
// i obavijest na vrhu weba admin mijenja na /admin/postavke (tablica store_settings, migracija 0029).
export const STORE = {
  mall: 'Mepas Mall',
  floor: '3. kat',
  street: 'Kardinala Stepinca bb',
  postalCode: '88000',
  city: 'Mostar',
  countryCode: 'BA',
  country: 'Bosna i Hercegovina',
  mapUrl: 'https://www.google.com/maps/search/?api=1&query=Mepas+Mall+Mostar',
  // Google profil tvrtke (Google Business Profile, oznaka /g/11f5v9ncbl iz Googleove pretrage "viva mostar").
  // Otvara se klikom na kartu (StoreMap) i ide u JSON-LD kao sameAs.
  businessProfileUrl: 'https://www.google.com/search?kgmid=/g/11f5v9ncbl',
  // Karta u sekciji "Posjetite nas". Ne treba API ključ.
  mapEmbedUrl: 'https://www.google.com/maps?q=Mepas+Mall,+Kneza+Branimira+2b,+88000+Mostar&z=16&output=embed',
  // Za Google (ClothingStore JSON-LD). Prazno se ne šalje. Ne izmišljati: koordinate se kopiraju iz Google karte
  // (desni klik na trgovinu), raspon cijena i fotografiju potvrđuje vlasnica.
  geo: null as { latitude: number; longitude: number } | null,
  // Potvrdila vlasnica (studeni 2026.).
  priceRange: '20–600 KM',
  // Fotografija trgovine ili izloga u public/, npr. '/images/trgovina.webp'. Bez nje se šalje logo.
  photo: '',
}

// Tvrtka koja vodi trgovinu (Politika privatnosti, Uvjeti kupnje, podnožje).
// JIB i PDV broj još nisu upisani; prazna polja se ne prikazuju.
export const COMPANY = {
  name: 'Silver Trend d.o.o.',
  seat: 'Mepas Mall, Kardinala Stepinca bb, 88000 Mostar',
  country: 'Bosna i Hercegovina',
  jib: '',
  vatNumber: '',
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

// Način preuzimanja online narudžbe (migracija 0048). Preuzimanje u trgovini je bez poštarine.
// Vrijednosti moraju odgovarati provjeri inquiries.delivery_method u bazi.
// Preuzimanje u Sarajevu je maknuto iz košarice (studeni 2026., na zahtjev vlasnice), ali stare narudžbe ga mogu imati,
// pa naziv ostaje u DELIVERY_METHOD_LABELS. Za povratak dodaj redak u DELIVERY_METHODS (baza ga i dalje prihvaća).
export type DeliveryMethod = 'delivery' | 'pickup_mostar' | 'pickup_sarajevo'
const DELIVERY_METHOD_LABELS: Record<DeliveryMethod, string> = {
  delivery: 'Dostava na adresu',
  pickup_mostar: 'Preuzimanje u Mostaru',
  pickup_sarajevo: 'Preuzimanje u Sarajevu',
}
// Opis dostave na adresu ovisi o poštarini, pa ga slaže CartDeliveryPicker.
export const DELIVERY_METHODS: { value: DeliveryMethod; label: string; hint: string }[] = [
  { value: 'delivery', label: DELIVERY_METHOD_LABELS.delivery, hint: 'Po cijeloj BiH, plaćanje pouzećem' },
  { value: 'pickup_mostar', label: DELIVERY_METHOD_LABELS.pickup_mostar, hint: 'Mepas Mall, 3. kat, bez poštarine' },
]
export const deliveryMethodLabel = (value: DeliveryMethod | null | undefined) => DELIVERY_METHOD_LABELS[value ?? 'delivery'] ?? DELIVERY_METHOD_LABELS.delivery

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
