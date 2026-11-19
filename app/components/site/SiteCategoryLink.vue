<script setup lang="ts">
// Poveznica na kategoriju u tekstu stranice. Dok je kategorija isključena ili ne postoji, ostaje običan tekst,
// da Google i kupci ne dođu na stranicu koja ne postoji (404).
const props = defineProps<{ slug: string }>()

const { data: categories } = useSiteCategories()
const isActive = computed(() => categories.value.some((category) => category.slug === props.slug))
</script>

<template>
  <NuxtLink v-if="isActive" :to="`/kategorija/${slug}`" class="underline underline-offset-4 hover:text-gold"><slot /></NuxtLink>
  <span v-else><slot /></span>
</template>
