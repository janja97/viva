<script setup lang="ts">
// Poveznice za WhatsApp i Viber, ako su brojevi upisani u postavkama.
const { settings } = useStoreSettings()

const links = computed(() => [
  settings.value.whatsapp && { label: 'WhatsApp', url: `https://wa.me/${phoneDigits(settings.value.whatsapp).replace('+', '')}` },
  settings.value.viber && { label: 'Viber', url: `viber://chat?number=${encodeURIComponent(phoneDigits(settings.value.viber))}` },
].filter((link): link is { label: string; url: string } => Boolean(link)))
</script>

<template>
  <ul v-if="links.length" class="flex flex-wrap gap-x-5">
    <li v-for="link in links" :key="link.label">
      <a :href="link.url" target="_blank" rel="noopener" class="inline-flex min-h-11 items-center underline underline-offset-4">{{ link.label }}</a>
    </li>
  </ul>
</template>
