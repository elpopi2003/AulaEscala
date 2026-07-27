-- ============================================================================
-- 20260726090200_profiles
-- Perfil publico + rol de aplicacion. Un perfil por usuario de auth.users.
-- ============================================================================

create table public.profiles (
  id                 uuid primary key references auth.users (id) on delete cascade,
  display_name       text not null check (length(btrim(display_name)) between 2 and 60),
  slug               text not null check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and length(slug) between 3 and 40),
  avatar_url         text,
  bio                text check (length(bio) <= 600),
  location           text check (length(location) <= 80),

  -- Enlaces externos del portafolio (§9 del handoff: Instagram, YouTube, Web).
  -- jsonb en vez de columnas fijas: la lista de redes cambia sin migracion.
  links              jsonb not null default '{}'::jsonb,

  -- §3.2: preferencias del usuario, usadas para personalizar el feed.
  preferred_scales   uuid[] not null default '{}',
  preferred_subjects uuid[] not null default '{}',

  -- Rol de operador. NUNCA escribible por el propio usuario: mas abajo se
  -- revoca el privilegio de columna para `authenticated`.
  role               public.app_role not null default 'user',

  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),

  constraint profiles_slug_key unique (slug),
  constraint profiles_links_is_object check (jsonb_typeof(links) = 'object')
);

comment on table public.profiles is 'Perfil publico. Legible por cualquiera; editable solo por su dueno.';
comment on column public.profiles.role is
  'Rol de aplicacion. Solo service_role puede modificarlo (privilegio de columna revocado a authenticated).';

create index profiles_slug_idx on public.profiles (slug);
-- pg_trgm para el buscador de usuarios (§4: la busqueda de usuarios es publica).
create index profiles_display_name_trgm_idx on public.profiles using gin (display_name extensions.gin_trgm_ops);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ── Alta automatica de perfil al registrarse ────────────────────────────────
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  base_slug text;
  final_slug text;
  suffix int := 0;
  raw_name text;
begin
  raw_name := coalesce(
    nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
    split_part(new.email, '@', 1)
  );

  base_slug := nullif(public.slugify(raw_name), '');
  if base_slug is null or length(base_slug) < 3 then
    base_slug := 'modelista';
  end if;
  base_slug := left(base_slug, 32);

  final_slug := base_slug;
  while exists (select 1 from public.profiles p where p.slug = final_slug) loop
    suffix := suffix + 1;
    final_slug := base_slug || '-' || suffix::text;
  end loop;

  insert into public.profiles (id, display_name, slug)
  values (new.id, left(raw_name, 60), final_slug);

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── Resolucion de rol ───────────────────────────────────────────────────────
-- SECURITY DEFINER para poder consultarse desde politicas sobre `profiles`
-- sin provocar recursion infinita de RLS.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
     where p.id = (select auth.uid())
       and p.role = 'admin'
  );
$$;

comment on function public.is_admin is
  'True si el usuario actual tiene rol admin. SECURITY DEFINER: evita la '
  'recursion de RLS al usarse en politicas sobre profiles.';

-- ── RLS ─────────────────────────────────────────────────────────────────────
alter table public.profiles enable row level security;

create policy "profiles: lectura publica"
  on public.profiles for select
  to anon, authenticated
  using (true);

create policy "profiles: alta solo del propio perfil"
  on public.profiles for insert
  to authenticated
  with check (id = (select auth.uid()));

create policy "profiles: edicion solo del propio perfil"
  on public.profiles for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Sin politica de DELETE: los perfiles se borran en cascada con auth.users.

-- ── Escalada de privilegios: allowlist de columnas ──────────────────────────
-- RLS es row-level, no column-level: la politica de UPDATE de arriba deja al
-- usuario editar CUALQUIER columna de su propia fila, incluida `role`. La
-- unica defensa real son los privilegios de columna.
--
-- OJO: un UPDATE a nivel de tabla implica todas las columnas, y revocar solo
-- unas pocas no surte efecto mientras el privilegio de tabla siga concedido.
-- Hay que revocar la tabla entera y volver a conceder la allowlist.
revoke update on public.profiles from anon, authenticated;

grant update (
  display_name,
  slug,
  avatar_url,
  bio,
  location,
  links,
  preferred_scales,
  preferred_subjects
) on public.profiles to authenticated;
