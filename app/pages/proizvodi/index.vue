<script setup lang="ts">
usePageSeo({
  title: 'Svečane haljine, cipele i torbice - kolekcija',
  description: 'Svečane i maturalne haljine, ženska odijela, cipele na petu, torbice i nakit. Dostava po BiH, plaćanje pouzećem ili isprobajte u Mepas Mallu u Mostaru.',
})
</script>

<template>
  <section class="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8 lg:py-14">
    <SiteBreadcrumbs class="mb-6" :items="[{ label: 'Početna', to: '/' }, { label: 'Kolekcija' }]" />
    <h1 class="mb-8 font-display text-5xl font-normal leading-tight">Kolekcija</h1>
    <ShopListing listing-key="collection" empty-text="Kolekcija uskoro stiže na web." />
  </section>
</template>
