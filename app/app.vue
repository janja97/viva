<script setup lang="ts">
const { siteName } = useRuntimeConfig().public

useHead({
  titleTemplate: (title) => (title ? `${title} | ${siteName}` : siteName),
})
</script>

<template>
  <NuxtRouteAnnouncer />
  <NuxtLoadingIndicator color="#b8923f" />
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
</template>
