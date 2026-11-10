<script setup lang="ts">
import { EXCHANGE } from '~/config/store'

usePageSeo({
  title: 'Zamjena proizvoda u 15 dana',
  description: `Svečanu haljinu, obuću ili dodatak možete zamijeniti u roku od ${EXCHANGE.days} dana, ako proizvod nema tragova nošenja. Za grešku na proizvodu javite nam se.`,
})

const faq = [
  { question: 'Koliko imam vremena za zamjenu?', answer: `Proizvod možete zamijeniti u roku od ${EXCHANGE.days} dana od preuzimanja.` },
  { question: 'Koji proizvodi se mogu zamijeniti?', answer: 'Proizvodi bez tragova nošenja.' },
  { question: 'Što ako proizvod ima grešku?', answer: 'Javite nam se telefonom ili e-mailom, a mi ćemo to riješiti.' },
]
</script>

<template>
  <InfoPage
    title="Povrat i zamjena"
    :intro="`Ako vam veličina ili model ne odgovaraju, proizvod možete zamijeniti u roku od ${EXCHANGE.days} dana.`"
    :faq="faq"
  >
    <section>
      <h2>Zamjena u {{ EXCHANGE.days }} dana</h2>
      <p>Proizvod možete zamijeniti u roku od {{ EXCHANGE.days }} dana od preuzimanja, ako nema tragova nošenja.</p>
    </section>

    <section>
      <h2>Kako zatražiti zamjenu</h2>
      <p>
        <NuxtLink to="/kontakt" class="underline underline-offset-4 hover:text-gold">Javite nam se</NuxtLink>
        i dogovorit ćemo zamjenu.
      </p>
    </section>

    <section>
      <h2>Greška na proizvodu</h2>
      <p>Ako proizvod stigne s greškom, javite nam se telefonom ili e-mailom, a mi ćemo to riješiti.</p>
    </section>
  </InfoPage>
</template>
