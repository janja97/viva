import { PRODUCT_IMAGES_BUCKET } from '~/config/products'
import type { BlogPost, BlogPostInput } from '~/types/database'

export type BlogCard = Pick<BlogPost, 'slug' | 'title' | 'excerpt' | 'cover_path' | 'cover_alt' | 'published_at'>

// Javni URL naslovne slike (spremište product-images, mapa blog/).
export function useBlogImage() {
  const storage = useSupabase().storage.from(PRODUCT_IMAGES_BUCKET)
  return (path: string | null) => (path ? storage.getPublicUrl(path).data.publicUrl : null)
}

export const blogDate = (iso: string | null) =>
  (iso ? new Intl.DateTimeFormat('hr-HR', { dateStyle: 'long', timeZone: 'Europe/Sarajevo' }).format(new Date(iso)) : '')

// Javni dio bloga (SSR). RLS kupcima vraća samo objavljene članke.
export function useBlog() {
  const supabase = useSupabase()

  async function fetchPosts() {
    const { data, error } = await supabase
      .from('blog_posts')
      .select('slug, title, excerpt, cover_path, cover_alt, published_at')
      .eq('is_published', true)
      .order('published_at', { ascending: false })
    if (error) throw error
    return data as BlogCard[]
  }

  async function fetchPost(slug: string) {
    const { data, error } = await supabase.from('blog_posts').select('*').eq('slug', slug).eq('is_published', true).maybeSingle()
    if (error) throw error
    return data
  }

  return { fetchPosts, fetchPost }
}

// Admin (/admin/blog). Pišu i objavljuju admin i super admin (RLS, migracija 0037).
export function useBlogAdmin() {
  const supabase = useSupabase()
  const storage = supabase.storage.from(PRODUCT_IMAGES_BUCKET)

  const posts = ref<BlogPost[]>([])
  const isLoading = ref(true)
  const loadError = ref('')

  async function load() {
    isLoading.value = true
    loadError.value = ''
    const { data, error } = await supabase.from('blog_posts').select('*').order('created_at', { ascending: false })
    isLoading.value = false
    if (error) {
      loadError.value = productErrorMessage(error)
      return
    }
    posts.value = data
  }

  async function save(input: BlogPostInput, id?: string) {
    const query = id
      ? supabase.from('blog_posts').update(input).eq('id', id)
      : supabase.from('blog_posts').insert(input)
    const { error } = await query.select('id').single()
    if (error) throw error
    await load()
  }

  async function remove(post: BlogPost) {
    const { error } = await supabase.from('blog_posts').delete().eq('id', post.id).select('id').single()
    if (error) throw error
    if (post.cover_path) await storage.remove([post.cover_path])
    await load()
  }

  // Naslovna slika se smanjuje i pretvara u WebP kao i slike proizvoda.
  async function uploadCover(file: File, slug: string) {
    const { blob, type } = await optimizeImage(file)
    const extension = type === 'image/webp' ? 'webp' : (file.name.split('.').pop() ?? 'jpg')
    const path = `blog/${slugify(slug) || 'clanak'}-${crypto.randomUUID().slice(0, 8)}.${extension}`
    const { error } = await storage.upload(path, blob, { cacheControl: '31536000', contentType: type })
    if (error) throw error
    return path
  }

  async function removeCover(path: string) {
    await storage.remove([path])
  }

  return { posts, isLoading, loadError, load, save, remove, uploadCover, removeCover }
}
