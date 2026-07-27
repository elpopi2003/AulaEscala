-- ============================================================================
-- 20260726090500_projects
-- Bitacoras de montaje. El proyecto entero es publico e indexable: el limite
-- de pago esta en el CUERPO del paso, no aqui (§4).
-- ============================================================================

create table public.projects (
  id                   uuid primary key default extensions.gen_random_uuid(),
  author_id            uuid not null references public.profiles (id) on delete cascade,

  title                text not null check (length(btrim(title)) between 3 and 140),
  subtitle             text check (length(subtitle) <= 160),
  slug                 text not null check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and length(slug) between 3 and 160),
  body                 text,
  cover_url            text,

  -- Metadatos del kit, mostrados en la barra de atributos de la portada.
  manufacturer         text check (length(manufacturer) <= 80),
  kit_ref              text check (length(kit_ref) <= 60),
  difficulty           public.difficulty_level,
  build_status         public.build_status  not null default 'wip',

  scale_id             uuid references public.scales (id)   on delete set null,
  subject_id           uuid references public.subjects (id) on delete set null,

  status               public.content_status not null default 'draft',
  published_at         timestamptz,
  finished_at          timestamptz,

  -- §3.4 — preparacion multiidioma, no implementado en el MVP.
  locale               text not null default 'es' check (locale ~ '^[a-z]{2}(-[A-Z]{2})?$'),
  translation_group_id uuid not null default extensions.gen_random_uuid(),

  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),

  -- Slugs unicos POR LOCALE, no globalmente (§3.4).
  constraint projects_locale_slug_key unique (locale, slug),
  -- Una sola traduccion por idioma dentro de un grupo de traduccion.
  constraint projects_translation_key unique (translation_group_id, locale),
  constraint projects_published_has_date check (
    (status = 'published') = (published_at is not null)
  ),
  constraint projects_finished_has_date check (
    build_status = 'finished' or finished_at is null
  )
);

comment on table public.projects is
  'Bitacora de montaje. Metadatos y cuerpo introductorio son publicos e '
  'indexables — son la puerta de entrada del embudo (§2).';
comment on column public.projects.translation_group_id is
  '§3.4: todas las traducciones de un mismo contenido comparten valor.';

-- §3.3 — columna generada + GIN. Valido porque to_tsvector(regconfig, text)
-- es IMMUTABLE con la configuracion fijada.
alter table public.projects
  add column search_vector tsvector
  generated always as (
    setweight(to_tsvector('public.es_unaccent', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('public.es_unaccent', coalesce(subtitle, '')), 'B') ||
    setweight(to_tsvector('public.es_unaccent', coalesce(manufacturer, '') || ' ' || coalesce(kit_ref, '')), 'C') ||
    setweight(to_tsvector('public.es_unaccent', coalesce(body, '')), 'D')
  ) stored;

create index projects_search_idx      on public.projects using gin (search_vector);
create index projects_title_trgm_idx  on public.projects using gin (title extensions.gin_trgm_ops);
create index projects_author_idx      on public.projects (author_id, created_at desc);
create index projects_published_idx   on public.projects (published_at desc) where status = 'published';
create index projects_scale_idx       on public.projects (scale_id)   where status = 'published';
create index projects_subject_idx     on public.projects (subject_id) where status = 'published';
create index projects_locale_idx      on public.projects (locale);

create trigger projects_set_updated_at
  before update on public.projects
  for each row execute function public.set_updated_at();

-- Coherencia de fechas de publicacion: las pone el servidor, no el cliente.
create or replace function public.projects_sync_publish_dates()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status = 'published' and new.published_at is null then
    new.published_at := now();
  elsif new.status = 'draft' then
    new.published_at := null;
  end if;

  if new.build_status = 'finished' and new.finished_at is null then
    new.finished_at := now();
  elsif new.build_status = 'wip' then
    new.finished_at := null;
  end if;

  return new;
end;
$$;

create trigger projects_sync_publish_dates
  before insert or update on public.projects
  for each row execute function public.projects_sync_publish_dates();

-- ── N:M proyecto <-> tecnicas ───────────────────────────────────────────────
create table public.project_techniques (
  project_id   uuid not null references public.projects (id)   on delete cascade,
  technique_id uuid not null references public.techniques (id) on delete cascade,
  primary key (project_id, technique_id)
);

create index project_techniques_technique_idx on public.project_techniques (technique_id);

-- ── Helper de visibilidad ───────────────────────────────────────────────────
-- Un proyecto es visible si esta publicado, o si lo consulta su autor.
-- Se centraliza aqui porque lo usan las politicas de steps, media, comments,
-- materials... y una definicion divergente seria una fuga.
create or replace function public.can_view_project(p_project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.projects p
     where p.id = p_project_id
       and (p.status = 'published' or p.author_id = (select auth.uid()))
  );
$$;

comment on function public.can_view_project is
  'Visibilidad del proyecto contenedor. NO concede acceso al cuerpo de los '
  'pasos: eso lo decide ademas el tramo (§4).';

-- ── RLS ─────────────────────────────────────────────────────────────────────
alter table public.projects           enable row level security;
alter table public.project_techniques enable row level security;

create policy "projects: publico si esta publicado"
  on public.projects for select
  to anon, authenticated
  using (
    status = 'published'
    or author_id = (select auth.uid())
  );

-- Crear/editar/borrar: solo el autor Y con tramo modelista (§5).
-- Consecuencia querida del downgrade (§10): al perder el tramo, el contenido
-- sigue publicado pero deja de poder editarse.
create policy "projects: crea el autor modelista"
  on public.projects for insert
  to authenticated
  with check (
    author_id = (select auth.uid())
    and (select public.is_at_least('modelista'))
  );

create policy "projects: edita el autor modelista"
  on public.projects for update
  to authenticated
  using (
    author_id = (select auth.uid())
    and (select public.is_at_least('modelista'))
  )
  with check (
    author_id = (select auth.uid())
    and (select public.is_at_least('modelista'))
  );

create policy "projects: borra el autor modelista"
  on public.projects for delete
  to authenticated
  using (
    author_id = (select auth.uid())
    and (select public.is_at_least('modelista'))
  );

create policy "project_techniques: lectura si el proyecto es visible"
  on public.project_techniques for select
  to anon, authenticated
  using ((select public.can_view_project(project_id)));

create policy "project_techniques: escribe el autor modelista"
  on public.project_techniques for all
  to authenticated
  using (
    (select public.is_at_least('modelista'))
    and exists (
      select 1 from public.projects p
       where p.id = project_techniques.project_id
         and p.author_id = (select auth.uid())
    )
  )
  with check (
    (select public.is_at_least('modelista'))
    and exists (
      select 1 from public.projects p
       where p.id = project_techniques.project_id
         and p.author_id = (select auth.uid())
    )
  );
