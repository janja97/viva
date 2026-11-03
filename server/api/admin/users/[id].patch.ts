// Oko 100 godina, jer Supabase nema trajnu blokadu.
const BLOCK_DURATION = '876000h'

export default defineEventHandler(async (event) => {
  const actor = await requireRole(event, ['super_admin'])
  const id = getRouterParam(event, 'id')
  const body = await readBody<{ blocked?: unknown }>(event)

  if (typeof body?.blocked !== 'boolean') {
    throw createError({ statusCode: 400, message: 'Neispravan zahtjev.' })
  }
  if (id === actor.id) {
    throw createError({ statusCode: 400, message: 'Ne možeš blokirati vlastiti račun.' })
  }

  const { error } = await useSupabaseAdmin(event).auth.admin.updateUserById(id!, {
    ban_duration: body.blocked ? BLOCK_DURATION : 'none',
  })
  if (error) {
    console.error(error)
    throw createError({ statusCode: 500, message: 'Promjena blokade nije uspjela.' })
  }

  return { id, blocked: body.blocked }
})
