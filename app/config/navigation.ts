import type { Component } from 'vue'
import { FolderTree, LayoutDashboard, Package, Settings, ShoppingBag, Tag, UserRound, Users } from '@lucide/vue'

export interface NavLink {
  label: string
  to: string
}

export interface AdminNavLink extends NavLink {
  icon: Component
  // Broj uz stavku, npr. nove narudžbe.
  badge?: 'newInquiries'
}

export const PUBLIC_NAV: NavLink[] = [
  { label: 'Početna', to: '/' },
  { label: 'Kolekcija', to: '/proizvodi' },
  { label: 'O nama', to: '/o-nama' },
  { label: 'Kontakt', to: '/kontakt' },
]

// Glavni izbornik trgovine. Bez sluga vodi na cijelu kolekciju, a to je i rezerva dok kategorija ne postoji.
export const SHOP_NAV: { label: string; slug?: string; highlight?: boolean }[] = [
  { label: 'Haljine', slug: 'haljine' },
  { label: 'Odijela', slug: 'odijela' },
  { label: 'Svečano', slug: 'svecano' },
  { label: 'Obuća', slug: 'obuca' },
  { label: 'Torbice', slug: 'torbice' },
  { label: 'Dodaci', slug: 'dodaci' },
  { label: 'Novo', highlight: true },
]

// Svaka grupa je u izborniku odvojena crtom.
export const ADMIN_NAV_GROUPS: AdminNavLink[][] = [
  [
    { label: 'Nadzorna ploča', to: '/admin', icon: LayoutDashboard },
    { label: 'Narudžbe', to: '/admin/narudzbe', icon: ShoppingBag, badge: 'newInquiries' },
  ],
  [
    { label: 'Proizvodi', to: '/admin/proizvodi', icon: Package },
    { label: 'Kategorije', to: '/admin/kategorije', icon: FolderTree },
    { label: 'Popusti', to: '/admin/popusti', icon: Tag },
  ],
]

// Stoji na dnu izbornika.
export const ADMIN_NAV_BOTTOM: AdminNavLink[] = [
  { label: 'Postavke', to: '/admin/postavke', icon: Settings },
  { label: 'Moj račun', to: '/admin/moj-racun', icon: UserRound },
  { label: 'Korisnici', to: '/admin/korisnici', icon: Users },
]

// Admin stranice dostupne bez prijave. Sve ostalo pod /admin je zaštićeno.
export const ADMIN_AUTH_PATHS = [
  '/admin/prijava',
  '/admin/zaboravljena-lozinka',
  '/admin/nova-lozinka',
]
