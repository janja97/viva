<script setup lang="ts">
import { STORE } from '~/config/store'

// Stranica za kupce iz Hrvatske (Split, Dubrovnik, Makarska, Dalmacija), koji dolaze u trgovinu u Mostaru.
// Online narudžbe idu samo u BiH, pa je cilj posjet trgovini. Samo potvrđene tvrdnje (vidi CLAUDE.md).
// Povrat PDV-a: Instrukcija UIO-a, Službeni glasnik BiH 48/25. Provjeriti ako se propis promijeni.
usePageSeo({
  title: 'Kupovina u Mostaru za goste iz Splita i Dubrovnika',
  description: 'Svečane i maturalne haljine, cipele i torbe u Mepas Mallu u Mostaru. Za goste iz Dalmacije: isprobavanje, plaćanje karticom i povrat PDV-a za kupnju veću od 200 KM.',
})

const { hoursText } = useStoreSettings()
const place = `${STORE.mall}, ${STORE.street}, ${STORE.city}`

const faq = [
  { question: 'Gdje se nalazi trgovina?', answer: `U ${STORE.mall}u u Mostaru, ${STORE.street}, na ${STORE.floor}u. Parking je u garaži ${STORE.mall}a i naplaćuje se.` },
  { question: 'Mogu li kao kupac iz Hrvatske dobiti povrat PDV-a?', answer: 'Da, kupci bez prebivališta u BiH mogu ostvariti povrat PDV-a za kupnju veću od 200 KM. Na blagajni zatražite obrazac PDV-SL-2, ovjerite ga na granici pri izlasku iz BiH u roku od 3 mjeseca, a ovjereni obrazac vratite nama. PDV vraćamo u KM, gotovinom ili na vaš račun.' },
  { question: 'Kako se plaća u trgovini?', answer: 'Gotovinom u KM ili karticom, a moguće je i plaćanje na rate.' },
  { question: 'Šaljete li narudžbe u Hrvatsku?', answer: 'Ne, online narudžbe zasad šaljemo samo na adrese u Bosni i Hercegovini. Iz Hrvatske nas posjetite u trgovini u Mostaru.' },
  { question: 'Mogu li isprobati više haljina?', answer: 'Da, u trgovini možete isprobati više modela prije nego što se odlučite. Rezervacija termina nije potrebna.' },
  { question: 'Mogu li rezervirati haljinu dok ne dođem?', answer: 'Ne, haljine ne rezerviramo i ne ostavljamo sa strane.' },
]
</script>

<template>
  <InfoPage
    title="Kupovina u Mostaru"
    intro="Kupci iz Splita, Dubrovnika, Makarske i cijele Dalmacije često nam dolaze po haljinu za maturu, vjenčanje ili posebnu večer. Evo što je dobro znati prije dolaska."
    :faq="faq"
  >
    <section>
      <h2>Gdje smo</h2>
      <p>Naša trgovina je u {{ STORE.mall }}u u Mostaru, {{ STORE.street }}, na {{ STORE.floor }}u. Parking je u garaži {{ STORE.mall }}a i naplaćuje se.</p>
      <p v-if="hoursText">Radno vrijeme: {{ hoursText }}.</p>
      <p><a :href="STORE.mapUrl" target="_blank" rel="noopener" class="underline underline-offset-4 hover:text-gold">Otvori {{ place }} na karti</a></p>
    </section>

    <section>
      <h2>Što vas čeka</h2>
      <p>
        <NuxtLink to="/kategorija/svecane-haljine" class="underline underline-offset-4 hover:text-gold">Svečane haljine</NuxtLink>,
        <NuxtLink to="/kategorija/maturalne-haljine" class="underline underline-offset-4 hover:text-gold">maturalne haljine</NuxtLink> za veliku i malu maturu,
        <NuxtLink to="/kategorija/haljine-za-svadbu" class="underline underline-offset-4 hover:text-gold">haljine za svadbu i za kumu</NuxtLink>,
        <NuxtLink to="/kategorija/zenska-odijela" class="underline underline-offset-4 hover:text-gold">ženska odijela</NuxtLink>,
        <NuxtLink to="/kategorija/obuca" class="underline underline-offset-4 hover:text-gold">štikle, salonke, sandale i čizme</NuxtLink>,
        <NuxtLink to="/kategorija/torbice" class="underline underline-offset-4 hover:text-gold">torbe</NuxtLink>
        i nakit od nehrđajućeg čelika. Veličine idu do 58, ovisno o modelu, a nova kolekcija stiže često.
      </p>
    </section>

    <section>
      <h2>Isprobajte više modela</h2>
      <p>Dođite kad vam odgovara, termin nije potreban. U trgovini možete isprobati više modela i odmah uz haljinu odabrati cipele i torbicu. Skraćivanje i prepravke ne radimo, pa je najbolje isprobati više veličina.</p>
    </section>

    <section>
      <h2>Plaćanje i povrat PDV-a</h2>
      <p>U trgovini plaćate gotovinom u KM ili karticom, a moguće je i plaćanje na rate.</p>
      <p>Kupci bez prebivališta u BiH mogu ostvariti povrat PDV-a za kupnju veću od 200 KM:</p>
      <ul>
        <li>na blagajni zatražite obrazac PDV-SL-2,</li>
        <li>ovjerite ga na granici pri izlasku iz BiH, u roku od 3 mjeseca,</li>
        <li>ovjereni obrazac vratite nama, a PDV vraćamo u KM, gotovinom ili na vaš račun.</li>
      </ul>
    </section>

    <section>
      <h2>Online narudžbe</h2>
      <p>Proizvode možete pogledati na webu, ali online narudžbe zasad šaljemo samo na adrese u Bosni i Hercegovini. Ako vam se nešto svidi, dođite to isprobati u Mostar.</p>
      <p>Tražite poklon? Pogledajte <NuxtLink to="/poklon-bon" class="underline underline-offset-4 hover:text-gold">poklon bon</NuxtLink>.</p>
    </section>
  </InfoPage>
</template>
