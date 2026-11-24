<script setup lang="ts">
import { COMPANY, DELIVERY, EXCHANGE, STORE } from '~/config/store'

usePageSeo({
  title: 'Uvjeti kupnje',
  description: `Uvjeti kupnje u web trgovini: narudžba, cijene u KM, plaćanje pouzećem, dostava po BiH, preuzimanje u trgovini i zamjena u roku od ${EXCHANGE.days} dana.`,
})

const { siteName } = useRuntimeConfig().public
const storeSettings = useStoreSettings()
await storeSettings.ready()
const { settings } = storeSettings
const shippingPrice = computed(() => formatPrice(Number(settings.value.shipping_price)))
const freeAbove = computed(() => formatPrice(Number(settings.value.free_shipping_above)))
// Datum zadnje izmjene teksta. Promijeni ga uz svaku izmjenu ove stranice.
const UPDATED = '24. 11. 2026.'
</script>

<template>
  <InfoPage
    title="Uvjeti kupnje"
    :intro="`Ovi uvjeti vrijede za sve narudžbe poslane kroz web trgovinu ${siteName}. Slanjem narudžbe potvrđujete da ste ih pročitali i prihvatili.`"
  >
    <section>
      <h2>Prodavatelj</h2>
      <p>
        {{ COMPANY.name }}, {{ COMPANY.seat }}, {{ COMPANY.country }}<template v-if="COMPANY.jib">, JIB {{ COMPANY.jib }}</template><template v-if="COMPANY.vatNumber">, PDV broj {{ COMPANY.vatNumber }}</template>.
        Trgovina se nalazi u {{ STORE.mall }}u, na {{ STORE.floor }}u.
        <template v-if="settings.phone">Telefon: {{ settings.phone }}.</template>
        <template v-if="settings.email">E-mail: <a :href="`mailto:${settings.email}`" class="underline underline-offset-4 hover:text-gold">{{ settings.email }}</a>.</template>
      </p>
    </section>

    <section>
      <h2>Proizvodi i cijene</h2>
      <p>Cijene su u konvertibilnim markama (KM) i uključuju PDV. Poštarina nije uključena u cijenu proizvoda, a prikazuje se u košarici prije slanja narudžbe.</p>
      <p>Trudimo se da fotografije i opisi budu točni, ali boja na zaslonu može se malo razlikovati od stvarne. Proizvodi označeni kao „Dostupno samo u poslovnicama” ne mogu se naručiti online.</p>
    </section>

    <section>
      <h2>Narudžba</h2>
      <p>Narudžbu šaljete iz košarice, kroz obrazac na webu ili preko WhatsAppa. Poslana narudžba je upit: nakon nje vam se javljamo kako bismo potvrdili dostupnost, veličinu i način preuzimanja. Kupoprodaja je sklopljena kad vam narudžbu potvrdimo.</p>
      <p>Ako proizvod u međuvremenu više nije dostupan, javit ćemo vam se i ponuditi drugu veličinu, boju ili otkazivanje narudžbe.</p>
    </section>

    <section>
      <h2>Plaćanje</h2>
      <p>Online narudžbe plaćaju se {{ DELIVERY.payment }}: iznos plaćate kuriru kad vam donese paket ili u trgovini pri preuzimanju. Online plaćanja karticom nema. U trgovini se plaća gotovinom u KM, karticom ili na rate.</p>
    </section>

    <section>
      <h2>Dostava i preuzimanje</h2>
      <p>Šaljemo samo na adrese u Bosni i Hercegovini. Dostava traje {{ DELIVERY.minDays }} do {{ DELIVERY.maxDays }} dana od potvrde narudžbe.</p>
      <p>Poštarina je {{ shippingPrice }}, a za narudžbe veće od {{ freeAbove }} dostava je besplatna.</p>
      <p>Narudžbu možete i preuzeti u trgovini, bez poštarine. Način preuzimanja birate u košarici.</p>
    </section>

    <section>
      <h2>Promo kodovi</h2>
      <p>Promo kod upisujete u košarici, a popust vrijedi za iznos proizvoda koji nisu već sniženi, bez poštarine. Na već snižene proizvode promo kod se ne primjenjuje. Na jednu narudžbu može se iskoristiti jedan kod. Kod s ograničenim brojem upotreba troši se slanjem narudžbe, i ako se ona kasnije otkaže. Promo kod se ne može zamijeniti za novac.</p>
    </section>

    <section>
      <h2>Zamjena</h2>
      <p>
        Proizvod možete zamijeniti u roku od {{ EXCHANGE.days }} dana od preuzimanja, ako nema tragova nošenja.
        <NuxtLink to="/povrat-i-zamjena" class="underline underline-offset-4 hover:text-gold">Kako ide zamjena</NuxtLink>
      </p>
    </section>

    <section>
      <h2>Greška na proizvodu</h2>
      <p>Ako proizvod stigne s greškom, javite nam se telefonom ili e-mailom, a mi ćemo to riješiti. Vaša zakonska prava kao potrošača ovim uvjetima nisu ograničena.</p>
    </section>

    <section>
      <h2>Osobni podaci</h2>
      <p>
        Podatke iz narudžbe koristimo samo za njezinu obradu i isporuku.
        <NuxtLink to="/politika-privatnosti" class="underline underline-offset-4 hover:text-gold">Politika privatnosti</NuxtLink>
      </p>
    </section>

    <section>
      <h2>Sporovi</h2>
      <p>Na ove uvjete primjenjuju se propisi Bosne i Hercegovine. Moguće nesporazume nastojimo riješiti dogovorom, a ako to ne uspije, nadležan je sud u Mostaru, osim ako zakon o zaštiti potrošača ne određuje drukčije.</p>
      <p>Zadnja izmjena: {{ UPDATED }}</p>
    </section>
  </InfoPage>
</template>
