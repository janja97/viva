// Javna prijava na newsletter. Iznimka od pravila za server rute: ne traži prijavu,
// a tajni ključ koristi samo za newsletter_subscribe, koju posjetitelji ne smiju zvati izravno.
// Kod se nikad ne vraća pregledniku, nego ide samo na upisanu adresu.
export default defineEventHandler(async (event) => {
  const body = await readBody<{ email?: unknown; website?: unknown; elapsed?: unknown }>(event)

  // Skriveno polje "website" popunjavaju samo botovi, a čovjek ne pošalje formu za manje od 2,5 s
  // (ili bez JavaScripta forme, kad vremena nema). Odgovor je kao za uspjeh, da bot ne zna da je blokiran.
  const elapsed = Number(body?.elapsed)
  if (body?.website || !Number.isFinite(elapsed) || elapsed < NEWSLETTER_MIN_FILL_MS) return { ok: true }

  const check = checkNewsletterEmail(body?.email)
  if (!check.ok) throw createError({ statusCode: 400, message: check.message })
  const email = check.email

  const supabase = useSupabaseAdmin(event)
  const { data, error } = await supabase.rpc('newsletter_subscribe', { p_email: email })
  if (error) {
    console.error(error)
    throw createError({ statusCode: 500, message: 'Prijava trenutno nije moguća. Pokušajte ponovno kasnije.' })
  }

  // Postojeća adresa ne dobiva novi kod, a odgovor je isti, da se ne otkrije tko je već prijavljen.
  if (data?.is_new) {
    try {
      await sendNewsletterCode(event, email, data)
    } catch (sendError) {
      console.error(sendError)
    }
  }

  return { ok: true }
})
