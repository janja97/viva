<script setup lang="ts">
import { HOME_HIGHLIGHTS } from '~/config/home'
</script>

<template>
  <!-- Kratke, potvrđene prednosti trgovine (poklon bon, veličine, isprobavanje). Vidljivo i na mobitelu. -->
  <section :aria-label="HOME_HIGHLIGHTS.title" class="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8 lg:py-20">
    <SectionHeading :eyebrow="HOME_HIGHLIGHTS.eyebrow" :title="HOME_HIGHLIGHTS.title" />
    <ul class="grid gap-8 sm:grid-cols-3 lg:gap-12">
      <li v-for="item in HOME_HIGHLIGHTS.items" :key="item.title" class="border-t border-gold pt-5">
        <h3 class="font-display text-2xl font-normal">{{ item.title }}</h3>
        <p class="mt-2 text-sm leading-relaxed text-muted">{{ item.text }}</p>
      </li>
    </ul>
  </section>
</template>
