<script setup lang="ts">
import { ArrowUpRight } from '@lucide/vue'
import { STORE } from '~/config/store'

// Karta trgovine (HomeVisit, /kontakt). Klik bilo gdje na kartu otvara Google profil trgovine
// (recenzije, fotografije, radno vrijeme, upute), pa se karta ne pomiče mišem.
const { siteName } = useRuntimeConfig().public
</script>

<template>
  <div class="relative overflow-hidden border border-line bg-photo">
    <iframe
      :src="STORE.mapEmbedUrl"
      :title="`Karta: ${STORE.mall}, ${STORE.street}, ${STORE.city}`"
      loading="lazy"
      referrerpolicy="no-referrer-when-downgrade"
      tabindex="-1"
      aria-hidden="true"
      class="size-full border-0 [filter:grayscale(0.6)_sepia(0.15)]"
    />
    <a
      :href="STORE.businessProfileUrl"
      target="_blank"
      rel="noopener"
      class="group absolute inset-0 flex items-end justify-end p-3 focus-visible:outline-2 focus-visible:-outline-offset-4 focus-visible:outline-gold"
      :aria-label="`${siteName} na Googleu: recenzije, fotografije i upute (otvara se u novoj kartici)`"
    >
      <span class="inline-flex min-h-11 items-center gap-2 bg-white/95 px-4 text-xs font-medium uppercase tracking-[0.16em] text-ink transition-colors group-hover:bg-graphite group-hover:text-white">
        Otvori na Googleu
        <ArrowUpRight class="size-4" stroke-width="1.5" />
      </span>
    </a>
  </div>
</template>
