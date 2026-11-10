<script setup lang="ts">
// Jednostavan tekst iz admina: prazan red odvaja odlomke, a red koji počinje s "## " je podnaslov (h2).
// Ne prikazuje HTML, pa je siguran za tekst koji upisuje tim.
const props = defineProps<{ text: string }>()

const blocks = computed(() => props.text
  .split(/\n\s*\n/)
  .map((block) => block.trim())
  .filter(Boolean)
  .flatMap((block) => {
    const [first = '', ...rest] = block.split('\n')
    if (!first.startsWith('## ')) return [{ type: 'p' as const, text: block }]
    const heading = { type: 'h2' as const, text: first.slice(3).trim() }
    return rest.length ? [heading, { type: 'p' as const, text: rest.join('\n').trim() }] : [heading]
  }))
</script>

<template>
  <div class="leading-relaxed text-muted">
    <template v-for="(block, index) in blocks" :key="index">
      <h2 v-if="block.type === 'h2'" class="mb-3 mt-8 font-display text-3xl font-normal text-ink first:mt-0">{{ block.text }}</h2>
      <p v-else class="mt-3 whitespace-pre-line first:mt-0">{{ block.text }}</p>
    </template>
  </div>
</template>
