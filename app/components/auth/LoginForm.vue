<script setup lang="ts">
const route = useRoute()
const { signIn } = useAuth()

const email = ref('')
const password = ref('')
const errorMessage = ref('')
const isLoading = ref(false)

async function onSubmit() {
  errorMessage.value = ''
  isLoading.value = true
  try {
    await signIn(email.value.trim(), password.value)
    const redirect = route.query.redirect
    // Samo admin putanje, kako link ne bi mogao preusmjeriti na tuđu stranicu.
    const target = typeof redirect === 'string' && redirect.startsWith('/admin') ? redirect : '/admin'
    await navigateTo(target)
  } catch (error) {
    errorMessage.value = authErrorMessage(error)
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <form class="space-y-4" @submit.prevent="onSubmit">
    <BaseAlert v-if="errorMessage" type="error">{{ errorMessage }}</BaseAlert>
    <BaseInput v-model="email" label="E-mail" type="email" autocomplete="email" required />
    <BaseInput v-model="password" label="Lozinka" type="password" autocomplete="current-password" required />
    <BaseButton type="submit" block :loading="isLoading">
      {{ isLoading ? 'Prijava...' : 'Prijavi se' }}
    </BaseButton>
    <p class="text-center text-sm">
      <NuxtLink to="/admin/zaboravljena-lozinka" class="inline-flex min-h-11 items-center text-primary-700 hover:text-primary-900">
        Zaboravljena lozinka?
      </NuxtLink>
    </p>
  </form>
</template>
