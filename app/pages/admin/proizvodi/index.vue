<script setup lang="ts">
import { History, Plus } from '@lucide/vue'
import type { BulkAction } from '~/composables/useProducts'

definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Proizvodi', noindex: true })

const route = useRoute()
const { can } = usePermissions()
const { filters, page, activeCount, goToPage, showArchived, toRpcFilters } = useAdminProductFilters()
const { categories, load: loadCategories } = useCategories()
const { rows, total, pageCount, options, isLoading, loadError, load, loadOptions, fetchAllIds } = useProductList()
const { archive, restore, remove, bulkUpdate } = useProducts()
const { campaigns, load: loadCampaigns } = useCampaigns()

const canWrite = computed(() => can('write'))

// Kategorija u filtru uključuje sve svoje podkategorije.
const categoryIds = computed(() => {
  const id = filters.value.categoryId
  return id ? [id, ...descendantIds(categories.value, id)] : []
})
const rpcFilters = computed(() => toRpcFilters(filters.value, categoryIds.value))

// Ključevi sprječavaju ponovno učitavanje kad se adresa promijeni, a filtri ostanu isti.
const filtersKey = computed(() => JSON.stringify(rpcFilters.value))
const listKey = computed(() => JSON.stringify([filtersKey.value, filters.value.sort, page.value]))
const optionsKey = computed(() => JSON.stringify([filters.value.archived, categoryIds.value, filters.value.sizeType]))

const reload = () => load(rpcFilters.value, filters.value.sort, page.value)
const reloadOptions = () => loadOptions({
  archived: filters.value.archived,
  category_ids: categoryIds.value,
  size_types: filters.value.sizeType ? [filters.value.sizeType] : [],
})

// ODABIR
// Ostaje pri promjeni stranice, a briše se kad se promijene filtri, kako radnja ne bi zahvatila skrivene proizvode.
const selected = ref<string[]>([])
const selectedSet = computed(() => new Set(selected.value))
const isPageSelected = computed(() => rows.value.length > 0 && rows.value.every((row) => selectedSet.value.has(row.id)))
const isSelectingAll = ref(false)

function toggleSelected(id: string) {
  selected.value = selectedSet.value.has(id) ? selected.value.filter((item) => item !== id) : [...selected.value, id]
}

function togglePage() {
  const pageIds = rows.value.map((row) => row.id)
  selected.value = isPageSelected.value
    ? selected.value.filter((id) => !pageIds.includes(id))
    : [...new Set([...selected.value, ...pageIds])]
}

async function selectAllMatching() {
  isSelectingAll.value = true
  try {
    selected.value = await fetchAllIds(rpcFilters.value, filters.value.sort)
  } catch (error) {
    actionError.value = productErrorMessage(error)
  } finally {
    isSelectingAll.value = false
  }
}

// RADNJE
const pending = ref<{ action: 'archive' | 'delete'; ids: string[]; label: string } | null>(null)
const campaignIds = ref<string[] | null>(null)
const isWorking = ref(false)
const actionError = ref('')
const actionDone = ref('')

const editingStock = ref<{ id: string; sku: string; name: string } | null>(null)
const stockSaved = ref('')

const labelFor = (ids: string[]) => (ids.length === 1
  ? `proizvod „${rows.value.find((row) => row.id === ids[0])?.name ?? ''}”`
  : `${ids.length} odabranih proizvoda`)

function startAction(action: BulkAction, ids = selected.value) {
  if (!ids.length) return
  actionError.value = ''
  if (action === 'archive' || action === 'delete') pending.value = { action, ids, label: labelFor(ids) }
  else if (action === 'campaign') campaignIds.value = ids
  else execute(action, ids)
}

async function execute(action: BulkAction, ids: string[], campaignId: string | null = null) {
  isWorking.value = true
  actionError.value = ''
  actionDone.value = ''
  try {
    actionDone.value = await perform(action, ids, campaignId)
    // Arhivirani, vraćeni i obrisani proizvodi odlaze s ovog popisa, pa ih nema smisla držati odabranima.
    if (action === 'archive' || action === 'restore' || action === 'delete') {
      selected.value = selected.value.filter((id) => !ids.includes(id))
    }
    pending.value = null
    campaignIds.value = null
    await Promise.all([reload(), reloadOptions()])
  } catch (error) {
    actionError.value = productErrorMessage(error)
  } finally {
    isWorking.value = false
  }
}

async function perform(action: BulkAction, ids: string[], campaignId: string | null) {
  switch (action) {
    case 'publish': {
      const { updated, skipped } = await bulkUpdate(ids, { is_visible: true })
      return `Objavljeno na webu: ${updated}.${skipped ? ` Preskočeno: ${skipped}, jer nemaju sliku za svaku boju.` : ''}`
    }
    case 'hide':
      return `Skriveno s weba: ${(await bulkUpdate(ids, { is_visible: false })).updated}.`
    case 'store_on':
      return `Označeno „samo u trgovini”: ${(await bulkUpdate(ids, { store_only: true })).updated}.`
    case 'store_off':
      return `Maknuto „samo u trgovini”: ${(await bulkUpdate(ids, { store_only: false })).updated}.`
    case 'campaign': {
      const { updated } = await bulkUpdate(ids, { campaign_id: campaignId })
      const name = campaigns.value.find((campaign) => campaign.id === campaignId)?.name
      return name ? `Dodano u kampanju „${name}”: ${updated}.` : `Maknuto iz kampanje: ${updated}.`
    }
    case 'archive':
      await archive(ids)
      return `Arhivirano: ${ids.length}.`
    case 'restore':
      return `Vraćeno iz arhive: ${await restore(ids)}. Skriveni su dok im ne dodaš slike i uključiš vidljivost.`
    case 'delete':
      return `Trajno obrisano: ${await remove(ids)}.`
  }
}

async function onStockSaved() {
  stockSaved.value = editingStock.value?.name ?? ''
  editingStock.value = null
  await reload()
}

// Kategorije trebaju prije prvog učitavanja, zbog podkategorija u filtru.
const isReady = ref(false)

watch(filtersKey, () => {
  selected.value = []
})
watch(listKey, () => isReady.value && reload())
watch(optionsKey, () => isReady.value && reloadOptions())

onMounted(async () => {
  await Promise.all([loadCategories(), loadCampaigns()])
  isReady.value = true
  reload()
  reloadOptions()
})
</script>

<template>
  <div>
    <AdminPageHeader title="Proizvodi" :description="isLoading && !rows.length ? undefined : `Rezultata: ${total}`">
      <div class="flex flex-col gap-2 sm:flex-row">
        <NuxtLink v-if="canWrite" to="/admin/proizvodi/novi" class="inline-flex min-h-11 items-center justify-center gap-1.5 rounded-lg bg-primary-600 px-3.5 text-sm font-medium text-white transition-colors hover:bg-primary-700 sm:order-last sm:min-h-9">
          <Plus class="size-4" stroke-width="2" />
          Novi proizvod
        </NuxtLink>
        <NuxtLink to="/admin/proizvodi/povijest" class="inline-flex min-h-11 items-center justify-center gap-1.5 rounded-lg border border-primary-300 bg-white px-3.5 text-sm font-medium text-stone-700 transition-colors hover:border-primary-500 hover:bg-primary-50 hover:text-primary-800 sm:min-h-9">
          <History class="size-4" stroke-width="1.75" />
          Povijest
        </NuxtLink>
      </div>
    </AdminPageHeader>

    <BaseAlert v-if="route.query.spremljeno" type="success" class="mb-4">
      Proizvod {{ route.query.spremljeno }} je spremljen.
    </BaseAlert>
    <BaseAlert v-if="stockSaved" type="success" class="mb-4">
      Količina za proizvod {{ stockSaved }} je spremljena i zapisana u povijest.
    </BaseAlert>
    <BaseAlert v-if="actionDone" type="success" class="mb-4">{{ actionDone }}</BaseAlert>
    <BaseAlert v-if="actionError && !pending && !campaignIds" type="error" class="mb-4">{{ actionError }}</BaseAlert>

    <div class="mb-4 flex border-b border-primary-300">
      <button
        v-for="tab in [{ label: 'Aktivni', value: false }, { label: 'Arhiva', value: true }]"
        :key="tab.label"
        type="button"
        :aria-pressed="filters.archived === tab.value"
        class="-mb-px min-h-11 cursor-pointer border-b-2 px-4 text-sm font-medium transition-colors sm:min-h-9"
        :class="filters.archived === tab.value ? 'border-primary-700 text-stone-900' : 'border-transparent text-stone-500 hover:text-stone-800'"
        @click="filters.archived !== tab.value && showArchived(tab.value)"
      >
        {{ tab.label }}
      </button>
    </div>

    <p v-if="filters.archived" class="mb-4 max-w-2xl text-sm text-stone-500">
      Arhivirani proizvodi nisu na webu, ali ostaju u bazi za povijest i statistiku. Čuva se samo prva slika.
    </p>

    <ProductFilters :options="options" :categories="categories" :total="total" />

    <div v-if="loadError" class="space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <BaseButton variant="secondary" @click="reload">Pokušaj ponovno</BaseButton>
    </div>
    <p v-else-if="isLoading && !rows.length" class="text-sm text-stone-500">Učitavanje...</p>
    <p v-else-if="!rows.length" class="rounded-xl border border-dashed border-primary-300 bg-white px-4 py-12 text-center text-sm text-stone-500">
      <template v-if="filters.search || activeCount">Nema proizvoda za odabrane filtere.</template>
      <template v-else>{{ filters.archived ? 'Arhiva je prazna.' : 'Još nema proizvoda.' }}</template>
    </p>
    <template v-else>
      <div class="rounded-xl border border-primary-300 bg-white shadow-sm" :class="isLoading && 'opacity-60'">
        <div v-if="canWrite" class="flex flex-wrap items-center gap-x-3 border-b border-primary-200 px-4 py-1 text-sm">
          <label class="-ml-3 flex min-h-11 cursor-pointer items-center gap-2 pl-3 sm:min-h-9">
            <input type="checkbox" class="size-4 cursor-pointer accent-primary-700" :checked="isPageSelected" @change="togglePage">
            Odaberi sve na stranici
          </label>
          <button
            v-if="isPageSelected && total > rows.length && selected.length < Math.min(total, MAX_BULK_SELECTION)"
            type="button"
            :disabled="isSelectingAll"
            class="inline-flex min-h-11 cursor-pointer items-center font-medium text-primary-800 underline underline-offset-4 hover:text-primary-900 disabled:opacity-50 sm:min-h-9"
            @click="selectAllMatching"
          >
            Odaberi svih {{ Math.min(total, MAX_BULK_SELECTION) }} rezultata
          </button>
        </div>
        <ul class="divide-y divide-primary-200">
          <li v-for="product in rows" :key="product.id">
            <ProductRow
              :product="product"
              :can-write="canWrite"
              :archived="filters.archived"
              :selected="selectedSet.has(product.id)"
              @toggle="toggleSelected(product.id)"
              @archive="startAction('archive', [product.id])"
              @restore="execute('restore', [product.id])"
              @delete="startAction('delete', [product.id])"
              @edit-stock="editingStock = product"
            />
          </li>
        </ul>
      </div>

      <nav v-if="pageCount > 1" aria-label="Stranice" class="mt-4 flex items-center justify-between gap-3">
        <BaseButton variant="secondary" :loading="page === 0" @click="goToPage(page - 1)">Prethodna</BaseButton>
        <span class="text-sm text-stone-600">{{ page + 1 }} / {{ pageCount }}</span>
        <BaseButton variant="secondary" :loading="page >= pageCount - 1" @click="goToPage(page + 1)">Sljedeća</BaseButton>
      </nav>
    </template>

    <ProductBulkBar
      v-if="canWrite && selected.length"
      :count="selected.length"
      :archived="filters.archived"
      :loading="isWorking"
      @action="startAction"
      @clear="selected = []"
    />

    <ProductStockModal :product="editingStock" @close="editingStock = null" @saved="onStockSaved" />

    <ProductCampaignModal
      :open="Boolean(campaignIds)"
      :count="campaignIds?.length ?? 0"
      :campaigns="campaigns"
      :loading="isWorking"
      :error="actionError"
      @close="campaignIds = null"
      @apply="(campaignId) => campaignIds && execute('campaign', campaignIds, campaignId)"
    />

    <ConfirmDialog
      :open="Boolean(pending)"
      :title="pending?.action === 'delete' ? 'Trajno obriši' : 'Arhiviraj'"
      :confirm-label="pending?.action === 'delete' ? 'Obriši trajno' : 'Arhiviraj'"
      :loading="isWorking"
      :error="actionError"
      @close="pending = null"
      @confirm="pending && execute(pending.action, pending.ids)"
    >
      <template v-if="pending?.action === 'delete'">
        Sigurno želiš trajno obrisati {{ pending?.label }} sa svim bojama, količinama i slikama? U povijesti ostaje samo zapis o brisanju. Ova radnja se ne može poništiti.
      </template>
      <template v-else>
        {{ pending?.label }} nestat će s weba i preći u arhivu. Podaci ostaju, ali se brišu sve slike osim prve. Proizvod možeš kasnije vratiti, ali ćeš slike morati dodati ponovno.
      </template>
    </ConfirmDialog>
  </div>
</template>
