export function categoryErrorMessage(error: unknown) {
  const { code, message } = (error ?? {}) as { code?: string; message?: string }

  if (code === '23505') return 'Taj URL naziv već koristi druga kategorija. Upiši drugi.'
  if (code === '23503') return 'Kategorija ima podkategorije ili proizvode. Prvo ih obriši ili premjesti.'
  if (code === '23514') return 'Neki SEO podatak je predug ili ima previše pitanja (najviše 12).'
  if (code === '42501' || code === 'PGRST116') return 'Nemaš ovlasti za ovu radnju.'
  // Poruke iz okidača u bazi već su napisane za korisnika.
  if (code === 'P0001' && message) return message

  console.error(error)
  return 'Nešto je pošlo po zlu. Pokušaj ponovno.'
}
