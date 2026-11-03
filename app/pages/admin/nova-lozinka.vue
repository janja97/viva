<script setup lang="ts">
definePageMeta({ layout: 'auth' })
usePageSeo({ title: 'Nova lozinka', noindex: true })
</script>

<template>
  <AuthCard title="Nova lozinka">
    <ResetPasswordForm />
  </AuthCard>
</template>
