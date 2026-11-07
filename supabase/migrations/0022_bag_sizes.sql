-- Torbice dobivaju vlastitu vrstu veličina (Mini, Mala, Srednja, Velika).
begin;

alter table public.products drop constraint if exists products_size_type_check;
alter table public.products
  add constraint products_size_type_check check (size_type in ('footwear', 'clothing', 'bags', 'universal'));

commit;
