<script setup lang="ts">
import { STORE } from '~/config/store'

// Stranica "Uskoro" preko cijelog ekrana, bez navigacije i footera (NUXT_PUBLIC_COMING_SOON=true).
// Ne smije u Google dok trgovina nije otvorena.
const { siteName } = useRuntimeConfig().public
const { settings, socialLinks } = useStoreSettings()

useHead({
  title: `${siteName} · Uskoro`,
  meta: [
    { name: 'description', content: `${siteName}, luksuzna svečana moda u Mepas Mallu u Mostaru. Online trgovina otvara se uskoro.` },
    { name: 'robots', content: 'noindex, follow' },
  ],
})
</script>

<template>
  <div class="coming-soon relative grid min-h-dvh bg-graphite font-body text-white lg:grid-cols-2">
    <!-- Na mobitelu je fotografija preko cijelog ekrana, a na računalu desna polovica. -->
    <div class="absolute inset-0 overflow-hidden lg:relative lg:order-last">
      <img
        src="/images/home/svecana-haljina-srebrna.jpg"
        alt="Svečana srebrna haljina s biserima i kristalima"
        width="1080"
        height="1440"
        fetchpriority="high"
        class="coming-soon__photo size-full object-cover object-top"
      >
      <div class="absolute inset-0 bg-graphite/60 lg:hidden" aria-hidden="true" />
    </div>

    <main class="coming-soon__content relative flex flex-col items-center justify-center px-6 py-16 text-center sm:px-10 lg:py-24">
      <img src="/logo/logo-gold.png" :alt="siteName" width="400" height="214" class="h-20 w-auto sm:h-24">

      <p class="mt-10 text-[11px] font-medium uppercase tracking-[0.4em] text-gold-light">Coming soon</p>
      <h1 class="mt-4 max-w-md font-display text-5xl font-normal leading-[1.05] sm:text-6xl">
        Uskoro otvaramo <em class="block text-gold-light">online trgovinu</em>
      </h1>
      <p class="mt-6 max-w-sm leading-relaxed text-white/80">
        Svečane i maturalne haljine, ženska odijela, cipele i torbice. Do tada nas posjetite u {{ STORE.mall }}u u {{ STORE.city }}u.
      </p>

      <!-- Zlatna linija koja putuje, kao znak da se trgovina priprema. -->
      <div class="coming-soon__loader mt-10 h-px w-48 overflow-hidden bg-white/20" role="progressbar" aria-label="Trgovina se priprema">
        <span class="block h-full w-1/3 bg-gold" />
      </div>

      <div class="mt-10 space-y-2 text-sm text-white/80">
        <p>{{ STORE.mall }}, {{ STORE.street }}, {{ STORE.city }}</p>
        <p v-if="settings.phone">
          <a :href="`tel:${phoneDigits(settings.phone)}`" class="inline-flex min-h-11 items-center hover:text-gold-light">{{ settings.phone }}</a>
        </p>
        <ul v-if="socialLinks.length" class="flex justify-center gap-6">
          <li v-for="item in socialLinks" :key="item.url">
            <a :href="item.url" target="_blank" rel="noopener" class="inline-flex min-h-11 items-center text-xs uppercase tracking-[0.2em] hover:text-gold-light">{{ item.label }}</a>
          </li>
        </ul>
      </div>
    </main>
  </div>
</template>

<style scoped>
.coming-soon__content > * {
  animation: coming-soon-rise 1s cubic-bezier(0.2, 0.7, 0.2, 1) both;
}
.coming-soon__content > :nth-child(2) { animation-delay: 0.15s; }
.coming-soon__content > :nth-child(3) { animation-delay: 0.3s; }
.coming-soon__content > :nth-child(4) { animation-delay: 0.45s; }
.coming-soon__content > :nth-child(5) { animation-delay: 0.6s; }
.coming-soon__content > :nth-child(6) { animation-delay: 0.75s; }

.coming-soon__photo {
  animation: coming-soon-zoom 12s ease-out both;
}

.coming-soon__loader > span {
  animation: coming-soon-slide 1.8s ease-in-out infinite;
}

@keyframes coming-soon-rise {
  from { opacity: 0; transform: translateY(12px); }
  to { opacity: 1; transform: none; }
}

@keyframes coming-soon-zoom {
  from { transform: scale(1.06); }
  to { transform: scale(1); }
}

@keyframes coming-soon-slide {
  from { transform: translateX(-100%); }
  to { transform: translateX(300%); }
}

@media (prefers-reduced-motion: reduce) {
  .coming-soon__content > *,
  .coming-soon__photo,
  .coming-soon__loader > span {
    animation: none;
  }
}
</style>
