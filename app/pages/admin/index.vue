<script setup lang="ts">
import { Package, ShoppingBag, Users } from '@lucide/vue'

definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Nadzorna ploča', noindex: true })

// Vrijednosti se povezuju s bazom kad nastanu tablice proizvoda i narudžbi.
const stats = [
  { label: 'Proizvodi', value: '—', icon: Package, tone: 'primary' as const },
  { label: 'Narudžbe', value: '—', icon: ShoppingBag, tone: 'pink' as const },
  { label: 'Korisnici', value: '—', icon: Users, tone: 'sky' as const },
]
</script>

<template>
  <div>
    <AdminPageHeader title="Nadzorna ploča" />
    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <StatCard v-for="stat in stats" :key="stat.label" v-bind="stat" />
    </div>
    <PermissionList class="mt-4 max-w-md" />
  </div>
</template>
