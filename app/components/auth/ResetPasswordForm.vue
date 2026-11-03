<script setup lang="ts">
const { user, updatePassword, signOut } = useAuth()

const password = ref('')
const passwordRepeat = ref('')
const errorMessage = ref('')
const isLoading = ref(false)

async function onSubmit() {
  errorMessage.value = ''
  if (password.value !== passwordRepeat.value) {
    errorMessage.value = 'Lozinke se ne podudaraju.'
    return
  }

  isLoading.value = true
  try {
    await updatePassword(password.value)
    await signOut()
    await navigateTo({ path: '/admin/prijava', query: { lozinka: 'promijenjena' } })
  } catch (error) {
    errorMessage.value = authErrorMessage(error)
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <div v-if="!user" class="space-y-4">
    <BaseAlert type="error">Poveznica je nevažeća ili je istekla. Zatraži novu.</BaseAlert>
    <p class="text-center text-sm">
      <NuxtLink to="/admin/zaboravljena-lozinka" class="inline-flex min-h-11 items-center text-primary-700 hover:text-primary-900">
        Zatraži novu poveznicu
      </NuxtLink>
    </p>
  </div>
  <form v-else class="space-y-4" @submit.prevent="onSubmit">
    <BaseAlert v-if="errorMessage" type="error">{{ errorMessage }}</BaseAlert>
    <BaseInput v-model="password" label="Nova lozinka" type="password" autocomplete="new-password" :minlength="8" required />
    <BaseInput v-model="passwordRepeat" label="Ponovi lozinku" type="password" autocomplete="new-password" :minlength="8" required />
    <BaseButton type="submit" block :loading="isLoading">
      {{ isLoading ? 'Spremanje...' : 'Spremi lozinku' }}
    </BaseButton>
  </form>
</template>
