<script setup lang="ts">
// Popis članaka bloga (migracija 0037). Savjeti za odabir svečane haljine, cipela i dodataka.
usePageSeo({
  title: 'Savjeti za svečanu modu - blog',
  description: 'Savjeti za odabir maturalne i svečane haljine, cipela, torbice i nakita. Što obući na maturu, svadbu ili obiteljsku proslavu.',
})

const { fetchPosts } = useBlog()
const imageFor = useBlogImage()
const { data: posts } = await useAsyncData('blog-posts', () => fetchPosts().catch((error) => {
  console.error(error)
  return []
}), { default: () => [] })
</script>

<template>
  <section class="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8 lg:py-14">
    <SiteBreadcrumbs class="mb-6" :items="[{ label: 'Početna', to: '/' }, { label: 'Blog' }]" />
    <h1 class="font-display text-5xl font-normal leading-tight">Savjeti za svečanu modu</h1>
    <p class="mt-4 max-w-2xl text-muted">Kako odabrati haljinu za maturu ili svadbu, što ide uz nju i na što paziti.</p>

    <p v-if="!posts.length" class="mt-12 border-y border-line py-16 text-center text-muted">Prvi članci stižu uskoro.</p>
    <ul v-else class="mt-10 grid gap-x-6 gap-y-12 sm:grid-cols-2 lg:grid-cols-3">
      <li v-for="(post, index) in posts" :key="post.slug">
        <NuxtLink :to="`/blog/${post.slug}`" class="group block">
          <div class="aspect-4/3 overflow-hidden bg-photo">
            <img
              v-if="post.cover_path"
              :src="imageFor(post.cover_path)!"
              :alt="post.cover_alt || post.title"
              width="800"
              height="600"
              :loading="index < 3 ? 'eager' : 'lazy'"
              class="size-full object-cover transition-transform duration-500 group-hover:scale-105"
            >
          </div>
          <p class="mt-4 text-[11px] uppercase tracking-[0.16em] text-muted">{{ blogDate(post.published_at) }}</p>
          <h2 class="mt-1 font-display text-2xl font-normal leading-tight group-hover:text-gold">{{ post.title }}</h2>
          <p v-if="post.excerpt" class="mt-2 line-clamp-3 text-sm text-muted">{{ post.excerpt }}</p>
        </NuxtLink>
      </li>
    </ul>
  </section>
</template>
