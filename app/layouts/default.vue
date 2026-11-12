<script setup lang="ts">
import '@fontsource-variable/cormorant-garamond/wght.css'
import '@fontsource-variable/cormorant-garamond/wght-italic.css'
import '@fontsource-variable/jost'

// Dok je NUXT_PUBLIC_COMING_SOON=true, kupci vide samo stranicu "Uskoro" (ComingSoon), bez navigacije i footera.
// Prijavljeni članovi tima vide pravi web (provjera tek u pregledniku), a odjava s newslettera uvijek radi.
const ALWAYS_OPEN_PATHS = ['/odjava']

const { comingSoon } = useRuntimeConfig().public
const route = useRoute()
const { role, init } = useAuth()

onMounted(() => {
  if (comingSoon) init().catch(console.error)
})

const showComingSoon = computed(() => Boolean(comingSoon) && !role.value && !ALWAYS_OPEN_PATHS.includes(route.path))
</script>

<template>
  <ComingSoon v-if="showComingSoon" />
  <div v-else class="flex min-h-dvh flex-col bg-ivory font-body text-ink">
    <a
      href="#sadrzaj"
      class="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-50 focus:bg-white focus:px-4 focus:py-2"
    >
      Preskoči na sadržaj
    </a>
    <SiteTopBar />
    <SiteHeader />
    <main id="sadrzaj" class="flex-1">
      <slot />
    </main>
    <SiteFooter />
    <CartDrawer />
  </div>
</template>
