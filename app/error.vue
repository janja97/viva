<script setup lang="ts">
import type { NuxtError } from '#app'

const props = defineProps<{ error: NuxtError }>()

const isNotFound = computed(() => props.error.status === 404)
const title = computed(() => (isNotFound.value ? 'Stranica nije pronađena' : 'Došlo je do greške'))

useSeoMeta({ title, robots: 'noindex, nofollow' })
</script>

<template>
  <NuxtLayout name="default">
    <section class="mx-auto max-w-xl px-4 py-24 text-center">
      <p class="text-xs uppercase tracking-[0.25em] text-gold">{{ error.status }}</p>
      <h1 class="mt-3 font-display text-4xl font-medium sm:text-5xl">{{ title }}</h1>
      <button
        type="button"
        class="mt-10 inline-flex min-h-12 items-center justify-center border border-graphite bg-graphite px-8 text-xs font-medium uppercase tracking-[0.2em] text-ivory transition-colors hover:bg-transparent hover:text-graphite"
        @click="clearError({ redirect: '/' })"
      >
        Natrag na početnu
      </button>
    </section>
  </NuxtLayout>
</template>
