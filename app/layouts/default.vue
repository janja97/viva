<script setup lang="ts">
import '@fontsource-variable/cormorant-garamond/wght.css'
import '@fontsource-variable/cormorant-garamond/wght-italic.css'
import '@fontsource-variable/jost'
import { HOME_TOP_BAR } from '~/config/home'
</script>

<template>
  <div class="flex min-h-dvh flex-col bg-ivory font-body text-ink">
    <a
      href="#sadrzaj"
      class="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-50 focus:bg-white focus:px-4 focus:py-2"
    >
      Preskoči na sadržaj
    </a>
    <p class="bg-graphite px-4 py-2 text-center text-[11px] uppercase tracking-[0.16em] text-white">
      <span class="hidden sm:inline">{{ HOME_TOP_BAR.desktop }}</span>
      <span class="sm:hidden">{{ HOME_TOP_BAR.mobile }}</span>
    </p>
    <SiteHeader />
    <main id="sadrzaj" class="flex-1">
      <slot />
    </main>
    <SiteFooter />
    <CartDrawer />
  </div>
</template>
