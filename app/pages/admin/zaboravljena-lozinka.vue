<script setup lang="ts">
definePageMeta({ layout: 'auth' })
usePageSeo({ title: 'Zaboravljena lozinka', noindex: true })
</script>

<template>
  <AuthCard title="Zaboravljena lozinka" description="Upiši e-mail i poslat ćemo ti poveznicu za novu lozinku.">
    <ForgotPasswordForm />
  </AuthCard>
</template>
