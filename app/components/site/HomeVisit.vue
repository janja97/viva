<script setup lang="ts">
import { HOME_VISIT_IMAGE } from '~/config/home'
import { STORE } from '~/config/store'
</script>

<template>
  <section aria-labelledby="naslov-posjet" class="mx-auto grid max-w-7xl items-center gap-10 px-4 pb-14 sm:px-6 sm:py-20 md:grid-cols-2 lg:gap-24 lg:px-8 lg:py-28">
    <div class="hidden aspect-4/5 overflow-hidden bg-photo-dark sm:block">
      <img v-if="HOME_VISIT_IMAGE" :src="HOME_VISIT_IMAGE" alt="Interijer butika u Mepas Mallu" loading="lazy" width="800" height="1000" class="size-full object-cover">
    </div>
    <div class="bg-champagne px-6 py-8 sm:bg-transparent sm:p-0">
      <p class="text-xs font-medium uppercase tracking-[0.24em] text-ink sm:text-gold">Posjetite nas</p>
      <h2 id="naslov-posjet" class="mb-5 mt-3 font-display text-[34px] font-normal leading-tight sm:mb-6 sm:text-5xl">
        <span class="sm:hidden">Butik u Mepas Mallu</span>
        <span class="hidden sm:inline">Butik u srcu <em class="block text-gold">Mostara</em></span>
      </h2>
      <address class="not-italic leading-relaxed text-muted">
        {{ STORE.mall }}<br>
        {{ STORE.street }}, {{ STORE.postalCode }} {{ STORE.city }}
      </address>
      <p class="mb-6 mt-4 text-muted">{{ STORE.hours }}</p>
      <div class="flex flex-wrap items-center gap-4">
        <a
          :href="STORE.mapUrl"
          target="_blank"
          rel="noopener"
          class="inline-flex min-h-13 items-center justify-center border border-ink px-8 text-xs font-medium uppercase tracking-[0.2em] transition-colors hover:bg-ink hover:text-white"
        >
          Upute do butika
        </a>
        <a
          v-if="STORE.phone"
          :href="`tel:${STORE.phone.replace(/\s/g, '')}`"
          class="hidden min-h-11 items-center text-xs font-medium uppercase tracking-[0.16em] text-gold sm:inline-flex"
        >
          Pozovi: {{ STORE.phone }}
        </a>
      </div>
    </div>
  </section>
</template>
