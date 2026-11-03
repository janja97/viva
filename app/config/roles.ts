import type { AppRole } from '~/types/database'

export type Permission = 'read' | 'write' | 'block_users' | 'delete_users'

export const ROLE_LABELS: Record<AppRole, string> = {
  super_admin: 'Super admin',
  admin: 'Administrator',
  viewer: 'Čitatelj',
}

export const ROLE_DESCRIPTIONS: Record<AppRole, string> = {
  super_admin: 'Može sve, uključujući blokiranje i brisanje korisnika.',
  admin: 'Može sve osim blokiranja i brisanja korisnika. Ne može mijenjati super admine.',
  viewer: 'Može samo pregledavati podatke.',
}

export const PERMISSION_LABELS: Record<Permission, string> = {
  read: 'Pregled podataka',
  write: 'Dodavanje i uređivanje',
  block_users: 'Blokiranje korisnika',
  delete_users: 'Brisanje korisnika',
}

// Služi samo za prikaz u sučelju. Stvarnu zaštitu podataka radi RLS u bazi.
export const ROLE_PERMISSIONS: Record<AppRole, Permission[]> = {
  super_admin: ['read', 'write', 'block_users', 'delete_users'],
  admin: ['read', 'write'],
  viewer: ['read'],
}

// Uloge koje pojedina uloga smije dodijeliti drugima.
export const ASSIGNABLE_ROLES: Record<AppRole, AppRole[]> = {
  super_admin: ['super_admin', 'admin', 'viewer'],
  admin: ['admin', 'viewer'],
  viewer: [],
}
