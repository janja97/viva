<script setup lang="ts">
import { HOME_HERO } from '~/config/home'

const categoryLink = useCategoryLink()
</script>

<template>
  <section class="relative grid bg-photo-dark md:min-h-[min(86vh,800px)] md:grid-cols-[9fr_11fr] md:bg-transparent">
    <div class="absolute inset-x-0 bottom-0 z-10 px-4 pb-8 sm:px-6 md:static md:self-center md:px-8 md:py-14 lg:pl-[max(2rem,calc((100vw-80rem)/2+2rem))]">
      <p class="text-xs font-medium uppercase tracking-[0.2em] text-ink md:tracking-[0.24em] md:text-gold">
        {{ HOME_HERO.eyebrow }}<span class="hidden md:inline">{{ HOME_HERO.eyebrowExtra }}</span>
      </p>
      <h1 class="mb-4 mt-2.5 font-display text-[40px] font-normal leading-[1.1] md:mb-5 md:mt-4 md:text-6xl xl:text-[88px]">
        <span class="md:block">Elegancija</span>
        {{ ' ' }}
        <span class="md:block"><span class="md:italic md:text-gold">za svaki</span> <em class="text-gold">važan</em></span>
        {{ ' ' }}
        <span class="italic text-gold md:block md:not-italic md:text-ink">trenutak.</span>
      </h1>
      <p class="mb-8 hidden max-w-[46ch] font-light leading-relaxed text-muted md:block">{{ HOME_HERO.text }}</p>
      <div class="flex flex-wrap gap-3">
        <SiteLink :to="categoryLink(HOME_HERO.primary.slug)">{{ HOME_HERO.primary.label }}</SiteLink>
        <div class="hidden md:block">
          <SiteLink variant="outline" :to="categoryLink(HOME_HERO.secondary.slug)">{{ HOME_HERO.secondary.label }}</SiteLink>
        </div>
      </div>
    </div>

    <div class="relative aspect-3/4 bg-photo-dark md:aspect-auto">
      <img
        v-if="HOME_HERO.image"
        :src="HOME_HERO.image"
        :alt="HOME_HERO.imageAlt"
        width="1100"
        height="1000"
        fetchpriority="high"
        class="absolute inset-0 size-full object-cover"
      >
      <span class="pointer-events-none absolute inset-7 hidden border border-gold-light md:block" aria-hidden="true" />
    </div>
  </section>
</template>
