const ROLES = ['super_admin', 'admin', 'viewer']

export default defineEventHandler(async (event) => {
  const actor = await requireRole(event, ['super_admin', 'admin'])

  const body = await readBody<{ email?: unknown; password?: unknown; role?: unknown }>(event)
  const email = String(body?.email ?? '').trim().toLowerCase()
  const password = String(body?.password ?? '')
  const role = String(body?.role ?? '')

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw createError({ statusCode: 400, message: 'E-mail adresa nije ispravna.' })
  }
  if (password.length < 8) {
    throw createError({ statusCode: 400, message: 'Lozinka mora imati barem 8 znakova.' })
  }
  if (!ROLES.includes(role)) {
    throw createError({ statusCode: 400, message: 'Uloga nije ispravna.' })
  }
  if (role === 'super_admin' && actor.role !== 'super_admin') {
    throw createError({ statusCode: 403, message: 'Samo super admin može dodijeliti ovu ulogu.' })
  }

  const supabase = useSupabaseAdmin(event)
  const { data, error } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  })
  if (error) {
    if (error.code === 'email_exists') {
      throw createError({ statusCode: 409, message: 'Račun s tim e-mailom već postoji.' })
    }
    if (error.code === 'weak_password') {
      throw createError({ statusCode: 400, message: 'Lozinka je preslaba.' })
    }
    console.error(error)
    throw createError({ statusCode: 500, message: 'Račun nije stvoren.' })
  }

  const { error: roleError } = await supabase
    .from('user_roles')
    .insert({ user_id: data.user.id, role })
  if (roleError) {
    // Bez uloge račun ne bi imao smisla, a e-mail bi ostao zauzet.
    console.error(roleError)
    await supabase.auth.admin.deleteUser(data.user.id)
    throw createError({ statusCode: 500, message: 'Uloga nije spremljena.' })
  }

  setResponseStatus(event, 201)
  return { id: data.user.id }
})
