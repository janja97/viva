<script setup lang="ts">
import { COMPANY, STORE } from '~/config/store'

usePageSeo({
  title: 'Politika privatnosti',
  description: `Kako ${COMPANY.name} prikuplja, koristi i čuva osobne podatke kupaca i posjetitelja web trgovine: narudžbe, newsletter i statistika posjeta.`,
})

const { siteName } = useRuntimeConfig().public
const { settings } = useStoreSettings()
// Datum zadnje izmjene teksta. Promijeni ga uz svaku izmjenu ove stranice.
const UPDATED = '19. 11. 2026.'
</script>

<template>
  <InfoPage
    title="Politika privatnosti"
    :intro="`Ovdje objašnjavamo koje podatke prikupljamo kad koristite web trgovinu ${siteName}, zašto ih trebamo, koliko ih čuvamo i koja su vaša prava.`"
  >
    <section>
      <h2>Tko obrađuje podatke</h2>
      <p>
        Voditelj obrade je {{ COMPANY.name }}, {{ COMPANY.seat }}, {{ COMPANY.country }}<template v-if="COMPANY.jib">, JIB {{ COMPANY.jib }}</template>.
        Za sva pitanja o osobnim podacima javite nam se
        <template v-if="settings.email">na <a :href="`mailto:${settings.email}`" class="underline underline-offset-4 hover:text-gold">{{ settings.email }}</a></template>
        <template v-if="settings.email && settings.phone"> ili </template>
        <template v-if="settings.phone">na broj {{ settings.phone }}</template><template v-if="!settings.email && !settings.phone">u trgovini u {{ STORE.mall }}u u {{ STORE.city }}u</template>.
      </p>
    </section>

    <section>
      <h2>Narudžbe</h2>
      <p>Kad pošaljete narudžbu kroz obrazac, upisujete ime i prezime, telefon, adresu, poštanski broj, grad, a po želji i e-mail i napomenu. Uz narudžbu spremamo naručene proizvode, iznose i promo kod ako ste ga upisali.</p>
      <p>Te podatke koristimo samo za obradu i isporuku narudžbe te za javljanje u vezi s njom. Kuriru dajemo ime, adresu i telefon, koliko je potrebno za dostavu.</p>
      <p>Ako naručujete preko WhatsAppa, s web stranice spremamo samo popis proizvoda, iznose i promo kod, bez imena i telefona. Daljnji razgovor ide kroz WhatsApp, na koji se primjenjuju i uvjeti tvrtke Meta.</p>
      <p>Narudžbe čuvamo koliko to traže propisi o računovodstvu i porezima te zbog mogućih zamjena i reklamacija.</p>
    </section>

    <section>
      <h2>Newsletter</h2>
      <p>Ako se prijavite na newsletter, spremamo vašu e-mail adresu i datum prijave te vam šaljemo osobni promo kod. E-mailove šaljemo preko usluge Resend.</p>
      <p>Odjaviti se možete u bilo kojem trenutku, poveznicom u svakom e-mailu ili na stranici <NuxtLink to="/odjava" class="underline underline-offset-4 hover:text-gold">Odjava</NuxtLink>. Nakon odjave vam više ne šaljemo e-mailove.</p>
    </section>

    <section>
      <h2>Košarica i lista želja</h2>
      <p>Za prijavu na web ne trebate račun. Da bi košarica i lista želja ostale spremljene, vaš preglednik pamti nasumičnu oznaku (u lokalnoj pohrani preglednika, bez kolačića). Po toj oznaci ne znamo tko ste. Košarica i lista želja brišu se nakon 7 dana bez izmjene.</p>
    </section>

    <section>
      <h2>Statistika posjeta</h2>
      <p>Da bismo znali odakle nam dolaze posjetitelji i koji su proizvodi zanimljivi, bilježimo:</p>
      <ul>
        <li>s koje stranice ili mreže ste došli (npr. Google, Instagram, Facebook) i oznake kampanje u poveznici,</li>
        <li>prvu stranicu koju ste otvorili,</li>
        <li>državu i grad, procijenjene iz IP adrese (samu IP adresu ne spremamo),</li>
        <li>vrstu uređaja (mobitel, tablet ili računalo),</li>
        <li>koje ste proizvode pogledali i jeste li otvorili narudžbu preko WhatsAppa.</li>
      </ul>
      <p>Ti podaci su vezani samo uz nasumičnu oznaku preglednika, a ne uz ime ili e-mail. Ne koristimo kolačiće za praćenje ni usluge za oglašavanje. Statistiku čuvamo najduže dvije godine.</p>
    </section>

    <section>
      <h2>Karta</h2>
      <p>Na nekim stranicama prikazuje se karta s lokacijom trgovine (Google Maps). Pri učitavanju karte Google može primiti vašu IP adresu i postaviti vlastite kolačiće, prema svojim pravilima privatnosti.</p>
    </section>

    <section>
      <h2>Tko još vidi podatke</h2>
      <p>Podaci se čuvaju u bazi podataka kod pružatelja usluge Supabase, a web stranica radi na poslužiteljima tvrtke Netlify. Ti pružatelji obrađuju podatke samo za nas i po našim uputama. Podatke ne prodajemo i ne dajemo drugima za oglašavanje.</p>
      <p>Pristup narudžbama i pretplatnicima ima samo naše osoblje, svatko prema svojoj ulozi.</p>
    </section>

    <section>
      <h2>Vaša prava</h2>
      <p>Imate pravo zatražiti uvid u svoje podatke, njihov ispravak ili brisanje, ograničenje obrade te prigovoriti obradi. Zahtjev nam pošaljite na kontakt naveden gore, a odgovorit ćemo u roku od 30 dana.</p>
      <p>Ako smatrate da su vaša prava povrijeđena, možete se obratiti Agenciji za zaštitu osobnih podataka u Bosni i Hercegovini, a ako živite u Europskoj uniji (npr. u Hrvatskoj), i nadzornom tijelu svoje države.</p>
    </section>

    <section>
      <h2>Izmjene</h2>
      <p>Ovu politiku možemo povremeno izmijeniti. Važeća verzija uvijek je na ovoj stranici. Zadnja izmjena: {{ UPDATED }}</p>
    </section>
  </InfoPage>
</template>
