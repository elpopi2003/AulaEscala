-- ============================================================================
-- 20260726090600_steps
-- EL SPLIT CRITICO (§3.1).
--
--   public.steps       -> metadatos PUBLICOS (titulo, posicion, miniatura,
--                         duracion). Indexables, devueltos a anonimos como
--                         teaser.
--   public.step_bodies -> CUERPO DE PAGO. Tabla aparte con politica Pro+.
--
-- RLS es row-level, no column-level: sobre una fila, o se ve entera o no se
-- ve. Separando en dos tablas, la fuga del cuerpo es ESTRUCTURALMENTE
-- IMPOSIBLE — el dato no esta en la tabla que el anonimo puede consultar.
-- ============================================================================

-- ── Configuracion global de la aplicacion ───────────────────────────────────
-- Tabla de una sola fila. Existe para que el tamano del teaser gratuito sea
-- un valor operable y no una constante enterrada en una politica.
create table public.app_config (
  id                 boolean primary key default true check (id),

  -- Cuantos pasos iniciales de cada bitacora tienen el cuerpo abierto a
  -- anonimos y suscriptores.
  --   0 = comportamiento de CLAUDE.md §4 (ningun cuerpo sin Pro).
  --   2 = comportamiento del prototipo de diseno (los dos primeros abiertos).
  -- Arranca en 0: fallar cerrado es la unica opcion segura para un muro de
  -- pago. Ver docs/adr/0004-teaser-de-pasos-gratuitos.md.
  free_preview_steps int not null default 0 check (free_preview_steps between 0 and 20),

  updated_at         timestamptz not null default now()
);

insert into public.app_config (id) values (true);

create trigger app_config_set_updated_at
  before update on public.app_config
  for each row execute function public.set_updated_at();

create or replace function public.free_preview_steps()
returns int
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select c.free_preview_steps from public.app_config c where c.id), 0);
$$;

alter table public.app_config enable row level security;

create policy "app_config: lectura publica"
  on public.app_config for select to anon, authenticated using (true);

-- Solo el operador cambia el tamano del teaser.
create policy "app_config: edita el operador"
  on public.app_config for update
  to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

revoke insert, delete on public.app_config from anon, authenticated;

-- ============================================================================
-- steps — METADATOS PUBLICOS
-- ============================================================================
create table public.steps (
  id                   uuid primary key default extensions.gen_random_uuid(),
  project_id           uuid not null references public.projects (id) on delete cascade,

  -- Orden de la bitacora. 1-based: "Paso 1 de 8".
  position             int  not null check (position >= 1),

  title                text not null check (length(btrim(title)) between 3 and 140),
  thumb_url            text,

  -- Duracion mostrada como pildora en la lista publica de pasos, asi que es
  -- metadato publico y vive aqui, no en step_bodies.
  duration_minutes     int check (duration_minutes between 0 and 100000),

  status               public.content_status not null default 'draft',
  published_at         timestamptz,

  -- §3.4 — preparacion multiidioma.
  locale               text not null default 'es' check (locale ~ '^[a-z]{2}(-[A-Z]{2})?$'),
  translation_group_id uuid not null default extensions.gen_random_uuid(),

  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),

  constraint steps_translation_key unique (translation_group_id, locale),
  constraint steps_published_has_date check (
    (status = 'published') = (published_at is not null)
  )
);

comment on table public.steps is
  'METADATOS PUBLICOS del paso (§3.1). Nunca debe contener texto de pago. '
  'Si en el futuro aparece un campo protegido, va a step_bodies o a una tabla '
  'nueva con su politica — jamas como columna de esta.';

-- El orden se edita con drag & drop (§9), y reordenar intercambia posiciones.
-- Con una restriccion inmediata, el paso intermedio del intercambio violaria
-- la unicidad. DEFERRABLE la valida al COMMIT, cuando el orden ya es coherente.
alter table public.steps
  add constraint steps_project_position_key unique (project_id, position)
  deferrable initially deferred;

alter table public.steps
  add column search_vector tsvector
  generated always as (
    to_tsvector('public.es_unaccent', coalesce(title, ''))
  ) stored;

create index steps_search_idx     on public.steps using gin (search_vector);
create index steps_title_trgm_idx on public.steps using gin (title extensions.gin_trgm_ops);
create index steps_project_idx    on public.steps (project_id, position);
create index steps_published_idx  on public.steps (published_at desc) where status = 'published';

create trigger steps_set_updated_at
  before update on public.steps
  for each row execute function public.set_updated_at();

create or replace function public.steps_sync_publish_dates()
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
  return new;
end;
$$;

create trigger steps_sync_publish_dates
  before insert or update on public.steps
  for each row execute function public.steps_sync_publish_dates();

-- ============================================================================
-- step_bodies — CUERPO DE PAGO
-- ============================================================================
create table public.step_bodies (
  step_id    uuid primary key references public.steps (id) on delete cascade,
  body       text,
  -- Bloque "nota tecnica / consejo" que el diseno pinta destacado bajo la
  -- descripcion. Es contenido de pago, va aqui.
  tip        text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.step_bodies is
  'CUERPO DE PAGO (§3.1). Politica Pro/Modelista. Indexado aparte para la '
  'busqueda dentro del contenido, que solo Pro puede ejecutar (§4).';

-- Indice de busqueda SEPARADO del de steps: la busqueda dentro del cuerpo es
-- una capacidad de Pro (§4), y consultarla pasa por la RLS de esta tabla.
alter table public.step_bodies
  add column search_vector tsvector
  generated always as (
    setweight(to_tsvector('public.es_unaccent', coalesce(body, '')), 'A') ||
    setweight(to_tsvector('public.es_unaccent', coalesce(tip, '')), 'B')
  ) stored;

create index step_bodies_search_idx on public.step_bodies using gin (search_vector);

create trigger step_bodies_set_updated_at
  before update on public.step_bodies
  for each row execute function public.set_updated_at();

-- ── N:M paso <-> tecnicas ───────────────────────────────────────────────────
create table public.step_techniques (
  step_id      uuid not null references public.steps (id)      on delete cascade,
  technique_id uuid not null references public.techniques (id) on delete cascade,
  primary key (step_id, technique_id)
);

create index step_techniques_technique_idx on public.step_techniques (technique_id);

-- ── Helpers de visibilidad ──────────────────────────────────────────────────

-- Metadatos del paso visibles: paso publicado dentro de proyecto visible,
-- o bien el autor mirando lo suyo.
create or replace function public.can_view_step(p_step_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.steps s
      join public.projects p on p.id = s.project_id
     where s.id = p_step_id
       and (
         (s.status = 'published' and p.status = 'published')
         or p.author_id = (select auth.uid())
       )
  );
$$;

-- ¿Puede el usuario actual leer el CUERPO de este paso?
-- Tres vias, y solo tres:
--   1. Es el autor de la bitacora.
--   2. Tiene tramo pro o superior y el paso le es visible.
--   3. El paso cae dentro del teaser gratuito configurado.
create or replace function public.can_view_step_body(p_step_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.steps s
      join public.projects p on p.id = s.project_id
     where s.id = p_step_id
       and (
         -- (1) autor
         p.author_id = (select auth.uid())
         or (
           -- el paso tiene que ser visible en cualquier caso
           s.status = 'published'
           and p.status = 'published'
           and (
             -- (2) tramo de pago
             public.tier_rank(public.user_tier()) >= public.tier_rank('pro')
             -- (3) teaser gratuito
             or s.position <= public.free_preview_steps()
           )
         )
       )
  );
$$;

comment on function public.can_view_step_body is
  'Unico punto de decision sobre el cuerpo de pago. Lo usan la politica de '
  'step_bodies, la de media privada y la firma de URLs de Storage; una '
  'definicion divergente en cualquiera de ellas seria una fuga (§13).';

-- ── RLS ─────────────────────────────────────────────────────────────────────
alter table public.steps           enable row level security;
alter table public.step_bodies     enable row level security;
alter table public.step_techniques enable row level security;

-- steps: PUBLICO si el proyecto esta publicado (§5). Es lo que alimenta el
-- feed, la busqueda publica y el teaser.
create policy "steps: publico si el proyecto esta publicado"
  on public.steps for select
  to anon, authenticated
  using (
    (
      status = 'published'
      and exists (
        select 1 from public.projects p
         where p.id = steps.project_id and p.status = 'published'
      )
    )
    or exists (
      select 1 from public.projects p
       where p.id = steps.project_id and p.author_id = (select auth.uid())
    )
  );

create policy "steps: escribe el autor modelista"
  on public.steps for all
  to authenticated
  using (
    (select public.is_at_least('modelista'))
    and exists (
      select 1 from public.projects p
       where p.id = steps.project_id and p.author_id = (select auth.uid())
    )
  )
  with check (
    (select public.is_at_least('modelista'))
    and exists (
      select 1 from public.projects p
       where p.id = steps.project_id and p.author_id = (select auth.uid())
    )
  );

-- step_bodies: SOLO pro o modelista (+ autor sobre lo suyo, + teaser).
create policy "step_bodies: solo pro, modelista, autor o teaser"
  on public.step_bodies for select
  to anon, authenticated
  using ((select public.can_view_step_body(step_id)));

create policy "step_bodies: escribe el autor modelista"
  on public.step_bodies for all
  to authenticated
  using (
    (select public.is_at_least('modelista'))
    and exists (
      select 1 from public.steps s
        join public.projects p on p.id = s.project_id
       where s.id = step_bodies.step_id and p.author_id = (select auth.uid())
    )
  )
  with check (
    (select public.is_at_least('modelista'))
    and exists (
      select 1 from public.steps s
        join public.projects p on p.id = s.project_id
       where s.id = step_bodies.step_id and p.author_id = (select auth.uid())
    )
  );

-- Las tecnicas asociadas a un paso son metadato publico (chips clicables que
-- llevan al archivo por tecnica — puerta de SEO).
create policy "step_techniques: lectura si el paso es visible"
  on public.step_techniques for select
  to anon, authenticated
  using ((select public.can_view_step(step_id)));

create policy "step_techniques: escribe el autor modelista"
  on public.step_techniques for all
  to authenticated
  using (
    (select public.is_at_least('modelista'))
    and exists (
      select 1 from public.steps s
        join public.projects p on p.id = s.project_id
       where s.id = step_techniques.step_id and p.author_id = (select auth.uid())
    )
  )
  with check (
    (select public.is_at_least('modelista'))
    and exists (
      select 1 from public.steps s
        join public.projects p on p.id = s.project_id
       where s.id = step_techniques.step_id and p.author_id = (select auth.uid())
    )
  );
