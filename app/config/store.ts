// Podaci o trgovini za web i Google. Prazna polja se ne prikazuju.
export const STORE = {
  mall: 'Mepas Mall',
  street: 'Kneza Branimira 2b',
  postalCode: '88000',
  city: 'Mostar',
  countryCode: 'BA',
  country: 'Bosna i Hercegovina',
  phone: '',
  email: '',
  hours: 'Pon – Sub 09:00 – 21:00 · Ned 12:00 – 20:00',
  // Isto radno vrijeme za Google. Mijenjaj ga zajedno s `hours`.
  openingHours: [
    { days: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'], opens: '09:00', closes: '21:00' },
    { days: ['Sunday'], opens: '12:00', closes: '20:00' },
  ],
  // Upiši punu adresu profila, npr. { label: 'Instagram', url: 'https://...' }.
  social: [] as { label: string; url: string }[],
  mapUrl: 'https://www.google.com/maps/search/?api=1&query=Mepas+Mall+Mostar',
  // Karta u sekciji "Posjetite nas". Ne treba API ključ.
  mapEmbedUrl: 'https://www.google.com/maps?q=Mepas+Mall,+Kneza+Branimira+2b,+88000+Mostar&z=16&output=embed',
}

// Poštarina u KM. Isto pravilo provodi baza u shop_submit_inquiry (migracija 0019), pa ga mijenjaj na oba mjesta.
export const SHIPPING = {
  price: 9,
  // Besplatna je za narudžbe veće od ovog iznosa.
  freeAbove: 150,
}

export const shippingFor = (subtotal: number) => (subtotal > SHIPPING.freeAbove ? 0 : SHIPPING.price)
