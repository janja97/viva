<script setup lang="ts">
defineProps<{ title: string; description?: string }>()
</script>

<template>
  <div class="rounded-xl border border-primary-300 bg-white p-6 sm:p-8">
    <AppLogo />
    <h1 class="mt-4 font-display text-4xl font-normal leading-tight">{{ title }}</h1>
    <p v-if="description" class="mt-1 text-sm text-stone-500">{{ description }}</p>
    <div class="mt-6">
      <slot />
    </div>
  </div>
</template>
