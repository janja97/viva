<script setup lang="ts">
import { ROLE_LABELS } from '~/config/roles'
import type { AppRole } from '~/types/database'

defineProps<{ role: AppRole }>()

const COLORS: Record<AppRole, string> = {
  super_admin: 'bg-primary-950 text-white',
  admin: 'bg-primary-200 text-primary-900',
  viewer: 'border border-primary-300 bg-white text-stone-700',
}
</script>

<template>
  <span class="whitespace-nowrap rounded-md px-2 py-1 text-xs font-medium" :class="COLORS[role]">
    {{ ROLE_LABELS[role] }}
  </span>
</template>
