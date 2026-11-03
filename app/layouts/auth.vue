<script setup lang="ts">
import '@fontsource-variable/cormorant-garamond/wght.css'
import '@fontsource-variable/jost'
</script>

<template>
  <main class="flex min-h-dvh items-center justify-center bg-primary-100 px-4 py-10 font-admin">
    <div class="w-full max-w-sm">
      <slot />
    </div>
  </main>
</template>
