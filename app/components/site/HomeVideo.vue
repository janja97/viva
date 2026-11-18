<script setup lang="ts">
import { HOME_VIDEO } from '~/config/home'

// "Kolekcija u pokretu": video, a dok ga nema kolaž fotografija (HOME_VIDEO.images).
// Fotografije različitih veličina spojene su bez razmaka, kao jedna slika. Koja ide na koje mjesto je u HOME_VIDEO.order.
// Izmiješano, da cijele figure i detalji nisu grupirani.
// Računalo, mreža 4 × 3 kvadrata: visoka | velika (2 × 2) | mali detalj iznad visoke; dolje široka, mala i visoka.
// Mobitel, mreža 2 × 6: velika preko cijele širine, pa visoke i male naizmjence lijevo i desno.
const categoryLink = useCategoryLink()
const PLACES = [
  // velika
  { area: 'col-start-1 col-span-2 row-start-1 row-span-2 md:col-start-2 md:col-span-2 md:row-start-1 md:row-span-2', focus: 'object-top' },
  // visoka
  { area: 'col-start-2 row-start-3 row-span-2 md:col-start-1 md:row-start-1 md:row-span-2', focus: 'object-center' },
  // visoka
  { area: 'col-start-1 row-start-5 row-span-2 md:col-start-4 md:row-start-2 md:row-span-2', focus: 'object-center' },
  // mala
  { area: 'col-start-1 row-start-3 md:col-start-4 md:row-start-1', focus: 'object-[50%_30%]' },
  // mala
  { area: 'col-start-1 row-start-4 md:col-start-3 md:row-start-3', focus: 'object-[30%_55%]' },
  // široka na računalu, visoka na mobitelu
  { area: 'col-start-2 row-start-5 row-span-2 md:col-start-1 md:col-span-2 md:row-start-3 md:row-span-1', focus: 'object-[50%_40%]' },
]
const tiles = HOME_VIDEO.order
  .map((index, position) => ({ image: HOME_VIDEO.images[index], place: PLACES[position] }))
  .filter((tile) => tile.image && tile.place)
</script>

<template>
  <section aria-labelledby="naslov-video" class="bg-sand py-14 lg:py-28">
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="mb-8 flex flex-wrap items-end justify-between gap-4 lg:mb-12">
        <div>
          <p class="mb-2 text-xs font-medium uppercase tracking-[0.24em] text-ink">{{ HOME_VIDEO.eyebrow }}</p>
          <h2 id="naslov-video" class="font-display text-4xl font-normal leading-tight lg:text-5xl">{{ HOME_VIDEO.title }}</h2>
        </div>
        <NuxtLink
          :to="categoryLink(HOME_VIDEO.link.slug)"
          class="inline-flex min-h-11 items-center text-xs font-medium uppercase tracking-[0.16em] underline underline-offset-[6px]"
        >
          {{ HOME_VIDEO.link.label }}
        </NuxtLink>
      </div>

      <!-- Uspravno na mobitelu, široko od tableta. -->
      <div v-if="HOME_VIDEO.src" class="aspect-4/5 overflow-hidden bg-photo-dark sm:aspect-video">
        <video
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

      <ul v-else-if="tiles.length === PLACES.length" class="grid aspect-2/5 grid-cols-2 grid-rows-6 md:aspect-4/3 md:grid-cols-4 md:grid-rows-3">
        <li v-for="tile in tiles" :key="tile.image!.src" class="overflow-hidden bg-photo-dark" :class="tile.place!.area">
          <img :src="tile.image!.src" :alt="tile.image!.alt" loading="lazy" width="900" height="1125" class="block size-full object-cover" :class="tile.place!.focus">
        </li>
      </ul>

      <div v-else class="aspect-4/5 bg-photo-dark sm:aspect-video" />
    </div>
  </section>
</template>
