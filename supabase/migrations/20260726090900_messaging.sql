-- ============================================================================
-- 20260726090900_messaging
-- Mensajeria privada — capacidad Pro (§4).
--
-- Regla dificil de §4: el Suscriptor queda fuera EN AMBOS SENTIDOS. Ni envia
-- ni recibe, y un Pro NO PUEDE contactarle. No basta con rechazar el envio:
-- los suscriptores tampoco aparecen en el selector de destinatarios, asi que
-- la base de datos expone ademas el predicado que filtra esa busqueda.
-- ============================================================================

create table public.conversations (
  id         uuid primary key default extensions.gen_random_uuid(),
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now()
);

create table public.conversation_participants (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  user_id         uuid not null references public.profiles (id)      on delete cascade,
  joined_at       timestamptz not null default now(),
  last_read_at    timestamptz,
  primary key (conversation_id, user_id)
);

create index conversation_participants_user_idx on public.conversation_participants (user_id);

create table public.messages (
  id              uuid primary key default extensions.gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id       uuid not null references public.profiles (id)      on delete cascade,
  body            text not null check (length(btrim(body)) between 1 and 8000),
  created_at      timestamptz not null default now(),
  read_at         timestamptz
);

create index messages_conversation_idx on public.messages (conversation_id, created_at desc);
create index messages_sender_idx       on public.messages (sender_id);

-- ── Predicados de mensajeria ────────────────────────────────────────────────

-- Tramo de OTRO usuario. SECURITY DEFINER porque subscriptions solo es
-- legible por su dueno. Se expone unicamente como el booleano de abajo.
create or replace function public.tier_of(p_user_id uuid)
returns public.subscription_tier
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (
      select s.tier
        from public.subscriptions s
       where s.user_id = p_user_id
         and s.status in ('active', 'trialing')
         and (s.current_period_end is null or s.current_period_end > now())
       limit 1
    ),
    'subscriber'::public.subscription_tier
  );
$$;

revoke execute on function public.tier_of(uuid) from anon, authenticated;

-- Este SI es publico para authenticated: es lo que necesita el selector de
-- destinatarios para no ofrecer a quien no puede recibir.
create or replace function public.can_receive_messages(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.tier_rank(public.tier_of(p_user_id)) >= public.tier_rank('pro');
$$;

comment on function public.can_receive_messages is
  '§4: un Suscriptor no recibe mensajes. Filtra el selector de destinatarios '
  'ademas de bloquear el alta de participantes.';

-- Selector de destinatarios: solo devuelve perfiles que pueden recibir.
create or replace function public.search_message_recipients(
  query text,
  max_results int default 10
)
returns table (id uuid, display_name text, slug text, avatar_url text)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, p.display_name, p.slug, p.avatar_url
    from public.profiles p
   where (select public.is_at_least('pro'))          -- quien busca tambien ha de ser Pro
     and p.id <> (select auth.uid())
     and public.can_receive_messages(p.id)
     and (
       query is null or btrim(query) = ''
       or p.display_name ilike '%' || query || '%'
       or p.slug ilike '%' || query || '%'
     )
   order by extensions.similarity(p.display_name, coalesce(query, '')) desc, p.display_name
   limit greatest(1, least(max_results, 25));
$$;

-- Participacion del usuario actual. SECURITY DEFINER para cortar la recursion
-- entre las politicas de conversations y conversation_participants.
create or replace function public.is_conversation_participant(p_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.conversation_participants cp
     where cp.conversation_id = p_conversation_id
       and cp.user_id = (select auth.uid())
  );
$$;

-- Mantener last_message_at para ordenar la bandeja sin agregados.
create or replace function public.messages_touch_conversation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.conversations
     set last_message_at = new.created_at
   where id = new.conversation_id;
  return new;
end;
$$;

create trigger messages_touch_conversation
  after insert on public.messages
  for each row execute function public.messages_touch_conversation();

-- ── RLS ─────────────────────────────────────────────────────────────────────
alter table public.conversations              enable row level security;
alter table public.conversation_participants  enable row level security;
alter table public.messages                   enable row level security;

-- Participante Y tramo pro/modelista, en todas las tablas (§5).
create policy "conversations: solo participantes pro"
  on public.conversations for select
  to authenticated
  using (
    (select public.is_at_least('pro'))
    and (select public.is_conversation_participant(id))
  );

create policy "conversations: abre un pro"
  on public.conversations for insert
  to authenticated
  with check (
    (select public.is_at_least('pro'))
    and created_by = (select auth.uid())
  );

create policy "conversation_participants: solo participantes pro"
  on public.conversation_participants for select
  to authenticated
  using (
    (select public.is_at_least('pro'))
    and (select public.is_conversation_participant(conversation_id))
  );

-- Alta de participante: el que invita ha de ser Pro, y el invitado tambien.
-- Aqui es donde se impide materialmente que un Pro contacte a un Suscriptor.
create policy "conversation_participants: alta solo entre pros"
  on public.conversation_participants for insert
  to authenticated
  with check (
    (select public.is_at_least('pro'))
    and public.can_receive_messages(user_id)
    and (
      user_id = (select auth.uid())
      or (select public.is_conversation_participant(conversation_id))
      or exists (
        select 1 from public.conversations c
         where c.id = conversation_participants.conversation_id
           and c.created_by = (select auth.uid())
      )
    )
  );

create policy "conversation_participants: actualiza su propia lectura"
  on public.conversation_participants for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "conversation_participants: se sale el propio usuario"
  on public.conversation_participants for delete
  to authenticated
  using (user_id = (select auth.uid()));

create policy "messages: solo participantes pro"
  on public.messages for select
  to authenticated
  using (
    (select public.is_at_least('pro'))
    and (select public.is_conversation_participant(conversation_id))
  );

create policy "messages: envia un participante pro"
  on public.messages for insert
  to authenticated
  with check (
    (select public.is_at_least('pro'))
    and sender_id = (select auth.uid())
    and (select public.is_conversation_participant(conversation_id))
  );

create policy "messages: edita el remitente"
  on public.messages for update
  to authenticated
  using (sender_id = (select auth.uid()))
  with check (sender_id = (select auth.uid()));

create policy "messages: borra el remitente"
  on public.messages for delete
  to authenticated
  using (sender_id = (select auth.uid()));

-- Realtime para la mensajeria (§8: Supabase Realtime abarata mucho esta pieza).
-- Realtime respeta RLS, asi que un suscriptor no recibe nada por este canal.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1 from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = 'messages'
    ) then
      alter publication supabase_realtime add table public.messages;
    end if;
  end if;
end
$$;
