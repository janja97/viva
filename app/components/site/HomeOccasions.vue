<script setup lang="ts">
import { HOME_OCCASIONS } from '~/config/home'

// Haljine po prigodi: poveznice na podkategorije haljina, da su haljine istaknute cijelu godinu.
// Prikazuju se samo uključene kategorije, pa poveznica nikad ne vodi na praznu stranicu.
const { data: categories } = useSiteCategories()
const items = computed(() => HOME_OCCASIONS.items.filter((item) => categories.value.some((category) => category.slug === item.slug)))
</script>

<template>
  <section v-if="items.length" class="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8 lg:py-24">
    <SectionHeading :eyebrow="HOME_OCCASIONS.eyebrow" :title="HOME_OCCASIONS.title" link-to="/kategorija/haljine" link-label="Sve haljine" link-label-short="Sve" />
    <ul class="grid border-l border-t border-line sm:grid-cols-2 lg:grid-cols-3">
      <li v-for="(item, index) in items" :key="item.slug" class="border-b border-r border-line">
        <NuxtLink :to="`/kategorija/${item.slug}`" class="group flex h-full min-h-40 flex-col justify-between gap-6 bg-white p-6 transition-colors hover:bg-champagne lg:p-8">
          <span class="text-xs font-medium tracking-[0.24em] text-gold" aria-hidden="true">{{ String(index + 1).padStart(2, '0') }}</span>
          <span>
            <span class="block font-display text-3xl font-normal leading-tight">{{ item.title }}</span>
            <span class="mt-2 block text-sm leading-relaxed text-muted">{{ item.text }}</span>
          </span>
        </NuxtLink>
      </li>
    </ul>
  </section>
</template>
