<script setup lang="ts">
const props = defineProps<{
  options: { value: string; label: string }[]
  // Glavna kategorija i njezine nadređene. Proizvod je na tim stranicama već sam od sebe.
  excludedIds: string[]
}>()

const model = defineModel<string[]>({ required: true })

const available = computed(() => props.options.filter((option) => !props.excludedIds.includes(option.value)))
const selectedCount = computed(() => available.value.filter((option) => model.value.includes(option.value)).length)
</script>

<template>
  <details class="min-w-0 border border-primary-300">
    <summary class="flex min-h-11 cursor-pointer items-center px-3 text-sm font-medium text-stone-700 sm:min-h-9">
      Prikaži i u drugoj kategoriji<template v-if="selectedCount"> ({{ selectedCount }})</template>
    </summary>
    <div class="border-t border-primary-200 p-3">
      <p class="mb-2 text-xs text-stone-500">Neobavezno. Npr. haljina koja je i svečana i maturalna. Proizvod ostaje jedan, s istom adresom, cijenom i količinama.</p>
      <p v-if="!available.length" class="text-sm text-stone-500">Nema drugih kategorija.</p>
      <ul v-else class="grid gap-x-4 sm:grid-cols-2">
        <li v-for="option in available" :key="option.value">
          <label class="flex min-h-11 cursor-pointer items-center gap-2.5 text-sm text-stone-700 sm:min-h-9">
            <input v-model="model" type="checkbox" :value="option.value" class="size-4 accent-primary-600">
            {{ option.label }}
          </label>
        </li>
      </ul>
    </div>
  </details>
</template>
