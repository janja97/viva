<script setup lang="ts">
import { Archive, ArchiveRestore, Eye, ImageOff, Pencil, Trash2 } from '@lucide/vue'
import type { ProductListRow } from '~/composables/useProducts'

defineProps<{
  product: ProductListRow
  canWrite: boolean
  archived?: boolean
  selected?: boolean
}>()

const emit = defineEmits<{ archive: []; restore: []; delete: []; editStock: []; toggle: [] }>()
</script>

<template>
  <div class="flex items-center gap-3 px-4 py-3" :class="selected && 'bg-primary-50'">
    <label v-if="canWrite" class="-my-2 -ml-3 -mr-1 flex size-11 shrink-0 cursor-pointer items-center justify-center sm:size-8">
      <input
        type="checkbox"
        class="size-4 cursor-pointer accent-primary-700"
        :checked="selected"
        :aria-label="`Odaberi: ${product.name}`"
        @change="emit('toggle')"
      >
    </label>
    <NuxtLink :to="`/admin/proizvodi/${product.id}`" class="flex min-w-0 flex-1 items-center gap-3">
      <img v-if="product.thumbnail" :src="product.thumbnail" alt="" loading="lazy" class="size-14 shrink-0 rounded-lg border border-primary-300 object-cover">
      <span v-else class="flex size-14 shrink-0 items-center justify-center rounded-lg border border-primary-300 bg-primary-50 text-primary-500">
        <ImageOff class="size-5" stroke-width="1.75" />
      </span>

      <span class="min-w-0 flex-1">
        <span class="block truncate text-sm font-medium">{{ product.name }}</span>
        <span class="block truncate text-xs text-stone-500">{{ product.sku }} · {{ product.categoryName }}<template v-if="product.brand"> · {{ product.brand }}</template></span>
        <span class="mt-1 flex flex-wrap items-center gap-1.5">
          <ColorSwatch v-for="color in product.colors" :key="color.id" class="size-3.5" :name="color.name" :hex="color.hex" />
          <span v-if="!product.isVisible && !archived" class="rounded-md bg-stone-200 px-1.5 py-0.5 text-xs text-stone-700">Skriveno</span>
          <span v-if="product.storeOnly" class="rounded-md bg-primary-200 px-1.5 py-0.5 text-xs text-primary-900">Samo u poslovnicama</span>
          <span v-if="product.stock === 0" class="rounded-md bg-red-100 px-1.5 py-0.5 text-xs text-red-800">Rasprodano</span>
        </span>
      </span>
    </NuxtLink>

    <div class="shrink-0 text-right">
      <p class="whitespace-nowrap text-sm font-semibold">{{ formatPrice(product.salePrice ?? product.price) }}</p>
      <del v-if="product.salePrice !== null" class="block whitespace-nowrap text-xs text-stone-500">{{ formatPrice(product.price) }}</del>
      <button
        v-if="canWrite && !archived"
        type="button"
        :aria-label="`Uredi količinu: ${product.name}, trenutno ${product.stock} kom`"
        class="inline-flex min-h-11 cursor-pointer items-center whitespace-nowrap text-xs font-medium text-primary-800 underline underline-offset-4 hover:text-primary-900 sm:min-h-8"
        @click="emit('editStock')"
      >
        {{ product.stock }} kom
      </button>
      <p v-else class="whitespace-nowrap text-xs text-stone-500">{{ product.stock }} kom</p>
    </div>

    <div class="-mr-2 flex items-center">
      <NuxtLink
        :to="{ path: `/admin/proizvodi/${product.id}`, query: { pregled: 1 } }"
        :aria-label="`Pregledaj: ${product.name}`"
        :title="`Pregledaj: ${product.name}`"
        class="inline-flex size-11 items-center justify-center rounded-lg text-stone-500 hover:bg-primary-100 hover:text-primary-700 sm:size-8"
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
        <NuxtLink :to="`/admin/proizvodi/${product.id}`" :aria-label="`Uredi: ${product.name}`" :title="`Uredi: ${product.name}`" class="hidden size-8 items-center justify-center rounded-lg text-stone-500 hover:bg-primary-100 hover:text-primary-700 sm:inline-flex">
          <Pencil class="size-4" stroke-width="1.75" />
        </NuxtLink>
        <IconButton :label="`Arhiviraj: ${product.name}`" @click="emit('archive')">
          <Archive class="size-4" stroke-width="1.75" />
        </IconButton>
      </template>
    </div>
  </div>
</template>
