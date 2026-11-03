<script setup lang="ts">
import { ASSIGNABLE_ROLES, ROLE_DESCRIPTIONS, ROLE_LABELS } from '~/config/roles'
import type { AppRole } from '~/types/database'
import type { NewTeamMember } from '~/composables/useTeamMembers'

const props = defineProps<{
  actorRole: AppRole
  submit: (member: NewTeamMember) => Promise<void>
}>()
const emit = defineEmits<{ cancel: [] }>()

const email = ref('')
const password = ref(generatePassword())
// Najmanje ovlasti su početni izbor, kako nitko ne bi slučajno dobio previše.
const role = ref<AppRole>('viewer')
const errorMessage = ref('')
const isSaving = ref(false)

const roleOptions = computed(() =>
  ASSIGNABLE_ROLES[props.actorRole].map((value) => ({ value, label: ROLE_LABELS[value] })),
)

async function onSubmit() {
  errorMessage.value = ''
  isSaving.value = true
  try {
    await props.submit({ email: email.value.trim(), password: password.value, role: role.value })
  } catch (error) {
    errorMessage.value = teamErrorMessage(error)
  } finally {
    isSaving.value = false
  }
}
</script>

<template>
  <form class="space-y-4" @submit.prevent="onSubmit">
    <BaseAlert v-if="errorMessage" type="error">{{ errorMessage }}</BaseAlert>
    <BaseInput v-model="email" label="E-mail" type="email" autocomplete="off" required />
    <div class="flex items-start gap-2">
      <BaseInput
        v-model="password"
        class="min-w-0 flex-1"
        label="Privremena lozinka"
        autocomplete="off"
        :minlength="8"
        hint="Korisnik je mijenja u Moj račun nakon prve prijave."
        required
      />
      <BaseButton class="mt-6.5" variant="secondary" @click="password = generatePassword()">Nova</BaseButton>
    </div>
    <BaseSelect v-model="role" label="Uloga" :options="roleOptions" :hint="ROLE_DESCRIPTIONS[role]" />
    <div class="flex flex-col-reverse gap-2 pt-2 sm:flex-row sm:justify-end">
      <BaseButton variant="secondary" @click="emit('cancel')">Odustani</BaseButton>
      <BaseButton type="submit" :loading="isSaving">{{ isSaving ? 'Dodavanje...' : 'Dodaj korisnika' }}</BaseButton>
    </div>
  </form>
</template>
