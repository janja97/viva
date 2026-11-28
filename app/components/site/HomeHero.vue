<script setup lang="ts">
import { HOME_HERO } from '~/config/home'

const categoryLink = useCategoryLink()

// Fotografija heroja je najveći element naslovne (LCP). Najavljuje se u <head>, da je preglednik krene
// učitavati odmah, prije CSS-a i JavaScripta. Mobitel i računalo dobivaju samo svoju verziju (media).
useHead({
  link: [
    ...(HOME_HERO.imageMobile
      ? [{ rel: 'preload', as: 'image' as const, href: HOME_HERO.imageMobile, type: 'image/webp', media: '(max-width: 767px)', fetchpriority: 'high' as const, tagPriority: 'critical' as const }]
      : []),
    { rel: 'preload', as: 'image' as const, href: HOME_HERO.image, type: 'image/webp', media: HOME_HERO.imageMobile ? '(min-width: 768px)' : undefined, fetchpriority: 'high' as const, tagPriority: 'critical' as const },
  ],
})
</script>

<template>
  <!-- Na mobitelu je tekst preko donjeg dijela fotografije, na tamnom sloju (bijela i svijetlozlatna slova). Od md je tekst lijevo, a fotografija desno. -->
  <section class="relative grid md:min-h-[min(86vh,800px)] md:grid-cols-[9fr_11fr]">
    <div class="absolute inset-x-0 bottom-0 z-10 px-4 pb-8 text-white sm:px-6 md:static md:self-center md:text-ink md:px-8 md:py-14 lg:pl-[max(2rem,calc((100vw-80rem)/2+2rem))]">
      <p class="text-xs font-medium uppercase tracking-[0.2em] text-gold-light md:tracking-[0.24em] md:text-gold">
        {{ HOME_HERO.eyebrow }}<span class="hidden md:inline">{{ HOME_HERO.eyebrowExtra }}</span>
      </p>
      <h1 class="mb-4 mt-2.5 font-display text-[40px] font-normal leading-[1.1] md:mb-5 md:mt-4 md:text-6xl xl:text-[88px]">
        <span class="md:block">Elegancija</span>
        {{ ' ' }}
        <span class="md:block"><span class="md:italic md:text-gold">za svaki</span> <em class="text-white md:text-gold">važan</em></span>
        {{ ' ' }}
        <span class="italic text-white md:block md:not-italic md:text-ink">trenutak.</span>
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
      <!-- Mobitel dobiva uspravni izrez, a računalo cijeli kolaž (lijeva figura ostaje u kadru). -->
      <picture v-if="HOME_HERO.image">
        <source v-if="HOME_HERO.imageMobile" media="(max-width: 767px)" :srcset="HOME_HERO.imageMobile" width="760" height="1013">
        <img
          :src="HOME_HERO.image"
          :alt="HOME_HERO.imageAlt"
          width="1600"
          height="1112"
          fetchpriority="high"
          class="absolute inset-0 size-full object-cover object-top md:object-left"
        >
      </picture>
      <!-- Ujednačeni tamni sloj samo na mobitelu, da se bijeli tekst čita (bez gradijenta i bez vidljivog ruba). -->
      <span class="pointer-events-none absolute inset-0 bg-graphite/40 md:hidden" aria-hidden="true" />
      <span class="pointer-events-none absolute inset-7 hidden border border-gold-light md:block" aria-hidden="true" />
    </div>
  </section>
</template>
