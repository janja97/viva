import { createClient } from '@supabase/supabase-js'

// Bilježi dolazak na web (migracija 0046): izvor, kampanju, državu i grad, uređaj i prvu stranicu.
// Javna ruta bez tajnog ključa: zove samo shop_track_visit s javnim ključem, a baza sama odbacuje ponavljanja.
// Državu i grad daje Netlify u zaglavlju x-nf-geo (lokalno ih nema). IP adresa se ne sprema.
// Prijavljeni član tima šalje svoj token, pa ga baza označi (is_team) i ne ulazi u statistiku.

type Body = {
  session?: unknown
  path?: unknown
  referrer?: unknown
  utmSource?: unknown
  utmMedium?: unknown
  utmCampaign?: unknown
  clickId?: unknown
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
const BOT = /bot|crawl|spider|slurp|preview|lighthouse|headless|facebookexternalhit|whatsapp\//i

const SEARCH = [/(^|\.)google\./, /(^|\.)bing\.com$/, /(^|\.)yahoo\./, /(^|\.)duckduckgo\.com$/, /(^|\.)yandex\./, /(^|\.)ecosia\.org$/]
const SOCIAL: [RegExp, string][] = [
  [/(^|\.)instagram\.com$/, 'instagram'],
  [/(^|\.)(facebook\.com|fb\.me|fb\.com)$/, 'facebook'],
  [/(^|\.)(t\.co|twitter\.com|x\.com)$/, 'x'],
  [/(^|\.)tiktok\.com$/, 'tiktok'],
  [/(^|\.)pinterest\./, 'pinterest'],
  [/(^|\.)(youtube\.com|youtu\.be)$/, 'youtube'],
  [/(^|\.)(whatsapp\.com|wa\.me)$/, 'whatsapp'],
  [/(^|\.)viber\.com$/, 'viber'],
]

const text = (value: unknown, max: number) => (typeof value === 'string' ? value.trim().slice(0, max) : '')

function hostOf(url: string) {
  try {
    return new URL(url).hostname.replace(/^www\./, '').toLowerCase()
  } catch {
    return ''
  }
}

// Izvor i vrsta dolaska: prvo oznake kampanje (utm), zatim stranica s koje je kupac došao.
function classify(referrerHost: string, utmSource: string, utmMedium: string, clickId: string) {
  const medium = utmMedium.toLowerCase()
  const fromUtm = (): string | null => {
    if (/cpc|ppc|paid|ads?$/.test(medium)) return 'paid'
    if (/e-?mail|newsletter/.test(medium)) return 'email'
    if (/social/.test(medium)) return 'social'
    return null
  }

  if (utmSource) {
    const source = utmSource.toLowerCase()
    const social = SOCIAL.find(([, name]) => source.includes(name))
    return { source, medium: fromUtm() ?? (social ? 'social' : source.includes('google') ? 'paid' : 'referral') }
  }
  // Oznake klika iz oglasa (gclid) i s Facebooka ili Instagrama (fbclid).
  if (clickId === 'gclid') return { source: 'google', medium: 'paid' }

  if (!referrerHost) return clickId === 'fbclid' ? { source: 'facebook', medium: 'social' } : { source: 'izravno', medium: 'direct' }
  if (SEARCH.some((pattern) => pattern.test(referrerHost))) return { source: referrerHost.split('.').find((part) => part !== 'm') ?? referrerHost, medium: 'organic' }
  const social = SOCIAL.find(([pattern]) => pattern.test(referrerHost))
  if (social) return { source: social[1], medium: 'social' }
  return { source: referrerHost, medium: 'referral' }
}

function deviceOf(userAgent: string) {
  if (/ipad|tablet|android(?!.*mobile)/i.test(userAgent)) return 'tablet'
  if (/mobi|iphone|android/i.test(userAgent)) return 'mobile'
  return 'desktop'
}

// Netlify šalje lokaciju kao base64 JSON. Dekodira se kao UTF-8, zbog naših slova u nazivima gradova.
function geoOf(headers: Headers) {
  const raw = headers.get('x-nf-geo')
  if (raw) {
    try {
      const bytes = Uint8Array.from(atob(raw), (char) => char.charCodeAt(0))
      const geo = JSON.parse(new TextDecoder().decode(bytes)) as { city?: string; country?: { code?: string }; subdivision?: { name?: string } }
      return { country: geo.country?.code ?? '', region: geo.subdivision?.name ?? '', city: geo.city ?? '' }
    } catch {
      // Neispravno zaglavlje: ide samo država, ako postoji.
    }
  }
  return { country: headers.get('x-country') ?? headers.get('cf-ipcountry') ?? '', region: '', city: '' }
}

export default defineEventHandler(async (event) => {
  const body = await readBody<Body>(event).catch(() => null)
  const session = text(body?.session, 36)
  const path = text(body?.path, 300)
  const userAgent = getRequestHeader(event, 'user-agent') ?? ''
  if (!UUID.test(session) || !path.startsWith('/') || path.startsWith('/admin') || BOT.test(userAgent)) return { ok: true }

  const { siteUrl, supabaseUrl, supabasePublishableKey } = useRuntimeConfig(event).public
  const ownHost = hostOf(siteUrl || getRequestURL(event).origin)
  const referrerHost = hostOf(text(body?.referrer, 500))
  const external = referrerHost && referrerHost !== ownHost ? referrerHost : ''
  const utmSource = text(body?.utmSource, 100)
  const utmMedium = text(body?.utmMedium, 100)
  const { source, medium } = classify(external, utmSource, utmMedium, text(body?.clickId, 10))
  const geo = geoOf(new Headers(getRequestHeaders(event) as Record<string, string>))

  const authorization = getRequestHeader(event, 'authorization')
  const supabase = createClient(supabaseUrl, supabasePublishableKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: authorization?.startsWith('Bearer ') ? { headers: { Authorization: authorization } } : undefined,
  })

  const { error } = await supabase.rpc('shop_track_visit', {
    p_session: session,
    p_landing_path: path,
    p_referrer_host: external,
    p_source: source,
    p_medium: medium,
    p_utm_source: utmSource,
    p_utm_medium: utmMedium,
    p_utm_campaign: text(body?.utmCampaign, 150),
    p_country: geo.country.slice(0, 2),
    p_region: geo.region,
    p_city: geo.city,
    p_device: deviceOf(userAgent),
  })
  if (error) console.error(error)

  return { ok: true }
})
