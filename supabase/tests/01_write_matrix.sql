-- ============================================================================
-- MATRIZ DE ESCRITURA POR TRAMO (§5) + escalada de privilegios
--
-- El test 00 cubre la lectura (que no se filtre lo de pago). Este cubre la
-- escritura: quien puede crear, quien puede editar lo ajeno, y las tres vias
-- clasicas de escalada — ascenderse a admin, autoconcederse un tramo, e
-- inyectar eventos en el feed.
-- ============================================================================

begin;

create extension if not exists pgtap with schema extensions;

select plan(22);

insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                        email_confirmed_at, created_at, updated_at,
                        raw_app_meta_data, raw_user_meta_data)
values
 ('11111111-1111-1111-1111-111111111111','00000000-0000-0000-0000-000000000000','authenticated','authenticated','autor@test.local','x',now(),now(),now(),'{}','{"display_name":"Marta Vidal"}'),
 ('22222222-2222-2222-2222-222222222222','00000000-0000-0000-0000-000000000000','authenticated','authenticated','suscriptor@test.local','x',now(),now(),now(),'{}','{"display_name":"Suscriptor Gratis"}'),
 ('33333333-3333-3333-3333-333333333333','00000000-0000-0000-0000-000000000000','authenticated','authenticated','pro@test.local','x',now(),now(),now(),'{}','{"display_name":"Usuario Pro"}'),
 ('44444444-4444-4444-4444-444444444444','00000000-0000-0000-0000-000000000000','authenticated','authenticated','otro@test.local','x',now(),now(),now(),'{}','{"display_name":"Otro Modelista"}');

insert into public.subscriptions (user_id, tier, status) values
 ('11111111-1111-1111-1111-111111111111','modelista','active'),
 ('33333333-3333-3333-3333-333333333333','pro','active'),
 ('44444444-4444-4444-4444-444444444444','modelista','active');

insert into public.projects (id, author_id, title, slug, status, build_status)
values ('aaaaaaaa-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111',
        'Panther Ausf. G','panther-ausf-g','published','wip');

insert into public.steps (id, project_id, position, title, status)
values ('bbbbbbbb-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001',
        1,'Montaje del casco','published');

insert into public.step_bodies (step_id, body) values
 ('bbbbbbbb-0000-0000-0000-000000000001','cuerpo original');

-- ════════════════════════════════════════════════════════════════════════════
-- SUSCRIPTOR
-- ════════════════════════════════════════════════════════════════════════════
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', true);

select throws_ok(
  $$insert into public.projects (author_id,title,slug,status)
    values ('22222222-2222-2222-2222-222222222222','Intruso','intruso','draft')$$,
  '42501', null, 'SUSCRIPTOR: no puede crear proyectos (exige modelista)');

-- Escalada 1: ascenderse a admin. Lo para el privilegio de COLUMNA, no la RLS.
select throws_ok(
  $$update public.profiles set role='admin'
     where id='22222222-2222-2222-2222-222222222222'$$,
  '42501', null, 'SUSCRIPTOR: no puede ascenderse a admin');

-- Escalada 2: autoconcederse un tramo de pago.
select throws_ok(
  $$insert into public.subscriptions (user_id,tier,status)
    values ('22222222-2222-2222-2222-222222222222','pro','active')$$,
  '42501', null, 'SUSCRIPTOR: no puede autoconcederse el tramo Pro');

-- Escalada 3: inyectar en el feed (que es publico) contenido a su gusto.
select throws_ok(
  $$insert into public.activity (actor_id,type,project_id,snapshot)
    values ('22222222-2222-2222-2222-222222222222','step_published',
            'aaaaaaaa-0000-0000-0000-000000000001','{}')$$,
  '42501', null, 'SUSCRIPTOR: no puede inyectar eventos en el feed');

select throws_ok(
  $$insert into public.conversations (created_by)
    values ('22222222-2222-2222-2222-222222222222')$$,
  '42501', null, 'SUSCRIPTOR: no puede abrir conversaciones (§4)');

-- Lo que SI puede: comentar, favoritos, follows y editar su perfil.
select lives_ok(
  $$insert into public.comments (author_id,project_id,body)
    values ('22222222-2222-2222-2222-222222222222',
            'aaaaaaaa-0000-0000-0000-000000000001','Gran trabajo')$$,
  'SUSCRIPTOR: puede comentar (§4)');

select lives_ok(
  $$insert into public.favorites (user_id,project_id)
    values ('22222222-2222-2222-2222-222222222222','aaaaaaaa-0000-0000-0000-000000000001')$$,
  'SUSCRIPTOR: puede guardar favoritos (§4)');

select lives_ok(
  $$update public.profiles set bio='Modelista de fin de semana'
     where id='22222222-2222-2222-2222-222222222222'$$,
  'SUSCRIPTOR: puede editar su propio perfil');

reset role;

-- ════════════════════════════════════════════════════════════════════════════
-- PRO — mensajeria si, autoria no
-- ════════════════════════════════════════════════════════════════════════════
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}', true);

select throws_ok(
  $$insert into public.projects (author_id,title,slug,status)
    values ('33333333-3333-3333-3333-333333333333','Mio','mio-pro','draft')$$,
  '42501', null, 'PRO: no puede crear proyectos (autoria = modelista)');

select throws_ok(
  $$insert into public.techniques (slug,name,created_by)
    values ('aerografia','Aerografia','33333333-3333-3333-3333-333333333333')$$,
  '42501', null, 'PRO: no puede crear tecnicas (§5)');

select lives_ok(
  $$insert into public.conversations (id,created_by)
    values ('cccccccc-0000-0000-0000-000000000001','33333333-3333-3333-3333-333333333333')$$,
  'PRO: puede abrir una conversacion');

select lives_ok(
  $$insert into public.conversation_participants (conversation_id,user_id)
    values ('cccccccc-0000-0000-0000-000000000001','33333333-3333-3333-3333-333333333333')$$,
  'PRO: puede anadirse como participante');

-- LA regla dificil de §4: el Suscriptor no recibe, y el Pro no puede
-- contactarle. No basta con esconderlo en la UI.
select throws_ok(
  $$insert into public.conversation_participants (conversation_id,user_id)
    values ('cccccccc-0000-0000-0000-000000000001','22222222-2222-2222-2222-222222222222')$$,
  '42501', null, 'PRO: NO puede meter a un Suscriptor en la conversacion (§4)');

select lives_ok(
  $$insert into public.conversation_participants (conversation_id,user_id)
    values ('cccccccc-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111')$$,
  'PRO: si puede contactar a un Modelista');

-- ...y tampoco aparece en el selector de destinatarios.
select is((select count(*)::int from public.search_message_recipients('Suscriptor')), 0,
          'PRO: el Suscriptor no sale en el selector de destinatarios (§4)');
select is((select count(*)::int from public.search_message_recipients('Marta')), 1,
          'PRO: el Modelista si sale en el selector');

reset role;

-- ════════════════════════════════════════════════════════════════════════════
-- MODELISTA B — aislamiento entre autores
-- ════════════════════════════════════════════════════════════════════════════
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"44444444-4444-4444-4444-444444444444","role":"authenticated"}', true);

-- Sin filtro por autor: la RLS debe reducir el alcance a 0 filas, no fallar.
update public.projects set title='SECUESTRADO'
 where id='aaaaaaaa-0000-0000-0000-000000000001';
select is((select title from public.projects where id='aaaaaaaa-0000-0000-0000-000000000001'),
          'Panther Ausf. G',
          'MODELISTA B: no puede modificar el proyecto de otro autor');

update public.step_bodies set body='SECUESTRADO'
 where step_id='bbbbbbbb-0000-0000-0000-000000000001';
select is((select body from public.step_bodies where step_id='bbbbbbbb-0000-0000-0000-000000000001'),
          'cuerpo original',
          'MODELISTA B: no puede modificar el cuerpo de un paso ajeno');

delete from public.projects where id='aaaaaaaa-0000-0000-0000-000000000001';
select isnt_empty(
  $$select 1 from public.projects where id='aaaaaaaa-0000-0000-0000-000000000001'$$,
  'MODELISTA B: no puede borrar el proyecto de otro autor');

-- Suplantacion: crear contenido a nombre de otro.
select throws_ok(
  $$insert into public.projects (author_id,title,slug,status)
    values ('11111111-1111-1111-1111-111111111111','Suplantado','suplantado','draft')$$,
  '42501', null, 'MODELISTA B: no puede publicar a nombre de otro autor');

select lives_ok(
  $$insert into public.projects (author_id,title,slug,status)
    values ('44444444-4444-4444-4444-444444444444','Yamato','yamato','draft')$$,
  'MODELISTA B: si puede crear proyectos propios');

reset role;

-- ════════════════════════════════════════════════════════════════════════════
-- MODELISTA A — autoria completa sobre lo suyo
-- ════════════════════════════════════════════════════════════════════════════
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);

-- create_step escribe DOS tablas en una transaccion (§9).
select lives_ok(
  $$select public.create_step('aaaaaaaa-0000-0000-0000-000000000001',
      'Imprimacion y preshading','cuerpo nuevo','consejo',120)$$,
  'MODELISTA: create_step escribe steps + step_bodies transaccionalmente');

-- Reordenar exige que la unique (project_id, position) sea DEFERRABLE: en
-- mitad del intercambio hay posiciones duplicadas.
select lives_ok(
  $$select public.reorder_steps('aaaaaaaa-0000-0000-0000-000000000001',
      (select array_agg(id order by position desc) from public.steps
        where project_id='aaaaaaaa-0000-0000-0000-000000000001'))$$,
  'MODELISTA: reorder_steps invierte el orden sin violar la unicidad');

reset role;

select * from finish();
rollback;
