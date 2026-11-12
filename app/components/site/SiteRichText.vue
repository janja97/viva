<script setup lang="ts">
// Jednostavan tekst iz admina: prazan red odvaja odlomke, red koji počinje s "## " je podnaslov (h2),
// a [tekst](/kategorija/haljine) je poveznica (samo putanja na webu ili https://).
// Ne prikazuje HTML, pa je siguran za tekst koji upisuje tim.
const props = defineProps<{ text: string }>()

type Segment = { text: string; href?: string }
const LINK = /\[([^\]]+)\]\(((?:\/|https:\/\/)[^)\s]*)\)/g

function segments(text: string): Segment[] {
  const result: Segment[] = []
  let last = 0
  for (const match of text.matchAll(LINK)) {
    if (match.index > last) result.push({ text: text.slice(last, match.index) })
    result.push({ text: match[1]!, href: match[2]! })
    last = match.index + match[0].length
  }
  if (last < text.length) result.push({ text: text.slice(last) })
  return result
}

const blocks = computed(() => props.text
  .split(/\n\s*\n/)
  .map((block) => block.trim())
  .filter(Boolean)
  .flatMap((block) => {
    const [first = '', ...rest] = block.split('\n')
    if (!first.startsWith('## ')) return [{ type: 'p' as const, parts: segments(block) }]
    const heading = { type: 'h2' as const, parts: [{ text: first.slice(3).trim() }] }
    return rest.length ? [heading, { type: 'p' as const, parts: segments(rest.join('\n').trim()) }] : [heading]
  }))
</script>

<template>
  <div class="leading-relaxed text-muted">
    <template v-for="(block, index) in blocks" :key="index">
      <h2 v-if="block.type === 'h2'" class="mb-3 mt-8 font-display text-3xl font-normal text-ink first:mt-0">{{ block.parts[0]?.text }}</h2>
      <p v-else class="mt-3 whitespace-pre-line first:mt-0">
        <template v-for="(part, partIndex) in block.parts" :key="partIndex">
          <NuxtLink v-if="part.href?.startsWith('/')" :to="part.href" class="text-ink underline underline-offset-4 hover:text-gold">{{ part.text }}</NuxtLink>
          <a v-else-if="part.href" :href="part.href" target="_blank" rel="noopener" class="text-ink underline underline-offset-4 hover:text-gold">{{ part.text }}</a>
          <template v-else>{{ part.text }}</template>
        </template>
      </p>
    </template>
  </div>
</template>
