<script setup lang="ts">
definePageMeta({ layout: 'auth' })
usePageSeo({ title: 'Admin prijava', noindex: true })

const route = useRoute()
</script>

<template>
  <AuthCard title="Admin prijava" description="Prijavi se za pristup administraciji.">
    <BaseAlert v-if="route.query.lozinka === 'promijenjena'" type="success" class="mb-4">
      Lozinka je promijenjena. Prijavi se novom lozinkom.
    </BaseAlert>
    <LoginForm />
  </AuthCard>
</template>
