// Isti izračun radi i baza (stupac sale_price), a ovo služi za prikaz dok se proizvod uređuje.
export function discountedPrice(price: number, percent: number) {
  return Math.round(price * (100 - percent)) / 100
}
