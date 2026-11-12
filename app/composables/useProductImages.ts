import { IMAGE_EXTENSIONS, MAX_IMAGE_BYTES, MAX_SOURCE_IMAGE_BYTES, PRODUCT_IMAGES_BUCKET } from '~/config/products'
import type { ImageForm } from '~/types/productForm'

// Slike se šalju odmah pri odabiru, a brišu tek kad je proizvod spremljen.
// Ako korisnik odustane, nove slike se uklanjaju, a stare ostaju.
export function useProductImages(productId: string) {
  const storage = useSupabase().storage.from(PRODUCT_IMAGES_BUCKET)

  const newPaths = new Set<string>()
  const removedPaths: string[] = []

  const urlFor = (path: string) => storage.getPublicUrl(path).data.publicUrl

  // Slika se prije slanja smanjuje i pretvara u WebP (optimizeImage). Ime datoteke je opisno, npr.
  // aurora-crna-svecana-haljina-1a2b3c4d.webp, jer i ime slike pomaže Google pretrazi slika.
  async function upload(colorId: string, file: File, baseName = ''): Promise<ImageForm> {
    if (!IMAGE_EXTENSIONS[file.type]) {
      throw Object.assign(new Error('Dopuštene su slike JPG, PNG, WEBP i AVIF.'), { code: 'image' })
    }
    if (file.size > MAX_SOURCE_IMAGE_BYTES) {
      throw Object.assign(new Error('Slika može imati najviše 25 MB.'), { code: 'image' })
    }

    const { blob, type } = await optimizeImage(file)
    if (blob.size > MAX_IMAGE_BYTES) {
      throw Object.assign(new Error('Slika je i nakon smanjivanja veća od 5 MB. Pokušaj s manjom.'), { code: 'image' })
    }

    const id = crypto.randomUUID()
    const name = slugify(baseName).slice(0, 80)
    const path = `${productId}/${colorId}/${name ? `${name}-` : ''}${id.slice(0, 8)}.${IMAGE_EXTENSIONS[type]}`
    const { error } = await storage.upload(path, blob, { cacheControl: '31536000', contentType: type })
    if (error) throw error

    newPaths.add(path)
    return { id, path, alt: '' }
  }

  function discard(path: string) {
    if (newPaths.delete(path)) storage.remove([path])
    else removedPaths.push(path)
  }

  // Poziva se nakon uspješnog spremanja proizvoda.
  async function commit() {
    newPaths.clear()
    if (removedPaths.length) await storage.remove(removedPaths.splice(0))
  }

  function rollback() {
    if (newPaths.size) storage.remove([...newPaths])
    newPaths.clear()
  }

  return { urlFor, upload, discard, commit, rollback }
}

export type ProductImagesApi = ReturnType<typeof useProductImages>
