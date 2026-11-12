// Slika proizvoda prije slanja: duža stranica najviše MAX_IMAGE_EDGE px i WebP kvalitete 0,82.
// Tako se na mobitelu učitava i do deset puta manje podataka, a Google brzinu računa u poredak.
// Ako preglednik ne zna napraviti WebP ili bi rezultat bio veći, šalje se original.
export const MAX_IMAGE_EDGE = 1600
const WEBP_QUALITY = 0.82

export async function optimizeImage(file: File): Promise<{ blob: Blob; type: string }> {
  try {
    const bitmap = await createImageBitmap(file)
    const scale = Math.min(1, MAX_IMAGE_EDGE / Math.max(bitmap.width, bitmap.height))
    const canvas = document.createElement('canvas')
    canvas.width = Math.round(bitmap.width * scale)
    canvas.height = Math.round(bitmap.height * scale)
    const context = canvas.getContext('2d')
    if (!context) return { blob: file, type: file.type }
    context.drawImage(bitmap, 0, 0, canvas.width, canvas.height)
    bitmap.close()

    const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, 'image/webp', WEBP_QUALITY))
    if (!blob || blob.type !== 'image/webp' || blob.size >= file.size) return { blob: file, type: file.type }
    return { blob, type: 'image/webp' }
  } catch {
    return { blob: file, type: file.type }
  }
}
