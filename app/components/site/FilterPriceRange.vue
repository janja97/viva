<script setup lang="ts">
// Cijena od-do u filtrima. Polja primaju samo znamenke (bez strelica broja), a KM stoji u polju.
// Vrijednost se primjenjuje kad kupac napusti polje ili pritisne Enter.
const props = defineProps<{
  min: number | null
  max: number | null
  // Raspon cijena na popisu, za tekst u praznom polju.
  rangeMin?: number | null
  rangeMax?: number | null
}>()
const emit = defineEmits<{ change: [key: 'minPrice' | 'maxPrice', value: number | null] }>()

const id = useId()

// Sve što nije znamenka se briše dok kupac piše.
function onInput(event: Event) {
  const input = event.target as HTMLInputElement
  const digits = input.value.replace(/\D/g, '').slice(0, 6)
  if (digits !== input.value) input.value = digits
}

function onChange(key: 'minPrice' | 'maxPrice', event: Event) {
  const digits = (event.target as HTMLInputElement).value.replace(/\D/g, '')
  emit('change', key, digits === '' ? null : Number(digits))
}

const fields = computed(() => [
  { key: 'minPrice' as const, label: 'Od', value: props.min, placeholder: props.rangeMin != null ? String(Math.floor(props.rangeMin)) : '' },
  { key: 'maxPrice' as const, label: 'Do', value: props.max, placeholder: props.rangeMax != null ? String(Math.ceil(props.rangeMax)) : '' },
])
</script>

<template>
  <div class="grid grid-cols-2 gap-3">
    <div v-for="field in fields" :key="field.key" class="min-w-0">
      <label :for="`${id}-${field.key}`" class="mb-1.5 block text-[11px] uppercase tracking-[0.16em] text-muted">{{ field.label }}</label>
      <div class="flex min-h-11 items-center border border-line bg-white transition-colors focus-within:border-ink lg:min-h-10">
        <input
          :id="`${id}-${field.key}`"
          type="text"
          inputmode="numeric"
          pattern="[0-9]*"
          autocomplete="off"
          maxlength="6"
          :placeholder="field.placeholder"
          :value="field.value ?? ''"
          class="w-full min-w-0 bg-transparent py-2 pl-3 text-base text-ink placeholder:text-muted/70 focus:outline-none lg:text-sm"
          @input="onInput"
          @change="onChange(field.key, $event)"
          @keydown.enter="($event.target as HTMLInputElement).blur()"
        >
        <span class="flex-none pr-3 text-xs text-muted" aria-hidden="true">KM</span>
      </div>
    </div>
  </div>
</template>
