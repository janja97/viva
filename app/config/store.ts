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
  // Upiši punu adresu profila, npr. { label: 'Instagram', url: 'https://...' }.
  social: [] as { label: string; url: string }[],
  mapUrl: 'https://www.google.com/maps/search/?api=1&query=Mepas+Mall+Mostar',
}

// Poštarina u KM. Isto pravilo provodi baza u shop_submit_inquiry (migracija 0019), pa ga mijenjaj na oba mjesta.
export const SHIPPING = {
  price: 9,
  // Besplatna je za narudžbe veće od ovog iznosa.
  freeAbove: 150,
}

export const shippingFor = (subtotal: number) => (subtotal > SHIPPING.freeAbove ? 0 : SHIPPING.price)
