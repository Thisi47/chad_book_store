-- Associe les documents déjà présents dans Storage aux lignes de public.books.
-- À exécuter en une seule fois dans Supabase Dashboard > SQL Editor.
-- Correspondances reconnues : nom de fichier basé sur l'ID OU sur le titre.
-- Exemples : <id>.pdf, <id>-version2.epub, Mon-Titre.pdf.
-- Les chemins existants ne sont jamais remplacés. Les ambiguïtés sont signalées.

with storage_files as (
  select
    o.name as storage_path,
    lower(regexp_replace(
      regexp_replace(o.name, '^.*/', ''),
      '\.(pdf|epub|txt|md|markdown)$', ''
    )) as filename_without_extension
  from storage.objects o
  where o.bucket_id = 'book-files'
    and lower(o.name) ~ '\.(pdf|epub|txt|md|markdown)$'
), normalized_files as (
  select
    storage_path,
    regexp_replace(filename_without_extension, '[^[:alnum:]]', '', 'g') as normalized_basename
  from storage_files
), candidates as (
  select distinct
    b.id as book_id,
    b.title as book_title,
    f.storage_path,
    case
      when f.normalized_basename = regexp_replace(lower(b.id::text), '[^[:alnum:]]', '', 'g') then 1
      when f.normalized_basename like regexp_replace(lower(b.id::text), '[^[:alnum:]]', '', 'g') || '%' then 1
      else 2
    end as match_priority
  from public.books b
  join normalized_files f on
    f.normalized_basename = regexp_replace(lower(b.id::text), '[^[:alnum:]]', '', 'g')
    or f.normalized_basename like regexp_replace(lower(b.id::text), '[^[:alnum:]]', '', 'g') || '%'
    or f.normalized_basename = regexp_replace(lower(b.title), '[^[:alnum:]]', '', 'g')
), best_priority as (
  select book_id, min(match_priority) as match_priority
  from candidates
  group by book_id
), resolved as (
  select
    c.book_id,
    min(c.book_title) as book_title,
    min(c.storage_path) as storage_path,
    count(distinct c.storage_path)::integer as candidate_count
  from candidates c
  join best_priority p using (book_id, match_priority)
  group by c.book_id
), updated as (
  update public.books b
  set reading_path = r.storage_path
  from resolved r
  where b.id = r.book_id
    and r.candidate_count = 1
    and nullif(trim(b.reading_path), '') is null
  returning b.id, b.reading_path
)
select
  b.id as book_id,
  b.title,
  coalesce(u.reading_path, b.reading_path) as reading_path,
  case
    when u.id is not null then 'mis à jour'
    when nullif(trim(b.reading_path), '') is not null then 'déjà configuré'
    when r.candidate_count > 1 then 'plusieurs fichiers correspondent : vérifier manuellement'
    else 'aucun fichier correspondant : ajouter le document à book-files'
  end as resultat,
  case when r.candidate_count > 1 then r.candidate_count else null end as nombre_de_candidats
from public.books b
left join resolved r on r.book_id = b.id
left join updated u on u.id = b.id
order by b.title;
