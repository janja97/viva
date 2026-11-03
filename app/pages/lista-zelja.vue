<script setup lang="ts">
usePageSeo({ title: 'Lista želja', noindex: true })

const { cards, isLoaded, load, remove } = useWishlist()
const error = ref('')
const removingId = ref('')

async function onRemove(colorId: string) {
  removingId.value = colorId
  error.value = ''
  try {
    await remove(colorId)
  } catch (caught) {
    error.value = shopErrorMessage(caught)
  } finally {
    removingId.value = ''
  }
}

onMounted(() => load().catch((caught) => {
  error.value = shopErrorMessage(caught)
}))
</script>

<template>
  <div class="mx-auto max-w-7xl px-4 pb-20 pt-8 sm:px-6 lg:px-8 lg:pt-12">
    <h1 class="font-display text-4xl font-normal leading-tight lg:text-5xl">Lista želja</h1>
    <p class="mt-2 text-sm text-muted">Lista se čuva 7 dana od zadnje izmjene.</p>
    <p v-if="error" role="alert" class="mt-4 text-sm text-red-700">{{ error }}</p>

    <p v-if="!isLoaded && !error" class="mt-8 text-muted">Učitavanje...</p>
    <div v-else-if="!cards.length" class="mt-8 border-y border-line py-16 text-center">
      <p class="text-muted">Na listi želja još nema proizvoda.</p>
      <SiteLink to="/proizvodi" class="mt-6">Pogledaj kolekciju</SiteLink>
    </div>
    <ul v-else class="mt-8 grid grid-cols-2 gap-x-4 gap-y-10 lg:grid-cols-4">
      <li v-for="(card, index) in cards" :key="card.id">
        <ProductCard :card="card" :eager="index < 2" />
        <button
          type="button"
          :disabled="removingId === card.id"
          class="mt-2 inline-flex min-h-11 items-center text-xs font-medium uppercase tracking-[0.16em] text-muted underline underline-offset-4 hover:text-ink disabled:opacity-50"
          @click="onRemove(card.id)"
        >
          Ukloni s liste
        </button>
      </li>
    </ul>
  </div>
</template>
