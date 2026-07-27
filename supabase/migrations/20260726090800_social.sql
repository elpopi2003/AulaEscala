-- ============================================================================
-- 20260726090800_social
-- Comentarios (con respuestas y me gusta), seguimientos y favoritos.
-- Requieren estar autenticado — es decir, tramo Suscriptor o superior (§4).
-- ============================================================================

create table public.comments (
  id         uuid primary key default extensions.gen_random_uuid(),
  author_id  uuid not null references public.profiles (id) on delete cascade,

  project_id uuid references public.projects (id) on delete cascade,
  step_id    uuid references public.steps (id)    on delete cascade,

  -- Respuestas anidadas (un nivel en la UI, sin limite en el modelo).
  parent_id  uuid references public.comments (id) on delete cascade,

  body       text not null check (length(btrim(body)) between 1 and 4000),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- §3.2: exactamente uno de project_id / step_id no nulo.
  constraint comments_belongs_to_one check (
    (project_id is not null)::int + (step_id is not null)::int = 1
  )
);

create index comments_project_idx on public.comments (project_id, created_at desc) where project_id is not null;
create index comments_step_idx    on public.comments (step_id, created_at desc)    where step_id is not null;
create index comments_parent_idx  on public.comments (parent_id) where parent_id is not null;
create index comments_author_idx  on public.comments (author_id);

create trigger comments_set_updated_at
  before update on public.comments
  for each row execute function public.set_updated_at();

-- ── Me gusta ────────────────────────────────────────────────────────────────
create table public.comment_likes (
  comment_id uuid not null references public.comments (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, user_id)
);

create index comment_likes_user_idx on public.comment_likes (user_id);

-- ── Seguimientos ────────────────────────────────────────────────────────────
create table public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  followee_id uuid not null references public.profiles (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (follower_id, followee_id),
  constraint follows_no_self check (follower_id <> followee_id)
);

create index follows_followee_idx on public.follows (followee_id);

-- ── Favoritos ───────────────────────────────────────────────────────────────
create table public.favorites (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  project_id uuid not null references public.projects (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, project_id)
);

create index favorites_project_idx on public.favorites (project_id);

-- ── Comentario visible = su contenido contenedor es visible ─────────────────
-- Un comentario sobre un paso es visible si los METADATOS del paso lo son:
-- comentar no es contenido de pago, y ocultarlos romperia el hilo publico.
create or replace function public.can_view_comment_target(
  p_project_id uuid,
  p_step_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p_step_id is not null then public.can_view_step(p_step_id)
    else public.can_view_project(p_project_id)
  end;
$$;

-- ── RLS ─────────────────────────────────────────────────────────────────────
alter table public.comments      enable row level security;
alter table public.comment_likes enable row level security;
alter table public.follows       enable row level security;
alter table public.favorites     enable row level security;

create policy "comments: lectura si el contenido es visible"
  on public.comments for select
  to anon, authenticated
  using ((select public.can_view_comment_target(project_id, step_id)));

-- Comentar exige autenticacion (Suscriptor+), no tramo de pago (§4).
create policy "comments: comenta cualquier usuario autenticado"
  on public.comments for insert
  to authenticated
  with check (
    author_id = (select auth.uid())
    and (select public.can_view_comment_target(project_id, step_id))
  );

create policy "comments: edita el autor"
  on public.comments for update
  to authenticated
  using (author_id = (select auth.uid()))
  with check (author_id = (select auth.uid()));

-- Borra el autor... o el operador, que necesita retirar UGC (§8, DSA).
create policy "comments: borra el autor o el operador"
  on public.comments for delete
  to authenticated
  using (author_id = (select auth.uid()) or (select public.is_admin()));

create policy "comment_likes: lectura publica"
  on public.comment_likes for select to anon, authenticated using (true);

create policy "comment_likes: gestiona el propio usuario"
  on public.comment_likes for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy "comment_likes: retira el propio usuario"
  on public.comment_likes for delete
  to authenticated
  using (user_id = (select auth.uid()));

create policy "follows: lectura publica"
  on public.follows for select to anon, authenticated using (true);

create policy "follows: sigue el propio usuario"
  on public.follows for insert
  to authenticated
  with check (follower_id = (select auth.uid()));

create policy "follows: deja de seguir el propio usuario"
  on public.follows for delete
  to authenticated
  using (follower_id = (select auth.uid()));

-- Favoritos publicos: el perfil tiene una pestana "Favoritos (N)" visible.
create policy "favorites: lectura publica"
  on public.favorites for select to anon, authenticated using (true);

create policy "favorites: guarda el propio usuario"
  on public.favorites for insert
  to authenticated
  with check (
    user_id = (select auth.uid())
    and (select public.can_view_project(project_id))
  );

create policy "favorites: quita el propio usuario"
  on public.favorites for delete
  to authenticated
  using (user_id = (select auth.uid()));
