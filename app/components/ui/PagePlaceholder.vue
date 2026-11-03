<script setup lang="ts">
defineProps<{ title: string }>()
</script>

<template>
  <div>
    <h1 class="font-display text-4xl font-normal leading-tight">{{ title }}</h1>
    <p class="mt-1 text-sm text-stone-500">Ova stranica je u izradi.</p>
  </div>
</template>
