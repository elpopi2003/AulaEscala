-- ============================================================================
-- 20260726091000_notifications_and_reports
-- ============================================================================

-- ── Notificaciones — capacidad Pro (§4) ─────────────────────────────────────
-- El filtro de tramo se aplica al GENERARLAS (solo se crean para Pro+), no al
-- leerlas: §5 fija "solo el propio usuario" para el SELECT, y asi un usuario
-- que hace downgrade conserva su historial en vez de verlo desaparecer.
create table public.notifications (
  id         uuid primary key default extensions.gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  type       public.notification_type not null,
  -- Teaser-seguro por construccion (§13): titulo, autor, enlace. Nunca cuerpo.
  payload    jsonb not null default '{}'::jsonb,
  read_at    timestamptz,
  emailed_at timestamptz,
  created_at timestamptz not null default now(),

  constraint notifications_payload_is_object check (jsonb_typeof(payload) = 'object')
);

create index notifications_user_idx   on public.notifications (user_id, created_at desc);
create index notifications_unread_idx on public.notifications (user_id) where read_at is null;
-- Cola del digest de Resend.
create index notifications_pending_email_idx on public.notifications (created_at) where emailed_at is null;

alter table public.notifications enable row level security;

create policy "notifications: solo el propio usuario"
  on public.notifications for select
  to authenticated
  using (user_id = (select auth.uid()));

-- Marcar como leida es lo unico que el cliente puede escribir.
create policy "notifications: el propio usuario marca leido"
  on public.notifications for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "notifications: el propio usuario borra las suyas"
  on public.notifications for delete
  to authenticated
  using (user_id = (select auth.uid()));

-- Solo el servicio las crea (§5).
revoke insert on public.notifications from anon, authenticated;
revoke update on public.notifications from anon, authenticated;
grant  update (read_at) on public.notifications to authenticated;

-- Alta de notificacion respetando el tramo. La usan los triggers de dominio y
-- las Edge Functions.
create or replace function public.enqueue_notification(
  p_user_id uuid,
  p_type public.notification_type,
  p_payload jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_id uuid;
begin
  -- §4: las notificaciones son una capacidad Pro. Se descartan en silencio
  -- para todos los demas.
  if public.tier_rank(public.tier_of(p_user_id)) < public.tier_rank('pro') then
    return null;
  end if;

  insert into public.notifications (user_id, type, payload)
  values (p_user_id, p_type, coalesce(p_payload, '{}'::jsonb))
  returning id into new_id;

  return new_id;
end;
$$;

revoke execute on function public.enqueue_notification(uuid, public.notification_type, jsonb)
  from anon, authenticated;

-- ── Reportes — diferido en producto, la tabla nace ya (§8) ──────────────────
-- Requerido antes del lanzamiento publico: con publicacion directa (§7.1) no
-- hay filtro previo, y en la UE el reporte y la retirada de UGC entra en
-- terreno regulatorio (DSA). Confirmar con asesoria legal.
create table public.reports (
  id          uuid primary key default extensions.gen_random_uuid(),
  reporter_id uuid references public.profiles (id) on delete set null,
  target_type public.report_target_type not null,
  target_id   uuid not null,
  reason      text not null check (length(btrim(reason)) between 3 and 2000),
  status      public.report_status not null default 'open',
  resolved_by uuid references public.profiles (id) on delete set null,
  resolved_at timestamptz,
  notes       text,
  created_at  timestamptz not null default now()
);

create index reports_status_idx on public.reports (status, created_at desc);
create index reports_target_idx on public.reports (target_type, target_id);

alter table public.reports enable row level security;

create policy "reports: solo el operador los lee"
  on public.reports for select
  to authenticated
  using ((select public.is_admin()));

create policy "reports: reporta cualquier usuario autenticado"
  on public.reports for insert
  to authenticated
  with check (
    reporter_id = (select auth.uid())
    and status = 'open'
  );

create policy "reports: resuelve el operador"
  on public.reports for update
  to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));
