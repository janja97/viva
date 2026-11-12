-- Blog (/blog, /blog/[slug], admin /admin/blog): članci koji odgovaraju na pitanja kupaca
-- (npr. "Kako odabrati haljinu za maturu") i vode na kategorije. Tekst je u istom obliku kao SEO tekst
-- kategorija: prazan red je novi odlomak, a red koji počinje s "## " je podnaslov.
-- Naslovna slika je u spremištu product-images, u mapi blog/ (pravila spremišta iz migracije 0004).
begin;

create table public.blog_posts (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  title text not null check (char_length(btrim(title)) between 5 and 120),
  -- Kratki uvod na popisu članaka i za Google, ako opis nije upisan.
  excerpt text not null default '' check (char_length(excerpt) <= 300),
  body text not null default '' check (char_length(body) <= 30000),
  cover_path text check (cover_path is null or char_length(cover_path) <= 300),
  cover_alt text not null default '' check (char_length(cover_alt) <= 200),
  meta_title text check (meta_title is null or char_length(meta_title) between 1 and 70),
  meta_description text check (meta_description is null or char_length(meta_description) between 1 and 170),
  faq jsonb not null default '[]'::jsonb check (jsonb_typeof(faq) = 'array' and jsonb_array_length(faq) <= 12),
  is_published boolean not null default false,
  -- Postavlja se pri prvoj objavi i ne mijenja se poslije, jer je to datum članka.
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index blog_posts_published_idx on public.blog_posts (published_at desc) where is_published;

create function public.touch_blog_post()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  if new.is_published and new.published_at is null then
    new.published_at := now();
  end if;
  return new;
end;
$$;

create trigger touch_blog_post
before insert or update on public.blog_posts
for each row execute function public.touch_blog_post();

alter table public.blog_posts enable row level security;

revoke all on public.blog_posts from public, anon, authenticated;
grant select on public.blog_posts to anon;
grant select, insert, update, delete on public.blog_posts to authenticated;
grant all on public.blog_posts to service_role;

-- Kupci vide samo objavljene članke.
create policy blog_posts_select_public on public.blog_posts
for select to anon
using (is_published);

-- Cijeli tim (super_admin, admin, viewer) vidi i neobjavljene, a prijavljeni bez uloge samo objavljene.
create policy blog_posts_select_authenticated on public.blog_posts
for select to authenticated
using (is_published or (select public.current_user_role()) is not null);

-- Pišu, objavljuju i brišu samo super_admin i admin. Viewer samo čita.
create policy blog_posts_insert on public.blog_posts
for insert to authenticated
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy blog_posts_update on public.blog_posts
for update to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'))
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy blog_posts_delete on public.blog_posts
for delete to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'));

commit;
