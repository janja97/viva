export const MAX_CATEGORY_DEPTH = 3

type TreeItem = { id: string; parent_id: string | null }

export function childrenOf<T extends TreeItem>(categories: T[], id: string) {
  return categories.filter((category) => category.parent_id === id)
}

export function descendantIds<T extends TreeItem>(categories: T[], id: string): string[] {
  return childrenOf(categories, id).flatMap((child) => [child.id, ...descendantIds(categories, child.id)])
}

// Od glavne kategorije do tražene, uključujući nju.
export function categoryPath<T extends TreeItem>(categories: T[], id: string): T[] {
  const category = categories.find((item) => item.id === id)
  if (!category) return []
  return [...(category.parent_id ? categoryPath(categories, category.parent_id) : []), category]
}

// Broj razina ispod kategorije.
export function categoryHeight<T extends TreeItem>(categories: T[], id: string): number {
  return Math.max(0, ...childrenOf(categories, id).map((child) => 1 + categoryHeight(categories, child.id)))
}

// Stablo za popise, s nazivom "Obuća / Sandale / Ravne sandale".
export function categoryOptions<T extends TreeItem & { name: string; is_active: boolean }>(categories: T[]) {
  const walk = (parentId: string | null, prefix: string): { value: string; label: string }[] =>
    categories
      .filter((category) => category.parent_id === parentId)
      .flatMap((category) => {
        const label = `${prefix}${category.name}`
        return [
          { value: category.id, label: category.is_active ? label : `${label} (neaktivna)` },
          ...walk(category.id, `${label} / `),
        ]
      })
  return walk(null, '')
}
