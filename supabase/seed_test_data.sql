-- TESTNI PODACI. Briše SVE proizvode, kategorije i kampanje pa upisuje testne (oko 60 proizvoda). Treba migracije 0022 i 0024.
-- Narudžbe ostaju: njihove stavke čuvaju kopiju naziva, šifre i cijene, a veza na proizvod postaje prazna.
-- Slike u spremištu "product-images" SQL ne može obrisati. Isprazni ga u Supabaseu: Storage > product-images.
-- Testni proizvodi nemaju slika, pa se na webu prikazuju s obojenom podlogom.
begin;

-- 1. BRISANJE

-- Boje, veličine, slike, kategorije proizvoda, brend, povijest cijena, košarice i liste želja brišu se same (cascade).
delete from public.products;
-- Povijest izmjena testnih proizvoda nije potrebna.
delete from public.product_audit_log;
delete from public.campaigns;

-- Kategorije se brišu od najniže razine, jer nadređena ne smije ostati bez provjere (on delete restrict).
delete from public.categories c where not exists (select 1 from public.categories child where child.parent_id = c.id);
delete from public.categories c where not exists (select 1 from public.categories child where child.parent_id = c.id);
delete from public.categories;

-- 2. KATEGORIJE (najviše tri razine; slugovi prate izbornik i naslovnu)

insert into public.categories (name, slug, description, sort_order) values
  ('Odjeća', 'odjeca', 'Ženska odjeća: svečane i lagane haljine, kaputi, kompleti i sakoi. Pogledajte ponudu online ili nas posjetite u Mepas Mallu u Mostaru.', 1),
  ('Obuća', 'obuca', 'Sandale na petu, salonke i čizme uz svečanu haljinu. Pogledajte ponudu online ili nas posjetite u Mepas Mallu u Mostaru.', 2),
  ('Torbice', 'torbice', 'Torbice-pisma i večernje torbice za svečane prilike. Pogledajte ponudu online ili nas posjetite u Mepas Mallu u Mostaru.', 3),
  ('Dodaci', 'dodaci', 'Nakit, šalovi i remeni koji zaokružuju svečani izgled.', 4),
  ('Svečano', 'svecano', 'Izbor za maturu, vjenčanja i gala večeri: haljine i torbice na jednom mjestu.', 5);

insert into public.categories (name, slug, description, sort_order, parent_id)
select v.name, v.slug, v.description, v.sort_order, parent.id
from (values
  ('Haljine', 'haljine', 'Svečane, maturalne i elegantne haljine. Pogledajte modele online ili nas posjetite u Mepas Mallu u Mostaru.', 1, 'odjeca'),
  ('Kaputi', 'kaputi', 'Kaputi za hladnije dane, uz svečane i lagane haljine.', 2, 'odjeca'),
  ('Kompleti i sakoi', 'kompleti-i-sakoi', null, 3, 'odjeca'),
  ('Sandale na petu', 'sandale-na-petu', null, 1, 'obuca'),
  ('Salonke', 'salonke', null, 2, 'obuca'),
  ('Čizme', 'cizme', null, 3, 'obuca'),
  ('Torbice-pisma', 'torbice-pisma', null, 1, 'torbice'),
  ('Večernje torbice', 'vecernje-torbice', null, 2, 'torbice'),
  ('Nakit', 'nakit', null, 1, 'dodaci'),
  ('Šalovi', 'salovi', null, 2, 'dodaci'),
  ('Remeni', 'remeni', null, 3, 'dodaci')
) as v (name, slug, description, sort_order, parent_slug)
join public.categories parent on parent.slug = v.parent_slug;

insert into public.categories (name, slug, description, sort_order, parent_id)
select v.name, v.slug, v.description, v.sort_order, parent.id
from (values
  ('Maturalne haljine', 'maturalne-haljine', 'Maturalne haljine za večer koju ćete pamtiti.', 1, 'haljine'),
  ('Večernje haljine', 'vecernje-haljine', null, 2, 'haljine'),
  ('Koktel haljine', 'koktel-haljine', null, 3, 'haljine'),
  ('Lagane haljine', 'lagane-haljine', null, 4, 'haljine')
) as v (name, slug, description, sort_order, parent_slug)
join public.categories parent on parent.slug = v.parent_slug;

-- 3. KAMPANJE
-- Trajna kampanja za svaki postotak iz popisa proizvoda. Kaputi su u privremenoj aktivnoj kampanji, a proljetna je zakazana i prazna.
insert into public.campaigns (name, kind, discount_percent)
values
  ('Sniženje 10 %', 'permanent', 10), ('Sniženje 15 %', 'permanent', 15), ('Sniženje 20 %', 'permanent', 20),
  ('Sniženje 25 %', 'permanent', 25), ('Sniženje 30 %', 'permanent', 30);

insert into public.campaigns (name, kind, discount_percent, starts_at, ends_at)
values
  ('Zimsko sniženje (test)', 'temporary', 35, now() - interval '1 day', now() + interval '14 days'),
  ('Proljetna kampanja (test)', 'temporary', 15, now() + interval '30 days', now() + interval '60 days');

-- 4. PROIZVODI

create function pg_temp.viva_slug(p_text text)
returns text
language sql
immutable
as $$
  select trim(both '-' from regexp_replace(translate(lower(p_text), 'čćđšž', 'ccdsz'), '[^a-z0-9]+', '-', 'g'));
$$;

-- Iste boje kao PRODUCT_COLORS u app/config/products.ts.
create temp table seed_colors (name text primary key, hex text) on commit drop;
insert into seed_colors values
  ('Crna', '#000000'), ('Bijela', '#ffffff'), ('Siva', '#9ca3af'), ('Srebrna', '#c0c0c0'), ('Bež', '#d6c3a5'),
  ('Krem', '#f5efdc'), ('Smeđa', '#6f4e37'), ('Crvena', '#dc2626'), ('Bordo', '#7f1d2d'), ('Roza', '#f472b6'),
  ('Ljubičasta', '#7e22ce'), ('Plava', '#2563eb'), ('Teget', '#1e2a4a'), ('Zelena', '#16a34a'),
  ('Maslinasta', '#6b7a3a'), ('Žuta', '#facc15'), ('Zlatna', '#d4af37');

-- status: '' (na webu), 'skriven', 'arhiva' ili 'trgovina' (samo u poslovnicama).
create temp table seed_products (
  sku text, name text, category text, extra_category text, price numeric, discount integer,
  dress_length text, heel_height text, status text, colors text[], sizes text[]
) on commit drop;

insert into seed_products values
  -- Maturalne haljine
  ('VH-1001', 'Maturalna haljina Aurora', 'maturalne-haljine', 'svecano', 389, null, 'maxi', null, '', '{Bež,Zlatna}', '{36,38,40,42,44}'),
  ('VH-1002', 'Maturalna haljina Selena', 'maturalne-haljine', 'svecano', 429, 20, 'maxi', null, '', '{Srebrna,Crna}', '{36,38,40,42,44}'),
  ('VH-1003', 'Maturalna haljina s korzetom Elena', 'maturalne-haljine', 'svecano', 459, null, 'maxi', null, '', '{Krem,Roza}', '{36,38,40,42}'),
  ('VH-1004', 'Maturalna haljina sa šljokicama Stella', 'maturalne-haljine', 'svecano', 499, null, 'maxi', null, '', '{Srebrna,Zlatna,Crna}', '{36,38,40,42,44}'),
  ('VH-1005', 'Maturalna haljina na jedno rame Iris', 'maturalne-haljine', 'svecano', 369, 15, 'maxi', null, '', '{Teget,Bordo}', '{36,38,40,42,44,46}'),
  ('VH-1006', 'Maturalna haljina s volanima Flora', 'maturalne-haljine', 'svecano', 349, null, 'maxi', null, '', '{Maslinasta}', '{36,38,40,42}'),
  ('VH-1007', 'Maturalna haljina s prorezom Nera', 'maturalne-haljine', 'svecano', 399, null, 'maxi', null, '', '{Crna,Crvena}', '{36,38,40,42,44}'),
  ('VH-1008', 'Maturalna haljina sa šlepom Grace', 'maturalne-haljine', 'svecano', 549, null, 'maxi', null, 'trgovina', '{Bež}', '{36,38,40,42}'),
  ('VH-1009', 'Maturalna haljina Luna', 'maturalne-haljine', null, 329, null, 'maxi', null, 'skriven', '{Plava}', '{36,38,40}'),
  -- Večernje haljine
  ('VH-2001', 'Večernja satenska haljina Vera', 'vecernje-haljine', 'svecano', 289, null, 'maxi', null, '', '{Smeđa,Crna,Bordo}', '{36,38,40,42,44}'),
  ('VH-2002', 'Večernja haljina s perlicama Mira', 'vecernje-haljine', 'svecano', 459, null, 'maxi', null, '', '{Srebrna}', '{36,38,40,42}'),
  ('VH-2003', 'Večernja uska haljina Ada', 'vecernje-haljine', 'svecano', 379, null, 'maxi', null, '', '{Crna,Smeđa}', '{36,38,40,42,44}'),
  ('VH-2004', 'Večernja haljina s mašnom Lara', 'vecernje-haljine', 'svecano', 349, 30, 'maxi', null, '', '{Smeđa}', '{36,38,40,42}'),
  ('VH-2005', 'Večernja čipkasta haljina Noemi', 'vecernje-haljine', 'svecano', 399, null, 'maxi', null, '', '{Crna}', '{38,40,42,44}'),
  ('VH-2006', 'Večernja midi haljina Sofia', 'vecernje-haljine', null, 259, null, 'midi', null, '', '{Zelena,Teget}', '{36,38,40,42,44}'),
  ('VH-2007', 'Večernja haljina s ogrtačem Dora', 'vecernje-haljine', null, 479, null, 'maxi', null, 'arhiva', '{Roza}', '{36,38,40}'),
  -- Koktel haljine
  ('VH-3001', 'Koktel haljina Mila', 'koktel-haljine', null, 189, null, 'knee', null, '', '{Crvena,Crna}', '{36,38,40,42}'),
  ('VH-3002', 'Koktel haljina bez naramenica Rita', 'koktel-haljine', null, 219, null, 'mini', null, '', '{Crvena}', '{36,38,40}'),
  ('VH-3003', 'Koktel haljina sa šljokicama Zara', 'koktel-haljine', null, 239, 25, 'mini', null, '', '{Zlatna,Srebrna}', '{36,38,40,42}'),
  ('VH-3004', 'Koktel haljina s pelerinom Ines', 'koktel-haljine', null, 249, null, 'knee', null, '', '{Bež}', '{36,38,40,42,44}'),
  ('VH-3005', 'Koktel čipkasta haljina Ana', 'koktel-haljine', null, 199, null, 'knee', null, '', '{Bijela,Crna}', '{36,38,40,42}'),
  ('VH-3006', 'Koktel midi haljina Tea', 'koktel-haljine', null, 209, null, 'midi', null, '', '{Ljubičasta}', '{38,40,42,44}'),
  -- Lagane haljine
  ('VH-4001', 'Lagana haljina na naramenice Ema', 'lagane-haljine', null, 119, null, 'midi', null, '', '{Bež,Bijela}', '{S,M,L,XL}'),
  ('VH-4002', 'Lagana haljina s remenom Nika', 'lagane-haljine', null, 139, null, 'maxi', null, '', '{Krem,Maslinasta}', '{S,M,L,XL}'),
  ('VH-4003', 'Lagana košulja haljina Lea', 'lagane-haljine', null, 129, null, 'knee', null, '', '{Plava,Bijela}', '{S,M,L}'),
  ('VH-4004', 'Lagana cvjetna haljina Maja', 'lagane-haljine', null, 109, 10, 'midi', null, '', '{Žuta}', '{S,M,L,XL}'),
  ('VH-4005', 'Lagana pletena haljina Iva', 'lagane-haljine', null, 149, null, 'midi', null, '', '{Siva,Krem}', '{S,M,L,XL}'),
  -- Kaputi
  ('KP-5001', 'Kaput s remenom Milano', 'kaputi', null, 389, null, null, null, '', '{Smeđa,Bež}', '{S,M,L,XL,XXL}'),
  ('KP-5002', 'Dugi kaput Torino', 'kaputi', null, 429, null, null, null, '', '{Crna,Siva}', '{S,M,L,XL}'),
  ('KP-5003', 'Kaput s ovratnikom Verona', 'kaputi', null, 499, null, null, null, '', '{Smeđa}', '{S,M,L,XL}'),
  ('KP-5004', 'Kratki kaput Roma', 'kaputi', null, 299, 20, null, null, '', '{Krem}', '{S,M,L}'),
  ('KP-5005', 'Dvoredni kaput Napoli', 'kaputi', null, 349, null, null, null, '', '{Teget,Bež}', '{S,M,L,XL,XXL}'),
  ('KP-5006', 'Kaput ogrtač Siena', 'kaputi', null, 319, null, null, null, 'trgovina', '{Bordo}', '{S,M,L}'),
  -- Kompleti i sakoi
  ('KS-6001', 'Komplet sako i hlače Paris', 'kompleti-i-sakoi', null, 279, null, null, null, '', '{Bež,Crna}', '{36,38,40,42,44}'),
  ('KS-6002', 'Sako s peplumom Nice', 'kompleti-i-sakoi', null, 199, null, null, null, '', '{Smeđa}', '{36,38,40,42}'),
  ('KS-6003', 'Komplet sako i suknja Lyon', 'kompleti-i-sakoi', null, 259, 15, null, null, '', '{Bijela}', '{36,38,40,42}'),
  ('KS-6004', 'Satenski sako Cannes', 'kompleti-i-sakoi', null, 189, null, null, null, 'skriven', '{Zlatna}', '{S,M,L}'),
  -- Sandale na petu
  ('OB-7001', 'Sandale na petu Bella', 'sandale-na-petu', null, 169, null, null, 'high', '', '{Zlatna,Srebrna,Crna}', '{36,37,38,39,40,41}'),
  ('OB-7002', 'Sandale s ukrasnom trakom Stella', 'sandale-na-petu', null, 189, null, null, 'high', '', '{Srebrna}', '{36,37,38,39,40}'),
  ('OB-7003', 'Sandale na tanku petu Lina', 'sandale-na-petu', null, 149, 20, null, 'medium', '', '{Bež,Crna}', '{36,37,38,39,40,41}'),
  ('OB-7004', 'Sandale s remenčićem Nora', 'sandale-na-petu', null, 139, null, null, 'low', '', '{Bež}', '{35,36,37,38,39,40}'),
  -- Salonke
  ('OB-7101', 'Salonke na petu Classic', 'salonke', null, 159, null, null, 'high', '', '{Crna,Bež,Crvena}', '{36,37,38,39,40,41}'),
  ('OB-7102', 'Salonke s otvorenom petom Eva', 'salonke', null, 169, null, null, 'medium', '', '{Bež}', '{36,37,38,39,40}'),
  ('OB-7103', 'Satenske salonke Gala', 'salonke', null, 179, null, null, 'high', 'trgovina', '{Srebrna,Zlatna}', '{36,37,38,39}'),
  ('OB-7104', 'Salonke s mašnom Mia', 'salonke', null, 149, 25, null, 'low', '', '{Roza}', '{36,37,38,39,40}'),
  -- Čizme
  ('OB-7201', 'Čizme do koljena Alpina', 'cizme', null, 289, null, null, 'high', '', '{Bež,Crna}', '{36,37,38,39,40,41}'),
  ('OB-7202', 'Čizme s vezicama Nordica', 'cizme', null, 299, null, null, 'high', '', '{Smeđa}', '{36,37,38,39,40}'),
  ('OB-7203', 'Gležnjače na petu Ria', 'cizme', null, 219, null, null, 'medium', 'arhiva', '{Crna}', '{37,38,39}'),
  -- Torbice
  ('TB-8001', 'Torbica-pismo Clara', 'torbice-pisma', 'svecano', 99, null, null, null, '', '{Zlatna,Srebrna}', '{Mala}'),
  ('TB-8002', 'Torbica-pismo s mašnom Ivy', 'torbice-pisma', 'svecano', 119, null, null, null, '', '{Srebrna}', '{Mala}'),
  ('TB-8003', 'Torbica-pismo Nude', 'torbice-pisma', null, 89, 10, null, null, '', '{Bež,Crna}', '{Mini,Mala}'),
  ('TB-8101', 'Večernja torbica s mašnom Diva', 'vecernje-torbice', 'svecano', 139, null, null, null, '', '{Srebrna}', '{Mala}'),
  ('TB-8102', 'Okrugla večernja torbica Orbit', 'vecernje-torbice', null, 129, null, null, null, '', '{Zlatna,Smeđa}', '{Mini}'),
  ('TB-8103', 'Večernja torbica s lančićem Glam', 'vecernje-torbice', null, 149, null, null, null, '', '{Crna}', '{Mala,Srednja}'),
  ('TB-8201', 'Velika torba Shopper', 'torbice', null, 179, null, null, null, '', '{Smeđa}', '{Velika}'),
  -- Dodaci
  ('DD-9001', 'Ogrlica Perla', 'nakit', null, 59, null, null, null, '', '{Srebrna}', '{Univerzalna}'),
  ('DD-9002', 'Naušnice Kapljica', 'nakit', null, 45, null, null, null, '', '{Zlatna,Srebrna}', '{Univerzalna}'),
  ('DD-9003', 'Narukvica Sjaj', 'nakit', null, 39, 20, null, null, '', '{Zlatna}', '{Univerzalna}'),
  ('DD-9004', 'Ukras za kosu Rosa', 'dodaci', null, 35, null, null, null, '', '{Bijela}', '{Univerzalna}'),
  ('DD-9101', 'Svečani šal Velvet', 'salovi', null, 69, null, null, null, '', '{Crna,Bordo}', '{Univerzalna}'),
  ('DD-9102', 'Satenski šal Seda', 'salovi', null, 59, null, null, null, '', '{Bež}', '{Univerzalna}'),
  ('DD-9201', 'Uski remen Fina', 'remeni', null, 49, null, null, null, '', '{Crna,Zlatna}', '{S,M,L}'),
  ('DD-9202', 'Remen s kopčom Lux', 'remeni', null, 59, null, null, null, '', '{Smeđa}', '{S,M,L}');

do $$
declare
  r record;
  v_product_id uuid;
  v_color_id uuid;
  v_color text;
  v_index integer;
  v_size_type text;
  v_sold_out boolean;
begin
  for r in select p.*, row_number() over () as seq from seed_products p loop
    v_size_type := case
      when r.sizes = '{Univerzalna}' then 'universal'
      when r.sizes[1] in ('Mini', 'Mala', 'Srednja', 'Velika') then 'bags'
      when r.heel_height is not null then 'footwear'
      else 'clothing'
    end;

    -- Najnoviji su prvi na popisu, kako bi "Novo" imalo smisla.
    insert into public.products (
      sku, name, category_id, description, size_type, price, campaign_id,
      dress_length, heel_height, is_visible, store_only, archived_at, created_at
    )
    values (
      r.sku,
      r.name,
      (select id from public.categories where slug = r.category),
      r.name || '. Testni opis proizvoda za provjeru prikaza na webu.',
      v_size_type,
      r.price,
      case when r.category = 'kaputi' then (select id from public.campaigns where name = 'Zimsko sniženje (test)')
        else (select id from public.campaigns where name = 'Sniženje ' || r.discount || ' %') end,
      r.dress_length,
      r.heel_height,
      r.status in ('', 'trgovina'),
      r.status = 'trgovina',
      case when r.status = 'arhiva' then now() end,
      now() - r.seq * interval '7 hours'
    )
    returning id into v_product_id;

    if r.extra_category is not null then
      insert into public.product_categories (product_id, category_id)
      select v_product_id, id from public.categories where slug = r.extra_category;
    end if;

    -- Brend je interni podatak, ovdje za provjeru admin filtra. Torbice i dodaci ga nemaju.
    insert into public.product_internal (product_id, brand)
    select v_product_id, case left(r.sku, 2)
      when 'VH' then 'Atelier Mira'
      when 'KP' then 'Nova Linea'
      when 'KS' then 'Nova Linea'
      when 'OB' then 'Passo'
    end
    where left(r.sku, 2) in ('VH', 'KP', 'KS', 'OB');

    v_index := 0;
    foreach v_color in array r.colors loop
      insert into public.product_colors (product_id, name, hex, slug, sort_order)
      values (
        v_product_id,
        v_color,
        (select hex from seed_colors where name = v_color),
        pg_temp.viva_slug(r.name || ' ' || v_color || ' ' || r.sku),
        v_index
      )
      returning id into v_color_id;

      -- Oko 7 % boja je potpuno rasprodano, a pojedine veličine su na nuli, za provjeru oznaka.
      v_sold_out := random() < 0.07;
      insert into public.product_sizes (color_id, size, quantity, sort_order)
      select v_color_id, size, case when v_sold_out or random() < 0.15 then 0 else 1 + floor(random() * 6)::integer end, (ord - 1)::integer
      from unnest(r.sizes) with ordinality as s (size, ord);

      v_index := v_index + 1;
    end loop;
  end loop;
end;
$$;

commit;

-- Provjera: broj kategorija, proizvoda i boja.
select
  (select count(*) from public.categories) as kategorije,
  (select count(*) from public.products) as proizvodi,
  (select count(*) from public.product_colors) as boje;
