-- Raspon veličina u tekstovima: "do 58" postaje "od 36 do 58".
-- Mijenja SEO tekstove kategorija i članke bloga koji su već upisani iz seed datoteka.
-- Smije se pokrenuti više puta: "od 36 do 58" se ne dira.

update public.categories
set
  description      = regexp_replace(description,      '(?<!od 36 )do 58', 'od 36 do 58', 'g'),
  meta_description = regexp_replace(meta_description, '(?<!od 36 )do 58', 'od 36 do 58', 'g'),
  seo_text         = regexp_replace(seo_text,         '(?<!od 36 )do 58', 'od 36 do 58', 'g'),
  faq              = regexp_replace(faq::text,        '(?<!od 36 )do 58', 'od 36 do 58', 'g')::jsonb
where concat_ws(' ', description, meta_description, seo_text, faq::text) ~ 'do 58';

update public.blog_posts
set
  excerpt          = regexp_replace(excerpt,          '(?<!od 36 )do 58', 'od 36 do 58', 'g'),
  body             = regexp_replace(body,             '(?<!od 36 )do 58', 'od 36 do 58', 'g'),
  meta_description = regexp_replace(meta_description, '(?<!od 36 )do 58', 'od 36 do 58', 'g'),
  faq              = regexp_replace(faq::text,        '(?<!od 36 )do 58', 'od 36 do 58', 'g')::jsonb
where concat_ws(' ', excerpt, body, meta_description, faq::text) ~ 'do 58';
