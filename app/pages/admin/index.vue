<script setup lang="ts">
import type { DashboardBasic as DashboardBasicData } from '~/types/database'

definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Nadzorna ploča', noindex: true })

// Super admin ima kartice Prodaja, Statistika i Zalihe. Ostali vide samo osnovno: što čeka obradu i zalihe.
// Analitiku prodaje baza daje samo super adminu.
const { can } = usePermissions()
const { fetchBasic } = useDashboard()

const basic = ref<DashboardBasicData | null>(null)
const loadError = ref('')

async function load() {
  loadError.value = ''
  try {
    basic.value = await fetchBasic()
  } catch (error) {
    loadError.value = productErrorMessage(error)
  }
}

onMounted(load)
</script>

<template>
  <div>
    <AdminPageHeader title="Nadzorna ploča" :description="can('view_analytics') ? undefined : 'Što čeka obradu i stanje zaliha.'" />
    <div v-if="loadError" class="mb-4 space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <BaseButton variant="secondary" @click="load">Pokušaj ponovno</BaseButton>
    </div>

    <SuperAdminDashboard v-if="can('view_analytics')" :basic="basic" />
    <template v-else>
      <p v-if="!basic && !loadError" class="text-sm text-stone-500">Učitavanje...</p>
      <DashboardBasic v-else-if="basic" :data="basic" />
      <PermissionList class="mt-6 max-w-md" />
    </template>
  </div>
</template>
