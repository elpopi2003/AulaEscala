-- ============================================================================
-- 20260726090400_taxonomies
-- Escalas, tematicas y tecnicas. Son las puertas de SEO y el eje del filtrado,
-- por eso la contaminacion por duplicados es el riesgo real (§7.2).
-- ============================================================================

-- ── Escalas (1/35, 1/48, 1/72...) ───────────────────────────────────────────
create table public.scales (
  id         uuid primary key default extensions.gen_random_uuid(),
  slug       text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name       text not null unique,
  -- Denominador de la escala: permite ordenar 1/16 < 1/35 < 1/72 sin parsear.
  ratio      int  not null check (ratio > 0),
  position   int  not null default 0,
  created_at timestamptz not null default now()
);

comment on table public.scales is 'Taxonomia cerrada. Solo la gestiona el operador.';

-- ── Tematicas (blindados, aviacion, figuras, naval...) ──────────────────────
create table public.subjects (
  id         uuid primary key default extensions.gen_random_uuid(),
  slug       text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name       text not null unique,
  position   int  not null default 0,
  created_at timestamptz not null default now()
);

comment on table public.subjects is 'Taxonomia cerrada. Solo la gestiona el operador.';

-- ── Tecnicas ────────────────────────────────────────────────────────────────
-- Taxonomia ABIERTA: cualquier modelista puede crear una. Se publica directa,
-- sin cola de revision (§7.2), pero nace marcada como `pending_review` para
-- que el operador la revise y funda duplicados.
create table public.techniques (
  id                uuid primary key default extensions.gen_random_uuid(),
  slug              text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name              text not null check (length(btrim(name)) between 2 and 60),
  description       text check (length(description) <= 1000),
  moderation_status public.moderation_status not null default 'pending_review',

  -- Destino de la fusion: cuando el operador unifica "drybrush" en
  -- "Dry brushing", la primera queda `merged` apuntando a la segunda.
  merged_into_id    uuid references public.techniques (id) on delete set null,

  created_by        uuid references public.profiles (id) on delete set null,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),

  constraint techniques_name_key unique (name),
  constraint techniques_merge_is_consistent check (
    (moderation_status = 'merged') = (merged_into_id is not null)
  ),
  constraint techniques_no_self_merge check (merged_into_id is distinct from id)
);

comment on table public.techniques is
  'Taxonomia abierta con anti-duplicados (§7.2). El autocompletado por '
  'similitud pg_trgm evita la mayoria de duplicados en el momento de escribir; '
  'los que pasen se funden despues con la herramienta del panel de operador.';

create trigger techniques_set_updated_at
  before update on public.techniques
  for each row execute function public.set_updated_at();

-- FTS para la busqueda publica de tecnicas (§4: la busqueda es de todos).
alter table public.techniques
  add column search_vector tsvector
  generated always as (
    setweight(to_tsvector('public.es_unaccent', coalesce(name, '')), 'A') ||
    setweight(to_tsvector('public.es_unaccent', coalesce(description, '')), 'B')
  ) stored;

create index techniques_search_idx on public.techniques using gin (search_vector);

-- pg_trgm: tolerancia a erratas Y deteccion de duplicados al crear (§7.2).
create index techniques_name_trgm_idx on public.techniques using gin (name extensions.gin_trgm_ops);

create index techniques_moderation_idx
  on public.techniques (moderation_status)
  where moderation_status = 'pending_review';

-- Sugerencia de duplicados: "¿querias decir Dry brushing?" (§7.2).
create or replace function public.suggest_similar_techniques(
  candidate text,
  min_similarity real default 0.35,
  max_results int default 5
)
returns table (id uuid, name text, slug text, similarity real)
language sql
stable
set search_path = ''
as $$
  select t.id,
         t.name,
         t.slug,
         extensions.similarity(t.name, candidate) as similarity
    from public.techniques t
   where t.moderation_status <> 'merged'
     and extensions.similarity(t.name, candidate) >= min_similarity
   order by similarity desc, t.name
   limit max_results;
$$;

comment on function public.suggest_similar_techniques is
  'Alimenta el autocompletado anti-duplicados del formulario de tecnicas (§7.2).';

-- ── RLS ─────────────────────────────────────────────────────────────────────
alter table public.scales     enable row level security;
alter table public.subjects   enable row level security;
alter table public.techniques enable row level security;

create policy "scales: lectura publica"
  on public.scales for select to anon, authenticated using (true);

create policy "subjects: lectura publica"
  on public.subjects for select to anon, authenticated using (true);

create policy "techniques: lectura publica"
  on public.techniques for select to anon, authenticated using (true);

-- Crear tecnica: solo Modelista (§5). Se publica directa.
create policy "techniques: crea el modelista"
  on public.techniques for insert
  to authenticated
  with check (
    (select public.is_at_least('modelista'))
    and created_by = (select auth.uid())
    -- El creador no decide el estado de moderacion ni la fusion.
    and moderation_status = 'pending_review'
    and merged_into_id is null
  );

-- Editar y fundir tecnicas: solo el operador. La fusion reasigna relaciones
-- N:M y no puede quedar en manos de cualquier modelista.
create policy "techniques: edita el operador"
  on public.techniques for update
  to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy "techniques: borra el operador"
  on public.techniques for delete
  to authenticated
  using ((select public.is_admin()));

-- Escalas y tematicas son taxonomia cerrada: sin politicas de escritura, solo
-- service_role / panel de operador.
revoke insert, update, delete on public.scales   from anon, authenticated;
revoke insert, update, delete on public.subjects from anon, authenticated;
