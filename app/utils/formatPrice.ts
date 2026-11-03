const numberFormat = new Intl.NumberFormat('hr-HR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })

// Valuta shopa je konvertibilna marka. Oznaka za Google je BAM (`CURRENCY_CODE`).
export function formatPrice(price: number) {
  return `${numberFormat.format(price)} KM`
}
