<script setup lang="ts">
import type { FaqItem } from '~/types/database'

// Česta pitanja na dnu stranice, uz FAQPage JSON-LD za Google.
const props = withDefaults(defineProps<{ items: FaqItem[]; title?: string }>(), { title: 'Česta pitanja' })
const headingId = useId()

useHead({
  script: computed(() => (props.items.length
    ? [{
        type: 'application/ld+json',
        innerHTML: JSON.stringify({
          '@context': 'https://schema.org',
          '@type': 'FAQPage',
          mainEntity: props.items.map(({ question, answer }) => ({
            '@type': 'Question',
            name: question,
            acceptedAnswer: { '@type': 'Answer', text: answer },
          })),
        }),
      }]
    : [])),
})
</script>

<template>
  <section v-if="items.length" :aria-labelledby="headingId">
    <h2 :id="headingId" class="mb-4 font-display text-3xl font-normal">{{ title }}</h2>
    <details v-for="item in items" :key="item.question" class="border-b border-line py-3">
      <summary class="flex min-h-11 cursor-pointer items-center font-medium">{{ item.question }}</summary>
      <p class="whitespace-pre-line pb-2 text-muted">{{ item.answer }}</p>
    </details>
  </section>
</template>
