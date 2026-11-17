<script setup lang="ts">
const { siteName, supabaseUrl } = useRuntimeConfig().public

useHead({
  titleTemplate: (title) => (title ? `${title} | ${siteName}` : siteName),
  // Slike proizvoda i podaci dolaze sa Supabasea, pa se veza otvara odmah (brže prve slike).
  link: supabaseUrl ? [{ rel: 'preconnect', href: supabaseUrl, crossorigin: '' }, { rel: 'dns-prefetch', href: supabaseUrl }] : [],
})
</script>

<template>
  <NuxtRouteAnnouncer />
  <NuxtLoadingIndicator color="#b8923f" />
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
</template>
