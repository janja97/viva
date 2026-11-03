<script setup lang="ts">
import { PERMISSION_LABELS, type Permission } from '~/config/roles'

const { can } = usePermissions()
const permissions = Object.keys(PERMISSION_LABELS) as Permission[]
</script>

<template>
  <AdminCard title="Tvoje ovlasti">
    <ul class="space-y-2 text-sm">
      <li v-for="permission in permissions" :key="permission" class="flex items-center justify-between gap-4">
        <span class="text-stone-600">{{ PERMISSION_LABELS[permission] }}</span>
        <span :class="can(permission) ? 'font-medium text-emerald-700' : 'text-stone-400'">
          {{ can(permission) ? 'Da' : 'Ne' }}
        </span>
      </li>
    </ul>
  </AdminCard>
</template>
