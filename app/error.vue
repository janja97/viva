<script setup lang="ts">
import type { NuxtError } from '#app'

// Stranica greške. Za 404 nudi pretragu i glavne kategorije, da kupac ne ode sa stranice
// (npr. stara poveznica na rasprodan ili maknut proizvod). Nikad ne ide u Google (noindex).
const props = defineProps<{ error: NuxtError }>()

const isNotFound = computed(() => props.error.status === 404)
const title = computed(() => (isNotFound.value ? 'Stranica nije pronađena' : 'Došlo je do greške'))
const text = computed(() => (isNotFound.value
  ? 'Stranica koju tražite ne postoji ili je proizvod više nije u ponudi. Potražite ga ili pogledajte kolekciju.'
  : 'Nešto nije u redu na našoj strani. Pokušajte ponovno za nekoliko trenutaka.'))

useSeoMeta({ title, robots: 'noindex, nofollow' })

const { to: shopLink } = useShopNavLink()
const shopNav = useShopNav()
</script>

<template>
  <NuxtLayout name="default">
    <section class="mx-auto max-w-2xl px-4 py-20 text-center sm:py-24">
      <p class="text-xs uppercase tracking-[0.25em] text-gold">{{ error.status }}</p>
      <h1 class="mt-3 font-display text-4xl font-medium sm:text-5xl">{{ title }}</h1>
      <p class="mx-auto mt-5 max-w-md leading-relaxed text-muted">{{ text }}</p>

      <template v-if="isNotFound">
        <SiteSearch class="mx-auto mt-8 max-w-md text-left" />

        <nav v-if="shopNav.length" aria-label="Kategorije" class="mt-10">
          <ul class="flex flex-wrap justify-center gap-2">
            <li v-for="link in shopNav" :key="link.label">
              <NuxtLink
                :to="shopLink(link)"
                class="inline-flex min-h-11 items-center border border-line px-5 text-xs font-medium uppercase tracking-[0.18em] transition-colors hover:border-graphite"
              >
                {{ link.label }}
              </NuxtLink>
            </li>
          </ul>
        </nav>
      </template>

      <div class="mt-10 flex flex-wrap justify-center gap-3">
        <button
          type="button"
          class="inline-flex min-h-12 cursor-pointer items-center justify-center border border-graphite bg-graphite px-8 text-xs font-medium uppercase tracking-[0.2em] text-ivory transition-colors hover:bg-transparent hover:text-graphite"
          @click="clearError({ redirect: '/' })"
        >
          Natrag na početnu
        </button>
        <button
          v-if="isNotFound"
          type="button"
          class="inline-flex min-h-12 cursor-pointer items-center justify-center border border-graphite px-8 text-xs font-medium uppercase tracking-[0.2em] text-graphite transition-colors hover:bg-graphite hover:text-ivory"
          @click="clearError({ redirect: '/proizvodi' })"
        >
          Cijela kolekcija
        </button>
      </div>
    </section>
  </NuxtLayout>
</template>
