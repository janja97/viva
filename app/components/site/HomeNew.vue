<script setup lang="ts">
import { ChevronLeft, ChevronRight } from '@lucide/vue'
import type { ShopCard } from '~/composables/useShop'
import { HOME_NEW } from '~/config/home'

// "Novo" na naslovnoj: vodoravni popis nasumično odabranih novih proizvoda (odabir radi naslovna pri svakom učitavanju).
// Popis se sam polako pomiče, a staje dok ga kupac dira, drži miš nad njim ili je u njemu tipkovnicom.
defineProps<{ cards: ShopCard[] }>()

const track = useTemplateRef<HTMLElement>('track')
const isPaused = ref(false)
const AUTOPLAY_MS = 4000

// Pomak za jednu karticu. Na kraju se vraća na početak, a na početku ide na kraj.
function move(direction: -1 | 1) {
  const element = track.value
  if (!element) return
  const step = (element.firstElementChild as HTMLElement | null)?.offsetWidth ?? element.clientWidth
  const end = element.scrollWidth - element.clientWidth
  if (direction === 1 && element.scrollLeft >= end - 4) element.scrollTo({ left: 0, behavior: 'smooth' })
  else if (direction === -1 && element.scrollLeft <= 4) element.scrollTo({ left: end, behavior: 'smooth' })
  else element.scrollBy({ left: direction * (step + 16), behavior: 'smooth' })
}

let timer: ReturnType<typeof setInterval> | undefined
onMounted(() => {
  // Tko je isključio animacije, popis pomiče sam.
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return
  timer = setInterval(() => {
    if (!isPaused.value && !document.hidden) move(1)
  }, AUTOPLAY_MS)
})
onBeforeUnmount(() => clearInterval(timer))

const arrowClass = 'hidden size-11 cursor-pointer items-center justify-center border border-line bg-white transition-colors hover:border-ink sm:inline-flex'
</script>

<template>
  <section class="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8 lg:py-24" aria-roledescription="vrtuljak" :aria-label="HOME_NEW.title">
    <div class="mb-8 flex items-end justify-between gap-4 lg:mb-12">
      <div>
        <p class="mb-2 hidden text-xs font-medium uppercase tracking-[0.24em] text-gold sm:block">{{ HOME_NEW.eyebrow }}</p>
        <h2 class="font-display text-4xl font-normal leading-tight lg:text-5xl">{{ HOME_NEW.title }}</h2>
      </div>
      <div class="flex flex-none items-center gap-2">
        <button type="button" :class="arrowClass" aria-label="Prethodni proizvodi" @click="move(-1)">
          <ChevronLeft class="size-4" stroke-width="1.5" />
        </button>
        <button type="button" :class="arrowClass" aria-label="Sljedeći proizvodi" @click="move(1)">
          <ChevronRight class="size-4" stroke-width="1.5" />
        </button>
        <NuxtLink to="/proizvodi" class="ml-2 inline-flex min-h-11 items-center text-xs font-medium uppercase tracking-[0.16em] text-gold hover:underline hover:underline-offset-4">
          <span class="sm:hidden">Sve</span>
          <span class="hidden sm:inline">Pogledaj sve</span>
          <span aria-hidden="true" class="ml-2">→</span>
        </NuxtLink>
      </div>
    </div>

    <ul
      ref="track"
      class="-mx-4 flex snap-x snap-mandatory gap-4 overflow-x-auto scroll-px-4 px-4 pb-2 [scrollbar-width:none] sm:mx-0 sm:scroll-px-0 sm:px-0 [&::-webkit-scrollbar]:hidden"
      @pointerenter="isPaused = true"
      @pointerleave="isPaused = false"
      @touchstart.passive="isPaused = true"
      @focusin="isPaused = true"
      @focusout="isPaused = false"
    >
      <li v-for="(card, index) in cards" :key="card.id" class="w-[46%] flex-none snap-start sm:w-[31%] lg:w-[23.5%]">
        <ProductCard :card="card" :eager="index < 2" is-new />
      </li>
    </ul>
  </section>
</template>
