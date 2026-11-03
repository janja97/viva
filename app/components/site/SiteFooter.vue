<script setup lang="ts">
import { PUBLIC_NAV, SHOP_NAV } from '~/config/navigation'
import { STORE } from '~/config/store'

const { siteName } = useRuntimeConfig().public
const categoryLink = useCategoryLink()
const year = new Date().getFullYear()

const linkClass = 'inline-flex min-h-11 items-center text-sm text-muted hover:text-ink hover:underline'
const headingClass = 'mb-2 text-xs font-medium uppercase tracking-[0.2em]'
</script>

<template>
  <footer class="bg-sand">
    <div class="mx-auto grid max-w-7xl grid-cols-2 gap-x-4 gap-y-10 px-4 pb-10 pt-14 sm:px-6 md:grid-cols-[2fr_1fr_1fr_1fr] lg:px-8">
      <div class="col-span-2 md:col-span-1">
        <img src="/logo/logo-dark.png" :alt="siteName" width="400" height="214" loading="lazy" class="h-14 w-auto">
        <p class="mt-3 max-w-xs text-sm leading-relaxed text-muted">Butik svečane mode.</p>
        <address class="mt-3 text-sm not-italic leading-relaxed text-muted">
          {{ STORE.mall }}, {{ STORE.street }}, {{ STORE.city }}
          <template v-if="STORE.phone"><br>{{ STORE.phone }}</template>
          <template v-if="STORE.email"><br>{{ STORE.email }}</template>
        </address>
      </div>

      <nav aria-labelledby="podnozje-kupovina">
        <h2 id="podnozje-kupovina" :class="headingClass">Kupovina</h2>
        <ul>
          <li v-for="link in SHOP_NAV" :key="link.label">
            <NuxtLink :to="categoryLink(link.slug)" :class="linkClass">{{ link.label }}</NuxtLink>
          </li>
        </ul>
      </nav>

      <nav aria-labelledby="podnozje-pomoc">
        <h2 id="podnozje-pomoc" :class="headingClass">Viva</h2>
        <ul>
          <li v-for="link in PUBLIC_NAV" :key="link.to">
            <NuxtLink :to="link.to" :class="linkClass">{{ link.label }}</NuxtLink>
          </li>
        </ul>
      </nav>

      <nav v-if="STORE.social.length" aria-labelledby="podnozje-mreze">
        <h2 id="podnozje-mreze" :class="headingClass">Pratite nas</h2>
        <ul>
          <li v-for="item in STORE.social" :key="item.url">
            <a :href="item.url" target="_blank" rel="noopener" :class="linkClass">{{ item.label }}</a>
          </li>
        </ul>
      </nav>
    </div>
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <p class="border-t border-line py-5 text-xs text-muted">© {{ year }} {{ siteName }}, {{ STORE.city }}</p>
    </div>
  </footer>
</template>
