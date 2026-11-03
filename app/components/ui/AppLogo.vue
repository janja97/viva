<script setup lang="ts">
withDefaults(defineProps<{ to?: string }>(), { to: '/' })

const { siteName } = useRuntimeConfig().public
</script>

<template>
  <NuxtLink :to="to" class="inline-flex min-h-11 items-center">
    <img src="/logo/logo-dark.png" :alt="siteName" width="400" height="214" class="h-10 w-auto">
  </NuxtLink>
</template>
