-- ============================================================================
-- 20260726090300_subscriptions_and_tier
-- Suscripciones (escritas SOLO por el webhook de Stripe) y resolucion del
-- tramo del usuario. Es la pieza de la que cuelga toda la matriz de acceso §5.
-- ============================================================================

create table public.subscriptions (
  user_id                uuid primary key references public.profiles (id) on delete cascade,
  tier                   public.subscription_tier   not null default 'subscriber',
  status                 public.subscription_status not null default 'active',
  stripe_customer_id     text,
  stripe_subscription_id text,
  current_period_end     timestamptz,
  cancel_at_period_end   boolean not null default false,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),

  constraint subscriptions_stripe_customer_key     unique (stripe_customer_id),
  constraint subscriptions_stripe_subscription_key unique (stripe_subscription_id)
);

comment on table public.subscriptions is
  'Tramo de pago por usuario. Escrita EXCLUSIVAMENTE por el webhook de Stripe '
  'con service_role (§5): no existe ninguna politica de escritura, asi que '
  'ningun cliente puede otorgarse un tramo.';

create index subscriptions_stripe_customer_idx on public.subscriptions (stripe_customer_id);

create trigger subscriptions_set_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();

-- ── Resolucion del tramo (§5) ───────────────────────────────────────────────
-- Decidido: siempre fresca (se lee la tabla), no via custom claims del JWT.
-- Un claim se queda obsoleto al cambiar la suscripcion y obligaria a forzar
-- el refresh del token.
create or replace function public.user_tier()
returns public.subscription_tier
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when (select auth.uid()) is null then null
    else coalesce(
      (
        select s.tier
          from public.subscriptions s
         where s.user_id = (select auth.uid())
           -- Solo una suscripcion viva otorga tramo de pago. `past_due`,
           -- `canceled`, `unpaid`... degradan a suscriptor gratuito.
           and s.status in ('active', 'trialing')
           and (s.current_period_end is null or s.current_period_end > now())
         limit 1
      ),
      'subscriber'::public.subscription_tier
    )
  end;
$$;

comment on function public.user_tier is
  'Tramo efectivo del usuario actual. NULL si es anonimo; `subscriber` si esta '
  'autenticado sin suscripcion de pago viva.';

-- Jerarquia de tramos. §4: "los tramos no anidan solos"; se resuelve dando a
-- cada uno un rango numerico y comparando, de forma que toda politica que
-- autorice a `pro` autoriza automaticamente a `modelista`.
create or replace function public.tier_rank(t public.subscription_tier)
returns int
language sql
immutable
parallel safe
set search_path = ''
as $$
  select case t
    when 'subscriber' then 1
    when 'pro'        then 2
    when 'modelista'  then 3
    else 0                    -- anonimo (NULL)
  end;
$$;

create or replace function public.is_at_least(min_tier public.subscription_tier)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.tier_rank(public.user_tier()) >= public.tier_rank(min_tier);
$$;

comment on function public.is_at_least is
  'Predicado de tramo usado por las politicas RLS. is_at_least(''pro'') es '
  'cierto tambien para modelista — §4, los tramos no anidan solos. '
  'Usar SIEMPRE envuelto: (select public.is_at_least(''pro'')) para que '
  'Postgres lo evalue una vez como InitPlan y no una vez por fila.';

-- ── RLS ─────────────────────────────────────────────────────────────────────
alter table public.subscriptions enable row level security;

create policy "subscriptions: el usuario lee la suya"
  on public.subscriptions for select
  to authenticated
  using (user_id = (select auth.uid()));

-- SIN politicas de INSERT/UPDATE/DELETE — deliberado.
-- El tramo lo escribe unicamente el webhook de Stripe con service_role, que
-- salta RLS. Cualquier politica de escritura aqui seria una via para que un
-- cliente se autoconcediera Pro. §12.3
revoke insert, update, delete on public.subscriptions from anon, authenticated;
