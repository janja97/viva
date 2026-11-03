<script setup lang="ts">
import type { ProductAuditEntry } from '~/types/database'

defineProps<{
  entry: ProductAuditEntry
  showProduct?: boolean
}>()

const ACTIONS = {
  created: { label: 'Upisano', color: 'bg-emerald-100 text-emerald-800' },
  updated: { label: 'Uređeno', color: 'bg-primary-200 text-primary-900' },
  deleted: { label: 'Obrisano', color: 'bg-red-100 text-red-800' },
  stock: { label: 'Količina', color: 'bg-primary-100 text-primary-900' },
  archived: { label: 'Arhivirano', color: 'bg-amber-100 text-amber-800' },
  restored: { label: 'Vraćeno', color: 'bg-emerald-100 text-emerald-800' },
}

const dateFormat = new Intl.DateTimeFormat('hr-HR', { dateStyle: 'short', timeStyle: 'short' })
</script>

<template>
  <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-sm">
    <span class="rounded-md px-1.5 py-0.5 text-xs font-medium" :class="ACTIONS[entry.action].color">
      {{ ACTIONS[entry.action].label }}
    </span>
    <template v-if="showProduct">
      <NuxtLink v-if="entry.action !== 'deleted'" :to="`/admin/proizvodi/${entry.product_id}`" class="font-medium text-primary-800 hover:text-primary-900">
        {{ entry.name }}
      </NuxtLink>
      <span v-else class="font-medium">{{ entry.name }}</span>
      <span class="text-xs text-stone-500">{{ entry.sku }}</span>
    </template>
    <span class="break-all text-stone-700">{{ entry.user_email ?? 'Nepoznat korisnik' }}</span>
    <span class="text-xs text-stone-500 sm:ml-auto">{{ dateFormat.format(new Date(entry.created_at)) }}</span>
    <ul v-if="entry.details?.length" class="w-full text-xs text-stone-600">
      <li v-for="item in entry.details" :key="`${item.color}-${item.size}`">
        {{ item.color }} {{ item.size }}: {{ item.from }} → {{ item.to }}
      </li>
    </ul>
  </div>
</template>
