-- ============================================================================
-- 20260726091100_activity_feed
-- Feed de progreso (§6). El diferenciador del producto: prioriza el progreso
-- real (pasos nuevos, builds terminados) sobre la publicacion generica.
--
-- Dos principios innegociables:
--   1. `snapshot` es TEASER-SEGURO: solo lo que pinta la tarjeta. Nunca el
--      cuerpo del paso (§3.5, §13).
--   2. `score` se PRECOMPUTA AL ESCRIBIR. El feed es un simple
--      SELECT ... ORDER BY score DESC, created_at DESC sobre indice (§3.5).
-- ============================================================================

-- ── Pesos, afinables sin desplegar codigo ───────────────────────────────────
create table public.activity_weights (
  type       public.activity_type primary key,
  weight     numeric not null check (weight >= 0),
  updated_at timestamptz not null default now()
);

comment on table public.activity_weights is
  'Tabla de pesos del feed (§6). Documentada en docs/feed-weights.md. '
  'Cambiarla afecta solo a los eventos futuros: el score es historico.';

insert into public.activity_weights (type, weight) values
  ('project_finished',  4.0),   -- el build terminado es el evento estrella
  ('step_published',    3.0),   -- progreso real: el nucleo del feed
  ('project_published', 2.0),   -- bitacora nueva
  ('project_updated',   1.0);   -- publicacion generica: pesa lo minimo

create trigger activity_weights_set_updated_at
  before update on public.activity_weights
  for each row execute function public.set_updated_at();

-- ── Eventos ─────────────────────────────────────────────────────────────────
create table public.activity (
  id         uuid primary key default extensions.gen_random_uuid(),
  actor_id   uuid not null references public.profiles (id) on delete cascade,
  type       public.activity_type not null,

  project_id uuid references public.projects (id) on delete cascade,
  step_id    uuid references public.steps (id)    on delete cascade,

  -- TEASER-SEGURO. Si dudas, no lo incluyas (§13).
  snapshot   jsonb   not null default '{}'::jsonb,
  score      numeric not null default 0,
  created_at timestamptz not null default now(),

  constraint activity_snapshot_is_object check (jsonb_typeof(snapshot) = 'object'),
  -- Un evento de paso se deduplica por paso; uno de proyecto, por proyecto.
  constraint activity_step_unique_per_type unique (type, step_id),
  constraint activity_has_target check (project_id is not null or step_id is not null)
);

comment on column public.activity.snapshot is
  'Solo lo que pinta la tarjeta del feed: titulo, miniatura, autor, proyecto '
  'padre y si el paso esta tras el muro. NUNCA el cuerpo del paso.';

-- El indice que sirve el feed (§3.5).
create index activity_feed_idx on public.activity (score desc, created_at desc);
create index activity_actor_idx on public.activity (actor_id, created_at desc);
create index activity_project_idx on public.activity (project_id);
create index activity_type_idx on public.activity (type, score desc);

-- ── Scoring ─────────────────────────────────────────────────────────────────
-- Formula tipo "hot ranking": peso del evento + tiempo normalizado.
--
--   score = weight + epoch_segundos / 45000
--
-- El termino temporal crece siempre, asi que lo nuevo sube solo sin recalcular
-- nada. 45000 s = 12,5 h, de modo que un punto de peso equivale a 12,5 h de
-- ventaja: un `step_published` (3.0) adelanta a un `project_updated` (1.0)
-- publicado hasta 25 h despues. Es lo que hace que el progreso real gane.
create or replace function public.activity_compute_score(
  p_type public.activity_type,
  p_created_at timestamptz
)
returns numeric
language sql
stable
set search_path = ''
as $$
  select coalesce((select w.weight from public.activity_weights w where w.type = p_type), 1.0)
       + (extract(epoch from p_created_at) / 45000.0);
$$;

create or replace function public.activity_set_score()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.score := public.activity_compute_score(new.type, coalesce(new.created_at, now()));
  return new;
end;
$$;

create trigger activity_set_score
  before insert on public.activity
  for each row execute function public.activity_set_score();

-- ── Generacion de eventos ───────────────────────────────────────────────────

-- Snapshot de un paso. Se construye con SECURITY DEFINER porque lee tablas con
-- RLS, pero SOLO selecciona campos publicos.
create or replace function public.build_step_snapshot(p_step_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'step_title',     s.title,
    'step_position',  s.position,
    'step_thumb_url', s.thumb_url,
    'duration_minutes', s.duration_minutes,
    'project_title',  p.title,
    'project_slug',   p.slug,
    'project_locale', p.locale,
    'author_name',    pr.display_name,
    'author_slug',    pr.slug,
    'author_avatar',  pr.avatar_url,
    -- Permite pintar el candado Pro en la tarjeta sin consultar nada mas.
    'is_paywalled',   s.position > public.free_preview_steps()
  )
    from public.steps s
    join public.projects p  on p.id = s.project_id
    join public.profiles pr on pr.id = p.author_id
   where s.id = p_step_id;
$$;

create or replace function public.build_project_snapshot(p_project_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'project_title',  p.title,
    'project_slug',   p.slug,
    'project_locale', p.locale,
    'subtitle',       p.subtitle,
    'cover_url',      p.cover_url,
    'build_status',   p.build_status,
    'author_name',    pr.display_name,
    'author_slug',    pr.slug,
    'author_avatar',  pr.avatar_url,
    'step_count',     (select count(*) from public.steps s
                        where s.project_id = p.id and s.status = 'published')
  )
    from public.projects p
    join public.profiles pr on pr.id = p.author_id
   where p.id = p_project_id;
$$;

-- Evento al publicar un paso de un proyecto ya publicado.
create or replace function public.steps_emit_activity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  proj public.projects;
begin
  if new.status <> 'published' then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.status = 'published' then
    return new;                       -- ya se emitio en su momento
  end if;

  select * into proj from public.projects p where p.id = new.project_id;
  if proj.status <> 'published' then
    return new;                       -- el proyecto aun es borrador
  end if;

  insert into public.activity (actor_id, type, project_id, step_id, snapshot)
  values (proj.author_id, 'step_published', new.project_id, new.id,
          public.build_step_snapshot(new.id))
  on conflict (type, step_id) do nothing;

  return new;
end;
$$;

create trigger steps_emit_activity
  after insert or update of status on public.steps
  for each row execute function public.steps_emit_activity();

-- Eventos de proyecto: publicacion y finalizacion.
create or replace function public.projects_emit_activity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status <> 'published' then
    return new;
  end if;

  if tg_op = 'INSERT' or old.status <> 'published' then
    insert into public.activity (actor_id, type, project_id, snapshot)
    values (new.author_id, 'project_published', new.id,
            public.build_project_snapshot(new.id));
  end if;

  if new.build_status = 'finished'
     and (tg_op = 'INSERT' or old.build_status is distinct from 'finished') then
    insert into public.activity (actor_id, type, project_id, snapshot)
    values (new.author_id, 'project_finished', new.id,
            public.build_project_snapshot(new.id));
  end if;

  return new;
end;
$$;

create trigger projects_emit_activity
  after insert or update of status, build_status on public.projects
  for each row execute function public.projects_emit_activity();

-- ── RLS ─────────────────────────────────────────────────────────────────────
alter table public.activity         enable row level security;
alter table public.activity_weights enable row level security;

-- Publico: el snapshot es teaser-seguro por construccion, asi que el feed
-- entero es cacheable con ISR (§6).
create policy "activity: lectura publica"
  on public.activity for select
  to anon, authenticated
  using (true);

create policy "activity_weights: lectura publica"
  on public.activity_weights for select
  to anon, authenticated
  using (true);

create policy "activity_weights: afina el operador"
  on public.activity_weights for update
  to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

-- §5: `activity` se escribe SOLO por trigger/servicio, nunca por cliente.
-- Sin politicas de escritura y sin privilegios: los triggers de arriba son
-- SECURITY DEFINER y su propietario salta RLS.
revoke insert, update, delete on public.activity from anon, authenticated;
revoke insert, delete on public.activity_weights from anon, authenticated;
