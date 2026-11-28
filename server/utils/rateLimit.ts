import type { H3Event } from 'h3'

// Jednostavno ograničenje po IP-u, u memoriji servera. Netlify pokreće više primjeraka funkcije,
// pa je ovo prvi filtar, a pravu granicu za cijelu trgovinu drži baza (migracija 0051). IP se ne sprema u bazu.
const hits = new Map<string, number[]>()

export function clientIp(event: H3Event) {
  return getRequestHeader(event, 'x-nf-client-connection-ip') ?? getRequestIP(event, { xForwardedFor: true }) ?? ''
}

// true = zahtjev smije proći. Pamti se samo zadnjih `windowMs` milisekundi.
export function allowRequest(key: string, limit: number, windowMs: number) {
  const now = Date.now()
  const recent = (hits.get(key) ?? []).filter((time) => now - time < windowMs)
  if (recent.length >= limit) {
    hits.set(key, recent)
    return false
  }
  recent.push(now)
  hits.set(key, recent)

  // Da mapa ne raste bez kraja.
  if (hits.size > 5000) {
    for (const [entry, times] of hits) {
      if (!times.some((time) => now - time < windowMs)) hits.delete(entry)
    }
  }
  return true
}
