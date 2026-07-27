-- ============================================================================
-- SEED DE DEMOSTRACION — solo desarrollo
--
-- Una bitacora completa con la que ver las pantallas funcionando: portada,
-- lista de pasos, teaser abierto en los dos primeros y muro a partir del
-- tercero.
--
-- NO es contenido real. Se borra entero con:
--   delete from auth.users where email like '%@demo.aulaescala';
--
-- Separado de seed.sql a proposito: aquel son taxonomias reales que si van a
-- produccion; esto no.
-- ============================================================================

delete from auth.users where email like '%@demo.aulaescala';

insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                        email_confirmed_at, created_at, updated_at,
                        raw_app_meta_data, raw_user_meta_data)
values ('a0000000-0000-4000-8000-000000000001',
        '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'marta@demo.aulaescala', 'x', now(), now(), now(),
        '{"provider":"email","providers":["email"]}',
        '{"display_name":"Marta Vidal"}');

insert into public.subscriptions (user_id, tier, status)
values ('a0000000-0000-4000-8000-000000000001', 'modelista', 'active');

update public.profiles
   set bio = 'Blindados en 1/35 y algun diorama cuando el tiempo acompana. Documento cada build paso a paso porque a mi me habria ahorrado muchos disgustos.',
       location = 'Valencia'
 where id = 'a0000000-0000-4000-8000-000000000001';

-- ── La bitacora ─────────────────────────────────────────────────────────────
insert into public.projects (
  id, author_id, title, subtitle, slug, body, manufacturer, kit_ref,
  difficulty, build_status, scale_id, subject_id, status
)
values (
  'b0000000-0000-4000-8000-000000000001',
  'a0000000-0000-4000-8000-000000000001',
  'Panther Ausf. G',
  'Kursk, verano de 1943',
  'panther-ausf-g',
  'Un Panther tardio con acabado de fabrica desgastado por el uso. La idea era trabajar el zimmerit sin que robara el protagonismo al camuflaje, y contener el envejecido: un vehiculo con seis semanas de frente, no una chatarra.',
  'Tamiya', '35065', 'avanzado', 'wip',
  (select id from public.scales where slug = '1-35'),
  (select id from public.subjects where slug = 'blindados'),
  'published'
);

-- ── Los pasos ───────────────────────────────────────────────────────────────
insert into public.steps (id, project_id, position, title, duration_minutes, status) values
 ('c0000000-0000-4000-8000-000000000001','b0000000-0000-4000-8000-000000000001',1,'Montaje del casco y tren de rodaje',260,'published'),
 ('c0000000-0000-4000-8000-000000000002','b0000000-0000-4000-8000-000000000001',2,'Imprimacion y preshading',120,'published'),
 ('c0000000-0000-4000-8000-000000000003','b0000000-0000-4000-8000-000000000001',3,'Capa base y modulacion de color',195,'published'),
 ('c0000000-0000-4000-8000-000000000004','b0000000-0000-4000-8000-000000000001',4,'Camuflaje a pincel y aerografo',160,'published'),
 ('c0000000-0000-4000-8000-000000000005','b0000000-0000-4000-8000-000000000001',5,'Calcas y sellado con barniz',90,'published'),
 ('c0000000-0000-4000-8000-000000000006','b0000000-0000-4000-8000-000000000001',6,'Chipping del casco superior',170,'published'),
 ('c0000000-0000-4000-8000-000000000007','b0000000-0000-4000-8000-000000000001',7,'Lavados con oleos y filtros',210,'published'),
 ('c0000000-0000-4000-8000-000000000008','b0000000-0000-4000-8000-000000000001',8,'Pigmentos y polvo en el tren de rodaje',145,'published');

insert into public.step_bodies (step_id, body, tip) values
 ('c0000000-0000-4000-8000-000000000001',
  E'Empiezo por el casco inferior y el tren de rodaje: es la base sobre la que se apoya todo el envejecido posterior, asi que dedico tiempo a que los ejes queden alineados y las ruedas giren sin holgura.\n\nDejo las orugas sin pegar y la torreta separada para poder pintar por subconjuntos. Enmascaro las zonas de contacto para que el pegamento agarre bien mas adelante.',
  'Numera y fotografia cada subconjunto antes de separarlo. Recuperar el orden de montaje al pintar es mucho mas rapido que reconstruirlo de memoria.'),
 ('c0000000-0000-4000-8000-000000000002',
  E'Imprimo con negro por debajo y voy levantando con gris claro desde arriba, fijando de una vez el volumen y las sombras del vehiculo.\n\nEl preshading marca paneles, tornilleria y huecos. No busco el contraste final aqui, solo un mapa de luces que la capa base dejara translucir.',
  'Deja secar la imprimacion 24 h antes de la capa de color. Ganaras adherencia y evitaras levantar el preshading al aerografiar encima.'),
 ('c0000000-0000-4000-8000-000000000003',
  E'La capa base va muy diluida y en pasadas sucesivas, dejando que el preshading asome. Tres o cuatro manos finas antes que una gruesa.\n\nLa modulacion se trabaja panel a panel: aclarado en el centro de cada superficie, sombra en los recovecos.',
  'Aclara siempre con el mismo tono base mas blanco roto, nunca blanco puro: el blanco puro vira a gris azulado y rompe la unidad del conjunto.'),
 ('c0000000-0000-4000-8000-000000000004',
  E'El patron de camuflaje va a mano alzada con aerografo de aguja fina, a baja presion y muy cerca de la superficie.\n\nLas franjas de marron se difuminan por los bordes para que el limite no quede de calca.',
  'Practica el patron en una cuchara de plastico antes de tocar el modelo. Cinco minutos ahi ahorran una tarde de correcciones.'),
 ('c0000000-0000-4000-8000-000000000005',
  E'Barniz brillante localizado donde van las calcas, para evitar el efecto plateado, y ablandador en dos pasadas.\n\nUna vez secas, sello todo en satinado y dejo reposar antes de empezar con los oleos.',
  'El ablandador se aplica una vez y no se toca. Si insistes con el pincel, la calca se arruga y no hay vuelta atras.'),
 ('c0000000-0000-4000-8000-000000000006',
  E'El chipping representa el desgaste de la pintura por el uso, el roce de la tripulacion y los impactos. En el Panther se concentra en los bordes del casco, escotillas, guardabarros y zonas de paso.\n\nTrabajo en dos capas: primero un tono de imprimacion desvaida aplicado con esponja para las marcas mas sutiles, y encima puntos de oxido oscuro con pincel de punta fina solo donde el metal quedaria realmente expuesto.\n\nLa clave es la contencion: menos es mas. Un desconchado creible es pequeno, irregular y agrupado en zonas logicas de contacto, nunca repartido de forma uniforme por toda la superficie.',
  'Diluye el oleo de oxido con un toque de blanco titanio para el borde superior de cada desconchado: simula el reflejo del metal recien aranado.'),
 ('c0000000-0000-4000-8000-000000000007',
  E'Pin wash de oleo oscuro solo en las lineas de panel y alrededor de la tornilleria, retirando el sobrante con un pincel apenas humedo en diluyente.\n\nDespues, filtros muy diluidos para unificar el conjunto y quitarle al camuflaje ese aspecto de recien pintado.',
  'Deja secar el barniz 48 h antes del pin wash. Con menos tiempo, el diluyente del oleo levanta la capa de abajo y el estropicio es irreversible.'),
 ('c0000000-0000-4000-8000-000000000008',
  E'Pigmentos aplicados en seco con pincel plano, concentrados en el tren de rodaje y las zonas bajas del casco.\n\nFijo con diluyente aplicado por capilaridad, sin tocar el pigmento con el pincel, y retiro el exceso de las superficies horizontales para que el polvo se acumule solo donde lo haria de verdad.',
  'Aplica el pigmento siempre en seco y fija despues. Al reves, el pigmento se convierte en barro y pierdes el control del tono.');

-- ── Tecnicas por paso ───────────────────────────────────────────────────────
insert into public.step_techniques (step_id, technique_id)
select s.id, t.id
  from public.steps s
  join (values
    (1,'masking'),(2,'imprimacion'),(2,'preshading'),(3,'aerografia'),
    (3,'modulacion-de-color'),(4,'aerografia'),(4,'masking'),(5,'calcas'),
    (5,'barnizado'),(6,'chipping'),(6,'lavados-con-oleos'),(7,'lavados-con-oleos'),
    (7,'filtros'),(8,'pigmentos')
  ) as m(pos, slug) on m.pos = s.position
  join public.techniques t on t.slug = m.slug
 where s.project_id = 'b0000000-0000-4000-8000-000000000001'
on conflict do nothing;

insert into public.project_techniques (project_id, technique_id)
select distinct 'b0000000-0000-4000-8000-000000000001'::uuid, st.technique_id
  from public.step_techniques st
  join public.steps s on s.id = st.step_id
 where s.project_id = 'b0000000-0000-4000-8000-000000000001'
on conflict do nothing;

-- ── Materiales ──────────────────────────────────────────────────────────────
insert into public.materials (project_id, storage_path, filename, mime, byte_size, position) values
 ('b0000000-0000-4000-8000-000000000001','a0000000-0000-4000-8000-000000000001/projects/panther/pinturas.pdf','Lista de pinturas AK · Tamiya.pdf','application/pdf',245760,1),
 ('b0000000-0000-4000-8000-000000000001','a0000000-0000-4000-8000-000000000001/projects/panther/camuflaje.pdf','Plantilla de camuflaje 1-35.pdf','application/pdf',1153434,2),
 ('b0000000-0000-4000-8000-000000000001','a0000000-0000-4000-8000-000000000001/projects/panther/kursk.zip','Referencias Kursk 1943.zip','application/zip',8808038,3);

-- ── Un segundo build, terminado, para que el feed tenga variedad ────────────
insert into public.projects (
  id, author_id, title, subtitle, slug, manufacturer, kit_ref,
  difficulty, build_status, scale_id, subject_id, status
)
values (
  'b0000000-0000-4000-8000-000000000002',
  'a0000000-0000-4000-8000-000000000001',
  'Spitfire Mk.IXc',
  'Biggin Hill, 1943',
  'spitfire-mk-ixc',
  'Eduard', '82117', 'intermedio', 'finished',
  (select id from public.scales where slug = '1-48'),
  (select id from public.subjects where slug = 'aviacion'),
  'published'
);

insert into public.steps (id, project_id, position, title, duration_minutes, status) values
 ('c0000000-0000-4000-8000-000000000101','b0000000-0000-4000-8000-000000000002',1,'Cabina y fotograbados',180,'published'),
 ('c0000000-0000-4000-8000-000000000102','b0000000-0000-4000-8000-000000000002',2,'Metal natural y paneles',150,'published'),
 ('c0000000-0000-4000-8000-000000000103','b0000000-0000-4000-8000-000000000002',3,'Camuflaje RAF y bandas',200,'published');

insert into public.step_bodies (step_id, body, tip) values
 ('c0000000-0000-4000-8000-000000000101', E'La cabina del Eduard viene con fotograbados pintados de fabrica, pero el asiento y los laterales piden trabajo de pincel.\n\nClaroscuro a pincel sobre negro, porque a esta escala el aerografo no entra en los recovecos.', 'Monta y pinta la cabina antes de cerrar el fuselaje. Despues no se llega, y se ve mas de lo que uno cree.'),
 ('c0000000-0000-4000-8000-000000000102', E'Aluminio pulido sobre imprimacion negra brillante, variando el tono panel a panel para que el metal no quede plano.', 'Enmascara con cinta de bajo tack sobre metal natural: la cinta normal levanta el acabado y hay que repetir el panel entero.'),
 ('c0000000-0000-4000-8000-000000000103', E'Camuflaje RAF de dos tonos a mano alzada y bandas de invasion enmascaradas.\n\nEl limite entre colores lleva un difuminado muy corto, casi duro, como en las fotos de epoca.', 'Las bandas de invasion se pintaron a brocha y con prisa. Un borde perfecto es historicamente falso: dejalo irregular.');
