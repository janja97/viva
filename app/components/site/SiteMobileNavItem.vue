<script setup lang="ts">
import { ChevronDown } from '@lucide/vue'
import type { ShopNavLink } from '~/config/navigation'

// Stavka izbornika ☰ na mobitelu. Naziv vodi na kategoriju, a strelica otvara podkategorije ispod nje.
const props = defineProps<{ link: ShopNavLink }>()

const route = useRoute()
const { to, isActive, subcategories } = useShopNavLink()
const children = computed(() => subcategories(props.link))
const active = computed(() => isActive(props.link))

// Otvorena je unaprijed ako je kupac već na nekoj od podkategorija.
const isOpen = ref(children.value.some((child) => route.path === `/kategorija/${child.slug}`))
const listId = useId()
</script>

<template>
  <li>
    <div class="flex items-center justify-between">
      <NuxtLink
        :to="to(link)"
        class="flex min-h-13 flex-1 items-center font-display text-[26px] leading-none"
        :class="(link.highlight || active) && 'text-gold'"
        :aria-current="active ? 'page' : undefined"
      >
        {{ link.label }}
      </NuxtLink>
      <button
        v-if="children.length"
        type="button"
        class="-mr-2 inline-flex size-11 items-center justify-center hover:text-gold"
        :aria-expanded="isOpen"
        :aria-controls="listId"
        :aria-label="`${isOpen ? 'Sakrij' : 'Prikaži'} podkategorije: ${link.label}`"
        @click="isOpen = !isOpen"
      >
        <ChevronDown class="size-5 transition-transform" :class="isOpen && 'rotate-180'" stroke-width="1.25" />
      </button>
    </div>

    <ul v-if="children.length" v-show="isOpen" :id="listId" class="mb-2 border-l border-line pl-4">
      <li v-for="child in children" :key="child.id">
        <NuxtLink
          :to="`/kategorija/${child.slug}`"
          class="flex min-h-11 items-center text-sm text-ink"
          active-class="text-gold"
        >
          {{ child.name }}
        </NuxtLink>
      </li>
    </ul>
  </li>
</template>
