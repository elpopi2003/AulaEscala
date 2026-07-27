-- ============================================================================
-- 20260726090000_extensions_and_search
-- Extensiones, configuracion de busqueda en espanol (§3.3) y utilidades comunes.
-- ============================================================================

-- Supabase aloja las extensiones en el esquema `extensions`, no en `public`.
create extension if not exists "unaccent"  with schema extensions;
create extension if not exists "pg_trgm"   with schema extensions;
create extension if not exists "pgcrypto"  with schema extensions;

-- ── Configuracion FTS: stemmer espanol + insensible a tildes ────────────────
-- "aerografia" debe encontrar "aerografia". §3.3
do $$
begin
  if not exists (
    select 1 from pg_ts_config c
      join pg_namespace n on n.oid = c.cfgnamespace
     where c.cfgname = 'es_unaccent' and n.nspname = 'public'
  ) then
    create text search configuration public.es_unaccent (copy = pg_catalog.spanish);
  end if;
end
$$;

alter text search configuration public.es_unaccent
  alter mapping for hword, hword_part, word
  with extensions.unaccent, pg_catalog.spanish_stem;

comment on text search configuration public.es_unaccent is
  'Espanol + unaccent. Usada por todas las columnas generadas search_vector. '
  'AVISO §3.4: al implementar multiidioma, la configuracion pasa a depender de '
  '`locale` y habra que migrar de columna generada a trigger — el cast '
  'text::regconfig no es IMMUTABLE.';

-- ── updated_at automatico ───────────────────────────────────────────────────
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

comment on function public.set_updated_at is
  'Trigger BEFORE UPDATE generico para mantener updated_at.';

-- ── Slugs ───────────────────────────────────────────────────────────────────
-- Genera un slug ASCII a partir de un texto libre. IMMUTABLE para poder usarse
-- en indices y columnas generadas si hiciera falta.
create or replace function public.slugify(value text)
returns text
language sql
immutable
parallel safe
set search_path = ''
as $$
  select trim(both '-' from
    regexp_replace(
      -- La forma de 2 argumentos de unaccent() es IMMUTABLE; la de 1 solo es
      -- STABLE porque resuelve el diccionario via search_path.
      regexp_replace(lower(extensions.unaccent('extensions.unaccent'::regdictionary, coalesce(value, ''))), '[^a-z0-9]+', '-', 'g'),
      '-{2,}', '-', 'g'
    )
  );
$$;

comment on function public.slugify is
  'Normaliza texto libre a slug ASCII (minusculas, sin tildes, separado por guiones).';
