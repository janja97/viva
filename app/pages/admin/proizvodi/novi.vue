<script setup lang="ts">
definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Novi proizvod', noindex: true })

const initial = emptyProductForm()
</script>

<template>
  <div>
    <AdminPageHeader title="Novi proizvod" />
    <ProductEditor :initial="initial" is-new />
  </div>
</template>
