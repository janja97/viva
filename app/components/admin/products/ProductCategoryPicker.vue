<script setup lang="ts">
import type { Category } from '~/types/database'

const props = defineProps<{
  categories: Category[]
  disabled?: boolean
}>()

const model = defineModel<string>({ required: true })

const LEVEL_LABELS = ['Kategorija', 'Podkategorija', 'Uža podkategorija']

const path = computed(() => categoryPath(props.categories, model.value))

const optionsOf = (items: Category[]) => items.map((item) => ({
  value: item.id,
  label: item.is_active ? item.name : `${item.name} (neaktivna)`,
}))

// Sljedeći izbornik pojavi se samo ako odabrana kategorija ima razinu ispod sebe.
const levels = computed(() => {
  const roots = props.categories.filter((item) => !item.parent_id)
  const result = [{ items: roots, value: path.value[0]?.id ?? '' }]
  for (let depth = 0; depth < LEVEL_LABELS.length - 1; depth++) {
    const parent = path.value[depth]
    if (!parent) break
    const items = childrenOf(props.categories, parent.id)
    if (!items.length) break
    result.push({ items, value: path.value[depth + 1]?.id ?? '' })
  }
  return result
})

// Prazan odabir vraća proizvod na razinu iznad.
function select(depth: number, value: string) {
  model.value = value || path.value[depth - 1]?.id || ''
}

const shownOn = computed(() => path.value.map((item) => item.name).join(', '))
</script>

<template>
  <div>
    <div class="grid gap-4 sm:grid-cols-3">
      <BaseSelect
        v-for="(level, depth) in levels"
        :key="depth"
        :model-value="level.value"
        :label="LEVEL_LABELS[depth]!"
        :options="[{ value: '', label: depth ? 'Bez dalje podjele' : 'Odaberi kategoriju' }, ...optionsOf(level.items)]"
        :disabled="disabled"
        @update:model-value="select(depth, $event)"
      />
    </div>
    <p v-if="shownOn" class="mt-2 text-xs text-stone-500">Prikazuje se na stranicama: {{ shownOn }}.</p>
  </div>
</template>
