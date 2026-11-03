<script setup lang="ts">
const props = defineProps<{
  images: { id: string; url: string; alt: string }[]
}>()

const main = computed(() => props.images[0])
const rest = computed(() => props.images.slice(1))
</script>

<template>
  <div class="grid grid-cols-2 gap-2">
    <div class="col-span-2 aspect-4/5 overflow-hidden bg-photo-dark">
      <img v-if="main" :src="main.url" :alt="main.alt" width="1000" height="1250" fetchpriority="high" class="size-full object-cover">
    </div>
    <div v-for="image in rest" :key="image.id" class="aspect-3/4 overflow-hidden bg-photo">
      <img :src="image.url" :alt="image.alt" loading="lazy" width="600" height="800" class="size-full object-cover">
    </div>
  </div>
</template>
