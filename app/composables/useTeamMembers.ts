import type { AppRole, TeamMember } from '~/types/database'

export type NewTeamMember = { email: string; password: string; role: AppRole }

export function useTeamMembers() {
  const supabase = useSupabase()

  const members = ref<TeamMember[]>([])
  const isLoading = ref(true)
  const loadError = ref('')

  async function authHeaders() {
    const { data } = await supabase.auth.getSession()
    return { Authorization: `Bearer ${data.session?.access_token}` }
  }

  async function load() {
    isLoading.value = true
    loadError.value = ''
    const { data, error } = await supabase.rpc('list_team_members')
    if (error) loadError.value = teamErrorMessage(error)
    else members.value = data
    isLoading.value = false
  }

  async function create(member: NewTeamMember) {
    await $fetch('/api/admin/users', {
      method: 'POST',
      headers: await authHeaders(),
      body: member,
    })
    await load()
  }

  async function changeRole(userId: string, role: AppRole) {
    const { error } = await supabase
      .from('user_roles')
      .update({ role })
      .eq('user_id', userId)
      .select('user_id')
      .single()
    if (error) throw error
    await load()
  }

  async function remove(userId: string) {
    await $fetch(`/api/admin/users/${userId}`, {
      method: 'DELETE',
      headers: await authHeaders(),
    })
    await load()
  }

  async function setBlocked(userId: string, blocked: boolean) {
    await $fetch(`/api/admin/users/${userId}`, {
      method: 'PATCH',
      headers: await authHeaders(),
      body: { blocked },
    })
    await load()
  }

  return { members, isLoading, loadError, load, create, changeRole, remove, setBlocked }
}
