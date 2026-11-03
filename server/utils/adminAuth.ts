import { createClient } from '@supabase/supabase-js'
import type { H3Event } from 'h3'

// Klijent s tajnim ključem zaobilazi RLS, zato ovdje svaka ruta sama provjerava ulogu.
export function useSupabaseAdmin(event: H3Event) {
  const config = useRuntimeConfig(event)
  if (!config.supabaseSecretKey) {
    throw createError({
      statusCode: 503,
      message: 'Nije postavljen NUXT_SUPABASE_SECRET_KEY.',
    })
  }
  if (config.supabaseSecretKey.startsWith('sb_publishable_')) {
    throw createError({
      statusCode: 503,
      message: 'NUXT_SUPABASE_SECRET_KEY sadrži javni ključ. Upiši ključ koji počinje sa sb_secret_.',
    })
  }
  return createClient(config.public.supabaseUrl, config.supabaseSecretKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  })
}

export async function requireRole(event: H3Event, allowedRoles: string[]) {
  const supabase = useSupabaseAdmin(event)
  const token = getHeader(event, 'authorization')?.replace(/^Bearer /, '')
  if (!token) {
    throw createError({ statusCode: 401, message: 'Prijava je obavezna.' })
  }

  const { data: auth, error: authError } = await supabase.auth.getUser(token)
  if (authError || !auth.user) {
    throw createError({ statusCode: 401, message: 'Prijava je obavezna.' })
  }
  // Pristupni token blokiranog korisnika vrijedi do isteka, a tajni ključ zaobilazi RLS.
  if (auth.user.banned_until && new Date(auth.user.banned_until) > new Date()) {
    throw createError({ statusCode: 403, message: 'Nemaš ovlasti za ovu radnju.' })
  }

  const { data, error } = await supabase
    .from('user_roles')
    .select('role')
    .eq('user_id', auth.user.id)
    .maybeSingle()
  if (error) {
    console.error(error)
    throw createError({ statusCode: 500, message: 'Provjera uloge nije uspjela.' })
  }
  if (!data || !allowedRoles.includes(data.role)) {
    throw createError({ statusCode: 403, message: 'Nemaš ovlasti za ovu radnju.' })
  }

  return { id: auth.user.id, role: data.role as string }
}
