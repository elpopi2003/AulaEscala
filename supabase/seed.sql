-- ============================================================================
-- SEED — taxonomias de arranque.
--
-- Se ejecuta con `supabase db reset`. Contiene SOLO taxonomia real (escalas,
-- tematicas y tecnicas de modelismo estatico), no contenido de ejemplo: los
-- proyectos y pasos de prueba viven en los tests, que hacen rollback.
--
-- Idempotente: `on conflict do nothing` en todo.
-- ============================================================================

-- ── Escalas ─────────────────────────────────────────────────────────────────
insert into public.scales (slug, name, ratio, position) values
  ('1-16', '1/16',  16, 10),
  ('1-24', '1/24',  24, 20),
  ('1-32', '1/32',  32, 30),
  ('1-35', '1/35',  35, 40),
  ('1-48', '1/48',  48, 50),
  ('1-72', '1/72',  72, 60),
  ('1-144','1/144',144, 70),
  ('1-350','1/350',350, 80),
  ('1-700','1/700',700, 90),
  ('54mm', '54 mm',  1, 100),
  ('75mm', '75 mm',  1, 110)
on conflict (slug) do nothing;

-- ── Tematicas ───────────────────────────────────────────────────────────────
insert into public.subjects (slug, name, position) values
  ('blindados',   'Blindados',        10),
  ('aviacion',    'Aviacion',         20),
  ('naval',       'Naval',            30),
  ('figuras',     'Figuras',          40),
  ('dioramas',    'Dioramas',         50),
  ('civil',       'Vehiculo civil',   60),
  ('ciencia-ficcion', 'Ciencia ficcion', 70),
  ('artilleria',  'Artilleria',       80)
on conflict (slug) do nothing;

-- ── Tecnicas ────────────────────────────────────────────────────────────────
-- Semilla curada del vocabulario canonico. Nacen 'approved' porque las pone el
-- operador; las que cree un modelista nacen 'pending_review' (§7.2).
--
-- Sembrar bien esta tabla es la primera linea del anti-duplicados: cuantos mas
-- terminos canonicos existan, mas veces el autocompletado por similitud
-- pg_trgm redirige a uno existente en lugar de dejar crear un sinonimo.
insert into public.techniques (slug, name, description, moderation_status) values
  ('aerografia','Aerografia','Aplicacion de pintura con aerografo.','approved'),
  ('imprimacion','Imprimacion','Capa base que garantiza la adherencia de la pintura.','approved'),
  ('preshading','Preshading','Sombreado previo que marca paneles y volumenes bajo la capa base.','approved'),
  ('modulacion-de-color','Modulacion de color','Aclarado y oscurecido por paneles para simular la luz cenital.','approved'),
  ('masking','Masking','Enmascarado con cinta, liquido o masilla para delimitar zonas.','approved'),
  ('chipping','Chipping / desconchados','Desgaste de la pintura por uso, roce e impactos.','approved'),
  ('lavados-con-oleos','Lavados con oleos','Lavados y pin wash con oleo para resaltar recovecos.','approved'),
  ('filtros','Filtros','Veladuras muy diluidas que unifican y viran el tono general.','approved'),
  ('dry-brushing','Dry brushing','Pincel casi seco sobre aristas para resaltar el relieve.','approved'),
  ('pigmentos','Pigmentos','Polvos para barro, polvo y hollin.','approved'),
  ('barnizado','Barnizado','Sellado en brillo, satinado o mate.','approved'),
  ('calcas','Calcas','Aplicacion de calcomanias con liquidos ablandadores.','approved'),
  ('oxidos','Oxidos y corrosion','Texturas y tonos de metal oxidado.','approved'),
  ('nmf','Metal natural (NMF)','Acabados metalicos pulidos sin pintura de color.','approved'),
  ('scratch','Scratch building','Piezas fabricadas desde cero.','approved'),
  ('fotograbados','Fotograbados','Detallado con piezas de laton grabado.','approved'),
  ('masillado','Masillado y lijado','Relleno de juntas y correccion de superficies.','approved'),
  ('vegetacion','Vegetacion','Elaboracion de flora para dioramas.','approved'),
  ('agua-y-resinas','Agua y resinas','Simulacion de agua, barro humedo y hielo.','approved'),
  ('claroscuro','Claroscuro a pincel','Volumen a pincel por capas de luces y sombras, tipico en figuras.','approved')
on conflict (slug) do nothing;
