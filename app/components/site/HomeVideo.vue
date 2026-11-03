<script setup lang="ts">
import { HOME_VIDEO } from '~/config/home'
</script>

<template>
  <section aria-labelledby="naslov-video" class="bg-sand py-14 lg:py-28">
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <p class="mb-2 text-xs font-medium uppercase tracking-[0.24em] text-ink">{{ HOME_VIDEO.eyebrow }}</p>
      <h2 id="naslov-video" class="mb-8 font-display text-4xl font-normal leading-tight lg:mb-12 lg:text-5xl">{{ HOME_VIDEO.title }}</h2>

      <!-- Uspravno na mobitelu, široko od tableta. Bez videa ostaje obojena podloga. -->
      <div class="aspect-4/5 overflow-hidden bg-photo-dark sm:aspect-video">
        <video
          v-if="HOME_VIDEO.src"
          :src="HOME_VIDEO.src"
          :poster="HOME_VIDEO.poster || undefined"
          :aria-label="HOME_VIDEO.label"
          autoplay
          muted
          loop
          playsinline
          preload="metadata"
          class="size-full object-cover"
        />
      </div>
    </div>
  </section>
</template>
