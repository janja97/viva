import type { Category } from '~/types/database'

export type CategoryInput = Pick<Category, 'name' | 'slug' | 'parent_id' | 'description' | 'is_active' | 'meta_title' | 'meta_description' | 'seo_text' | 'faq'>

export function useCategories() {
  const supabase = useSupabase()

  const categories = ref<Category[]>([])
  const isLoading = ref(true)
  const loadError = ref('')

  const siblingsOf = (parentId: string | null) =>
    categories.value.filter((category) => category.parent_id === parentId)

  const tree = computed(() =>
    siblingsOf(null).map((main) => ({
      ...main,
      children: siblingsOf(main.id).map((child) => ({ ...child, children: siblingsOf(child.id) })),
    })),
  )

  function nextSortOrder(parentId: string | null) {
    return Math.max(0, ...siblingsOf(parentId).map((category) => category.sort_order)) + 1
  }

  async function load() {
    isLoading.value = true
    loadError.value = ''
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .order('sort_order')
      .order('name')
    if (error) loadError.value = categoryErrorMessage(error)
    else categories.value = data
    isLoading.value = false
  }

  async function save(input: CategoryInput, existing?: Category | null) {
    const moved = !existing || existing.parent_id !== input.parent_id
    const payload = moved ? { ...input, sort_order: nextSortOrder(input.parent_id) } : input

    const query = existing
      ? supabase.from('categories').update(payload).eq('id', existing.id)
      : supabase.from('categories').insert(payload)
    const { error } = await query.select('id').single()
    if (error) throw error
    await load()
  }

  async function remove(id: string) {
    const { error } = await supabase.from('categories').delete().eq('id', id).select('id').single()
    if (error) throw error
    await load()
  }

  // Zamjenjuje mjesto sa susjedom i pritom popravlja jednake redoslijede.
  async function move(category: Category, direction: -1 | 1) {
    const siblings = siblingsOf(category.parent_id)
    const index = siblings.findIndex((sibling) => sibling.id === category.id)
    const neighbour = siblings[index + direction]
    if (!neighbour) return

    const results = await Promise.all([
      supabase.from('categories').update({ sort_order: index + direction + 1 }).eq('id', category.id),
      supabase.from('categories').update({ sort_order: index + 1 }).eq('id', neighbour.id),
    ])
    const failed = results.find((result) => result.error)
    await load()
    if (failed) throw failed.error
  }

  return { categories, tree, isLoading, loadError, load, save, remove, move }
}
