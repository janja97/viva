export function productErrorMessage(error: unknown) {
  const { code, message, statusCode } = (error ?? {}) as {
    code?: string
    message?: string
    statusCode?: string
  }

  if (code === '23505') {
    if (message?.includes('products_sku_key')) return 'Proizvod s tom šifrom već postoji.'
    if (message?.includes('product_colors_slug_key')) return 'Taj URL već koristi druga boja ili proizvod. Upiši drugi.'
    if (message?.includes('product_colors_product_id_name_key')) return 'Dvije boje ne mogu imati isti naziv.'
  }
  if (code === '23514' && message?.includes('products_archived_hidden_check')) {
    return 'Arhivirani proizvod ne može biti vidljiv na webu. Prvo ga vrati iz arhive.'
  }
  if (code === '23514') return 'Neki podatak nije ispravan. Provjeri nazive, cijenu, količine i URL.'
  if (code === '42501' || code === 'PGRST116' || statusCode === '403') return 'Nemaš ovlasti za ovu radnju.'
  // Poruke iz baze i provjere slika već su napisane za korisnika.
  if ((code === 'P0001' || code === 'image') && message) return message

  console.error(error)
  return 'Nešto je pošlo po zlu. Pokušaj ponovno.'
}
