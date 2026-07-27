-- ============================================================================
-- 20260726091400_harden_function_privileges
--
-- Postgres concede EXECUTE a PUBLIC por defecto en toda funcion nueva, y
-- Supabase expone el esquema `public` entero como /rest/v1/rpc/*. Resultado:
-- un `revoke ... from anon, authenticated` NO basta — el privilegio sigue
-- llegando por PUBLIC.
--
-- Este es el fallo que detecto el linter de seguridad. El caso grave era
-- `build_step_snapshot(uuid)`: SECURITY DEFINER, acepta cualquier id de paso y
-- devuelve titulo, miniatura y autor SALTANDOSE la RLS. Un anonimo podia
-- sacar metadatos de pasos en BORRADOR llamandola con ids al azar.
--
-- Criterio: revocar de PUBLIC en todas, y volver a conceder solo lo necesario.
--   * Predicados sobre los permisos DE QUIEN LLAMA -> publicos (no revelan
--     nada que el usuario no sepa ya de si mismo) y ademas los necesitan las
--     politicas RLS, que se evaluan con el rol que consulta.
--   * Funciones que aceptan un id AJENO y saltan RLS -> solo service_role.
--   * Funciones de trigger -> nadie. El privilegio se comprueba al crear el
--     trigger, no al dispararse.
-- ============================================================================

-- ── 1. Funciones de trigger: nunca invocables como RPC ──────────────────────
revoke execute on function public.handle_new_user()            from public, anon, authenticated;
revoke execute on function public.steps_emit_activity()        from public, anon, authenticated;
revoke execute on function public.projects_emit_activity()     from public, anon, authenticated;
revoke execute on function public.messages_touch_conversation() from public, anon, authenticated;
revoke execute on function public.activity_set_score()         from public, anon, authenticated;
revoke execute on function public.set_updated_at()             from public, anon, authenticated;
revoke execute on function public.projects_sync_publish_dates() from public, anon, authenticated;
revoke execute on function public.steps_sync_publish_dates()   from public, anon, authenticated;

-- ── 2. Saltan RLS con un id ajeno: solo el servicio ─────────────────────────
-- build_*_snapshot leen contenido sin filtrar por estado de publicacion.
-- Existen para que los triggers compongan el snapshot del feed, no para el API.
revoke execute on function public.build_step_snapshot(uuid)    from public, anon, authenticated;
revoke execute on function public.build_project_snapshot(uuid) from public, anon, authenticated;

-- tier_of() revela el tramo de OTRO usuario. Se expone solo el booleano
-- can_receive_messages(), que es lo unico que el producto necesita.
revoke execute on function public.tier_of(uuid) from public, anon, authenticated;

-- enqueue_notification() escribe en notifications saltando RLS: dejarla
-- abierta permitiria a cualquiera inundar de notificaciones a cualquier Pro.
revoke execute on function public.enqueue_notification(uuid, public.notification_type, jsonb)
  from public, anon, authenticated;

grant execute on function public.enqueue_notification(uuid, public.notification_type, jsonb)
  to service_role;
grant execute on function public.build_step_snapshot(uuid)    to service_role;
grant execute on function public.build_project_snapshot(uuid) to service_role;
grant execute on function public.tier_of(uuid)                to service_role;

-- ── 3. Predicados del propio usuario: publicos y necesarios para la RLS ─────
-- Las expresiones de una politica RLS se evaluan con el rol que ejecuta la
-- consulta, asi que anon/authenticated NECESITAN execute sobre estas o toda
-- lectura fallaria con "permission denied for function".
revoke execute on function public.user_tier()                    from public;
revoke execute on function public.is_at_least(public.subscription_tier) from public;
revoke execute on function public.tier_rank(public.subscription_tier)   from public;
revoke execute on function public.is_admin()                     from public;
revoke execute on function public.free_preview_steps()           from public;
revoke execute on function public.can_view_project(uuid)         from public;
revoke execute on function public.can_view_step(uuid)            from public;
revoke execute on function public.can_view_step_body(uuid)       from public;
revoke execute on function public.can_view_comment_target(uuid, uuid) from public;
revoke execute on function public.is_conversation_participant(uuid)   from public;

grant execute on function public.user_tier()                     to anon, authenticated, service_role;
grant execute on function public.is_at_least(public.subscription_tier) to anon, authenticated, service_role;
grant execute on function public.tier_rank(public.subscription_tier)   to anon, authenticated, service_role;
grant execute on function public.is_admin()                      to anon, authenticated, service_role;
grant execute on function public.free_preview_steps()            to anon, authenticated, service_role;
grant execute on function public.can_view_project(uuid)          to anon, authenticated, service_role;
grant execute on function public.can_view_step(uuid)             to anon, authenticated, service_role;
grant execute on function public.can_view_step_body(uuid)        to anon, authenticated, service_role;
grant execute on function public.can_view_comment_target(uuid, uuid) to anon, authenticated, service_role;
grant execute on function public.is_conversation_participant(uuid)   to anon, authenticated, service_role;

-- ── 4. Mensajeria: autenticados, nunca anonimos ─────────────────────────────
revoke execute on function public.can_receive_messages(uuid) from public, anon;
revoke execute on function public.search_message_recipients(text, int) from public, anon;
grant  execute on function public.can_receive_messages(uuid) to authenticated, service_role;
grant  execute on function public.search_message_recipients(text, int) to authenticated, service_role;

-- ── 5. Busqueda y autoria: SECURITY INVOKER, la RLS ya las filtra ───────────
revoke execute on function public.search_public(text, int)      from public;
revoke execute on function public.search_step_bodies(text, int) from public;
revoke execute on function public.suggest_similar_techniques(text, real, int) from public;
revoke execute on function public.slugify(text) from public;

grant execute on function public.search_public(text, int)       to anon, authenticated, service_role;
-- Se concede tambien a anon a proposito: no hace falta comprobar el tramo
-- aqui, porque la RLS de step_bodies devuelve 0 filas a quien no es Pro (§4).
grant execute on function public.search_step_bodies(text, int)  to anon, authenticated, service_role;
grant execute on function public.suggest_similar_techniques(text, real, int) to authenticated, service_role;
grant execute on function public.slugify(text) to anon, authenticated, service_role;

revoke execute on function public.create_step(uuid, text, text, text, int, uuid[], text, public.content_status, int) from public, anon;
revoke execute on function public.update_step(uuid, text, text, text, int, uuid[], text, public.content_status) from public, anon;
revoke execute on function public.reorder_steps(uuid, uuid[]) from public, anon;

grant execute on function public.create_step(uuid, text, text, text, int, uuid[], text, public.content_status, int) to authenticated, service_role;
grant execute on function public.update_step(uuid, text, text, text, int, uuid[], text, public.content_status) to authenticated, service_role;
grant execute on function public.reorder_steps(uuid, uuid[]) to authenticated, service_role;

-- ── 6. Storage: un bucket publico no necesita politica de listado ───────────
-- Los objetos de un bucket publico se sirven por su URL sin pasar por RLS. La
-- politica amplia de SELECT solo habilitaba `storage.list()`, es decir,
-- enumerar TODOS los ficheros del bucket. El catalogo de imagenes se lee de la
-- tabla `media`, no listando el bucket.
drop policy if exists "media-public: lectura de todos" on storage.objects;
