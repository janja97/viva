<script setup lang="ts">
import { SlidersHorizontal, X } from '@lucide/vue'
import { SIZE_TYPES } from '~/config/products'
import type { AdminProductFilters, AdminProductSort } from '~/composables/useAdminProductFilters'
import type { ProductFilterOptions } from '~/composables/useProducts'
import type { Category, SizeType } from '~/types/database'

const props = defineProps<{
  options: ProductFilterOptions | null
  categories: Category[]
  // Broj rezultata za gumb u prozoru, jer se filtri primjenjuju odmah.
  total: number
}>()

const { filters, activeCount, apply, toggle, clear } = useAdminProductFilters()

const isOpen = ref(false)

const categorySelect = computed(() => [{ value: '', label: 'Sve kategorije' }, ...categoryOptions(props.categories)])
const sizeTypeSelect = [{ value: '', label: 'Sve vrste' }, ...SIZE_TYPES]
const brandSelect = computed(() => [
  { value: '', label: 'Svi brendovi' },
  { value: NO_BRAND, label: 'Bez brenda' },
  ...[...(props.options?.brands ?? [])].sort((a, b) => a.localeCompare(b, 'hr')).map((brand) => ({ value: brand, label: brand })),
])
const sortSelect = computed(() => ADMIN_PRODUCT_SORTS.filter((sort) => filters.value.archived || sort.value !== 'archived'))
const sizes = computed(() => sortSizes(props.options?.sizes ?? []))

// Odabrana boja ili veličina ostaje vidljiva i kad je nema u ponuđenima, kako bi se mogla isključiti.
const colorChoices = computed(() => {
  const offered = props.options?.colors ?? []
  const missing = filters.value.colors.filter((name) => !offered.some((color) => color.name === name))
  return [...offered, ...missing.map((name) => ({ name, hex: '#ffffff' }))]
})
const sizeChoices = computed(() => [...sizes.value, ...filters.value.sizes.filter((size) => !sizes.value.includes(size))])

// Tri stanja: svi, da i ne.
const yesNoSelect = (all: string, yes: string, no: string) => [
  { value: '', label: all },
  { value: 'da', label: yes },
  { value: 'ne', label: no },
]
const toYesNo = (value: boolean | null) => (value === null ? '' : value ? 'da' : 'ne')
const fromYesNo = (value: string) => (value === '' ? null : value === 'da')

function select<K extends keyof AdminProductFilters>(key: K, toValue: (value: string) => AdminProductFilters[K], fromValue: (value: AdminProductFilters[K]) => string) {
  return computed({
    get: () => fromValue(filters.value[key]),
    set: (value: string) => apply({ [key]: toValue(value) }),
  })
}

const category = select('categoryId', (value) => value, (value) => value)
const sizeType = select('sizeType', (value) => value as SizeType | '', (value) => value)
const brand = select('brand', (value) => value, (value) => value)
const sort = select('sort', (value) => value as AdminProductSort, (value) => value)
const visible = select('visible', fromYesNo, toYesNo)
const storeOnly = select('storeOnly', fromYesNo, toYesNo)
const onSale = select('onSale', fromYesNo, toYesNo)

// Tekst i brojevi se upisuju slovo po slovo, pa se primjenjuju tek kad korisnik zastane.
const draft = reactive({ search: '', minPrice: '', maxPrice: '', minQty: '', maxQty: '' })
const asDraft = (value: number | null) => (value === null ? '' : String(value))

function syncDraft() {
  draft.search = filters.value.search
  draft.minPrice = asDraft(filters.value.minPrice)
  draft.maxPrice = asDraft(filters.value.maxPrice)
  draft.minQty = asDraft(filters.value.minQty)
  draft.maxQty = asDraft(filters.value.maxQty)
}
syncDraft()
watch(filters, syncDraft)

function parse(value: string) {
  const number = value.trim() === '' ? null : Number(value)
  return number !== null && Number.isFinite(number) && number >= 0 ? number : null
}

let draftTimer: ReturnType<typeof setTimeout>
watch(draft, () => {
  clearTimeout(draftTimer)
  draftTimer = setTimeout(() => {
    const next = {
      search: draft.search.trim(),
      minPrice: parse(draft.minPrice),
      maxPrice: parse(draft.maxPrice),
      minQty: parse(draft.minQty),
      maxQty: parse(draft.maxQty),
    }
    const current = filters.value
    const changed = (Object.keys(next) as (keyof typeof next)[]).some((key) => next[key] !== current[key])
    if (changed) apply(next)
  }, 400)
})
onBeforeUnmount(() => clearTimeout(draftTimer))

const chipClass = (active: boolean) => [
  'inline-flex min-h-11 cursor-pointer items-center gap-1.5 rounded-full border px-3 text-sm transition-colors sm:min-h-8',
  active ? 'border-primary-700 bg-primary-700 text-white' : 'border-primary-300 bg-white text-stone-700 hover:border-primary-500',
]
</script>

<template>
  <div class="mb-4 space-y-3">
    <div class="flex flex-col gap-3 sm:flex-row sm:items-end">
      <BaseInput v-model="draft.search" class="flex-1" label="Pretraži po šifri, nazivu ili brendu" type="search" />
      <BaseSelect v-model="sort" class="sm:w-56" label="Poredaj" :options="sortSelect" />
      <BaseButton variant="secondary" aria-haspopup="dialog" @click="isOpen = true">
        <SlidersHorizontal class="size-4" stroke-width="1.75" />
        Filteri<template v-if="activeCount"> ({{ activeCount }})</template>
      </BaseButton>
    </div>

    <div v-if="activeCount" class="flex items-center gap-2 text-sm text-stone-500">
      <span>Aktivnih filtera: {{ activeCount }}</span>
      <button type="button" class="inline-flex min-h-11 cursor-pointer items-center gap-1 font-medium text-primary-800 underline underline-offset-4 hover:text-primary-900 sm:min-h-8" @click="clear">
        <X class="size-4" stroke-width="1.75" />
        Očisti filtere
      </button>
    </div>

    <BaseModal :open="isOpen" title="Filteri" wide @close="isOpen = false">
      <div class="grid gap-4 sm:grid-cols-2">
        <BaseSelect v-model="category" label="Kategorija" :options="categorySelect" hint="Uključuje i sve podkategorije." />
        <BaseSelect v-model="sizeType" label="Vrsta" :options="sizeTypeSelect" hint="Mijenja ponuđene veličine." />
        <BaseSelect v-model="brand" label="Brend" :options="brandSelect" />

        <fieldset class="min-w-0">
          <legend class="mb-1.5 text-sm font-medium text-stone-700">Cijena kupca (KM)</legend>
          <div class="grid grid-cols-2 gap-2">
            <BaseInput v-model="draft.minPrice" label="Od" type="number" inputmode="decimal" :min="0" step="0.01" :placeholder="options?.minPrice != null ? String(options.minPrice) : undefined" />
            <BaseInput v-model="draft.maxPrice" label="Do" type="number" inputmode="decimal" :min="0" step="0.01" :placeholder="options?.maxPrice != null ? String(options.maxPrice) : undefined" />
          </div>
        </fieldset>

        <fieldset class="min-w-0">
          <legend class="mb-1.5 text-sm font-medium text-stone-700">Količina (kom)</legend>
          <div class="grid grid-cols-2 gap-2">
            <BaseInput v-model="draft.minQty" label="Od" type="number" inputmode="numeric" :min="0" step="1" />
            <BaseInput v-model="draft.maxQty" label="Do" type="number" inputmode="numeric" :min="0" step="1" />
          </div>
          <p class="mt-1.5 text-xs text-stone-500">Ako su odabrane boje ili veličine, broje se samo one. Npr. crna, 38, do 0 = rasprodano.</p>
        </fieldset>

        <BaseSelect v-model="visible" label="Na webu" :options="yesNoSelect('Svi', 'Vidljivi', 'Skriveni')" />
        <BaseSelect v-model="storeOnly" label="Samo u trgovini" :options="yesNoSelect('Svi', 'Da', 'Ne')" />
        <BaseSelect v-model="onSale" label="Sniženje" :options="yesNoSelect('Svi', 'Na sniženju', 'Bez sniženja')" />

        <label class="flex min-h-11 cursor-pointer items-center gap-2.5 self-end text-sm text-stone-700">
          <input type="checkbox" class="size-4 accent-primary-700" :checked="filters.missingImages" @change="apply({ missingImages: !filters.missingImages })">
          Nedostaje slika za neku boju
        </label>

        <fieldset v-if="colorChoices.length" class="min-w-0 sm:col-span-2">
          <legend class="mb-1.5 text-sm font-medium text-stone-700">Boje</legend>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="color in colorChoices"
              :key="color.name"
              type="button"
              :aria-pressed="filters.colors.includes(color.name)"
              :class="chipClass(filters.colors.includes(color.name))"
              @click="toggle('colors', color.name)"
            >
              <ColorSwatch class="size-3.5" :name="color.name" :hex="color.hex" />
              {{ color.name }}
            </button>
          </div>
        </fieldset>

        <fieldset v-if="sizeChoices.length" class="min-w-0 sm:col-span-2">
          <legend class="mb-1.5 text-sm font-medium text-stone-700">Veličine</legend>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="size in sizeChoices"
              :key="size"
              type="button"
              :aria-pressed="filters.sizes.includes(size)"
              :class="[chipClass(filters.sizes.includes(size)), 'min-w-11 justify-center']"
              @click="toggle('sizes', size)"
            >
              {{ size }}
            </button>
          </div>
          <p class="mt-1.5 text-xs text-stone-500">Nude se samo veličine proizvoda iz odabrane kategorije i vrste.</p>
        </fieldset>
      </div>

      <div class="sticky bottom-0 -mx-5 -mb-5 mt-6 flex flex-col-reverse gap-2 border-t border-primary-300 bg-white px-5 py-4 sm:-mx-6 sm:-mb-6 sm:flex-row sm:justify-between sm:px-6">
        <BaseButton variant="secondary" :loading="!activeCount" @click="clear">Očisti filtere</BaseButton>
        <BaseButton @click="isOpen = false">Prikaži rezultate ({{ total }})</BaseButton>
      </div>
    </BaseModal>
  </div>
</template>
