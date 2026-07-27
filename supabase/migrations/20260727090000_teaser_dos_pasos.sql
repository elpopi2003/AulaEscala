-- ============================================================================
-- 20260727090000_teaser_dos_pasos
--
-- Resuelve el conflicto documentado en docs/adr/0004-teaser-de-pasos.md a
-- favor del prototipo de diseno: los DOS PRIMEROS pasos de cada bitacora
-- tienen el cuerpo abierto; del tercero en adelante exige Pro.
--
-- Es la estrategia de embudo que ya prometia la pagina de precios ("ver
-- proyectos y primeros pasos") y la que pinta la pantalla 5 del prototipo
-- (teaser difuminado + muro).
--
-- CONSECUENCIA DELIBERADA: el cuerpo de los pasos 1 y 2 pasa a ser publico e
-- INDEXABLE por Google. Es lo que se busca —contenido real posicionando en vez
-- de solo titulos— pero conviene tenerlo presente al escribir esos pasos: son
-- escaparate, no contenido reservado.
-- ============================================================================

update public.app_config set free_preview_steps = 2 where id;

comment on column public.app_config.free_preview_steps is
  'Cuantos pasos iniciales tienen el cuerpo abierto a anonimos y suscriptores. '
  'Vale 2 (ADR 0004). Subirlo expone mas contenido de pago; bajarlo a 0 vuelve '
  'al comportamiento de la especificacion §4 y obliga a corregir la copia de la '
  'pagina de precios.';
