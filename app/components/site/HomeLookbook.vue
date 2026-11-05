<script setup lang="ts">
import { HOME_LOOKBOOK } from '~/config/home'

const categoryLink = useCategoryLink()

// Velike fotografije zauzimaju 2×2 polja na računalu i cijeli red na mobitelu.
// Uz 15 fotografija ovaj raspored puni 6 redova po 4 polja bez praznina (lijevo, desno, lijevo).
const LOOKBOOK_LARGE = new Set([0, 7, 10])
</script>

<template>
  <section aria-labelledby="naslov-lookbook" class="mx-auto max-w-7xl px-4 py-14 sm:px-6 lg:px-8 lg:py-28">
    <div class="mb-8 grid gap-4 lg:mb-12 lg:grid-cols-2 lg:items-end lg:gap-16">
      <div>
        <p class="mb-2 text-xs font-medium uppercase tracking-[0.24em] text-gold">{{ HOME_LOOKBOOK.eyebrow }}</p>
        <h2 id="naslov-lookbook" class="font-display text-4xl font-normal leading-tight lg:text-5xl">{{ HOME_LOOKBOOK.title }}</h2>
      </div>
      <div>
        <p class="max-w-[52ch] leading-relaxed text-muted">{{ HOME_LOOKBOOK.text }}</p>
        <NuxtLink
          :to="categoryLink(HOME_LOOKBOOK.link.slug)"
          class="mt-3 inline-flex min-h-11 items-center text-xs font-medium uppercase tracking-[0.16em] underline underline-offset-[6px]"
        >
          {{ HOME_LOOKBOOK.link.label }}
        </NuxtLink>
      </div>
    </div>

    <ul class="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
      <li
        v-for="(image, index) in HOME_LOOKBOOK.images"
        :key="index"
        class="overflow-hidden"
        :class="[
          LOOKBOOK_LARGE.has(index) ? 'col-span-2 aspect-4/5 sm:aspect-square lg:row-span-2 lg:aspect-auto' : 'aspect-3/4',
          index % 2 ? 'bg-photo-dark' : 'bg-photo',
        ]"
      >
        <img
          v-if="image.src"
          :src="image.src"
          :alt="image.alt"
          loading="lazy"
          :width="LOOKBOOK_LARGE.has(index) ? 900 : 600"
          :height="LOOKBOOK_LARGE.has(index) ? 1200 : 800"
          class="size-full object-cover"
        >
      </li>
    </ul>
  </section>
</template>
