<script setup lang="ts">
defineProps<{ title: string; description?: string }>()
</script>

<template>
  <header class="mb-6 flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between lg:mb-8">
    <div>
      <h1 class="font-display text-4xl font-normal leading-tight">{{ title }}</h1>
      <p v-if="description" class="mt-1 text-sm text-stone-500">{{ description }}</p>
    </div>
    <slot />
  </header>
</template>
