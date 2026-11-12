<script setup lang="ts">
import { STORE } from '~/config/store'

// Sve tvrdnje potvrdila je vlasnica (studeni 2026.). Ne dodavati ništa što nije potvrđeno.
usePageSeo({
  title: 'O nama - svečana moda u Mostaru i Sarajevu',
  description: 'Viva je butik svečane mode u Mepas Mallu u Mostaru, s poslovnicom u Sarajevu: svečane i maturalne haljine, ženska odijela, cipele na petu i torbice.',
})

const categoryLink = useCategoryLink()
const links = [
  { label: 'Svečane haljine', slug: 'haljine' },
  { label: 'Maturalne haljine', slug: 'maturalne-haljine' },
  { label: 'Ženska odijela', slug: 'zenska-odijela' },
  { label: 'Cipele na petu', slug: 'obuca' },
  { label: 'Torbice', slug: 'torbice' },
  { label: 'Nakit i dodaci', slug: 'dodaci' },
]
</script>

<template>
  <article class="mx-auto max-w-3xl px-4 py-16 sm:px-6 sm:py-20">
    <h1 class="text-center font-display text-5xl font-normal">O nama</h1>
    <span class="mx-auto mb-10 mt-5 block h-px w-14 bg-gold" aria-hidden="true" />

    <div class="space-y-10 leading-relaxed text-muted [&_h2]:mb-3 [&_h2]:font-display [&_h2]:text-3xl [&_h2]:font-normal [&_h2]:text-ink">
      <p class="text-center text-lg">
        Naš butik u {{ STORE.mall }}u u {{ STORE.city }}u posvećen je svečanoj modi za žene, a imamo i poslovnicu u Sarajevu.
        Ovdje ćete naći haljinu za maturu, svadbu ili obiteljsku proslavu, ali i sve što uz nju ide.
      </p>

      <section>
        <h2>Svečane i maturalne haljine</h2>
        <p>
          Glavni dio ponude su svečane i maturalne haljine, za veliku i za malu maturu, za svadbe, te haljine za mame
          za pričest, krizmu i krštenje. Uz njih su ženska odijela, ležernije haljine za posao i manje proslave,
          jakne i kaputi, cipele na petu, torbice i nakit od nehrđajućeg čelika.
        </p>
      </section>

      <section>
        <h2>Uvijek nešto novo</h2>
        <p>
          Nova kolekcija stiže nam često, po najnovijoj modi. Veličine idu do 58, ovisno o modelu, a dostupne veličine
          vidite na stranici svakog proizvoda.
        </p>
      </section>

      <section>
        <h2>Isprobajte kod nas ili naručite online</h2>
        <p>
          U trgovini možete isprobati više modela prije nego što se odlučite, a plaćate gotovinom, karticom ili na rate.
          Online narudžbe šaljemo na adrese u cijeloj BiH, uz plaćanje pouzećem, a možete ih preuzeti i u trgovini.
        </p>
      </section>

      <nav aria-label="Ponuda">
        <h2>Pogledajte ponudu</h2>
        <ul class="flex flex-wrap gap-2">
          <li v-for="link in links" :key="link.slug">
            <NuxtLink :to="categoryLink(link.slug)" class="inline-flex min-h-11 items-center border border-line bg-white px-4 text-xs font-medium uppercase tracking-[0.15em] text-ink hover:border-ink">
              {{ link.label }}
            </NuxtLink>
          </li>
        </ul>
      </nav>
    </div>

    <div class="mt-12 text-center">
      <SiteLink to="/kontakt" variant="outline">Kako do nas</SiteLink>
    </div>
  </article>
</template>
