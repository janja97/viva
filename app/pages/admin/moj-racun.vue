<script setup lang="ts">
import { ROLE_DESCRIPTIONS } from '~/config/roles'

definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Moj račun', noindex: true })

const { user, role } = useAuth()
</script>

<template>
  <div>
    <AdminPageHeader title="Moj račun" />
    <div class="max-w-lg space-y-4">
      <AdminCard title="Podaci">
        <p class="break-all text-sm text-stone-700">{{ user?.email }}</p>
        <div v-if="role" class="mt-3">
          <RoleBadge :role="role" />
          <p class="mt-2 text-sm text-stone-500">{{ ROLE_DESCRIPTIONS[role] }}</p>
        </div>
      </AdminCard>
      <AdminCard title="Promjena lozinke">
        <ChangePasswordForm />
      </AdminCard>
    </div>
  </div>
</template>
