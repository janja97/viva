import { createClient } from '@supabase/supabase-js'
import { HOME_FAQ } from '../../app/config/home'
import { COMPANY, DEFAULT_STORE_SETTINGS, DELIVERY, EXCHANGE, STORE, WEEK_DAYS } from '../../app/config/store'
import { fillYear } from '../../app/utils/seasonYear'
import type { StoreSettings } from '../../app/types/database'

// /llms.txt: sažetak trgovine za AI asistente (ChatGPT, Claude, Perplexity, Gemini), po prijedlogu llmstxt.org.
// Kategorije, kontakt, radno vrijeme i poštarina čitaju se iz baze, pa datoteka ostaje točna bez ručnog uređivanja.
// Smiju se navoditi samo potvrđene tvrdnje (iste kao na webu). Netlify je kešira 1 sat (routeRules).
type CategoryRow = { id: string; parent_id: string | null; name: string; slug: string; description: string | null; sort_order: number }

const PAGES = [
  ['/kupovina-u-mostaru', 'Kupovina u Mostaru', 'lokacija, isprobavanje, plaćanje i povrat PDV-a za kupce iz Hrvatske'],
  ['/dostava', 'Dostava', 'dostava po BiH, rokovi, poštarina i plaćanje pouzećem'],
  ['/povrat-i-zamjena', 'Povrat i zamjena', 'zamjena u roku od 15 dana'],
  ['/poklon-bon', 'Poklon bon i pokloni za nju', 'poklon bon u iznosu po izboru, nakit i torbice'],
  ['/o-nama', 'O nama', 'o trgovini'],
  ['/kontakt', 'Kontakt', 'telefon, e-mail, adresa i radno vrijeme'],
  ['/blog', 'Savjeti', 'savjeti za odabir svečane i maturalne haljine'],
] as const

export default defineEventHandler(async (event) => {
  const { siteUrl, siteName, supabaseUrl, supabasePublishableKey, previewDeploy } = useRuntimeConfig(event).public
  const origin = (siteUrl || getRequestURL(event).origin).replace(/\/$/, '')
  setResponseHeader(event, 'Content-Type', 'text/plain; charset=utf-8')
  // Pregled grane nije prava trgovina.
  if (previewDeploy) return ''

  const supabase = createClient(supabaseUrl, supabasePublishableKey, { auth: { persistSession: false } })
  const [{ data: categoryData }, { data: settingsData }] = await Promise.all([
    supabase.from('categories').select('id, parent_id, name, slug, description, sort_order').eq('is_active', true).order('sort_order'),
    supabase.from('store_settings').select('*').maybeSingle(),
  ])
  const categories = (categoryData ?? []) as CategoryRow[]
  const settings = { ...DEFAULT_STORE_SETTINGS, ...(settingsData as StoreSettings | null) }

  const link = (category: CategoryRow) => {
    const description = category.description ? `: ${fillYear(category.description).replace(/\s+/g, ' ').trim()}` : ''
    return `[${category.name}](${origin}/kategorija/${category.slug})${description}`
  }
  const categoryLines = categories
    .filter((category) => !category.parent_id)
    .flatMap((main) => [
      `- ${link(main)}`,
      ...categories.filter((child) => child.parent_id === main.id).map((child) => `  - ${link(child)}`),
    ])

  const hours = settings.opening_hours
    .map(({ day, closed, opens, closes }) => `${WEEK_DAYS.find((item) => item.value === day)?.label ?? day}: ${closed ? 'zatvoreno' : `${opens}–${closes}`}`)
    .join(', ')
  const contact = [
    settings.phone && `Telefon: ${settings.phone}`,
    settings.whatsapp && `WhatsApp: ${settings.whatsapp}`,
    settings.email && `E-mail: ${settings.email}`,
    settings.instagram_url && `Instagram: ${settings.instagram_url}`,
    settings.facebook_url && `Facebook: ${settings.facebook_url}`,
  ].filter(Boolean)

  return [
    `# ${siteName}`,
    '',
    `> ${siteName} je butik luksuzne svečane ženske mode u ${STORE.mall}u u Mostaru (${STORE.street}, ${STORE.floor}), Bosna i Hercegovina, s poslovnicom u Sarajevu. Prodaje svečane i maturalne haljine (velika i mala matura), haljine za svadbu i za mame za pričest, krizmu i krštenje, ženska odijela, cipele na petu, čizme, torbice i nakit od nehrđajućeg čelika. Ponuda je samo za žene.`,
    '',
    `Veličine idu od 36 do 58, ovisno o modelu. U trgovini se može isprobati više modela, a plaća se gotovinom u KM, karticom ili na rate. Online narudžbe šalju se samo unutar Bosne i Hercegovine (${DELIVERY.minDays} do ${DELIVERY.maxDays} dana, plaćanje pouzećem; poštarina ${settings.shipping_price} KM, besplatna iznad ${settings.free_shipping_above} KM) ili se bez poštarine preuzimaju u Mostaru ili Sarajevu. Zamjena je moguća u roku od ${EXCHANGE.days} dana za proizvode bez tragova nošenja. Kupci iz cijele Hrvatske dolaze u trgovinu u Mostaru; za kupnju veću od 200 KM strancima se može vratiti PDV. Cijene su u konvertibilnim markama (KM, BAM). Trgovina ne radi skraćivanje ni prepravke i ne rezervira haljine.`,
    '',
    '## Trgovina',
    '',
    `- Adresa: ${STORE.mall}, ${STORE.street}, ${STORE.floor}, ${STORE.postalCode} ${STORE.city}, ${STORE.country}`,
    `- Karta: ${STORE.mapUrl}`,
    `- Radno vrijeme: ${hours}`,
    ...contact.map((line) => `- ${line}`),
    `- Tvrtka: ${COMPANY.name}`,
    '',
    '## Kategorije',
    '',
    `- [Sva kolekcija](${origin}/proizvodi)`,
    ...categoryLines,
    '',
    '## Informacije za kupce',
    '',
    ...PAGES.map(([path, title, text]) => `- [${title}](${origin}${path}): ${text}`),
    '',
    '## Česta pitanja',
    '',
    ...HOME_FAQ.flatMap(({ question, answer }) => [`### ${question}`, '', answer, '']),
    '## Optional',
    '',
    `- [Uvjeti kupnje](${origin}/uvjeti-kupnje)`,
    `- [Politika privatnosti](${origin}/politika-privatnosti)`,
    `- [Sitemap](${origin}/sitemap.xml): sve stranice proizvoda (svaka boja ima svoju adresu)`,
    '',
  ].join('\n')
})
