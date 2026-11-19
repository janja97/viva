<script setup lang="ts">
import { STORE } from '~/config/store'

// Poklon bon i ideje za poklon za nju (nakit, torbe). Potvrđeno je samo da postoji poklon bon u iznosu po izboru.
// Rok trajanja i način kupnje nisu potvrđeni, pa se ne navode: kupac se za detalje javlja trgovini.
usePageSeo({
  title: 'Poklon bon i pokloni za nju | Mostar',
  description: `Poklon bon u iznosu po vašem izboru, nakit od nehrđajućeg čelika i torbe kao poklon za nju. Butik u ${STORE.mall}u u Mostaru.`,
})

const faq = [
  { question: 'Imate li poklon bon?', answer: 'Da, poklon bon možete kupiti u iznosu po vašem izboru.' },
  { question: 'Što pokloniti ženi?', answer: 'Najčešće se poklanjaju nakit od nehrđajućeg čelika, torbe i torbice, šalovi ili poklon bon, uz koji sama bira haljinu ili cipele.' },
  { question: 'Od čega je nakit?', answer: 'Nakit u našoj ponudi izrađen je od nehrđajućeg čelika.' },
]
</script>

<template>
  <InfoPage
    title="Poklon bon i pokloni za nju"
    intro="Kad niste sigurni koja će joj se haljina ili veličina svidjeti, poklonite joj poklon bon i pustite je da sama odabere."
    :faq="faq"
  >
    <section>
      <h2>Poklon bon u iznosu po izboru</h2>
      <p>Poklon bon možete kupiti u iznosu po vašem izboru. Za poklon bon dođite u našu trgovinu u {{ STORE.mall }}u u Mostaru ili nam se <NuxtLink to="/kontakt" class="underline underline-offset-4 hover:text-gold">javite</NuxtLink>.</p>
    </section>

    <section>
      <h2>Nakit od nehrđajućeg čelika</h2>
      <p>Ogrlice, naušnice i narukvice od nehrđajućeg čelika nose se svaki dan i uz svečanu haljinu. Idealan su poklon za rođendan, Božić ili Valentinovo. <SiteCategoryLink slug="nakit">Pogledajte nakit</SiteCategoryLink>.</p>
    </section>

    <section>
      <h2>Torba kao poklon</h2>
      <p>Svečana clutch torbica ili torba za svaki dan, mala, srednja ili velika, jedan je od najdražih poklona za nju. <SiteCategoryLink slug="torbice">Pogledajte torbe</SiteCategoryLink>.</p>
    </section>
  </InfoPage>
</template>
