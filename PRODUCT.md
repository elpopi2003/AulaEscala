# PRODUCT.md — AULAESCALA

> Contexto de producto para trabajo de diseño. El detalle vive en los documentos
> enlazados; esto es el resumen que orienta decisiones de interfaz.

## Qué es

Plataforma comunitaria de **modelismo estático a escala** (maquetas, dioramas,
figuras, blindados, aviación, naval). El núcleo son las **bitácoras de montaje**:
proyectos documentados paso a paso, con técnicas etiquetadas, orientados al
aprendizaje técnico práctico.

No es un foro ni una red social genérica: es un **build-log estructurado premium**.

## Register

`product` — la interfaz sirve a la tarea. El usuario viene a aprender una técnica
o a documentar su trabajo, no a admirar la web. La excepción es la **portada del
proyecto**, que sí es superficie de marca: full-bleed, titular grande, es la
primera impresión de un build y la puerta de entrada desde Google.

## Platform

`web`

## Quién lo usa

Modelistas. Gente que dedica 30 horas a un kit de 1/35 y fotografía cada
subconjunto. Perfil técnico, paciente, exigente con el detalle — el mismo tipo de
persona que nota si una sombra tiene desenfoque cuando no debería.

**Escena física:** de noche, en el banco de trabajo, con flexo encendido y las
manos ocupadas. O en el sofá, leyendo el paso 6 antes de atreverse con el
aerógrafo mañana. Por eso el **tema oscuro no es decorativo**: es la condición de
uso más frecuente. Ambos temas son de primera clase.

## Tramos y su consecuencia en la UI

| Tramo | Ve |
|---|---|
| Anónimo / Suscriptor | Feed, proyectos, títulos de todos los pasos, **cuerpo de los 2 primeros** |
| Pro | Todo el contenido + materiales + PDF + mensajería |
| Modelista | Lo anterior + crear y editar bitácoras |

**El muro de pago es el elemento de diseño más importante del producto.** Aparece
en tres tratamientos distintos y no son intercambiables: candado sobre miniatura
en el feed, candado en la fila del paso, y muro completo con teaser difuminado en
la página de paso. Tiene que dar ganas de pagar, no sensación de puerta en la
cara.

## Sistema de diseño

**Blueprint / Industrial** — estética de plano técnico de ingeniería. Tokens
exactos y finales en [`docs/design-tokens.md`](docs/design-tokens.md); prototipo
navegable en `docs/design/Escala.dc.html`.

Las dos señas de identidad: **rejilla de ingeniería de 40×40 px** en toda la
página, y **sombra dura de 4px sin desenfoque**. Si aparece un `blur` en esa
sombra, está mal.

Azul estructural = `--primary` y **Terminado**. Naranja precisión = `--accent`,
CTA y **WIP**. Todo lo técnico (escalas, tiempos, precios, referencias de kit) en
JetBrains Mono: es lo que da el aire de plano.

## Documentos

- [`CLAUDE.md`](CLAUDE.md) — estado del proyecto y reglas de ingeniería
- [`docs/especificacion.md`](docs/especificacion.md) — especificación completa
- [`docs/design-tokens.md`](docs/design-tokens.md) — tokens (finales)
- [`docs/matriz-de-acceso.md`](docs/matriz-de-acceso.md) — qué ve cada tramo
