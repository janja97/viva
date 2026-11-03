<script setup lang="ts">
import { Search } from '@lucide/vue'

const route = useRoute()
const id = useId()
const query = ref(typeof route.query.q === 'string' ? route.query.q : '')

function onSubmit() {
  const q = query.value.trim()
  if (q) navigateTo({ path: '/pretraga', query: { q } })
}
</script>

<template>
  <form action="/pretraga" method="get" role="search" class="relative" @submit.prevent="onSubmit">
    <label :for="id" class="sr-only">Pretraži proizvode</label>
    <input
      :id="id"
      v-model="query"
      type="search"
      name="q"
      placeholder="Pretraži haljine, obuću, torbice..."
      class="min-h-11 w-full border border-line bg-white pl-4 pr-12 text-base placeholder:text-muted focus:border-graphite focus:outline-none md:text-sm"
    >
    <button type="submit" aria-label="Traži" class="absolute right-0 top-0 inline-flex size-11 items-center justify-center text-graphite">
      <Search class="size-4" stroke-width="1.25" />
    </button>
  </form>
</template>
