<script setup lang="ts">
import '@fontsource-variable/cormorant-garamond/wght.css'
import '@fontsource-variable/jost'

const route = useRoute()
const { user } = useAuth()

const isSidebarOpen = ref(false)
const { refresh: refreshNewInquiries } = useNewInquiries()

watch(() => route.fullPath, () => {
  isSidebarOpen.value = false
  refreshNewInquiries()
})

// Nove narudžbe provjeravaju se svake minute, pa se oznaka pojavi i bez osvježavanja stranice.
const NEW_INQUIRIES_INTERVAL = 60_000
let newInquiriesTimer: ReturnType<typeof setInterval> | undefined

onMounted(() => {
  refreshNewInquiries()
  newInquiriesTimer = setInterval(refreshNewInquiries, NEW_INQUIRIES_INTERVAL)
})
onBeforeUnmount(() => clearInterval(newInquiriesTimer))

// Odjava ili istek sesije, i iz druge kartice preglednika.
watch(user, (currentUser) => {
  if (!currentUser) navigateTo('/admin/prijava')
})
</script>

<template>
  <div class="min-h-dvh bg-primary-50 font-admin lg:pl-60">
    <AdminSidebar :open="isSidebarOpen" @close="isSidebarOpen = false" />
    <div class="flex min-h-dvh min-w-0 flex-col">
      <AdminTopbar @open-menu="isSidebarOpen = true" />
      <main class="mx-auto w-full max-w-5xl flex-1 px-4 py-6 sm:px-6 lg:px-8 lg:py-10">
        <slot />
      </main>
    </div>
  </div>
</template>
