<script setup lang="ts">
import { ArrowUpRight } from '@lucide/vue'
import { ADMIN_NAV_BOTTOM, ADMIN_NAV_GROUPS } from '~/config/navigation'

const props = defineProps<{ open: boolean }>()
const emit = defineEmits<{ close: [] }>()

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape' && props.open) emit('close')
}

onMounted(() => window.addEventListener('keydown', onKeydown))
onBeforeUnmount(() => window.removeEventListener('keydown', onKeydown))
</script>

<template>
  <div v-if="open" class="fixed inset-0 z-40 bg-primary-950/50 lg:hidden" aria-hidden="true" @click="emit('close')" />

  <aside
    class="fixed inset-y-0 left-0 z-50 flex w-60 flex-col border-r border-primary-300 bg-primary-100 transition-transform lg:translate-x-0"
    :class="open ? 'translate-x-0' : 'invisible -translate-x-full lg:visible'"
  >
    <div class="flex h-14 shrink-0 items-center justify-between px-5">
      <AppLogo to="/admin" />
      <MenuButton class="-mr-2 lg:hidden" label="Zatvori izbornik" close @click="emit('close')" />
    </div>

    <nav aria-label="Admin navigacija" class="flex flex-1 flex-col overflow-y-auto px-3 pb-3 pt-2">
      <template v-for="(group, index) in ADMIN_NAV_GROUPS" :key="index">
        <hr v-if="index > 0" class="my-3 border-primary-300">
        <AdminNavList :links="group" />
      </template>

      <div class="mt-auto pt-3">
        <hr class="mb-3 border-primary-300">
        <AdminNavList :links="ADMIN_NAV_BOTTOM" />
        <NuxtLink to="/" class="mt-0.5 flex min-h-11 items-center gap-2.5 rounded-lg px-2.5 text-sm text-primary-900 transition-colors hover:bg-primary-200 lg:min-h-9">
          <ArrowUpRight class="size-4" stroke-width="1.75" />
          Pogledaj web shop
        </NuxtLink>
      </div>
    </nav>
  </aside>
</template>
