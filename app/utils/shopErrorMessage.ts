// Poruke za kupce. Poruke iz funkcija shop_* u bazi već su napisane za kupca.
export function shopErrorMessage(error: unknown) {
  const { code, message } = (error ?? {}) as { code?: string; message?: string }
  if (code === 'P0001' && message) return message

  console.error(error)
  return 'Nešto je pošlo po zlu. Pokušajte ponovno ili nas kontaktirajte.'
}
