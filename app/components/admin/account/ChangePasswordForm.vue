<script setup lang="ts">
const { changePassword } = useAuth()

const currentPassword = ref('')
const newPassword = ref('')
const newPasswordRepeat = ref('')
const errorMessage = ref('')
const isSaved = ref(false)
const isSaving = ref(false)

async function onSubmit() {
  errorMessage.value = ''
  isSaved.value = false
  if (newPassword.value !== newPasswordRepeat.value) {
    errorMessage.value = 'Nove lozinke se ne podudaraju.'
    return
  }

  isSaving.value = true
  try {
    await changePassword(currentPassword.value, newPassword.value)
    currentPassword.value = ''
    newPassword.value = ''
    newPasswordRepeat.value = ''
    isSaved.value = true
  } catch (error) {
    errorMessage.value = authErrorMessage(error)
  } finally {
    isSaving.value = false
  }
}
</script>

<template>
  <form class="space-y-4" @submit.prevent="onSubmit">
    <BaseAlert v-if="errorMessage" type="error">{{ errorMessage }}</BaseAlert>
    <BaseAlert v-if="isSaved" type="success">Lozinka je promijenjena.</BaseAlert>
    <BaseInput v-model="currentPassword" label="Trenutna lozinka" type="password" autocomplete="current-password" required />
    <BaseInput v-model="newPassword" label="Nova lozinka" type="password" autocomplete="new-password" :minlength="8" hint="Najmanje 8 znakova." required />
    <BaseInput v-model="newPasswordRepeat" label="Ponovi novu lozinku" type="password" autocomplete="new-password" :minlength="8" required />
    <BaseButton type="submit" :loading="isSaving">{{ isSaving ? 'Spremanje...' : 'Promijeni lozinku' }}</BaseButton>
  </form>
</template>
