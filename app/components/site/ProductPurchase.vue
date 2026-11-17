<script setup lang="ts">
import { Heart } from '@lucide/vue'

const props = defineProps<{
  colorId: string
  sizes: { id: string; size: string; quantity: number }[]
  storeOnly: boolean
}>()

const { add, isDrawerOpen } = useCart()
const { has, toggle, ensureLoaded } = useWishlist()

const available = computed(() => props.sizes.filter((size) => size.quantity > 0))
const soldOut = computed(() => !available.value.length)
const canOrder = computed(() => !soldOut.value && !props.storeOnly)

// Jedina dostupna veličina odabire se sama.
const selectedId = ref(available.value.length === 1 && props.sizes.length === 1 ? available.value[0]!.id : '')
const selected = computed(() => props.sizes.find((size) => size.id === selectedId.value))

const isAdding = ref(false)
const isSaving = ref(false)
const error = ref('')

// Stanje liste želja poznato je tek u pregledniku, pa je do tada gumb neutralan.
const isMounted = ref(false)
onMounted(() => {
  isMounted.value = true
  ensureLoaded().catch(console.error)
})
const isWished = computed(() => isMounted.value && has(props.colorId))

async function addToCart() {
  error.value = ''
  if (!selected.value) {
    error.value = 'Odaberite veličinu.'
    return
  }
  isAdding.value = true
  try {
    await add(selected.value.id)
    // Brzi pregled potvrđuje dodavanje i nudi narudžbu ili nastavak kupnje.
    isDrawerOpen.value = true
  } catch (caught) {
    error.value = shopErrorMessage(caught)
  } finally {
    isAdding.value = false
  }
}

async function toggleWish() {
  isSaving.value = true
  try {
    await toggle(props.colorId)
  } catch (caught) {
    error.value = shopErrorMessage(caught)
  } finally {
    isSaving.value = false
  }
}

const buttonClass = 'inline-flex min-h-13 items-center justify-center gap-2 border px-6 text-center text-xs font-medium uppercase tracking-[0.2em] transition-colors'
</script>

<template>
  <div>
    <fieldset class="mt-7 min-w-0">
      <legend class="text-xs font-medium uppercase tracking-[0.2em]">Veličina</legend>
      <div class="mt-3 flex flex-wrap gap-2">
        <label
          v-for="size in sizes"
          :key="size.id"
          class="flex min-h-11 min-w-13 flex-1 items-center justify-center border px-3 text-sm transition-colors has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-gold"
          :class="[
            size.quantity === 0 ? 'cursor-not-allowed border-line text-muted line-through' : 'cursor-pointer',
            size.quantity > 0 && selectedId === size.id ? 'border-ink bg-ink text-white' : '',
            size.quantity > 0 && selectedId !== size.id ? 'border-line bg-white hover:border-ink' : '',
          ]"
        >
          <input v-model="selectedId" type="radio" name="velicina" :value="size.id" :disabled="size.quantity === 0 || !canOrder" class="sr-only">
          {{ size.size }}
          <span v-if="size.quantity === 0" class="sr-only">, rasprodano</span>
        </label>
      </div>
    </fieldset>

    <div class="mt-7 flex flex-col gap-2">
      <div class="flex gap-2">
        <button
          v-if="canOrder"
          type="button"
          :disabled="isAdding"
          :class="[buttonClass, 'flex-1 border-ink bg-ink text-white hover:bg-transparent hover:text-ink disabled:cursor-wait disabled:opacity-70']"
          @click="addToCart"
        >
          {{ isAdding ? 'Dodavanje...' : 'Dodaj u košaricu' }}
        </button>
        <p v-else :class="[buttonClass, 'flex-1 cursor-not-allowed border-ink bg-ink text-white']">
          {{ soldOut ? 'Rasprodano' : 'Dostupno samo u poslovnicama' }}
        </p>
        <button
          type="button"
          :aria-pressed="isWished"
          :aria-label="isWished ? 'Ukloni s liste želja' : 'Dodaj na listu želja'"
          :title="isWished ? 'Ukloni s liste želja' : 'Dodaj na listu želja'"
          :disabled="isSaving"
          class="inline-flex size-13 shrink-0 items-center justify-center border border-line bg-white transition-colors hover:border-ink disabled:opacity-60"
          @click="toggleWish"
        >
          <Heart class="size-5" :class="isWished && 'fill-gold text-gold'" stroke-width="1.25" />
        </button>
      </div>

      <p v-if="error" role="alert" class="text-sm text-red-700">{{ error }}</p>
    </div>
  </div>
</template>
