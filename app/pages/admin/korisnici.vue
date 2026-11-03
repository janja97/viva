<script setup lang="ts">
import { Plus } from '@lucide/vue'
import { ASSIGNABLE_ROLES, ROLE_DESCRIPTIONS, ROLE_LABELS } from '~/config/roles'
import type { AppRole, TeamMember } from '~/types/database'
import type { NewTeamMember } from '~/composables/useTeamMembers'

definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Korisnici', noindex: true })

const { user, role: actorRole } = useAuth()
const { can } = usePermissions()
const { members, isLoading, loadError, load, create, changeRole, remove, setBlocked } = useTeamMembers()

const isFormOpen = ref(false)
const created = ref<{ email: string; password: string } | null>(null)

const pendingRole = ref<{ member: TeamMember; role: AppRole } | null>(null)
const roleError = ref('')
const isChangingRole = ref(false)

const blocking = ref<TeamMember | null>(null)
const blockError = ref('')
const isBlocking = ref(false)

const deleting = ref<TeamMember | null>(null)
const deleteError = ref('')
const isDeleting = ref(false)

// Isto pravilo provodi RLS: nitko ne mijenja sebe, a admin ne dira super admine.
function roleOptionsFor(member: TeamMember) {
  if (!actorRole.value || member.user_id === user.value?.id) return []
  if (actorRole.value !== 'super_admin' && member.role === 'super_admin') return []
  return ASSIGNABLE_ROLES[actorRole.value]
}

async function submitForm(member: NewTeamMember) {
  await create(member)
  created.value = { email: member.email, password: member.password }
  isFormOpen.value = false
}

function askRoleChange(member: TeamMember, role: AppRole) {
  roleError.value = ''
  pendingRole.value = { member, role }
}

async function confirmRoleChange() {
  if (!pendingRole.value) return
  isChangingRole.value = true
  roleError.value = ''
  try {
    await changeRole(pendingRole.value.member.user_id, pendingRole.value.role)
    pendingRole.value = null
  } catch (error) {
    roleError.value = teamErrorMessage(error)
  } finally {
    isChangingRole.value = false
  }
}

function askBlock(member: TeamMember) {
  blockError.value = ''
  blocking.value = member
}

async function confirmBlock() {
  if (!blocking.value) return
  isBlocking.value = true
  blockError.value = ''
  try {
    await setBlocked(blocking.value.user_id, !blocking.value.is_blocked)
    blocking.value = null
  } catch (error) {
    blockError.value = teamErrorMessage(error)
  } finally {
    isBlocking.value = false
  }
}

function askDelete(member: TeamMember) {
  deleteError.value = ''
  deleting.value = member
}

async function confirmDelete() {
  if (!deleting.value) return
  isDeleting.value = true
  deleteError.value = ''
  try {
    await remove(deleting.value.user_id)
    deleting.value = null
  } catch (error) {
    deleteError.value = teamErrorMessage(error)
  } finally {
    isDeleting.value = false
  }
}

onMounted(load)
</script>

<template>
  <div>
    <AdminPageHeader title="Korisnici" description="Članovi tima i njihove uloge.">
      <BaseButton v-if="can('write')" @click="isFormOpen = true">
        <Plus class="size-4" stroke-width="2" />
        Novi korisnik
      </BaseButton>
    </AdminPageHeader>

    <BaseAlert v-if="created" type="success" class="mb-4">
      Korisnik {{ created.email }} je dodan. Privremena lozinka: <strong class="break-all font-mono">{{ created.password }}</strong>.
      Prikazuje se samo sada, pa je odmah proslijedi sigurnim putem.
    </BaseAlert>

    <p v-if="isLoading && !members.length" class="text-sm text-stone-500">Učitavanje...</p>
    <div v-else-if="loadError" class="space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <BaseButton variant="secondary" @click="load">Pokušaj ponovno</BaseButton>
    </div>
    <ul v-else class="divide-y divide-primary-200 rounded-xl border border-primary-300 bg-white shadow-sm">
      <li v-for="member in members" :key="member.user_id">
        <UserRow
          :member="member"
          :is-self="member.user_id === user?.id"
          :role-options="roleOptionsFor(member)"
          :can-block="can('block_users') && member.user_id !== user?.id"
          :can-delete="can('delete_users') && member.user_id !== user?.id"
          @change-role="askRoleChange(member, $event)"
          @toggle-block="askBlock(member)"
          @delete="askDelete(member)"
        />
      </li>
    </ul>

    <BaseModal :open="isFormOpen" title="Novi korisnik" @close="isFormOpen = false">
      <UserForm v-if="actorRole" :actor-role="actorRole" :submit="submitForm" @cancel="isFormOpen = false" />
    </BaseModal>

    <ConfirmDialog
      :open="Boolean(pendingRole)"
      title="Promjena uloge"
      confirm-label="Promijeni ulogu"
      variant="primary"
      :loading="isChangingRole"
      :error="roleError"
      @close="pendingRole = null"
      @confirm="confirmRoleChange"
    >
      <template v-if="pendingRole">
        {{ pendingRole.member.email }} dobiva ulogu {{ ROLE_LABELS[pendingRole.role] }}.
        {{ ROLE_DESCRIPTIONS[pendingRole.role] }}
      </template>
    </ConfirmDialog>

    <ConfirmDialog
      :open="Boolean(blocking)"
      :title="blocking?.is_blocked ? 'Odblokiraj korisnika' : 'Blokiraj korisnika'"
      :confirm-label="blocking?.is_blocked ? 'Odblokiraj' : 'Blokiraj'"
      :variant="blocking?.is_blocked ? 'primary' : 'danger'"
      :loading="isBlocking"
      :error="blockError"
      @close="blocking = null"
      @confirm="confirmBlock"
    >
      <template v-if="blocking?.is_blocked">
        {{ blocking.email }} se ponovno može prijaviti, s istom ulogom i lozinkom.
      </template>
      <template v-else>
        {{ blocking?.email }} odmah gubi pristup podacima i ne može se prijaviti dok ga ne odblokiraš. Račun i uloga ostaju spremljeni.
      </template>
    </ConfirmDialog>

    <ConfirmDialog
      :open="Boolean(deleting)"
      title="Obriši korisnika"
      confirm-label="Obriši"
      :loading="isDeleting"
      :error="deleteError"
      @close="deleting = null"
      @confirm="confirmDelete"
    >
      Sigurno želiš trajno obrisati račun {{ deleting?.email }}? Ova radnja se ne može poništiti.
    </ConfirmDialog>
  </div>
</template>
