<script setup lang="ts">
import { ChevronDown } from '@lucide/vue'
import type { ShopNavLink } from '~/config/navigation'

// Stavka glavnog izbornika na računalu. Podkategorije se otvaraju prelaskom mišem ili tipkovnicom (fokus).
const props = defineProps<{ link: ShopNavLink; linkClass: string }>()

const { to, isActive, subcategories } = useShopNavLink()
const children = computed(() => subcategories(props.link))
const active = computed(() => isActive(props.link))

// Nakon klika fokus ostaje na poveznici, pa bi izbornik ostao otvoren i na novoj stranici.
const item = useTemplateRef('item')
const route = useRoute()
watch(() => route.fullPath, () => {
  if (item.value?.contains(document.activeElement)) (document.activeElement as HTMLElement).blur()
})
</script>

<template>
  <li ref="item" class="group relative">
    <NuxtLink
      :to="to(link)"
      :class="[linkClass, 'gap-1', (link.highlight || active) && 'text-gold']"
      :aria-current="active ? 'page' : undefined"
    >
      {{ link.label }}
      <ChevronDown
        v-if="children.length"
        class="size-3.5 transition-transform group-hover:rotate-180 group-focus-within:rotate-180"
        stroke-width="1.5"
        aria-hidden="true"
      />
    </NuxtLink>

    <div
      v-if="children.length"
      class="invisible absolute left-1/2 top-full z-50 -translate-x-1/2 pt-2 opacity-0 transition-opacity group-hover:visible group-hover:opacity-100 group-focus-within:visible group-focus-within:opacity-100"
    >
      <ul class="min-w-52 border border-line bg-ivory py-3">
        <li v-for="child in children" :key="child.id">
          <NuxtLink
            :to="`/kategorija/${child.slug}`"
            class="flex min-h-10 items-center whitespace-nowrap px-6 text-sm text-ink transition-colors hover:text-gold"
            active-class="text-gold"
          >
            {{ child.name }}
          </NuxtLink>
        </li>
      </ul>
    </div>
  </li>
</template>
