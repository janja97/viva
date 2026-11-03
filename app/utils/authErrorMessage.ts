const MESSAGES: Record<string, string> = {
  invalid_credentials: 'Pogrešan e-mail ili lozinka.',
  email_not_confirmed: 'E-mail adresa još nije potvrđena.',
  no_admin_access: 'Ovaj račun nema pristup administraciji.',
  user_banned: 'Ovaj račun je blokiran.',
  wrong_current_password: 'Trenutna lozinka nije točna.',
  over_request_rate_limit: 'Previše pokušaja. Pričekaj malo pa pokušaj ponovno.',
  over_email_send_rate_limit: 'Poslano je previše e-mailova. Pričekaj malo pa pokušaj ponovno.',
  same_password: 'Nova lozinka mora biti drugačija od stare.',
  weak_password: 'Lozinka je preslaba. Odaberi jaču lozinku.',
}

export function authErrorMessage(error: unknown) {
  const code = (error as { code?: string } | null)?.code
  if (code && MESSAGES[code]) return MESSAGES[code]
  console.error(error)
  return 'Nešto je pošlo po zlu. Pokušaj ponovno.'
}
