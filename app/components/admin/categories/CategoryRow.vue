<script setup lang="ts">
import { ChevronDown, ChevronUp, Pencil, Plus, Trash2 } from '@lucide/vue'
import type { Category } from '~/types/database'

defineProps<{
  category: Category
  isFirst: boolean
  isLast: boolean
  canWrite: boolean
  isMain?: boolean
  canAddChild?: boolean
  // Artikl je jedna boja proizvoda, s podkategorijama (useCategoryArticleCounts).
  count?: number
}>()

const articleLabel = (count: number) => {
  const lastTwo = count % 100
  const last = count % 10
  if (last === 1 && lastTwo !== 11) return `${count} artikl`
  if (last >= 2 && last <= 4 && (lastTwo < 12 || lastTwo > 14)) return `${count} artikla`
  return `${count} artikala`
}

const emit = defineEmits<{
  addChild: []
  edit: []
  delete: []
  move: [direction: -1 | 1]
}>()
</script>

<template>
  <div
    class="flex flex-wrap items-center justify-between gap-x-4 gap-y-1 px-4 py-2"
    :class="isMain ? 'bg-primary-50' : 'sm:pl-8'"
  >
    <div class="flex min-w-0 flex-wrap items-baseline gap-x-2">
      <span class="text-sm" :class="isMain ? 'font-semibold text-primary-900' : 'text-stone-700'">{{ category.name }}</span>
      <span class="truncate text-xs text-stone-500">/{{ category.slug }}</span>
      <span
        v-if="count !== undefined"
        class="border border-primary-300 px-1.5 py-0.5 text-xs tabular-nums"
        :class="count ? 'bg-primary-100 text-primary-900' : 'bg-white text-stone-500'"
        title="Boje nearhiviranih proizvoda, s podkategorijama"
      >{{ articleLabel(count) }}</span>
      <span v-if="!category.is_active" class="rounded-md bg-amber-100 px-1.5 py-0.5 text-xs text-amber-800">Neaktivna</span>
    </div>

    <div v-if="canWrite" class="-mr-2 flex items-center">
      <IconButton v-if="canAddChild" :label="`Dodaj podkategoriju u ${category.name}`" @click="emit('addChild')">
        <Plus class="size-4" stroke-width="1.75" />
      </IconButton>
      <IconButton :label="`Pomakni gore: ${category.name}`" :disabled="isFirst" @click="emit('move', -1)">
        <ChevronUp class="size-4" stroke-width="1.75" />
      </IconButton>
      <IconButton :label="`Pomakni dolje: ${category.name}`" :disabled="isLast" @click="emit('move', 1)">
        <ChevronDown class="size-4" stroke-width="1.75" />
      </IconButton>
      <IconButton :label="`Uredi: ${category.name}`" @click="emit('edit')">
        <Pencil class="size-4" stroke-width="1.75" />
      </IconButton>
      <IconButton :label="`Obriši: ${category.name}`" danger @click="emit('delete')">
        <Trash2 class="size-4" stroke-width="1.75" />
      </IconButton>
    </div>
  </div>
</template>
