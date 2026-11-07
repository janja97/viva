import { BAG_SIZES } from '~/config/products'

const NAMED_SIZES = ['XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL', ...BAG_SIZES.map((size) => size.toUpperCase())]

// Slovne veličine (i veličine torbica) idu prve, zatim brojevi po vrijednosti, a ostalo abecedno na kraju.
// Ne ovisi o ponuđenim veličinama, pa i ručno upisane (npr. 44 ili XS) dolaze na pravo mjesto.
function sizeRank(size: string) {
  const letter = NAMED_SIZES.indexOf(size.trim().toUpperCase())
  if (letter !== -1) return letter
  const number = Number(size.replace(',', '.'))
  return size.trim() && Number.isFinite(number) ? NAMED_SIZES.length + number : Number.POSITIVE_INFINITY
}

export function sortSizes(sizes: string[]) {
  return [...sizes].sort((a, b) => {
    const [first, second] = [sizeRank(a), sizeRank(b)]
    return first === second ? a.localeCompare(b, 'hr') : first < second ? -1 : 1
  })
}
