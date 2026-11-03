export default defineEventHandler(async (event) => {
  const actor = await requireRole(event, ['super_admin'])
  const id = getRouterParam(event, 'id')

  if (id === actor.id) {
    throw createError({ statusCode: 400, message: 'Ne možeš obrisati vlastiti račun.' })
  }

  const { error } = await useSupabaseAdmin(event).auth.admin.deleteUser(id!)
  if (error) {
    console.error(error)
    throw createError({ statusCode: 500, message: 'Korisnik nije obrisan.' })
  }

  return { id }
})
