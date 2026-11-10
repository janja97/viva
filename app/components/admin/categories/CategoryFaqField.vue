<script setup lang="ts">
import { Plus, Trash2 } from '@lucide/vue'
import type { FaqItem } from '~/types/database'

// Česta pitanja kategorije. Prikazuju se na dnu stranice kategorije i kao FAQ za Google.
const MAX_FAQ = 12
const items = defineModel<FaqItem[]>({ required: true })

const removingIndex = ref<number | null>(null)

function add() {
  items.value = [...items.value, { question: '', answer: '' }]
}

function confirmRemove() {
  if (removingIndex.value === null) return
  items.value = items.value.filter((_, index) => index !== removingIndex.value)
  removingIndex.value = null
}
</script>

<template>
  <fieldset class="space-y-3">
    <legend class="mb-1.5 text-sm font-medium text-stone-700">Česta pitanja</legend>
    <p v-if="!items.length" class="text-xs text-stone-500">Neobavezno. 3 do 5 pitanja koja kupci stvarno postavljaju.</p>

    <div v-for="(item, index) in items" :key="index" class="space-y-2 border border-primary-300 p-3">
      <div class="flex items-start gap-2">
        <BaseInput v-model="item.question" class="flex-1" :label="`Pitanje ${index + 1}`" :maxlength="200" required />
        <IconButton class="mt-6" :label="`Ukloni pitanje ${index + 1}`" danger @click="removingIndex = index">
          <Trash2 class="size-4" stroke-width="1.75" />
        </IconButton>
      </div>
      <BaseTextarea v-model="item.answer" label="Odgovor" :maxlength="600" required />
    </div>

    <BaseButton v-if="items.length < MAX_FAQ" variant="secondary" @click="add">
      <Plus class="size-4" stroke-width="2" />
      Dodaj pitanje
    </BaseButton>

    <ConfirmDialog
      :open="removingIndex !== null"
      title="Ukloni pitanje"
      confirm-label="Ukloni"
      @close="removingIndex = null"
      @confirm="confirmRemove"
    >
      Ukloniti pitanje „{{ removingIndex !== null ? items[removingIndex]?.question || 'bez naslova' : '' }}”? Promjena vrijedi tek kad spremiš kategoriju.
    </ConfirmDialog>
  </fieldset>
</template>
