# ADR 0002 — Prefijo de idioma en las URLs desde el día uno

**Estado:** aceptado
**Fecha:** 2026-07-26

## Contexto

El MVP es sólo en español, pero el esquema nace preparado para multiidioma
(especificación §3.4): `locale` y `translation_group_id` en `projects` y `steps`, y
slugs únicos **por locale** en vez de globalmente.

Quedaba abierto (§10) si las URLs llevan prefijo de idioma desde el principio o se
añade cuando llegue la fase 2.

## Decisión

Las rutas públicas llevan **prefijo de idioma desde el día uno**:

```
/es/proyectos/panther-ausf-g
/es/proyectos/panther-ausf-g/pasos/3
/es/tecnicas/aerografia
/es/precios
```

En el App Router: un segmento dinámico `app/[locale]/...`, con `es` como único valor
soportado hoy y `/` redirigiendo a `/es`.

## Motivo

El contenido público es la puerta de entrada del embudo y tiene que estar indexado.
Añadir el prefijo *después* obliga a redirecciones 301 masivas sobre URLs que Google
ya tiene posicionadas, con la pérdida de autoridad que eso conlleva — y el coste llega
justo cuando el contenido por fin vale algo. La propia especificación lo recomienda.

El coste de hacerlo ahora es un segmento de ruta y algo de middleware. El coste de
hacerlo después es SEO.

## Alternativa descartada

**Raíz para español, prefijo para el resto** (`/proyectos/...` y `/en/proyectos/...`).
Evita redirigir el contenido existente, pero deja el idioma por defecto sin marcar,
lo que complica el `hreflang` y el middleware, y crea una asimetría que se paga cada
vez que se toca el enrutado.

## Consecuencias

- Todo enlace interno se construye con el locale activo. Nada de rutas literales.
- `sitemap.xml` y `hreflang` nacen preparados aunque hoy sólo listen `es`.
- Recordatorio de §3.3: cuando llegue el segundo idioma, la configuración FTS pasará a
  depender de `locale` y habrá que **migrar `search_vector` de columna generada a
  trigger** — el cast `text::regconfig` no es `IMMUTABLE`. Está anotado como comentario
  en la propia configuración `public.es_unaccent`.
