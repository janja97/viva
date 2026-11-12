<script setup lang="ts">
// Članak bloga (migracija 0037), uz BlogPosting, BreadcrumbList i FAQ (SiteFaq) za Google.
const route = useRoute()
const slug = route.params.slug as string
const { fetchPost } = useBlog()
const imageFor = useBlogImage()
const { siteUrl, siteName } = useRuntimeConfig().public
const origin = (siteUrl || useRequestURL().origin).replace(/\/$/, '')

const { data: post } = await useAsyncData(`blog-${slug}`, () => fetchPost(slug))
if (!post.value) {
  throw createError({ statusCode: 404, statusMessage: 'Članak nije pronađen', fatal: true })
}

const article = post.value
const cover = imageFor(article.cover_path)
const url = `${origin}/blog/${article.slug}`

usePageSeo({
  title: article.meta_title || article.title,
  description: article.meta_description || article.excerpt || article.title,
  image: cover ?? undefined,
})

useHead({
  script: [
    {
      type: 'application/ld+json',
      innerHTML: JSON.stringify({
        '@context': 'https://schema.org',
        '@type': 'BlogPosting',
        headline: article.title,
        description: article.meta_description || article.excerpt,
        ...(cover && { image: [cover] }),
        datePublished: article.published_at,
        dateModified: article.updated_at,
        author: { '@type': 'Organization', name: siteName, url: origin },
        publisher: { '@type': 'Organization', name: siteName, logo: { '@type': 'ImageObject', url: `${origin}/logo/logo-square.png` } },
        mainEntityOfPage: url,
      }),
    },
    {
      type: 'application/ld+json',
      innerHTML: JSON.stringify(breadcrumbJsonLd([
        { name: 'Početna', url: `${origin}/` },
        { name: 'Blog', url: `${origin}/blog` },
        { name: article.title, url },
      ])),
    },
  ],
})
</script>

<template>
  <article v-if="post" class="mx-auto max-w-3xl px-4 py-10 sm:px-6 lg:py-14">
    <SiteBreadcrumbs class="mb-6" :items="[{ label: 'Početna', to: '/' }, { label: 'Blog', to: '/blog' }, { label: post.title }]" />
    <p class="text-[11px] uppercase tracking-[0.16em] text-muted">{{ blogDate(post.published_at) }}</p>
    <h1 class="mt-2 font-display text-4xl font-normal leading-tight sm:text-5xl">{{ post.title }}</h1>
    <p v-if="post.excerpt" class="mt-5 text-lg leading-relaxed text-muted">{{ post.excerpt }}</p>

    <img
      v-if="cover"
      :src="cover"
      :alt="post.cover_alt || post.title"
      width="1200"
      height="900"
      fetchpriority="high"
      class="mt-8 aspect-4/3 w-full bg-photo object-cover"
    >

    <SiteRichText class="mt-10" :text="post.body" />

    <SiteFaq v-if="post.faq.length" class="mt-14 border-t border-line pt-10" :items="post.faq" />

    <div class="mt-14 border-t border-line pt-10 text-center">
      <p class="font-display text-2xl">Pogledajte ponudu ili nas posjetite u Mepas Mallu u Mostaru</p>
      <div class="mt-6 flex flex-wrap justify-center gap-3">
        <SiteLink to="/proizvodi">Pogledaj kolekciju</SiteLink>
        <SiteLink to="/blog" variant="outline">Svi savjeti</SiteLink>
      </div>
    </div>
  </article>
</template>
