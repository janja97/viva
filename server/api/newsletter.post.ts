// Javna prijava na newsletter. Iznimka od pravila za server rute: ne traži prijavu,
// a tajni ključ koristi samo za newsletter_subscribe, koju posjetitelji ne smiju zvati izravno.
// Kod se nikad ne vraća pregledniku, nego ide samo na upisanu adresu.
export default defineEventHandler(async (event) => {
  const body = await readBody<{ email?: unknown; website?: unknown }>(event)

  // Skriveno polje "website" popunjavaju samo botovi. Odgovor je isti, da ga ne prepoznaju.
  if (body?.website) return { ok: true }

  const email = String(body?.email ?? '').trim().toLowerCase()
  if (email.length > 200 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw createError({ statusCode: 400, message: 'Upišite ispravnu e-mail adresu.' })
  }

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
