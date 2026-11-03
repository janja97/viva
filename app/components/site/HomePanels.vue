<script setup lang="ts">
import { HOME_PANELS } from '~/config/home'

const categoryLink = useCategoryLink()
</script>

<template>
  <section aria-label="Izdvojene kolekcije" class="mx-auto hidden max-w-7xl gap-4 px-4 sm:grid sm:grid-cols-2 sm:px-6 lg:px-8">
    <article
      v-for="panel in HOME_PANELS"
      :key="panel.title"
      class="flex min-h-96 flex-col justify-between gap-10 p-8 lg:min-h-[500px] lg:p-16"
      :class="panel.tone === 'white' ? 'border border-line bg-white' : 'bg-champagne'"
    >
      <!-- Sitni zlatni tekst na šampanjcu nema dovoljan kontrast. -->
      <p class="text-xs font-medium uppercase tracking-[0.24em]" :class="panel.tone === 'white' ? 'text-gold' : 'text-ink'">{{ panel.eyebrow }}</p>
      <div>
        <h2 class="font-display text-4xl font-normal leading-tight lg:text-5xl">
          {{ panel.title }} <em class="block" :class="panel.tone !== 'white' && 'text-gold'">{{ panel.accent }}</em>
        </h2>
        <p class="mb-5 mt-4 max-w-[44ch] leading-relaxed text-muted">{{ panel.text }}</p>
        <NuxtLink :to="categoryLink(panel.slug)" class="inline-flex min-h-11 items-center text-xs font-medium uppercase tracking-[0.16em] underline underline-offset-[6px]">
          {{ panel.link }}
        </NuxtLink>
      </div>
    </article>
  </section>
</template>
