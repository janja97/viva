<script setup lang="ts">
import { HOME_CATEGORIES } from '~/config/home'

const categoryLink = useCategoryLink()
</script>

<template>
  <section class="mx-auto hidden max-w-7xl px-4 py-20 sm:block sm:px-6 lg:px-8 lg:py-28">
    <SectionHeading title="Kategorije" link-to="/proizvodi" link-label="Sve kategorije" />
    <ul class="grid grid-cols-3 gap-4 lg:grid-cols-5">
      <li v-for="(category, index) in HOME_CATEGORIES" :key="category.slug">
        <NuxtLink :to="categoryLink(category.slug)" class="group block">
          <div class="aspect-3/4 overflow-hidden" :class="index % 2 ? 'bg-photo-dark' : 'bg-photo'">
            <img v-if="category.image" :src="category.image" :alt="category.imageAlt ?? category.title" loading="lazy" width="600" height="800" class="size-full object-cover">
          </div>
          <h3 class="mt-3.5 font-display text-2xl font-normal group-hover:text-gold">{{ category.title }}</h3>
        </NuxtLink>
      </li>
    </ul>
  </section>
</template>
