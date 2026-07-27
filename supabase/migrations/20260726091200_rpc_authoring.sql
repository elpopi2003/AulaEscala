-- ============================================================================
-- 20260726091200_rpc_authoring
-- Operaciones de autoria que tocan varias tablas (§9).
--
-- TODAS son SECURITY INVOKER (el modo por defecto): se ejecutan con los
-- privilegios de quien llama, asi que la RLS sigue siendo la frontera de
-- seguridad (§13). Un SECURITY DEFINER aqui convertiria cada RPC en un
-- agujero que saltaria la matriz de acceso.
-- ============================================================================

-- Crear un paso escribe DOS tablas (steps + step_bodies). Encapsulado en una
-- funcion transaccional para que no pueda quedar un paso sin cuerpo (§9).
create or replace function public.create_step(
  p_project_id       uuid,
  p_title            text,
  p_body             text default null,
  p_tip              text default null,
  p_duration_minutes int default null,
  p_technique_ids    uuid[] default '{}',
  p_thumb_url        text default null,
  p_status           public.content_status default 'draft',
  p_position         int default null
)
returns uuid
language plpgsql
set search_path = ''
as $$
declare
  new_step_id uuid;
  target_position int;
begin
  select coalesce(p_position, coalesce(max(s.position), 0) + 1)
    into target_position
    from public.steps s
   where s.project_id = p_project_id;

  -- El INSERT lo filtra la politica "steps: escribe el autor modelista".
  insert into public.steps (project_id, position, title, thumb_url, duration_minutes, status)
  values (p_project_id, target_position, p_title, p_thumb_url, p_duration_minutes, p_status)
  returning id into new_step_id;

  insert into public.step_bodies (step_id, body, tip)
  values (new_step_id, p_body, p_tip);

  if p_technique_ids is not null and array_length(p_technique_ids, 1) > 0 then
    insert into public.step_techniques (step_id, technique_id)
    select new_step_id, unnest(p_technique_ids)
    on conflict do nothing;
  end if;

  return new_step_id;
end;
$$;

create or replace function public.update_step(
  p_step_id          uuid,
  p_title            text default null,
  p_body             text default null,
  p_tip              text default null,
  p_duration_minutes int default null,
  p_technique_ids    uuid[] default null,
  p_thumb_url        text default null,
  p_status           public.content_status default null
)
returns void
language plpgsql
set search_path = ''
as $$
begin
  update public.steps s
     set title            = coalesce(p_title, s.title),
         thumb_url        = coalesce(p_thumb_url, s.thumb_url),
         duration_minutes = coalesce(p_duration_minutes, s.duration_minutes),
         status           = coalesce(p_status, s.status)
   where s.id = p_step_id;

  if not found then
    raise exception 'Paso no encontrado o sin permiso de edicion'
      using errcode = 'insufficient_privilege';
  end if;

  insert into public.step_bodies (step_id, body, tip)
  values (p_step_id, p_body, p_tip)
  on conflict (step_id) do update
     set body = coalesce(excluded.body, public.step_bodies.body),
         tip  = coalesce(excluded.tip,  public.step_bodies.tip);

  -- null = "no tocar las tecnicas"; '{}' = "quitar todas".
  if p_technique_ids is not null then
    delete from public.step_techniques st
     where st.step_id = p_step_id
       and not (st.technique_id = any (p_technique_ids));

    insert into public.step_techniques (step_id, technique_id)
    select p_step_id, unnest(p_technique_ids)
    on conflict do nothing;
  end if;
end;
$$;

-- Reordenar por drag & drop (§9). Reasigna `position` segun el orden del
-- array. Funciona en una sola sentencia gracias a que
-- steps_project_position_key es DEFERRABLE INITIALLY DEFERRED: las colisiones
-- intermedias no se validan hasta el COMMIT.
create or replace function public.reorder_steps(
  p_project_id uuid,
  p_step_ids   uuid[]
)
returns void
language plpgsql
set search_path = ''
as $$
declare
  affected int;
begin
  update public.steps s
     set position = ord.new_position
    from (
      select id, row_number() over () as new_position
        from unnest(p_step_ids) as id
    ) ord
   where s.id = ord.id
     and s.project_id = p_project_id;

  get diagnostics affected = row_count;

  if affected <> coalesce(array_length(p_step_ids, 1), 0) then
    raise exception 'El reordenado no coincide con los pasos del proyecto (% de %)',
      affected, coalesce(array_length(p_step_ids, 1), 0)
      using errcode = 'check_violation';
  end if;
end;
$$;

comment on function public.reorder_steps is
  'Reordena los pasos segun el orden del array. Requiere que la restriccion '
  'unique (project_id, position) sea DEFERRABLE.';

-- ── Busqueda ────────────────────────────────────────────────────────────────

-- Busqueda PUBLICA (§4: disponible en todos los tramos, incluido anonimo).
-- Devuelve solo metadatos: titulos de proyecto y de paso, tecnicas y usuarios.
-- Nunca cuerpo — el cuerpo ni siquiera esta en estas tablas (§3.1).
create or replace function public.search_public(
  query      text,
  max_results int default 30
)
returns table (
  kind        text,
  id          uuid,
  title       text,
  slug        text,
  thumb_url   text,
  project_id  uuid,
  rank        real
)
language sql
stable
set search_path = ''
as $$
  with q as (
    select websearch_to_tsquery('public.es_unaccent', coalesce(query, '')) as ts
  )
  select * from (
    select 'project'::text, p.id, p.title, p.slug, p.cover_url, p.id,
           ts_rank(p.search_vector, q.ts)
      from public.projects p, q
     where p.search_vector @@ q.ts

    union all

    select 'step'::text, s.id, s.title, null::text, s.thumb_url, s.project_id,
           ts_rank(s.search_vector, q.ts)
      from public.steps s, q
     where s.search_vector @@ q.ts

    union all

    select 'technique'::text, t.id, t.name, t.slug, null::text, null::uuid,
           ts_rank(t.search_vector, q.ts)
      from public.techniques t, q
     where t.search_vector @@ q.ts
       and t.moderation_status <> 'merged'

    union all

    select 'profile'::text, pr.id, pr.display_name, pr.slug, pr.avatar_url, null::uuid,
           extensions.similarity(pr.display_name, coalesce(query, ''))::real
      from public.profiles pr
     where coalesce(query, '') <> ''
       and pr.display_name ilike '%' || query || '%'
  ) r(kind, id, title, slug, thumb_url, project_id, rank)
  order by rank desc
  limit greatest(1, least(max_results, 100));
$$;

comment on function public.search_public is
  'Busqueda publica sobre METADATOS. SECURITY INVOKER: la RLS de cada tabla '
  'filtra lo no publicado. Es motor de conversion — devuelve el titulo del '
  'paso como teaser (§2).';

-- Busqueda DENTRO DEL CUERPO — capacidad Pro (§4).
-- No lleva ningun chequeo de tramo escrito a mano: consulta step_bodies, y la
-- politica de esa tabla ya deja fuera a anonimos y suscriptores. El resultado
-- para un no-Pro es, simplemente, vacio.
create or replace function public.search_step_bodies(
  query       text,
  max_results int default 30
)
returns table (
  step_id    uuid,
  step_title text,
  project_id uuid,
  headline   text,
  rank       real
)
language sql
stable
set search_path = ''
as $$
  with q as (
    select websearch_to_tsquery('public.es_unaccent', coalesce(query, '')) as ts
  )
  select sb.step_id,
         s.title,
         s.project_id,
         ts_headline('public.es_unaccent', sb.body, q.ts,
                     'MaxFragments=2, MinWords=8, MaxWords=22'),
         ts_rank(sb.search_vector, q.ts)
    from public.step_bodies sb
    join public.steps s on s.id = sb.step_id, q
   where sb.search_vector @@ q.ts
   order by ts_rank(sb.search_vector, q.ts) desc
   limit greatest(1, least(max_results, 100));
$$;

comment on function public.search_step_bodies is
  'Busqueda dentro del cuerpo de los pasos — solo Pro/Modelista (§4). El '
  'gating NO esta aqui: lo impone la RLS de step_bodies. Un no-Pro recibe 0 '
  'filas, nunca un fragmento.';
