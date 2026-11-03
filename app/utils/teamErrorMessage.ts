export function teamErrorMessage(error: unknown) {
  const { code, message, data } = (error ?? {}) as {
    code?: string
    message?: string
    data?: { message?: string }
  }

  // Poruka server rute je već napisana za korisnika.
  if (data?.message) return data.message
  if (code === '42501' || code === 'PGRST116') return 'Nemaš ovlasti za ovu radnju.'
  // Poruke iz okidača u bazi također.
  if (code === 'P0001' && message) return message

  console.error(error)
  return 'Nešto je pošlo po zlu. Pokušaj ponovno.'
}
