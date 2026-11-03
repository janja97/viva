<script setup lang="ts">
import { Ban, LockOpen, Trash2 } from '@lucide/vue'
import { ROLE_LABELS } from '~/config/roles'
import type { AppRole, TeamMember } from '~/types/database'

const props = defineProps<{
  member: TeamMember
  isSelf: boolean
  roleOptions: AppRole[]
  canBlock: boolean
  canDelete: boolean
}>()

const emit = defineEmits<{
  changeRole: [role: AppRole]
  toggleBlock: []
  delete: []
}>()

const dateFormat = new Intl.DateTimeFormat('hr-HR')
const lastSignIn = computed(() =>
  props.member.last_sign_in_at
    ? `Zadnja prijava ${dateFormat.format(new Date(props.member.last_sign_in_at))}`
    : 'Još se nije prijavio/la',
)

// Promjena se primjenjuje tek nakon potvrde, pa izbornik do tada ostaje na staroj ulozi.
function onRoleChange(event: Event) {
  const select = event.target as HTMLSelectElement
  emit('changeRole', select.value as AppRole)
  select.value = props.member.role
}
</script>

<template>
  <div class="flex flex-wrap items-center justify-between gap-x-4 gap-y-2 px-4 py-3">
    <div class="min-w-0">
      <p class="flex flex-wrap items-center gap-2 text-sm font-medium">
        <span class="break-all">{{ member.email }}</span>
        <span v-if="isSelf" class="rounded-md bg-primary-200 px-1.5 py-0.5 text-xs font-medium text-primary-900">Ti</span>
        <span v-if="member.is_blocked" class="rounded-md bg-red-100 px-1.5 py-0.5 text-xs font-medium text-red-700">Blokiran</span>
      </p>
      <p class="mt-0.5 text-xs text-stone-500">{{ lastSignIn }}</p>
    </div>

    <div class="flex items-center gap-1">
      <select
        v-if="roleOptions.length"
        class="form-field w-auto!"
        :aria-label="`Uloga: ${member.email}`"
        :value="member.role"
        @change="onRoleChange"
      >
        <option v-for="role in roleOptions" :key="role" :value="role">{{ ROLE_LABELS[role] }}</option>
      </select>
      <RoleBadge v-else :role="member.role" />
      <IconButton
        v-if="canBlock"
        :label="`${member.is_blocked ? 'Odblokiraj' : 'Blokiraj'}: ${member.email}`"
        @click="emit('toggleBlock')"
      >
        <LockOpen v-if="member.is_blocked" class="size-4" stroke-width="1.75" />
        <Ban v-else class="size-4" stroke-width="1.75" />
      </IconButton>
      <IconButton v-if="canDelete" :label="`Obriši: ${member.email}`" danger @click="emit('delete')">
        <Trash2 class="size-4" stroke-width="1.75" />
      </IconButton>
    </div>
  </div>
</template>
