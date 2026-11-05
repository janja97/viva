<script setup lang="ts">
import { HOME_PANELS } from '~/config/home'

const categoryLink = useCategoryLink()
</script>

<template>
  <section aria-label="Izdvojene kolekcije" class="mx-auto hidden max-w-7xl gap-4 px-4 sm:grid sm:grid-cols-2 sm:px-6 lg:px-8">
    <article
      v-for="panel in HOME_PANELS"
      :key="panel.title"
      class="relative isolate flex min-h-96 flex-col justify-between gap-10 overflow-hidden p-8 lg:min-h-[500px] lg:p-16"
      :class="panel.image ? 'bg-photo-dark text-ivory' : panel.tone === 'white' ? 'border border-line bg-white' : 'bg-champagne'"
    >
      <!-- Fotografija je pozadina, a tamni sloj preko nje čuva čitljivost svijetlog teksta. Lice je u gornjem dijelu kadra. -->
      <template v-if="panel.image">
        <img :src="panel.image" :alt="panel.imageAlt" loading="lazy" width="1080" height="1440" class="absolute inset-0 -z-10 size-full object-cover object-[50%_25%]">
        <span class="absolute inset-0 -z-10 bg-graphite/55" aria-hidden="true" />
      </template>

      <!-- Sitni zlatni tekst na šampanjcu nema dovoljan kontrast. -->
      <p
        class="text-xs font-medium uppercase tracking-[0.24em]"
        :class="panel.image ? 'text-gold-light' : panel.tone === 'white' ? 'text-gold' : 'text-ink'"
      >
        {{ panel.eyebrow }}
      </p>
      <div>
        <h2 class="font-display text-4xl font-normal leading-tight lg:text-5xl">
          {{ panel.title }}
          <em class="block" :class="panel.image ? 'text-gold-light' : panel.tone !== 'white' && 'text-gold'">{{ panel.accent }}</em>
        </h2>
        <p class="mb-5 mt-4 max-w-[44ch] leading-relaxed" :class="panel.image ? 'text-ivory/85' : 'text-muted'">{{ panel.text }}</p>
        <NuxtLink :to="categoryLink(panel.slug)" class="inline-flex min-h-11 items-center text-xs font-medium uppercase tracking-[0.16em] underline underline-offset-[6px]">
          {{ panel.link }}
        </NuxtLink>
      </div>
    </article>
  </section>
</template>
