<script setup lang="ts">
import { TriangleAlert, Clock, Eye, EyeOff, Mail, PackageX, ShoppingBag, Tag } from '@lucide/vue'
import type { DashboardBasic as DashboardBasicData } from '~/types/database'

// Osnovni pregled za cijeli tim: što treba obraditi i stanje zaliha, bez iznosa prodaje.
defineProps<{ data: DashboardBasicData }>()
</script>

<template>
  <div class="space-y-4">
    <div class="grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-4">
      <StatCard label="Nove narudžbe" :value="String(data.orders.new)" :icon="ShoppingBag" :hint="`Danas stiglo: ${data.orders.today}`" to="/admin/narudzbe?status=new" />
      <StatCard label="U obradi" :value="String(data.orders.in_progress)" :icon="Clock" to="/admin/narudzbe?status=in_progress" />
      <StatCard label="Pretplatnici na newsletter" :value="String(data.subscribers)" :icon="Mail" to="/admin/newsletter" />
      <StatCard label="Proizvodi na webu" :value="String(data.products.visible)" :icon="Eye" :hint="`U arhivi: ${data.products.archived}`" to="/admin/proizvodi" />
      <StatCard label="Skriveni proizvodi" :value="String(data.products.hidden)" :icon="EyeOff" />
      <StatCard label="Na sniženju" :value="String(data.products.on_sale)" :icon="Tag" to="/admin/kampanje" />
      <StatCard label="Rasprodane boje" :value="String(data.sold_out_colors)" :icon="PackageX" hint="Sve veličine su na nuli." />
      <StatCard label="Malo zalihe" :value="String(data.low_stock_total)" :icon="TriangleAlert" hint="Veličine s 1 ili 2 komada." />
    </div>

    <StockBySize />

    <AdminCard v-if="data.sold_out.length" title="Rasprodane boje">
      <ul class="divide-y divide-primary-200 text-sm">
        <li v-for="item in data.sold_out" :key="`${item.product_id}-${item.color}`" class="flex items-center justify-between gap-3 py-2">
          <NuxtLink :to="`/admin/proizvodi/${item.product_id}`" class="min-w-0 truncate text-primary-800 hover:text-primary-900">
            {{ item.name }} <span class="text-stone-500">· {{ item.color }}</span>
          </NuxtLink>
          <span class="shrink-0 rounded-md bg-red-100 px-1.5 py-0.5 text-xs font-medium text-red-800">Rasprodano</span>
        </li>
      </ul>
      <p v-if="data.sold_out_colors > data.sold_out.length" class="mt-3 text-xs text-stone-500">
        Prikazano {{ data.sold_out.length }} od {{ data.sold_out_colors }}.
      </p>
    </AdminCard>

    <AdminCard v-if="data.low_stock.length" title="Malo zalihe">
      <ul class="divide-y divide-primary-200 text-sm">
        <li v-for="item in data.low_stock" :key="`${item.product_id}-${item.color}-${item.size}`" class="flex items-center justify-between gap-3 py-2">
          <NuxtLink :to="`/admin/proizvodi/${item.product_id}`" class="min-w-0 truncate text-primary-800 hover:text-primary-900">
            {{ item.name }} <span class="text-stone-500">· {{ item.color }} · {{ item.size }}</span>
          </NuxtLink>
          <span class="shrink-0 rounded-md bg-amber-100 px-1.5 py-0.5 text-xs font-medium text-amber-800">{{ item.quantity }} kom</span>
        </li>
      </ul>
      <p v-if="data.low_stock_total > data.low_stock.length" class="mt-3 text-xs text-stone-500">
        Prikazano {{ data.low_stock.length }} od {{ data.low_stock_total }}. Ostale nađeš u Proizvodima filtrom količine.
      </p>
    </AdminCard>
  </div>
</template>
