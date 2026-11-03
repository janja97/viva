export default defineNuxtPlugin(() => {
  const { user, role } = useAuth()

  useSupabase().auth.onAuthStateChange((_event, session) => {
    user.value = session?.user ?? null
    if (!session) role.value = null
  })
})
