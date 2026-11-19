// Supabase (PostgREST) vraća najviše 1000 redaka po upitu. Ovo čita stranicu po stranicu dok ne pročita sve,
// npr. sve proizvode za sitemap ili sve pretplatnike. Radi i u pregledniku i na serveru (mapa shared/).
//
// Upit mora imati stalan redoslijed (npr. .order('id')), inače se retci na granici stranica mogu ponoviti ili preskočiti.
// Primjer: fetchAllRows((from, to) => supabase.from('products').select('id').order('id').range(from, to))
export const SUPABASE_PAGE_SIZE = 1000

type PageResult<T> = PromiseLike<{ data: T[] | null; error: unknown }>

export async function fetchAllRows<T>(page: (from: number, to: number) => PageResult<T>, pageSize = SUPABASE_PAGE_SIZE): Promise<T[]> {
  const rows: T[] = []
  for (let from = 0; ; from += pageSize) {
    const { data, error } = await page(from, from + pageSize - 1)
    if (error) throw error
    rows.push(...(data ?? []))
    if (!data || data.length < pageSize) return rows
  }
}

// Popis id-eva u filtru .in() ide u adresu zahtjeva, koja ima ograničenu duljinu.
// Za skupne radnje nad mnogo proizvoda popis se dijeli u manje dijelove.
export const IN_FILTER_CHUNK = 150

export function chunkList<T>(items: T[], size = IN_FILTER_CHUNK): T[][] {
  const chunks: T[][] = []
  for (let index = 0; index < items.length; index += size) chunks.push(items.slice(index, index + size))
  return chunks
}
