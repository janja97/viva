import type { User } from '@supabase/supabase-js'
import type { AppRole } from '~/types/database'

// Koristi se samo u pregledniku, jer admin dio nema SSR.
let initPromise: Promise<void> | null = null

export function useAuth() {
  const supabase = useSupabase()
  const user = useState<User | null>('auth:user', () => null)
  const role = useState<AppRole | null>('auth:role', () => null)

  // Blokirani korisnik ovdje dobiva null, pa gubi pristup i uz još važeću prijavu.
  async function fetchRole() {
    const { data, error } = await supabase.rpc('current_user_role')
    if (error) throw error
    return data ?? null
  }

  function init() {
    initPromise ??= (async () => {
      const { data } = await supabase.auth.getSession()
      user.value = data.session?.user ?? null
      if (!data.session) return
      try {
        role.value = await fetchRole()
      } catch (error) {
        console.error(error)
      }
    })()
    return initPromise
  }

  async function signIn(email: string, password: string) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error

    let userRole: AppRole | null = null
    try {
      userRole = await fetchRole()
    } catch (roleError) {
      await supabase.auth.signOut()
      throw roleError
    }
    if (!userRole) {
      await supabase.auth.signOut()
      throw Object.assign(new Error('no_admin_access'), { code: 'no_admin_access' })
    }

    user.value = data.user
    role.value = userRole
  }

  async function signOut() {
    await supabase.auth.signOut()
    user.value = null
    role.value = null
  }

  async function requestPasswordReset(email: string) {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/admin/nova-lozinka`,
    })
    if (error) throw error
  }

  async function updatePassword(password: string) {
    const { error } = await supabase.auth.updateUser({ password })
    if (error) throw error
  }

  // Trenutna lozinka se provjerava kako nitko ne bi mogao promijeniti lozinku na otključanom računalu.
  async function changePassword(currentPassword: string, newPassword: string) {
    const { error } = await supabase.auth.signInWithPassword({
      email: user.value?.email ?? '',
      password: currentPassword,
    })
    if (error?.code === 'invalid_credentials') {
      throw Object.assign(new Error('wrong_current_password'), { code: 'wrong_current_password' })
    }
    if (error) throw error
    await updatePassword(newPassword)
  }

  return { user, role, init, signIn, signOut, requestPasswordReset, updatePassword, changePassword }
}
