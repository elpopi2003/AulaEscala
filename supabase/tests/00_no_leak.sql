-- ============================================================================
-- TEST DE NO-FUGA — OBLIGATORIO EN CI (§13)
--
-- "Verificar que anonimo y Suscriptor NO obtienen el cuerpo de un paso ni un
--  material por NINGUNA via (consulta directa, feed, busqueda, Storage).
--  Bloquea el merge."
--
-- Con `free_preview_steps = 2` (ADR 0004) la frontera NO es "cero cuerpos":
-- los pasos 1 y 2 son teaser publico a proposito. Lo que este fichero prueba
-- es que la frontera cae EXACTAMENTE donde debe — el paso 3 en adelante — y
-- que no se filtra ni por consulta, ni por el feed, ni por la busqueda, ni por
-- Storage.
--
-- Si falla, hay contenido de pago accesible gratis. No se mergea.
-- ============================================================================

begin;

create extension if not exists pgtap with schema extensions;

select plan(30);

-- ── Escenario ───────────────────────────────────────────────────────────────
insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                        email_confirmed_at, created_at, updated_at,
                        raw_app_meta_data, raw_user_meta_data)
values
 ('11111111-1111-1111-1111-111111111111','00000000-0000-0000-0000-000000000000','authenticated','authenticated','autor@test.local','x',now(),now(),now(),'{}','{"display_name":"Marta Vidal"}'),
 ('22222222-2222-2222-2222-222222222222','00000000-0000-0000-0000-000000000000','authenticated','authenticated','suscriptor@test.local','x',now(),now(),now(),'{}','{"display_name":"Suscriptor Gratis"}'),
 ('33333333-3333-3333-3333-333333333333','00000000-0000-0000-0000-000000000000','authenticated','authenticated','pro@test.local','x',now(),now(),now(),'{}','{"display_name":"Usuario Pro"}');

insert into public.subscriptions (user_id, tier, status) values
 ('11111111-1111-1111-1111-111111111111','modelista','active'),
 ('33333333-3333-3333-3333-333333333333','pro','active');
-- El suscriptor NO tiene fila: user_tier() debe resolverlo a 'subscriber'.

insert into public.projects (id, author_id, title, slug, status, build_status)
values ('aaaaaaaa-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111',
        'Panther Ausf. G','panther-ausf-g','published','wip');

insert into public.steps (id, project_id, position, title, status) values
 ('bbbbbbbb-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001',1,'Montaje del casco','published'),
 ('bbbbbbbb-0000-0000-0000-000000000002','aaaaaaaa-0000-0000-0000-000000000001',2,'Imprimacion y preshading','published'),
 ('bbbbbbbb-0000-0000-0000-000000000003','aaaaaaaa-0000-0000-0000-000000000001',3,'Chipping del casco superior','published'),
 ('bbbbbbbb-0000-0000-0000-000000000004','aaaaaaaa-0000-0000-0000-000000000001',4,'Lavados con oleos','published');

-- Cada cuerpo lleva una palabra unica e inventada, para poder afirmar por cual
-- de ellos entra (o no entra) la busqueda. TEASER* = abierto, MURO* = de pago.
insert into public.step_bodies (step_id, body, tip) values
 ('bbbbbbbb-0000-0000-0000-000000000001','TEASERALFA montaje por subconjuntos','pista'),
 ('bbbbbbbb-0000-0000-0000-000000000002','TEASERBETA imprimacion en negro','pista'),
 ('bbbbbbbb-0000-0000-0000-000000000003','MUROGAMMA chipping con esponja','pista'),
 ('bbbbbbbb-0000-0000-0000-000000000004','MURODELTA lavados con oleo de oxido','pista');

insert into public.materials (project_id, storage_path, filename)
values ('aaaaaaaa-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111/projects/p1/pinturas.pdf','Lista de pinturas.pdf');

-- Media privada de un paso de PAGO (el 3) y de uno de TEASER (el 1).
insert into public.media (owner_id, step_id, storage_path, is_private) values
 ('11111111-1111-1111-1111-111111111111','bbbbbbbb-0000-0000-0000-000000000003',
  '11111111-1111-1111-1111-111111111111/steps/s3/proceso.jpg', true),
 ('11111111-1111-1111-1111-111111111111','bbbbbbbb-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111/steps/s1/proceso.jpg', true);

-- El test entero cuelga de este valor. Si alguien lo cambia, estas
-- expectativas dejan de valer y hay que revisarlas A PROPOSITO — nunca
-- aflojarlas para que el test pase. Ver ADR 0004.
select is((select free_preview_steps from public.app_config), 2,
          'app_config.free_preview_steps vale 2 (ADR 0004)');

-- ════════════════════════════════════════════════════════════════════════════
-- 1. ANONIMO
-- ════════════════════════════════════════════════════════════════════════════
set local role anon;
select set_config('request.jwt.claims', '', true);

select is((select count(*)::int from public.step_bodies), 2,
          'ANONIMO: ve exactamente los 2 cuerpos del teaser, ni uno mas');
select ok((select public.can_view_step_body('bbbbbbbb-0000-0000-0000-000000000001')),
          'ANONIMO: el paso 1 esta abierto');
select ok((select public.can_view_step_body('bbbbbbbb-0000-0000-0000-000000000002')),
          'ANONIMO: el paso 2 esta abierto');
select ok(not (select public.can_view_step_body('bbbbbbbb-0000-0000-0000-000000000003')),
          'ANONIMO: el paso 3 esta TRAS EL MURO');
select ok(not (select public.can_view_step_body('bbbbbbbb-0000-0000-0000-000000000004')),
          'ANONIMO: el paso 4 esta TRAS EL MURO');

-- La frontera, vista desde la busqueda.
select is((select count(*)::int from public.search_step_bodies('TEASERALFA')), 1,
          'ANONIMO: la busqueda encuentra el cuerpo del teaser');
select is((select count(*)::int from public.search_step_bodies('MUROGAMMA')), 0,
          'ANONIMO: la busqueda NO alcanza el cuerpo de pago');
select is((select count(*)::int from public.search_step_bodies('MURODELTA')), 0,
          'ANONIMO: ni siquiera un fragmento de ts_headline del cuerpo de pago');

-- Los materiales NO tienen excepcion de teaser: son de pago siempre (§4).
select is((select count(*)::int from public.materials), 0,
          'ANONIMO: los materiales no tienen teaser, son Pro sin excepcion');

-- Storage: la media privada de un paso de pago no se enumera.
select is((select count(*)::int from public.media
            where is_private and step_id = 'bbbbbbbb-0000-0000-0000-000000000003'), 0,
          'ANONIMO: no ve la media privada de un paso de pago');
select is((select count(*)::int from public.subscriptions), 0,
          'ANONIMO: no ve suscripciones');

-- El feed llega entero, pero solo con metadatos.
select is((select count(*)::int from public.steps), 4,
          'ANONIMO: los METADATOS de los 4 pasos son publicos');
select ok((select bool_and(snapshot::text not ilike '%MURO%') from public.activity),
          'ANONIMO: ningun snapshot del feed contiene un cuerpo de pago');
select ok((select bool_and(snapshot::text not ilike '%TEASER%') from public.activity),
          'ANONIMO: el snapshot tampoco lleva el cuerpo abierto (solo metadatos)');
select is((select count(*)::int from public.activity a
            where a.step_id = 'bbbbbbbb-0000-0000-0000-000000000003'
              and (a.snapshot->>'is_paywalled')::boolean), 1,
          'ANONIMO: el evento del paso 3 viene marcado is_paywalled');
select is((select count(*)::int from public.activity a
            where a.step_id = 'bbbbbbbb-0000-0000-0000-000000000001'
              and (a.snapshot->>'is_paywalled')::boolean), 0,
          'ANONIMO: el evento del paso 1 NO viene marcado is_paywalled');

reset role;

-- ════════════════════════════════════════════════════════════════════════════
-- 2. SUSCRIPTOR (gratuito, autenticado) — el caso que mas se olvida
-- ════════════════════════════════════════════════════════════════════════════
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', true);

select is((select public.user_tier()), 'subscriber'::public.subscription_tier,
          'SUSCRIPTOR: sin fila en subscriptions, el tramo resuelve a subscriber');
select is((select count(*)::int from public.step_bodies), 2,
          'SUSCRIPTOR: mismos 2 cuerpos que el anonimo, ni uno mas');
select ok(not (select public.can_view_step_body('bbbbbbbb-0000-0000-0000-000000000003')),
          'SUSCRIPTOR: el paso 3 sigue tras el muro');
select is((select count(*)::int from public.search_step_bodies('MUROGAMMA')), 0,
          'SUSCRIPTOR: la busqueda no alcanza el cuerpo de pago');
select is((select count(*)::int from public.materials), 0,
          'SUSCRIPTOR: no ve materiales');
select is((select count(*)::int from public.media
            where is_private and step_id = 'bbbbbbbb-0000-0000-0000-000000000003'), 0,
          'SUSCRIPTOR: no ve la media privada de un paso de pago');
select is((select count(*)::int from public.messages), 0,
          'SUSCRIPTOR: fuera de la mensajeria (§4)');

reset role;

-- ════════════════════════════════════════════════════════════════════════════
-- 3. PRO — si esto falla, el muro esta roto al reves: se cobra y no se sirve
-- ════════════════════════════════════════════════════════════════════════════
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}', true);

select is((select count(*)::int from public.step_bodies), 4,
          'PRO: ve los CUATRO cuerpos, teaser y pago');
select is((select count(*)::int from public.search_step_bodies('MUROGAMMA')), 1,
          'PRO: la busqueda dentro del cuerpo de pago funciona');
select is((select count(*)::int from public.materials), 1,
          'PRO: ve los materiales descargables');
select is((select count(*)::int from public.media where is_private), 2,
          'PRO: ve toda la media privada');
select ok((select public.is_at_least('pro')), 'PRO: is_at_least(pro)');
select ok(not (select public.is_at_least('modelista')),
          'PRO: NO alcanza el tramo modelista');

reset role;

-- ════════════════════════════════════════════════════════════════════════════
-- 4. MODELISTA — §4: los tramos no anidan solos, pero is_at_least si los anida
-- ════════════════════════════════════════════════════════════════════════════
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);

select ok((select public.is_at_least('pro')),
          'MODELISTA: hereda todo lo que autoriza a Pro (§4)');

reset role;

select * from finish();
rollback;
