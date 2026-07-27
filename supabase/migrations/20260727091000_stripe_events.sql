-- ============================================================================
-- 20260727091000_stripe_events
--
-- Registro de eventos de Stripe ya procesados.
--
-- Stripe garantiza entrega "al menos una vez": reintenta ante cualquier fallo
-- o timeout, asi que el MISMO evento llega varias veces. El webhook es lo
-- unico en todo el sistema que puede conceder un tramo de pago (§5), de modo
-- que tiene que ser idempotente por construccion y no por casualidad.
--
-- El PK sobre event_id convierte el "ya procesado" en una condicion de carrera
-- que resuelve Postgres: dos entregas simultaneas compiten por el INSERT y
-- solo una gana.
-- ============================================================================

create table public.stripe_events (
  event_id     text primary key,
  type         text not null,
  processed_at timestamptz not null default now(),
  payload      jsonb
);

comment on table public.stripe_events is
  'Deduplicacion de webhooks de Stripe. Sin RLS de lectura para nadie: solo '
  'service_role la toca.';

create index stripe_events_processed_idx on public.stripe_events (processed_at desc);

alter table public.stripe_events enable row level security;

-- Sin politicas: ni anon ni authenticated tienen nada que hacer aqui.
revoke all on public.stripe_events from anon, authenticated;

-- ── Aplicacion del tramo ────────────────────────────────────────────────────
-- Toda la escritura de `subscriptions` pasa por aqui. Concentrarla en una
-- funcion evita que el dia de manana un segundo camino (un script, otra
-- funcion) escriba el tramo con reglas ligeramente distintas.
create or replace function public.apply_stripe_subscription(
  p_user_id                uuid,
  p_tier                   public.subscription_tier,
  p_status                 public.subscription_status,
  p_stripe_customer_id     text,
  p_stripe_subscription_id text,
  p_current_period_end     timestamptz,
  p_cancel_at_period_end   boolean default false
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.subscriptions as s (
    user_id, tier, status, stripe_customer_id, stripe_subscription_id,
    current_period_end, cancel_at_period_end
  )
  values (
    p_user_id, p_tier, p_status, p_stripe_customer_id, p_stripe_subscription_id,
    p_current_period_end, coalesce(p_cancel_at_period_end, false)
  )
  on conflict (user_id) do update
     set tier                   = excluded.tier,
         status                 = excluded.status,
         stripe_customer_id     = coalesce(excluded.stripe_customer_id, s.stripe_customer_id),
         stripe_subscription_id = excluded.stripe_subscription_id,
         current_period_end     = excluded.current_period_end,
         cancel_at_period_end   = excluded.cancel_at_period_end;
end;
$$;

comment on function public.apply_stripe_subscription is
  'Unico punto de escritura del tramo. Lo llama el webhook de Stripe con '
  'service_role. §5: el tramo lo escribe solo el webhook, nunca el cliente.';

revoke execute on function public.apply_stripe_subscription(
  uuid, public.subscription_tier, public.subscription_status, text, text, timestamptz, boolean
) from public, anon, authenticated;

grant execute on function public.apply_stripe_subscription(
  uuid, public.subscription_tier, public.subscription_status, text, text, timestamptz, boolean
) to service_role;
