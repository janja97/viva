<script setup lang="ts">
import { DELIVERY } from '~/config/store'

usePageSeo({
  title: 'Dostava i plaćanje pouzećem u BiH',
  description: `Dostava svečanih haljina, obuće i dodataka na adresu u cijeloj BiH za ${DELIVERY.minDays} do ${DELIVERY.maxDays} dana. Plaćanje pouzećem, kuriru pri preuzimanju.`,
})

// Iznosi poštarine ulaze i u FAQ JSON-LD, pa se postavke čekaju prije prikaza.
const storeSettings = useStoreSettings()
await storeSettings.ready()
const { settings } = storeSettings
const shippingPrice = computed(() => formatPrice(Number(settings.value.shipping_price)))
const freeAbove = computed(() => formatPrice(Number(settings.value.free_shipping_above)))
const days = `${DELIVERY.minDays} do ${DELIVERY.maxDays} dana`

const faq = computed(() => [
  { question: 'Kako se plaća narudžba?', answer: 'Pouzećem: iznos plaćate kuriru kad vam donese paket. Online plaćanja karticom nema.' },
  { question: 'Koliko košta dostava?', answer: `Poštarina je ${shippingPrice.value}, a za narudžbe veće od ${freeAbove.value} dostava je besplatna.` },
  { question: 'Koliko traje dostava?', answer: `Dostava traje ${days}.` },
  { question: 'Šaljete li izvan Bosne i Hercegovine?', answer: 'Ne, zasad šaljemo samo na adrese u Bosni i Hercegovini.' },
])
</script>

<template>
  <InfoPage
    title="Dostava i plaćanje"
    intro="Dostavljamo na adrese u cijeloj Bosni i Hercegovini, a narudžbu plaćate pouzećem, kuriru pri preuzimanju paketa."
    :faq="faq"
  >
    <section>
      <h2>Plaćanje pouzećem</h2>
      <p>Online plaćanja nema. Iznos narudžbe zajedno s poštarinom plaćate kuriru kad vam donese paket.</p>
    </section>

    <section>
      <h2>Cijena dostave</h2>
      <p>Poštarina je {{ shippingPrice }}. Za narudžbe veće od {{ freeAbove }} dostava je besplatna. Točan iznos vidite u košarici prije slanja narudžbe.</p>
    </section>

    <section>
      <h2>Rok dostave</h2>
      <p>Dostava traje {{ days }}. Šaljemo samo na adrese u Bosni i Hercegovini.</p>
    </section>

    <section>
      <h2>Kako naručiti</h2>
      <ul>
        <li>Odaberite boju i veličinu te dodajte proizvod u košaricu.</li>
        <li>U košarici kliknite „Naruči” i upišite podatke za dostavu.</li>
        <li>Kliknite „Pošalji upit”.</li>
      </ul>
    </section>

    <section>
      <h2>Zamjena</h2>
      <p>
        Ako vam veličina ili model ne odgovaraju, proizvod možete zamijeniti.
        <NuxtLink to="/povrat-i-zamjena" class="underline underline-offset-4 hover:text-gold">Kako ide zamjena</NuxtLink>
      </p>
    </section>
  </InfoPage>
</template>
