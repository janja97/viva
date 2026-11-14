import type { Component } from 'vue'
import type { Permission } from '~/config/roles'
import { FolderTree, LayoutDashboard, Mail, Megaphone, Newspaper, Package, Settings, ShoppingBag, Tag, TicketPercent, Timer, UserRound, Users } from '@lucide/vue'

export interface NavLink {
  label: string
  to: string
}

export interface AdminNavLink extends NavLink {
  icon: Component
  // Broj uz stavku, npr. nove narudžbe.
  badge?: 'newInquiries'
  // Stavka se prikazuje samo ulogama s ovom ovlasti (npr. Postavke samo adminima).
  permission?: Permission
}

export const PUBLIC_NAV: NavLink[] = [
  { label: 'Početna', to: '/' },
  { label: 'Kolekcija', to: '/proizvodi' },
  { label: 'O nama', to: '/o-nama' },
  { label: 'Savjeti', to: '/blog' },
  { label: 'Kontakt', to: '/kontakt' },
]

// Informacije za kupce, u podnožju.
export const INFO_NAV: NavLink[] = [
  { label: 'Dostava i plaćanje', to: '/dostava' },
  { label: 'Povrat i zamjena', to: '/povrat-i-zamjena' },
]

export type ShopNavLink = {
  label: string
  // Stalna putanja umjesto kategorije, npr. /ciscenje-zaliha dok je akcija u tijeku.
  path?: string
  slug?: string
  // Filtar na popisu, npr. samo sniženi proizvodi.
  query?: { snizeno?: '1' }
  highlight?: boolean
}

// Glavni izbornik trgovine. Bez sluga vodi na cijelu kolekciju, a to je i rezerva dok kategorija ne postoji.
// Odjeća sadrži sve ostalo (kaputi, kompleti i sakoi...), jer kategorija prikazuje i svoje podkategorije.
export const SHOP_NAV: ShopNavLink[] = [
  { label: 'Haljine', slug: 'haljine' },
  { label: 'Odjeća', slug: 'odjeca' },
  { label: 'Obuća', slug: 'obuca' },
  { label: 'Torbice', slug: 'torbice' },
  { label: 'Dodaci', slug: 'dodaci' },
  { label: 'Novo', highlight: true },
  { label: 'Popust', query: { snizeno: '1' }, highlight: true },
]

// Akcijske stranice koje imaju datoteku u app/pages. Dok traju, preuzimaju stavku "Popust" (ako ih traje više,
// vrijedi prva s popisa), a admin prikazuje samo njih. Black Friday je zasad maknut: redak u bazi ostaje,
// a vraća se datotekom pages/black-friday.vue, slugom ovdje i u STATIC_ROUTES sitemapa.
export const PROMO_PAGE_SLUGS = ['ciscenje-zaliha']

// Stranica na koju se proizvodi dodaju pojedinačno s popisa proizvoda i prikazuju samo na njoj (migracija 0039).
// Dok je uključena, u izborniku je zasebna stavka iza "Popust".
export const EXCLUSIVE_PROMO_PAGE = { slug: 'ciscenje-zaliha', label: 'Čišćenje zaliha' }

// Svaka grupa je u izborniku odvojena crtom.
export const ADMIN_NAV_GROUPS: AdminNavLink[][] = [
  [
    { label: 'Nadzorna ploča', to: '/admin', icon: LayoutDashboard },
    { label: 'Narudžbe', to: '/admin/narudzbe', icon: ShoppingBag, badge: 'newInquiries' },
  ],
  [
    { label: 'Proizvodi', to: '/admin/proizvodi', icon: Package },
    { label: 'Kategorije', to: '/admin/kategorije', icon: FolderTree },
    { label: 'Kampanje', to: '/admin/kampanje', icon: Tag },
    { label: 'Akcijske stranice', to: '/admin/akcijske-stranice', icon: Megaphone },
    { label: 'Promo kodovi', to: '/admin/promo-kodovi', icon: TicketPercent },
    { label: 'Odbrojavanja', to: '/admin/odbrojavanja', icon: Timer },
    { label: 'Newsletter', to: '/admin/newsletter', icon: Mail },
    { label: 'Blog', to: '/admin/blog', icon: Newspaper },
  ],
]

// Stoji na dnu izbornika.
export const ADMIN_NAV_BOTTOM: AdminNavLink[] = [
  { label: 'Postavke', to: '/admin/postavke', icon: Settings, permission: 'write' },
  { label: 'Moj račun', to: '/admin/moj-racun', icon: UserRound },
  { label: 'Korisnici', to: '/admin/korisnici', icon: Users },
]

// Admin stranice dostupne bez prijave. Sve ostalo pod /admin je zaštićeno.
export const ADMIN_AUTH_PATHS = [
  '/admin/prijava',
  '/admin/zaboravljena-lozinka',
  '/admin/nova-lozinka',
]
