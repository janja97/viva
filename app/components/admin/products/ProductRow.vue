<script setup lang="ts">
import { Archive, ArchiveRestore, Eye, ImageOff, MessageCircle, Pencil, Trash2 } from '@lucide/vue'
import type { ProductListRow } from '~/composables/useProducts'
import { EXCLUSIVE_PROMO_PAGE } from '~/config/navigation'

defineProps<{
  product: ProductListRow
  canWrite: boolean
  archived?: boolean
  selected?: boolean
}>()

const emit = defineEmits<{ archive: []; restore: []; delete: []; editStock: []; toggle: [] }>()
</script>

<template>
  <!-- Na mobitelu je kartica (velika slika lijevo, podaci jedan ispod drugoga), a od sm: redak s većom slikom. -->
  <div class="flex gap-3 px-3 py-3 sm:gap-4 sm:px-4" :class="selected && 'bg-primary-50'">
    <div class="relative w-28 shrink-0 sm:w-20">
      <NuxtLink :to="`/admin/proizvodi/${product.id}`" class="block" :aria-label="`Uredi: ${product.name}`" tabindex="-1">
        <img v-if="product.thumbnail" :src="product.thumbnail" alt="" loading="lazy" class="aspect-3/4 w-full border border-primary-300 bg-primary-50 object-cover">
        <span v-else class="flex aspect-3/4 w-full items-center justify-center border border-primary-300 bg-primary-50 text-primary-500">
          <ImageOff class="size-6" stroke-width="1.75" />
        </span>
      </NuxtLink>
      <!-- Kvačica je preko kuta slike, da ne uzima širinu. Dodirna površina je 44 px. -->
      <label v-if="canWrite" class="absolute left-0 top-0 flex size-11 cursor-pointer items-start justify-start p-1.5">
        <span class="flex size-6 items-center justify-center bg-white/90">
          <input
            type="checkbox"
            class="size-4 cursor-pointer accent-primary-700"
            :checked="selected"
            :aria-label="`Odaberi: ${product.name}`"
            @change="emit('toggle')"
          >
        </span>
      </label>
    </div>

    <div class="flex min-w-0 flex-1 flex-col sm:flex-row sm:items-center sm:gap-4">
      <NuxtLink :to="`/admin/proizvodi/${product.id}`" class="block min-w-0 sm:flex-1">
        <span class="line-clamp-2 text-sm font-medium text-stone-900 sm:line-clamp-1">{{ product.name }}</span>
        <span class="mt-0.5 block text-sm text-stone-700">Šifra: <span class="font-semibold">{{ product.sku }}</span></span>
        <span class="block truncate text-xs text-stone-500">{{ product.categoryName }}<template v-if="product.brand"> · {{ product.brand }}</template></span>
        <!-- Ukupno pregleda i WhatsApp narudžbi (migracije 0041 i 0043). -->
        <span class="mt-1 flex items-center gap-3 text-xs tabular-nums text-stone-500" :title="`${product.views} pregleda, ${product.whatsappOrders} preko WhatsAppa`">
          <span class="inline-flex items-center gap-1"><Eye class="size-3.5" stroke-width="1.75" aria-hidden="true" />{{ product.views }}<span class="sr-only"> pregleda</span></span>
          <span class="inline-flex items-center gap-1"><MessageCircle class="size-3.5" stroke-width="1.75" aria-hidden="true" />{{ product.whatsappOrders }}<span class="sr-only"> preko WhatsAppa</span></span>
        </span>
        <span class="mt-1.5 flex flex-wrap items-center gap-1.5">
          <ColorSwatch v-for="color in product.colors" :key="color.id" class="size-4" :name="color.name" :hex="color.hex" />
          <span v-if="!product.isVisible && !archived" class="bg-stone-200 px-1.5 py-0.5 text-xs text-stone-700">Skriveno</span>
          <span v-if="product.storeOnly" class="bg-primary-200 px-1.5 py-0.5 text-xs text-primary-900">Samo u poslovnicama</span>
          <span v-if="product.onPromoPage" class="bg-amber-100 px-1.5 py-0.5 text-xs text-amber-800">{{ EXCLUSIVE_PROMO_PAGE.label }}</span>
          <span v-if="product.stock === 0" class="bg-red-100 px-1.5 py-0.5 text-xs text-red-800">Rasprodano</span>
        </span>
      </NuxtLink>

      <p class="mt-2 flex flex-wrap items-baseline gap-x-2 sm:mt-0 sm:block sm:shrink-0 sm:text-right">
        <span class="whitespace-nowrap text-base font-semibold sm:text-sm">{{ formatPrice(product.salePrice ?? product.price) }}</span>
        <del v-if="product.salePrice !== null" class="whitespace-nowrap text-xs text-stone-500 sm:block">{{ formatPrice(product.price) }}</del>
      </p>

      <div class="mt-auto flex items-center justify-between gap-2 sm:mt-0 sm:shrink-0">
        <button
          v-if="canWrite && !archived"
          type="button"
          :aria-label="`Uredi količinu: ${product.name}, trenutno ${product.stock} kom`"
          class="inline-flex min-h-11 cursor-pointer items-center whitespace-nowrap text-sm font-medium text-primary-800 underline underline-offset-4 hover:text-primary-900 sm:min-h-8 sm:w-16 sm:justify-end sm:text-xs"
          @click="emit('editStock')"
        >
          {{ product.stock }} kom
        </button>
        <p v-else class="whitespace-nowrap text-sm text-stone-500 sm:w-16 sm:text-right sm:text-xs">{{ product.stock }} kom</p>

        <div class="-mr-2 flex items-center">
          <NuxtLink
            :to="{ path: `/admin/proizvodi/${product.id}`, query: { pregled: 1 } }"
            :aria-label="`Pregledaj: ${product.name}`"
            :title="`Pregledaj: ${product.name}`"
            class="inline-flex size-11 items-center justify-center text-stone-500 hover:bg-primary-100 hover:text-primary-700 sm:size-8"
          >
            <Eye class="size-4" stroke-width="1.75" />
          </NuxtLink>
          <template v-if="canWrite && archived">
            <IconButton :label="`Vrati iz arhive: ${product.name}`" @click="emit('restore')">
              <ArchiveRestore class="size-4" stroke-width="1.75" />
            </IconButton>
            <IconButton :label="`Obriši trajno: ${product.name}`" danger @click="emit('delete')">
              <Trash2 class="size-4" stroke-width="1.75" />
            </IconButton>
          </template>
          <template v-else-if="canWrite">
            <NuxtLink :to="`/admin/proizvodi/${product.id}`" :aria-label="`Uredi: ${product.name}`" :title="`Uredi: ${product.name}`" class="inline-flex size-11 items-center justify-center text-stone-500 hover:bg-primary-100 hover:text-primary-700 sm:size-8">
              <Pencil class="size-4" stroke-width="1.75" />
            </NuxtLink>
            <IconButton :label="`Arhiviraj: ${product.name}`" @click="emit('archive')">
              <Archive class="size-4" stroke-width="1.75" />
            </IconButton>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>
