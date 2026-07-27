-- ============================================================================
-- TEST DE NO-FUGA — OBLIGATORIO EN CI (§13)
--
-- "Verificar que anonimo y Suscriptor NO obtienen el cuerpo de un paso ni un
--  material por NINGUNA via (consulta directa, feed, busqueda, Storage).
--  Bloquea el merge."
--
-- Si este fichero falla, hay contenido de pago accesible gratis. No se
-- mergea. No se despliega. Se arregla.
-- ============================================================================

begin;

create extension if not exists pgtap with schema extensions;

select plan(24);

-- ── Escenario ───────────────────────────────────────────────────────────────
-- Se monta como propietario de las tablas, que salta RLS a proposito.
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
 ('bbbbbbbb-0000-0000-0000-000000000003','aaaaaaaa-0000-0000-0000-000000000001',3,'Chipping del casco superior','published');

insert into public.step_bodies (step_id, body, tip) values
 ('bbbbbbbb-0000-0000-0000-000000000001','SECRETO diluye el oleo de oxido con blanco titanio','pista'),
 ('bbbbbbbb-0000-0000-0000-000000000002','SECRETO imprimo con negro y levanto con gris cenital','pista'),
 ('bbbbbbbb-0000-0000-0000-000000000003','SECRETO chipping con esponja en bordes de escotilla','pista');

insert into public.materials (project_id, storage_path, filename)
values ('aaaaaaaa-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111/projects/p1/pinturas.pdf','Lista de pinturas.pdf');

insert into public.media (owner_id, step_id, storage_path, is_private)
values ('11111111-1111-1111-1111-111111111111','bbbbbbbb-0000-0000-0000-000000000003',
        '11111111-1111-1111-1111-111111111111/steps/s3/proceso.jpg', true);

-- El teaser gratuito arranca en 0 (ADR 0004). El test asume ese valor: si
-- alguien lo sube, estas expectativas cambian a proposito y hay que revisarlas.
select is((select free_preview_steps from public.app_config), 0,
          'app_config.free_preview_steps sigue en 0 (fallar cerrado)');

-- ════════════════════════════════════════════════════════════════════════════
-- 1. ANONIMO
-- ════════════════════════════════════════════════════════════════════════════
set local role anon;
select set_config('request.jwt.claims', '', true);

select is((select count(*)::int from public.step_bodies), 0,
          'ANONIMO: consulta directa a step_bodies devuelve 0 filas');
select is((select count(*)::int from public.materials), 0,
          'ANONIMO: consulta directa a materials devuelve 0 filas');
select is((select count(*)::int from public.search_step_bodies('titanio')), 0,
          'ANONIMO: la busqueda dentro del cuerpo no devuelve nada');
select is((select count(*)::int from public.media where is_private), 0,
          'ANONIMO: no ve las filas de media privada');
select is((select count(*)::int from public.subscriptions), 0,
          'ANONIMO: no ve suscripciones');

-- El feed SI le llega, pero solo con el teaser.
select cmp_ok((select count(*)::int from public.activity), '>', 0,
          'ANONIMO: el feed de progreso es visible (motor de conversion)');
select is((select count(*)::int from public.steps), 3,
          'ANONIMO: los METADATOS de los pasos son publicos (teaser)');
select ok((select bool_and(not (snapshot::text ilike '%SECRETO%')) from public.activity),
          'ANONIMO: ningun snapshot del feed contiene el cuerpo del paso');
select ok((select bool_and(coalesce((snapshot->>'is_paywalled')::boolean, true))
             from public.activity where type = 'step_published'),
          'ANONIMO: los eventos de paso vienen marcados como is_paywalled');

reset role;

-- ════════════════════════════════════════════════════════════════════════════
-- 2. SUSCRIPTOR (gratuito, autenticado) — el caso que mas se olvida
-- ════════════════════════════════════════════════════════════════════════════
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', true);

select is((select public.user_tier()), 'subscriber'::public.subscription_tier,
          'SUSCRIPTOR: sin fila en subscriptions, el tramo resuelve a subscriber');
select is((select count(*)::int from public.step_bodies), 0,
          'SUSCRIPTOR: consulta directa a step_bodies devuelve 0 filas');
select is((select count(*)::int from public.materials), 0,
          'SUSCRIPTOR: consulta directa a materials devuelve 0 filas');
select is((select count(*)::int from public.search_step_bodies('titanio')), 0,
          'SUSCRIPTOR: la busqueda dentro del cuerpo no devuelve nada');
select is((select count(*)::int from public.media where is_private), 0,
          'SUSCRIPTOR: no ve las filas de media privada');
select is((select public.can_view_step_body('bbbbbbbb-0000-0000-0000-000000000001')), false,
          'SUSCRIPTOR: can_view_step_body es false incluso para el primer paso');
select is((select count(*)::int from public.steps), 3,
          'SUSCRIPTOR: los METADATOS de los pasos si son visibles');
select is((select count(*)::int from public.messages), 0,
          'SUSCRIPTOR: fuera de la mensajeria (§4)');

reset role;

-- ════════════════════════════════════════════════════════════════════════════
-- 3. PRO — el contenido de pago SI llega (si no, el muro esta roto al reves)
-- ════════════════════════════════════════════════════════════════════════════
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}', true);

select is((select count(*)::int from public.step_bodies), 3,
          'PRO: ve los tres cuerpos de paso');
select is((select count(*)::int from public.materials), 1,
          'PRO: ve los materiales descargables');
select is((select count(*)::int from public.search_step_bodies('titanio')), 1,
          'PRO: la busqueda dentro del cuerpo funciona');
select is((select count(*)::int from public.media where is_private), 1,
          'PRO: ve la media privada del cuerpo del paso');
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
