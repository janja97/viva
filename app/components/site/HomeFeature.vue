<script setup lang="ts">
// Istaknuta sekcija naslovne: fotografija s jedne i tekst s druge strane (npr. čizme, čišćenje zaliha).
// Bez fotografije ostaje obojena podloga.
defineProps<{
  eyebrow: string
  title: string
  accent?: string
  text: string
  linkLabel: string
  to: string
  image?: string
  imageAlt?: string
  // Fotografija desno umjesto lijevo (na računalu).
  reverse?: boolean
  // Tamna podloga za akcije, svijetla za kolekcije.
  dark?: boolean
}>()
</script>

<template>
  <section class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8 lg:py-12">
    <div class="grid sm:grid-cols-2" :class="dark ? 'bg-graphite text-white' : 'bg-sand'">
      <div class="aspect-4/3 overflow-hidden bg-photo-dark sm:aspect-auto sm:min-h-[420px] lg:min-h-[520px]" :class="reverse && 'sm:order-last'">
        <img v-if="image" :src="image" :alt="imageAlt ?? ''" loading="lazy" width="900" height="1200" class="size-full object-cover object-[50%_25%]">
      </div>
      <div class="flex flex-col justify-center px-6 py-10 sm:px-10 lg:px-16">
        <p class="text-xs font-medium uppercase tracking-[0.24em]" :class="dark ? 'text-gold-light' : 'text-ink'">{{ eyebrow }}</p>
        <h2 class="mt-3 font-display text-4xl font-normal leading-tight lg:text-5xl">
          {{ title }}
          <em v-if="accent" class="block" :class="dark ? 'text-gold-light' : 'text-gold'">{{ accent }}</em>
        </h2>
        <p class="mt-4 max-w-[44ch] leading-relaxed" :class="dark ? 'text-white/80' : 'text-muted'">{{ text }}</p>
        <NuxtLink
          :to="to"
          class="mt-7 inline-flex min-h-13 items-center justify-center self-start border px-8 text-xs font-medium uppercase tracking-[0.2em] transition-colors"
          :class="dark ? 'border-gold text-gold-light hover:bg-gold hover:text-graphite' : 'border-ink hover:bg-ink hover:text-white'"
        >
          {{ linkLabel }}
        </NuxtLink>
      </div>
    </div>
  </section>
</template>
