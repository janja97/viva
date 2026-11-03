<script setup lang="ts">
usePageSeo({
  title: 'O nama - svečana moda u Mostaru',
  description: 'Trgovina luksuzne svečane mode u Mepas Mallu u Mostaru. Svečane haljine, obuća i dodaci.',
})
</script>

<template>
  <section class="mx-auto max-w-3xl px-4 py-20 text-center">
    <h1 class="font-display text-5xl font-medium">O nama</h1>
    <span class="mx-auto mb-8 mt-5 block h-px w-14 bg-gold" aria-hidden="true" />
    <p class="text-lg leading-relaxed text-muted">
      Naša trgovina u Mepas Mallu u Mostaru posvećena je luksuznoj svečanoj modi. U ponudi su svečane haljine,
      obuća i dodaci za prilike koje zaslužuju posebnu pažnju.
    </p>
    <div class="mt-10">
      <SiteLink to="/proizvodi" variant="outline">Pogledajte kolekciju</SiteLink>
    </div>
  </section>
</template>
