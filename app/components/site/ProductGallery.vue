<script setup lang="ts">
import { ChevronLeft, ChevronRight } from '@lucide/vue'

// Slike proizvoda. Na mobitelu (ispod md) vrtuljak: sam se okreće, a kupac ga može povući prstom ili crticama.
// Od md je velika slika sa strelicama i male sličice ispod: klik na sličicu je prikaže kao veliku.
// Slike se prikazuju cijele (object-contain), da se proizvod ne odreže sa strane.
const props = defineProps<{
  images: { id: string; url: string; alt: string }[]
}>()

const ARROWS = [
  { step: -1, label: 'Prethodna slika', icon: ChevronLeft },
  { step: 1, label: 'Sljedeća slika', icon: ChevronRight },
]

// Velika slika na računalu.
const selected = ref(0)
const main = computed(() => props.images[selected.value] ?? props.images[0])
function select(index: number) {
  if (!props.images.length) return
  selected.value = (index + props.images.length) % props.images.length
}

const AUTOPLAY_MS = 4000
const track = useTemplateRef<HTMLElement>('track')
const active = ref(0)
// Nakon što kupac sam pomakne slike, vrtuljak čeka malo dulje prije nego što nastavi sam.
const pausedUntil = ref(0)
const isHeld = ref(false)

function goTo(index: number, smooth = true) {
  const element = track.value
  if (!element || !props.images.length) return
  const target = (index + props.images.length) % props.images.length
  element.scrollTo({ left: target * element.clientWidth, behavior: smooth ? 'smooth' : 'auto' })
  active.value = target
}

function onScroll() {
  const element = track.value
  if (!element?.clientWidth) return
  active.value = Math.round(element.scrollLeft / element.clientWidth)
}

function pauseAfterUser() {
  pausedUntil.value = Date.now() + AUTOPLAY_MS * 2
}

function onDot(index: number) {
  pauseAfterUser()
  goTo(index)
}

// Druga boja ima druge slike, pa vrtuljak kreće od prve.
watch(() => props.images.map((image) => image.id).join(), () => {
  active.value = 0
  selected.value = 0
  nextTick(() => goTo(0, false))
})

let timer: ReturnType<typeof setInterval> | undefined
onMounted(() => {
  // Tko je u sustavu isključio animacije, slike pomiče sam.
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return
  timer = setInterval(() => {
    const element = track.value
    // Vrtuljak je skriven od md, pa se tada ne okreće.
    if (!element?.offsetParent || props.images.length < 2) return
    if (isHeld.value || document.hidden || Date.now() < pausedUntil.value) return
    goTo(active.value + 1)
  }, AUTOPLAY_MS)
})
onBeforeUnmount(() => clearInterval(timer))
</script>

<template>
  <div>
    <!-- Mobitel: vrtuljak -->
    <div v-if="images.length" class="md:hidden" aria-roledescription="vrtuljak" aria-label="Slike proizvoda">
      <ul
        ref="track"
        class="-mx-4 flex snap-x snap-mandatory overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
        @scroll.passive="onScroll"
        @touchstart.passive="isHeld = true; pauseAfterUser()"
        @touchend.passive="isHeld = false"
        @touchcancel.passive="isHeld = false"
      >
        <li
          v-for="(image, index) in images"
          :key="image.id"
          class="aspect-4/5 w-full flex-none snap-center snap-always"
          aria-roledescription="slika"
          :aria-label="`${index + 1} od ${images.length}`"
        >
          <img
            :src="image.url"
            :alt="image.alt"
            width="1000"
            height="1250"
            :loading="index === 0 ? 'eager' : 'lazy'"
            :fetchpriority="index === 0 ? 'high' : undefined"
            draggable="false"
            data-fly-source
            class="size-full object-contain"
          >
        </li>
      </ul>

      <div v-if="images.length > 1" class="mt-3 flex justify-center gap-1">
        <button
          v-for="(image, index) in images"
          :key="image.id"
          type="button"
          class="flex h-11 w-8 cursor-pointer items-center justify-center"
          :aria-label="`Slika ${index + 1} od ${images.length}`"
          :aria-current="index === active ? 'true' : undefined"
          @click="onDot(index)"
        >
          <span class="block h-0.5 transition-all" :class="index === active ? 'w-6 bg-ink' : 'w-3 bg-line'" />
        </button>
      </div>
    </div>

    <!-- Računalo i tablet: velika slika sa strelicama i male sličice ispod; klik na sličicu je prikaže kao veliku. -->
    <div v-if="main" class="hidden md:block" aria-roledescription="galerija" aria-label="Slike proizvoda">
      <div class="group relative aspect-4/5 overflow-hidden">
        <!-- Prva slika ima istu adresu kao prva slika vrtuljka, pa se preuzima samo jednom. Bez lazy, jer je to glavna slika stranice (LCP). -->
        <img
          :key="main.id"
          :src="main.url"
          :alt="main.alt"
          width="1000"
          height="1250"
          :fetchpriority="selected === 0 ? 'high' : undefined"
          data-fly-source
          class="size-full animate-[fade-in_300ms_ease-out] object-contain"
        >
        <template v-if="images.length > 1">
          <button
            v-for="arrow in ARROWS"
            :key="arrow.step"
            type="button"
            class="absolute top-1/2 flex size-11 -translate-y-1/2 cursor-pointer items-center justify-center rounded-full border border-line bg-ivory/90 text-ink opacity-0 transition-opacity hover:border-ink focus-visible:opacity-100 group-hover:opacity-100"
            :class="arrow.step < 0 ? 'left-3' : 'right-3'"
            :aria-label="arrow.label"
            @click="select(selected + arrow.step)"
          >
            <component :is="arrow.icon" class="size-4" stroke-width="1.5" />
          </button>
          <span class="absolute bottom-3 right-3 bg-ivory/90 px-2 py-1 text-[11px] tabular-nums tracking-[0.14em] text-muted">
            {{ selected + 1 }} / {{ images.length }}
          </span>
        </template>
      </div>

      <ul v-if="images.length > 1" class="mt-3 flex gap-2 overflow-x-auto pb-1 [scrollbar-width:thin]">
        <li v-for="(image, index) in images" :key="image.id" class="flex-none">
          <button
            type="button"
            class="block aspect-4/5 w-16 cursor-pointer overflow-hidden border transition-colors lg:w-20"
            :class="index === selected ? 'border-ink' : 'border-transparent opacity-70 hover:opacity-100'"
            :aria-label="`Prikaži sliku ${index + 1} od ${images.length}`"
            :aria-current="index === selected ? 'true' : undefined"
            @click="select(index)"
          >
            <img :src="cardImageUrl(image.url, 200)" :alt="''" loading="lazy" width="80" height="100" class="size-full object-contain">
          </button>
        </li>
      </ul>
    </div>
  </div>
</template>
