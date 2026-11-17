<script setup lang="ts">
import type { Category } from '~/types/database'

// Glavne kategorije (Haljine, Odjeća, Obuća, Torbice, Dodaci) na vrhu popisa proizvoda.
// Popis se prikazuje tek kad je jedna odabrana; podkategorija se bira u filterima i nije obavezna.
const props = defineProps<{
  categories: Category[]
  selectedId: string
}>()
const emit = defineEmits<{ select: [id: string] }>()

const mainCategories = computed(() => props.categories
  .filter((category) => !category.parent_id)
  .sort((a, b) => a.sort_order - b.sort_order))
</script>

<template>
  <nav aria-label="Glavna kategorija" class="mb-4">
    <ul class="grid grid-cols-2 gap-2 sm:grid-cols-3 lg:grid-cols-5">
      <li v-for="category in mainCategories" :key="category.id">
        <button
          type="button"
          :aria-pressed="category.id === selectedId"
          class="flex min-h-12 w-full cursor-pointer flex-col items-center justify-center border px-3 py-2 text-center text-sm font-medium transition-colors sm:min-h-11"
          :class="category.id === selectedId
            ? 'border-primary-950 bg-primary-950 text-white'
            : 'border-primary-300 bg-white text-stone-800 hover:border-primary-600 hover:bg-primary-50'"
          @click="emit('select', category.id)"
        >
          {{ category.name }}
          <span v-if="!category.is_active" class="text-xs font-normal" :class="category.id === selectedId ? 'text-white/70' : 'text-stone-500'">isključena</span>
        </button>
      </li>
    </ul>
  </nav>
</template>
