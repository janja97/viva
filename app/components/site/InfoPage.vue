<script setup lang="ts">
import type { FaqItem } from '~/types/database'

// Okvir za info stranice (dostava, zamjena): naslov, uvod i sekcije, uz česta pitanja s FAQ JSON-LD-om.
defineProps<{
  title: string
  intro: string
  faq?: FaqItem[]
}>()
</script>

<template>
  <article class="mx-auto max-w-3xl px-4 py-14 sm:px-6 sm:py-20">
    <SiteBreadcrumbs class="mb-6" :items="[{ label: 'Početna', to: '/' }, { label: title }]" />
    <h1 class="font-display text-5xl font-normal leading-tight">{{ title }}</h1>
    <span class="mb-6 mt-5 block h-px w-14 bg-gold" aria-hidden="true" />
    <p class="text-lg leading-relaxed text-muted">{{ intro }}</p>

    <div class="mt-10 space-y-10 leading-relaxed [&_h2]:mb-3 [&_h2]:font-display [&_h2]:text-3xl [&_h2]:font-normal [&_p+p]:mt-3 [&_ul]:list-disc [&_ul]:space-y-1 [&_ul]:pl-5">
      <slot />
    </div>

    <SiteFaq v-if="faq?.length" class="mt-12 border-t border-line pt-10" :items="faq" />

    <p class="mt-12 text-muted">
      Imate pitanje? <NuxtLink to="/kontakt" class="text-ink underline underline-offset-4 hover:text-gold">Javite nam se</NuxtLink>.
    </p>
  </article>
</template>
