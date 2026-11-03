<script setup lang="ts">
definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Povijest proizvoda', noindex: true })

const { entries, page, pageCount, isLoading, loadError, load } = useProductAudit()

function goToPage(target: number) {
  page.value = target
  load()
}

onMounted(load)
</script>

<template>
  <div>
    <AdminPageHeader title="Povijest proizvoda" description="Tko je i kada upisao, uredio ili obrisao proizvod.">
      <NuxtLink to="/admin/proizvodi" class="inline-flex min-h-11 items-center text-sm font-medium text-primary-700 hover:text-primary-900 sm:min-h-9">
        Natrag na proizvode
      </NuxtLink>
    </AdminPageHeader>

    <div v-if="loadError" class="space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <BaseButton variant="secondary" @click="load">Pokušaj ponovno</BaseButton>
    </div>
    <p v-else-if="isLoading && !entries.length" class="text-sm text-stone-500">Učitavanje...</p>
    <p v-else-if="!entries.length" class="rounded-xl border border-dashed border-primary-300 bg-white px-4 py-12 text-center text-sm text-stone-500">
      Još nema zapisa.
    </p>
    <template v-else>
      <ul class="divide-y divide-primary-200 rounded-xl border border-primary-300 bg-white shadow-sm">
        <li v-for="entry in entries" :key="entry.id" class="px-4 py-3">
          <AuditEntry :entry="entry" show-product />
        </li>
      </ul>
      <nav v-if="pageCount > 1" aria-label="Stranice" class="mt-4 flex items-center justify-between gap-3">
        <BaseButton variant="secondary" :loading="page === 0" @click="goToPage(page - 1)">Novije</BaseButton>
        <span class="text-sm text-stone-600">{{ page + 1 }} / {{ pageCount }}</span>
        <BaseButton variant="secondary" :loading="page >= pageCount - 1" @click="goToPage(page + 1)">Starije</BaseButton>
      </nav>
    </template>
  </div>
</template>
