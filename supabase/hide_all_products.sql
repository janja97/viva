-- Jednokratno: svi proizvodi se skrivaju s weba i svima se gasi "samo u poslovnicama".
-- Namjerno nije u migrations/, jer mijenja podatke, a ne strukturu. Proizvodi, slike, količine i kampanje ostaju.
update public.products
set is_visible = false,
    store_only = false
where is_visible or store_only;

-- Provjera: oba broja moraju biti 0.
select
  count(*) filter (where is_visible) as vidljivi_na_webu,
  count(*) filter (where store_only) as samo_u_poslovnicama,
  count(*) as ukupno_proizvoda
from public.products;
