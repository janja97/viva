<script setup lang="ts">
const emit = defineEmits<{ openMenu: [] }>()

const { user, role, signOut } = useAuth()
</script>

<template>
  <header class="sticky top-0 z-30 flex h-14 items-center justify-between gap-3 border-b border-primary-300 bg-white px-4 sm:px-6 lg:px-8">
    <div class="flex items-center gap-2">
      <MenuButton class="-ml-2 lg:hidden" label="Otvori izbornik" @click="emit('openMenu')" />
      <NewOrdersAlert />
    </div>
    <div class="flex min-w-0 items-center gap-3">
      <NuxtLink to="/admin/moj-racun" class="hidden truncate text-sm text-stone-600 hover:text-primary-700 sm:block">{{ user?.email }}</NuxtLink>
      <RoleBadge v-if="role" :role="role" />
      <BaseButton variant="secondary" @click="signOut">Odjava</BaseButton>
    </div>
  </header>
</template>
