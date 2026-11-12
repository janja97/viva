// Upozorenje za sliku proizvoda prije slanja. Slika se svejedno doda, a tim odlučuje hoće li je zamijeniti.
// Galerija proizvoda prikazuje slike uspravno (4 : 5, glavna do 1000 × 1250 px), pa je za oštar
// prikaz i na mobitelima s gustim ekranom potrebno barem 1200 px po dužoj strani.
export const RECOMMENDED_IMAGE = { width: 1200, height: 1500 }
const MIN_SHORT_EDGE = 800
const MIN_LONG_EDGE = 1200
// Ispod ovoga je slika obično jako sažeta i mutna, čak i kad ima dovoljno piksela.
const MIN_BYTES_PER_MEGAPIXEL = 60_000

export async function imageQualityWarnings(file: File): Promise<string[]> {
  let width = 0
  let height = 0
  try {
    const bitmap = await createImageBitmap(file)
    width = bitmap.width
    height = bitmap.height
    bitmap.close()
  } catch {
    return []
  }

  const warnings: string[] = []
  const size = `${width} × ${height} px`
  if (Math.min(width, height) < MIN_SHORT_EDGE || Math.max(width, height) < MIN_LONG_EDGE) {
    warnings.push(`mala rezolucija (${size}), na webu može biti mutna. Preporuka je barem ${RECOMMENDED_IMAGE.width} × ${RECOMMENDED_IMAGE.height} px.`)
  }
  if (width > height * 1.05) {
    warnings.push(`vodoravna slika (${size}). Na webu se prikazuje uspravno, pa će lijevi i desni rub biti odrezani.`)
  }
  const megapixels = (width * height) / 1_000_000
  if (megapixels > 0 && file.size / megapixels < MIN_BYTES_PER_MEGAPIXEL) {
    warnings.push('slika je jako sažeta i može izgledati mutno ili zrnato.')
  }
  return warnings
}
