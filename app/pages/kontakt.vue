<script setup lang="ts">
import { ArrowUpRight, Car, CreditCard, MapPin, Shirt, Store } from '@lucide/vue'
import { STORE } from '~/config/store'

usePageSeo({
  title: 'Kontakt i lokacija: Mepas Mall Mostar',
  description: 'Posjetite butik svečane mode u Mepas Mallu u Mostaru, Kardinala Stepinca bb. Adresa, radno vrijeme, karta i kontakt. Imamo i poslovnicu u Sarajevu.',
})

await useStoreJsonLd()

const { socialLinks } = useStoreSettings()

// Samo potvrđene tvrdnje (CLAUDE.md): parking se plaća, isprobavanje bez termina, plaćanje, Sarajevo bez adrese.
const notes = [
  { icon: MapPin, title: 'Lokacija', text: `Butik je na ${STORE.floor}u ${STORE.mall}a.` },
  { icon: Car, title: 'Parking', text: `U garaži ${STORE.mall}a. Parking se naplaćuje.` },
  { icon: Shirt, title: 'Isprobavanje', text: 'Isprobajte više modela, bez najave i termina.' },
  { icon: CreditCard, title: 'Plaćanje', text: 'Gotovinom u KM, karticom ili na rate.' },
]
</script>

<template>
  <div>
    <section class="mx-auto max-w-7xl px-4 pt-10 sm:px-6 sm:pt-14 lg:px-8">
      <SiteBreadcrumbs :items="[{ label: 'Početna', to: '/' }, { label: 'Kontakt' }]" />
      <div class="mt-6 max-w-2xl">
        <p class="text-xs font-medium uppercase tracking-[0.24em] text-gold">Kontakt</p>
        <h1 class="mt-3 font-display text-5xl font-normal leading-tight sm:text-6xl">
          Posjetite nas <em class="text-gold">u Mostaru</em>
        </h1>
        <span class="mb-6 mt-5 block h-px w-14 bg-gold" aria-hidden="true" />
        <p class="text-lg leading-relaxed text-muted">
          Naš butik svečane mode je u {{ STORE.mall }}u. Svratite kad god želite, isprobajte više modela
          i odaberite haljinu u miru. Imamo i poslovnicu u Sarajevu.
        </p>
      </div>
    </section>

    <section class="mx-auto grid max-w-7xl gap-10 px-4 py-12 sm:px-6 sm:py-16 md:grid-cols-2 lg:gap-20 lg:px-8">
      <div class="space-y-10">
        <div class="flex items-start gap-4">
          <span class="flex size-11 flex-none items-center justify-center rounded-full bg-champagne text-gold">
            <Store class="size-4" stroke-width="1.5" aria-hidden="true" />
          </span>
          <div>
            <h2 class="font-display text-3xl font-normal">Butik {{ STORE.mall }}</h2>
            <address class="mt-2 not-italic leading-relaxed text-muted">
              {{ STORE.street }}, {{ STORE.floor }}<br>
              {{ STORE.postalCode }} {{ STORE.city }}, {{ STORE.country }}
            </address>
            <a
              :href="STORE.mapUrl"
              target="_blank"
              rel="noopener"
              class="mt-5 inline-flex min-h-13 items-center justify-center gap-2 border border-ink bg-ink px-8 text-xs font-medium uppercase tracking-[0.2em] text-white transition-colors hover:bg-transparent hover:text-ink"
            >
              Upute do butika
              <ArrowUpRight class="size-4" stroke-width="1.5" aria-hidden="true" />
            </a>
          </div>
        </div>

        <div>
          <h2 class="mb-4 text-xs font-medium uppercase tracking-[0.24em] text-gold">Radno vrijeme</h2>
          <ContactHours />
        </div>

        <div>
          <h2 class="mb-4 text-xs font-medium uppercase tracking-[0.24em] text-gold">Javite nam se</h2>
          <ContactChannels />
          <ul v-if="socialLinks.length" class="mt-5 flex flex-wrap gap-x-6">
            <li v-for="item in socialLinks" :key="item.url">
              <a :href="item.url" target="_blank" rel="noopener" class="inline-flex min-h-11 items-center gap-1.5 text-xs font-medium uppercase tracking-[0.16em] text-ink hover:text-gold">
                {{ item.label }}
                <ArrowUpRight class="size-3.5" stroke-width="1.5" aria-hidden="true" />
              </a>
            </li>
          </ul>
        </div>
      </div>

      <!-- Karta: na mobitelu ispod podataka, na računalu desno i uz pomicanje ostaje na mjestu. -->
      <div class="md:sticky md:top-28 md:self-start">
        <div class="aspect-4/3 overflow-hidden border border-line bg-photo md:aspect-4/5">
          <iframe
            :src="STORE.mapEmbedUrl"
            :title="`Karta: ${STORE.mall}, ${STORE.street}, ${STORE.city}`"
            loading="lazy"
            referrerpolicy="no-referrer-when-downgrade"
            class="size-full border-0 [filter:grayscale(0.6)_sepia(0.15)]"
          />
        </div>
      </div>
    </section>

    <section aria-labelledby="naslov-dobro-je-znati" class="bg-sand">
      <div class="mx-auto max-w-7xl px-4 py-14 sm:px-6 sm:py-20 lg:px-8">
        <h2 id="naslov-dobro-je-znati" class="text-center font-display text-4xl font-normal">Dobro je znati</h2>
        <span class="mx-auto mb-10 mt-5 block h-px w-14 bg-gold" aria-hidden="true" />
        <ul class="grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
          <li v-for="note in notes" :key="note.title" class="text-center">
            <span class="mx-auto flex size-12 items-center justify-center rounded-full border border-line bg-ivory text-gold">
              <component :is="note.icon" class="size-4" stroke-width="1.5" aria-hidden="true" />
            </span>
            <h3 class="mt-4 text-xs font-medium uppercase tracking-[0.2em]">{{ note.title }}</h3>
            <p class="mx-auto mt-2 max-w-60 text-sm leading-relaxed text-muted">{{ note.text }}</p>
          </li>
        </ul>
        <p class="mt-12 text-center text-muted">
          Dolazite iz Hrvatske?
          <NuxtLink to="/kupovina-u-mostaru" class="text-ink underline underline-offset-4 hover:text-gold">Sve o kupovini u Mostaru i povratu PDV-a</NuxtLink>
        </p>
      </div>
    </section>
  </div>
</template>
