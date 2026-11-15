// Naziv boje koji kupac vidi: osnovna boja i neobavezna oznaka, npr. "Crna pliš" (migracija 0040).
// Isto pravilo upisuje se u product_colors.name pri spremanju proizvoda.
export function colorTitle(color: { name: string; label?: string | null }) {
  return [color.name.trim(), color.label?.trim()].filter(Boolean).join(' ')
}
