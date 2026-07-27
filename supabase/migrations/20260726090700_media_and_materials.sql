-- ============================================================================
-- 20260726090700_media_and_materials
-- Imagenes (galerias) y materiales descargables.
--
-- Reparto de buckets (§5):
--   media.is_private = false -> bucket publico  (portadas, miniaturas, feed,
--                                                galeria del resultado final)
--   media.is_private = true  -> bucket privado  (fotos del cuerpo del paso)
--   materials                -> bucket privado, siempre Pro+
-- ============================================================================

create table public.media (
  id           uuid primary key default extensions.gen_random_uuid(),
  owner_id     uuid not null references public.profiles (id) on delete cascade,

  project_id   uuid references public.projects (id) on delete cascade,
  step_id      uuid references public.steps (id)    on delete cascade,

  storage_path text not null,
  kind         public.media_kind not null default 'image',
  alt_text     text check (length(alt_text) <= 300),
  position     int  not null default 0,
  width        int,
  height       int,
  byte_size    bigint check (byte_size >= 0),
  mime         text,

  -- Determina el bucket y, con el, si hace falta firmar la URL.
  is_private   boolean not null default false,

  created_at   timestamptz not null default now(),

  -- Cada media cuelga de un proyecto o de un paso, nunca de ambos ni de nada.
  constraint media_belongs_to_one check (
    (project_id is not null)::int + (step_id is not null)::int = 1
  ),
  constraint media_storage_path_key unique (storage_path)
);

comment on table public.media is
  'Galerias. Las fotos del cuerpo de un paso son privadas y se sirven con '
  'signed URLs de vida corta tras verificar el tramo (§5).';

create index media_project_idx on public.media (project_id, position) where project_id is not null;
create index media_step_idx    on public.media (step_id, position)    where step_id is not null;
create index media_owner_idx   on public.media (owner_id);

-- ── Materiales descargables — SIEMPRE de pago ───────────────────────────────
create table public.materials (
  id           uuid primary key default extensions.gen_random_uuid(),
  project_id   uuid not null references public.projects (id) on delete cascade,
  storage_path text not null unique,
  filename     text not null check (length(btrim(filename)) between 1 and 200),
  mime         text,
  byte_size    bigint check (byte_size >= 0),
  position     int not null default 0,
  created_at   timestamptz not null default now()
);

comment on table public.materials is
  'Plantillas, listas de pinturas, referencias. Contenido de pago (§4): '
  'sin excepcion de teaser, a diferencia del cuerpo de los pasos.';

create index materials_project_idx on public.materials (project_id, position);

-- ── RLS ─────────────────────────────────────────────────────────────────────
alter table public.media     enable row level security;
alter table public.materials enable row level security;

-- Media publica: visible con el contenido. Media privada: la fila solo se
-- muestra a quien podria abrir su contenido, para no filtrar ni el numero de
-- fotos de un paso de pago.
create policy "media: publica con el contenido, privada con el tramo"
  on public.media for select
  to anon, authenticated
  using (
    case
      when step_id is not null then
        case
          when is_private then (select public.can_view_step_body(step_id))
          else                 (select public.can_view_step(step_id))
        end
      else
        case
          when is_private then
            (select public.is_at_least('pro')) and (select public.can_view_project(project_id))
          else
            (select public.can_view_project(project_id))
        end
    end
  );

create policy "media: escribe el autor modelista"
  on public.media for all
  to authenticated
  using (
    owner_id = (select auth.uid())
    and (select public.is_at_least('modelista'))
  )
  with check (
    owner_id = (select auth.uid())
    and (select public.is_at_least('modelista'))
    and (
      -- Solo puede colgar media de contenido propio.
      (project_id is not null and exists (
        select 1 from public.projects p
         where p.id = media.project_id and p.author_id = (select auth.uid())
      ))
      or (step_id is not null and exists (
        select 1 from public.steps s
          join public.projects p on p.id = s.project_id
         where s.id = media.step_id and p.author_id = (select auth.uid())
      ))
    )
  );

-- materials: SOLO pro o modelista (§5). El autor ve los suyos aunque no tenga
-- el tramo (caso de downgrade, §10).
create policy "materials: solo pro o modelista"
  on public.materials for select
  to anon, authenticated
  using (
    (
      (select public.is_at_least('pro'))
      and (select public.can_view_project(project_id))
    )
    or exists (
      select 1 from public.projects p
       where p.id = materials.project_id and p.author_id = (select auth.uid())
    )
  );

create policy "materials: escribe el autor modelista"
  on public.materials for all
  to authenticated
  using (
    (select public.is_at_least('modelista'))
    and exists (
      select 1 from public.projects p
       where p.id = materials.project_id and p.author_id = (select auth.uid())
    )
  )
  with check (
    (select public.is_at_least('modelista'))
    and exists (
      select 1 from public.projects p
       where p.id = materials.project_id and p.author_id = (select auth.uid())
    )
  );
