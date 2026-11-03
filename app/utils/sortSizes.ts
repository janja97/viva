import { SIZE_PRESETS } from '~/config/products'

const KNOWN_SIZES: string[] = Object.values(SIZE_PRESETS).flat()

// Veličine idu redom kojim se nude pri unosu, a ostale iza njih abecedno.
export function sortSizes(sizes: string[]) {
  return [...sizes].sort((a, b) => {
    const [first, second] = [KNOWN_SIZES.indexOf(a), KNOWN_SIZES.indexOf(b)]
    if (first === -1 || second === -1) return (first === -1 ? 1 : 0) - (second === -1 ? 1 : 0) || a.localeCompare(b, 'hr')
    return first - second
  })
}
