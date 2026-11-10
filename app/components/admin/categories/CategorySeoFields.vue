<script setup lang="ts">
import type { FaqItem } from '~/types/database'

// SEO kategorije (migracija 0031). Prazno znači da web koristi zadani naslov i opis.
const metaTitle = defineModel<string>('metaTitle', { required: true })
const metaDescription = defineModel<string>('metaDescription', { required: true })
const seoText = defineModel<string>('seoText', { required: true })
const faq = defineModel<FaqItem[]>('faq', { required: true })

defineProps<{ name: string }>()

const filled = computed(() => [metaTitle.value, metaDescription.value, seoText.value].filter((value) => value.trim()).length + (faq.value.length ? 1 : 0))
</script>

<template>
  <details class="group border border-primary-300" :open="filled > 0">
    <summary class="flex min-h-11 cursor-pointer items-center justify-between px-3 text-sm font-medium text-stone-700">
      SEO i tekst za Google
      <span class="text-xs font-normal text-stone-500">{{ filled ? `Popunjeno: ${filled} od 4` : 'Neobavezno' }}</span>
    </summary>
    <div class="space-y-4 border-t border-primary-300 p-3">
      <p class="text-xs text-stone-500">
        U bilo koje polje možeš upisati <code class="bg-primary-100 px-1">{godina}</code>, a web ga mijenja u godinu sljedeće mature
        (npr. „Maturalne haljine {godina}”).
      </p>
      <BaseInput
        v-model="metaTitle"
        label="Naslov za Google"
        :maxlength="70"
        :placeholder="`${name} - svečana moda`"
        :hint="`${metaTitle.length}/70. Glavna ključna riječ na početku, npr. „Svečane haljine Mostar”.`"
      />
      <BaseTextarea
        v-model="metaDescription"
        label="Opis za Google"
        :maxlength="170"
        :hint="`${metaDescription.length}/170. Ako je prazno, koristi se kratki opis kategorije.`"
      />
      <BaseTextarea
        v-model="seoText"
        label="Tekst ispod proizvoda"
        :rows="8"
        :maxlength="6000"
        hint="150 do 300 riječi. Prazan red odvaja odlomke, a red koji počinje s „## ” je podnaslov."
      />
      <CategoryFaqField v-model="faq" />
    </div>
  </details>
</template>
