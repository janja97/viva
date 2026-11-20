<script setup lang="ts">
// Slike proizvoda. Na mobitelu (ispod md) vrtuljak: sam se okreće, a kupac ga može povući prstom ili točkicama.
// Od md je mreža kao prije: prva slika velika, ostale dvije u redu.
// Slike se prikazuju cijele (object-contain), da se proizvod ne odreže sa strane.
const props = defineProps<{
  images: { id: string; url: string; alt: string }[]
}>()

const main = computed(() => props.images[0])
const rest = computed(() => props.images.slice(1))

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

    <!-- Računalo i tablet: mreža -->
    <div class="hidden grid-cols-2 gap-2 md:grid">
      <div class="col-span-2 aspect-4/5 overflow-hidden">
        <!-- Ista adresa kao prva slika vrtuljka, pa se preuzima samo jednom. Bez lazy, jer je to glavna slika stranice (LCP). -->
        <img v-if="main" :key="main.id" :src="main.url" :alt="main.alt" width="1000" height="1250" fetchpriority="high" data-fly-source class="size-full animate-[fade-in_300ms_ease-out] object-contain">
      </div>
      <div v-for="image in rest" :key="image.id" class="aspect-3/4 overflow-hidden">
        <img :src="image.url" :alt="image.alt" loading="lazy" width="600" height="800" class="size-full object-contain">
      </div>
    </div>
  </div>
</template>
