<script setup lang="ts">
import { X } from '@lucide/vue'

const { promo, applyPromo, clearPromo } = useCart()

const id = useId()
const code = ref('')
const error = ref('')
const isChecking = ref(false)

async function onApply() {
  if (!code.value.trim()) return
  isChecking.value = true
  error.value = ''
  try {
    await applyPromo(code.value)
    code.value = ''
  } catch (caught) {
    error.value = shopErrorMessage(caught)
  } finally {
    isChecking.value = false
  }
}
</script>

<template>
  <div class="border-b border-line pb-4">
    <div v-if="promo" class="flex items-center justify-between gap-3 text-sm">
      <p>Promo kod <span class="font-medium tracking-wider">{{ promo.code }}</span> (-{{ promo.percent }} %)</p>
      <button
        type="button"
        class="inline-flex size-11 cursor-pointer items-center justify-center text-muted hover:text-ink"
        :aria-label="`Ukloni promo kod ${promo.code}`"
        @click="clearPromo"
      >
        <X class="size-4" stroke-width="1.5" />
      </button>
    </div>
    <form v-else class="flex gap-2" @submit.prevent="onApply">
      <label :for="id" class="sr-only">Promo kod</label>
      <input
        :id="id"
        v-model="code"
        type="text"
        maxlength="30"
        autocomplete="off"
        autocapitalize="characters"
        placeholder="Promo kod"
        class="min-h-11 min-w-0 flex-1 border border-line bg-white px-3 text-base uppercase placeholder:normal-case placeholder:text-muted lg:text-sm"
      >
      <button
        type="submit"
        :disabled="isChecking || !code.trim()"
        class="min-h-11 flex-none cursor-pointer border border-ink px-4 text-xs font-medium uppercase tracking-[0.16em] transition-colors hover:bg-ink hover:text-white disabled:cursor-not-allowed disabled:opacity-50"
      >
        {{ isChecking ? 'Provjera...' : 'Primijeni' }}
      </button>
    </form>
    <p v-if="error" role="alert" class="mt-2 text-sm text-red-700">{{ error }}</p>
  </div>
</template>
