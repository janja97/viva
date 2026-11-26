<script setup lang="ts">
import '@fontsource-variable/cormorant-garamond/wght.css'
import '@fontsource-variable/cormorant-garamond/wght-italic.css'
import '@fontsource-variable/jost'
</script>

<template>
  <div class="flex min-h-dvh flex-col bg-ivory font-body text-ink">
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
