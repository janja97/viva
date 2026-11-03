<script setup lang="ts">
const { requestPasswordReset } = useAuth()

const email = ref('')
const errorMessage = ref('')
const isLoading = ref(false)
const isSent = ref(false)

async function onSubmit() {
  errorMessage.value = ''
  isLoading.value = true
  try {
    await requestPasswordReset(email.value.trim())
    isSent.value = true
  } catch (error) {
    errorMessage.value = authErrorMessage(error)
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <div class="space-y-4">
    <BaseAlert v-if="isSent" type="success">
      Ako račun s tom adresom postoji, poslali smo poveznicu za novu lozinku.
    </BaseAlert>
    <form v-else class="space-y-4" @submit.prevent="onSubmit">
      <BaseAlert v-if="errorMessage" type="error">{{ errorMessage }}</BaseAlert>
      <BaseInput v-model="email" label="E-mail" type="email" autocomplete="email" required />
      <BaseButton type="submit" block :loading="isLoading">
        {{ isLoading ? 'Slanje...' : 'Pošalji poveznicu' }}
      </BaseButton>
    </form>
    <p class="text-center text-sm">
      <NuxtLink to="/admin/prijava" class="inline-flex min-h-11 items-center text-primary-700 hover:text-primary-900">
        Natrag na prijavu
      </NuxtLink>
    </p>
  </div>
</template>
