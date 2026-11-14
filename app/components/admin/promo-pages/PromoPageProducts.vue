<script setup lang="ts">
import { X } from '@lucide/vue'
import type { Product, PromoPage } from '~/types/database'

// Proizvodi pojedinačno dodani na akcijsku stranicu "samo ovdje" (Čišćenje zaliha, migracija 0039).
// Dodaju se na popisu proizvoda, a ovdje se pregledavaju i miču.
const props = defineProps<{ page: PromoPage; canWrite: boolean }>()

type Row = Pick<Product, 'id' | 'sku' | 'name' | 'price' | 'sale_price' | 'discount_percent' | 'is_visible'>

const supabase = useSupabase()
const { setPromoPage } = useProducts()

const rows = ref<Row[]>([])
const isLoading = ref(true)
const loadError = ref('')
const removing = ref<Row | null>(null)
const isRemoving = ref(false)
const removeError = ref('')

async function load() {
  isLoading.value = true
  loadError.value = ''
  const { data, error } = await supabase
    .from('products')
    .select('id, sku, name, price, sale_price, discount_percent, is_visible')
    .eq('promo_page_id', props.page.id)
    .is('archived_at', null)
    .order('name')
  isLoading.value = false
  if (error) loadError.value = productErrorMessage(error)
  else rows.value = data
}

async function remove() {
  if (!removing.value) return
  isRemoving.value = true
  removeError.value = ''
  try {
    await setPromoPage([removing.value.id], false)
    removing.value = null
    await load()
  } catch (error) {
    removeError.value = productErrorMessage(error)
  } finally {
    isRemoving.value = false
  }
}

onMounted(load)
</script>

<template>
  <AdminCard :title="`Proizvodi: ${page.title}`">
    <p class="mb-4 max-w-2xl text-sm text-stone-500">
      Ovi proizvodi su, dok je stranica uključena, vidljivi samo na /{{ page.slug }}. Nove dodaješ na
      <NuxtLink to="/admin/proizvodi" class="text-primary-800 underline underline-offset-4">popisu proizvoda</NuxtLink>:
      označi ih kvačicom i odaberi "Dodaj u {{ page.title }}".
    </p>

    <p v-if="isLoading && !rows.length" class="text-sm text-stone-500">Učitavanje...</p>
    <BaseAlert v-else-if="loadError" type="error">{{ loadError }}</BaseAlert>
    <p v-else-if="!rows.length" class="text-sm text-stone-500">Još nema dodanih proizvoda.</p>
    <template v-else>
      <p class="mb-2 text-xs text-stone-500">Ukupno: {{ rows.length }}</p>
      <ul class="divide-y divide-primary-200 border border-primary-300">
        <li v-for="row in rows" :key="row.id" class="flex items-center gap-3 px-3 py-2">
          <NuxtLink :to="`/admin/proizvodi/${row.id}`" class="min-w-0 flex-1">
            <span class="block truncate text-sm font-medium text-stone-900">{{ row.name }}</span>
            <span class="flex flex-wrap items-center gap-x-2 text-xs text-stone-500">
              {{ row.sku }}
              <span v-if="row.discount_percent" class="text-red-700">−{{ row.discount_percent }} %</span>
              <span v-else>bez sniženja</span>
              <span v-if="!row.is_visible" class="bg-stone-200 px-1.5 py-0.5 text-stone-700">Skriveno</span>
            </span>
          </NuxtLink>
          <div class="shrink-0 text-right">
            <p class="whitespace-nowrap text-sm font-semibold">{{ formatPrice(row.sale_price ?? row.price) }}</p>
            <del v-if="row.sale_price !== null" class="block whitespace-nowrap text-xs text-stone-500">{{ formatPrice(row.price) }}</del>
          </div>
          <IconButton v-if="canWrite" :label="`Makni sa stranice: ${row.name}`" @click="removing = row; removeError = ''">
            <X class="size-4" stroke-width="1.75" />
          </IconButton>
        </li>
      </ul>
    </template>

    <ConfirmDialog
      :open="Boolean(removing)"
      title="Makni sa stranice"
      confirm-label="Makni"
      :loading="isRemoving"
      :error="removeError"
      @close="removing = null"
      @confirm="remove"
    >
      Sigurno želiš maknuti proizvod „{{ removing?.name }}” sa stranice {{ page.title }}? Vraća se u kolekciju, kategorije i pretragu. Sniženje iz kampanje ostaje.
    </ConfirmDialog>
  </AdminCard>
</template>
