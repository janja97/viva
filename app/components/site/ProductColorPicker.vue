<script setup lang="ts">
import { PRODUCT_PATH } from '~/config/products'

// Odabir boje sličicama: glavna slika svake boje, s nazivom ispod. Svaka boja ima svoj URL, pa je sličica poveznica.
// Na računalu prelazak mišem (ili fokus tipkovnicom) odmah pokaže tu boju u velikoj galeriji (događaj `preview`),
// a odlazak vraća trenutnu. Rasprodana boja je prigušena, ali se može otvoriti.
// PROBNO: povratak na okrugle uzorke je COLOR_PICKER = 'swatches' u config/products.ts.
type PickerColor = {
  id: string
  name: string
  slug: string
  hex: string
  image: string | null
  soldOut: boolean
}

defineProps<{ colors: PickerColor[]; currentId: string }>()
const emit = defineEmits<{ preview: [colorId: string | null] }>()

// Pregled samo za miš: na dodir bi prvi dodir promijenio sliku umjesto da otvori boju.
const canHover = ref(false)
onMounted(() => {
  canHover.value = window.matchMedia('(hover: hover) and (pointer: fine)').matches
})

function preview(colorId: string | null) {
  if (canHover.value) emit('preview', colorId)
}
</script>

<template>
  <!-- p-1 i -m-1 ostavljaju mjesta za okvir odabrane boje, koji bi inače odrezao vodoravni pomak. -->
  <ul class="-m-1 flex gap-3 overflow-x-auto p-1 pb-2 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden" @mouseleave="preview(null)">
    <li v-for="item in colors" :key="item.id" class="w-18 flex-none sm:w-20">
      <NuxtLink
        :to="`${PRODUCT_PATH}/${item.slug}`"
        :aria-label="`Boja: ${item.name}${item.soldOut ? ', rasprodano' : ''}`"
        :aria-current="item.id === currentId ? 'page' : undefined"
        class="group block focus-visible:outline-none"
        @mouseenter="preview(item.id)"
        @focus="preview(item.id)"
        @blur="preview(null)"
      >
        <!-- Odabrana boja ima tanki tamni okvir s malim razmakom od slike; ostale ga dobivaju tek na prelazak mišem. -->
        <span
          class="relative block aspect-3/4 outline outline-offset-3 transition-[outline-color] duration-300 group-focus-visible:outline-gold"
          :class="item.id === currentId ? 'outline-ink' : 'outline-transparent group-hover:outline-line'"
        >
          <span class="block size-full overflow-hidden">
            <img
              v-if="item.image"
              :src="cardImageUrl(item.image, 200)"
              alt=""
              width="200"
              height="267"
              loading="lazy"
              class="size-full object-contain transition-transform duration-700 ease-out group-hover:scale-[1.06]"
              :class="item.soldOut && 'opacity-40 grayscale'"
            >
            <span v-else class="flex size-full items-center justify-center">
              <ColorSwatch class="size-8" :name="item.name" :hex="item.hex" />
            </span>
          </span>
          <span
            v-if="item.soldOut"
            class="absolute inset-x-0 bottom-0 bg-ivory/85 py-0.5 text-center text-[9px] font-medium uppercase tracking-[0.14em] text-muted"
          >
            Rasprodano
          </span>
        </span>
        <!-- Naziv je u sredini, a ispod odabrane boje je kratka zlatna crta. -->
        <span
          class="mt-2.5 block truncate text-center text-[10px] font-medium uppercase tracking-[0.16em] transition-colors"
          :class="item.id === currentId ? 'text-ink' : 'text-muted group-hover:text-ink'"
        >
          {{ item.name }}
        </span>
        <span
          class="mx-auto mt-1 block h-px bg-gold transition-all duration-300"
          :class="item.id === currentId ? 'w-5' : 'w-0 group-hover:w-3'"
          aria-hidden="true"
        />
      </NuxtLink>
    </li>
  </ul>
</template>
