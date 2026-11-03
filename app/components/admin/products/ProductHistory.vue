<script setup lang="ts">
const props = defineProps<{
  productId: string
  refreshKey: number
}>()

const { entries, isLoading, loadError, load } = useProductAudit(props.productId)

watch(() => props.refreshKey, load)
onMounted(load)
</script>

<template>
  <AdminCard title="Povijest izmjena">
    <BaseAlert v-if="loadError" type="error">{{ loadError }}</BaseAlert>
    <p v-else-if="isLoading && !entries.length" class="text-sm text-stone-500">Učitavanje...</p>
    <p v-else-if="!entries.length" class="text-sm text-stone-500">Još nema zapisa.</p>
    <ul v-else class="divide-y divide-primary-200">
      <li v-for="entry in entries" :key="entry.id" class="py-2 first:pt-0 last:pb-0">
        <AuditEntry :entry="entry" />
      </li>
    </ul>
  </AdminCard>
</template>
