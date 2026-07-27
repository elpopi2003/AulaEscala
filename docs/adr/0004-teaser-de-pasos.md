# ADR 0004 — Cuántos pasos son gratis

**Estado:** aceptado provisionalmente · ⚠️ **pendiente de confirmación de producto**
**Fecha:** 2026-07-26

## Contexto

Los dos documentos de partida se contradicen sobre el punto exacto del muro de pago.

**La especificación técnica (§4)** es tajante: "Ver **cuerpo de pasos**, PDF,
materiales" → `✗ ✗ ✓ ✓`. El cuerpo de cualquier paso exige Pro. Y §2 lo refuerza: "el
usuario gratuito ve el evento *nuevo paso publicado*, pero **al abrirlo encuentra el
muro de Pro**".

**El handoff de diseño** dice otra cosa, y en dos sitios:

- La regla de bloqueo del prototipo: *"en una bitácora, los pasos con índice ≥ 2 están
  bloqueados para `free`"* — es decir, los **dos primeros son gratis**.
- La tarjeta de precios del plan Suscriptor promete literalmente: *"feed completo, ver
  proyectos y **primeros pasos**, comentar, favoritos, perfil básico"*.

No es un descuido de maquetación: la pantalla 5 del prototipo se llama
"teaser/bloqueo" y enseña el muro *después* de haber dejado leer algo.

Son dos estrategias de embudo distintas y ambas defendibles:

- **0 pasos gratis** — máxima protección del contenido. El feed vende el titular y la
  miniatura; el valor se paga entero.
- **2 pasos gratis** — el usuario prueba el producto (calidad de redacción, nivel de
  detalle, fotos de proceso) y choca con el muro cuando ya le importa. Suele convertir
  mejor y genera páginas indexables con contenido real, no solo títulos.

## Decisión

Se implementa como **valor configurable**, no como constante enterrada en una política:

```sql
public.app_config.free_preview_steps int not null default 0
```

y un único predicado lo consume:

```sql
public.can_view_step_body(step_id)
  -- autor  OR  tramo >= pro  OR  position <= free_preview_steps()
```

Arranca en **0** — el comportamiento de la especificación técnica.

**El motivo de arrancar en 0 es asimetría de riesgo, no preferencia de producto.**
Si el valor correcto resulta ser 2 y arrancamos en 0, los usuarios ven de menos: se
corrige cambiando un entero. Si el correcto es 0 y arrancamos en 2, hemos estado
publicando contenido de pago —e indexándolo en Google— hasta que alguien lo note.
Un muro de pago se falla cerrado.

## Consecuencias

- Cambiar la estrategia es un `update public.app_config set free_preview_steps = 2;`.
  No hace falta migración ni despliegue.
- `activity.snapshot` lleva `is_paywalled`, calculado con el mismo valor, así que la
  tarjeta del feed pinta el candado correcto sin consultar nada más.
- El test de no-fuga (`supabase/tests/00_no_leak.sql`) **afirma que el valor es 0**.
  Si se sube a 2, ese test falla a propósito: obliga a revisar las expectativas en vez
  de aflojar el muro sin que nadie se entere.
- Con `free_preview_steps > 0` el cuerpo de los primeros pasos pasa a ser **público e
  indexable**. Eso es deseable para SEO, pero conviene decidirlo a sabiendas.

## Pendiente

Confirmar con producto. Si se elige el comportamiento del diseño:

```sql
update public.app_config set free_preview_steps = 2;
```

...y actualizar la expectativa en `00_no_leak.sql`. Si se elige el de la
especificación, hay que **corregir la copia de la página de precios**, que hoy promete
"primeros pasos" y no los daría.
