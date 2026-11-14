<script setup lang="ts">
import { ListChecks, X } from '@lucide/vue'
import type { BulkAction } from '~/composables/useProducts'
import { EXCLUSIVE_PROMO_PAGE } from '~/config/navigation'

const props = defineProps<{
  count: number
  archived: boolean
  loading?: boolean
}>()
const emit = defineEmits<{ action: [action: BulkAction]; clear: [] }>()

const ACTIVE_ACTIONS: { action: BulkAction; label: string; danger?: boolean }[] = [
  { action: 'publish', label: 'Objavi na webu' },
  { action: 'hide', label: 'Sakrij s weba' },
  { action: 'store_on', label: 'Samo u trgovini' },
  { action: 'store_off', label: 'Makni "samo u trgovini"' },
  { action: 'campaign', label: 'Kampanja (sniženje)' },
  { action: 'promo_on', label: `Dodaj u ${EXCLUSIVE_PROMO_PAGE.label}` },
  { action: 'promo_off', label: `Makni iz: ${EXCLUSIVE_PROMO_PAGE.label}` },
  { action: 'archive', label: 'Arhiviraj', danger: true },
]

const ARCHIVED_ACTIONS: { action: BulkAction; label: string; danger?: boolean }[] = [
  { action: 'restore', label: 'Vrati iz arhive' },
  { action: 'delete', label: 'Obriši trajno', danger: true },
]

const actions = computed(() => (props.archived ? ARCHIVED_ACTIONS : ACTIVE_ACTIONS))

// Na mobitelu su radnje u prozoru, jer u traci nema mjesta.
const isMenuOpen = ref(false)

function run(action: BulkAction) {
  isMenuOpen.value = false
  emit('action', action)
}

const actionClass = (danger?: boolean) => [
  'inline-flex min-h-11 cursor-pointer items-center justify-center rounded-lg border px-3 text-sm font-medium transition-colors disabled:cursor-not-allowed disabled:opacity-50 sm:min-h-9',
  danger
    ? 'border-red-200 bg-white text-red-700 hover:bg-red-50'
    : 'border-primary-300 bg-white text-stone-700 hover:border-primary-500 hover:bg-primary-50 hover:text-primary-800',
]
</script>

<template>
  <div role="region" aria-label="Radnje za odabrane proizvode" class="sticky bottom-0 z-10 -mx-4 mt-4 border-t border-primary-300 bg-primary-100 px-4 py-3 sm:mx-0 sm:rounded-xl sm:border">
    <div class="flex flex-wrap items-center gap-2">
      <p class="mr-auto text-sm font-medium text-stone-800" aria-live="polite">Odabrano: {{ count }}</p>

      <div class="hidden flex-wrap gap-2 lg:flex">
        <button v-for="item in actions" :key="item.action" type="button" :disabled="loading" :class="actionClass(item.danger)" @click="run(item.action)">
          {{ item.label }}
        </button>
      </div>
      <BaseButton class="lg:hidden" :loading="loading" @click="isMenuOpen = true">
        <ListChecks class="size-4" stroke-width="1.75" />
        Radnje
      </BaseButton>
      <IconButton label="Poništi odabir" @click="emit('clear')">
        <X class="size-4" stroke-width="1.75" />
      </IconButton>
    </div>

    <BaseModal :open="isMenuOpen" :title="`Odabrano: ${count}`" @close="isMenuOpen = false">
      <div class="grid gap-2">
        <button v-for="item in actions" :key="item.action" type="button" :class="actionClass(item.danger)" @click="run(item.action)">
          {{ item.label }}
        </button>
      </div>
    </BaseModal>
  </div>
</template>
