<script setup lang="ts">
import { Pencil } from '@lucide/vue'
import type { ProductForm } from '~/types/productForm'

definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Proizvod', noindex: true })

const route = useRoute()
const { can } = usePermissions()
const { fetchForm } = useProducts()

const initial = ref<ProductForm | null>(null)
const isLoading = ref(true)
const loadError = ref('')

const isArchived = computed(() => Boolean(initial.value?.archived_at))
const isPreview = computed(() => route.query.pregled !== undefined || !can('write') || isArchived.value)

async function load() {
  isLoading.value = true
  loadError.value = ''
  try {
    initial.value = await fetchForm(route.params.id as string)
    if (!initial.value) loadError.value = 'Proizvod nije pronađen.'
  } catch (error) {
    loadError.value = productErrorMessage(error)
  } finally {
    isLoading.value = false
  }
}

onMounted(load)
</script>

<template>
  <div>
    <AdminPageHeader :title="isPreview ? 'Pregled proizvoda' : 'Uredi proizvod'" :description="initial ? `Šifra ${initial.sku}` : undefined">
      <div v-if="isPreview && initial" class="flex items-center gap-2">
        <NuxtLink to="/admin/proizvodi" class="inline-flex min-h-11 items-center rounded-lg px-3.5 text-sm font-medium text-stone-700 hover:bg-primary-100 sm:min-h-9">
          Natrag
        </NuxtLink>
        <NuxtLink v-if="can('write') && !isArchived" :to="`/admin/proizvodi/${initial.id}`" class="inline-flex min-h-11 items-center gap-1.5 rounded-lg bg-primary-600 px-3.5 text-sm font-medium text-white transition-colors hover:bg-primary-700 sm:min-h-9">
          <Pencil class="size-4" stroke-width="1.75" />
          Uredi
        </NuxtLink>
      </div>
    </AdminPageHeader>
    <p v-if="isLoading" class="text-sm text-stone-500">Učitavanje...</p>
    <div v-else-if="loadError" class="space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <NuxtLink to="/admin/proizvodi" class="inline-flex min-h-11 items-center text-sm font-medium text-primary-700 hover:text-primary-900">Natrag na proizvode</NuxtLink>
    </div>
    <template v-else-if="initial">
      <BaseAlert v-if="isArchived" type="warning" class="mb-4">
        Proizvod je arhiviran i nije na webu. Za uređivanje ga vrati iz arhive na popisu proizvoda.
      </BaseAlert>
      <ProductEditor :initial="initial" :is-new="false" :read-only="isPreview" />
    </template>
  </div>
</template>
