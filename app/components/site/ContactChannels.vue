<script setup lang="ts">
import { Mail, MessageCircle, Phone, Send } from '@lucide/vue'

// Načini kontakta na stranici /kontakt: samo oni koji su upisani u postavkama trgovine.
const { settings } = useStoreSettings()

const channels = computed(() => [
  settings.value.phone && { label: 'Telefon', value: settings.value.phone, url: `tel:${phoneDigits(settings.value.phone)}`, icon: Phone, external: false },
  settings.value.whatsapp && { label: 'WhatsApp', value: 'Pošaljite poruku', url: `https://wa.me/${phoneDigits(settings.value.whatsapp).replace('+', '')}`, icon: MessageCircle, external: true },
  settings.value.viber && { label: 'Viber', value: 'Pošaljite poruku', url: `viber://chat?number=${encodeURIComponent(phoneDigits(settings.value.viber))}`, icon: Send, external: true },
  settings.value.email && { label: 'E-mail', value: settings.value.email, url: `mailto:${settings.value.email}`, icon: Mail, external: false },
].filter((item): item is NonNullable<typeof item> & object => Boolean(item)))
</script>

<template>
  <ul v-if="channels.length" class="grid gap-px border border-line bg-line sm:grid-cols-2">
    <li v-for="channel in channels" :key="channel.label" class="bg-ivory">
      <a
        :href="channel.url"
        :target="channel.external ? '_blank' : undefined"
        :rel="channel.external ? 'noopener' : undefined"
        class="group flex min-h-24 items-center gap-4 px-5 py-5 transition-colors hover:bg-sand"
      >
        <span class="flex size-11 flex-none items-center justify-center rounded-full border border-line text-gold transition-colors group-hover:border-gold">
          <component :is="channel.icon" class="size-4" stroke-width="1.5" aria-hidden="true" />
        </span>
        <span class="min-w-0">
          <span class="block text-[11px] font-medium uppercase tracking-[0.2em] text-muted">{{ channel.label }}</span>
          <span class="mt-1 block truncate text-ink group-hover:text-gold">{{ channel.value }}</span>
        </span>
      </a>
    </li>
  </ul>
</template>
