# ADR 0001 — La marca visible es AULAESCALA.

**Estado:** aceptado
**Fecha:** 2026-07-26

## Contexto

El prototipo de diseño rotula el wordmark del header como **"ESCALA."** (Raleway 800,
mayúsculas, punto final en `--accent`). El proyecto, el repositorio
(`github.com/elpopi2003/AulaEscala`) y el proyecto de Supabase se llaman **AULAESCALA**.

Dejarlo sin resolver significaba arrastrar dos nombres por toda la UI, los metadatos
SEO, las plantillas de email de Resend y los recibos de Stripe.

## Decisión

La marca visible es **AULAESCALA.**, con el punto final en `--accent`.

Se conserva el resto del sistema de identidad del prototipo sin cambios: el chip de
logo "1/35" (36×36, fondo `--primary`, texto mono, offset naranja `2px 2px 0`) y la
tipografía Raleway 800 en mayúsculas.

## Consecuencias

- El wordmark es más largo que "ESCALA." y el header sólo tiene 64 px de alto. Hay que
  vigilar el punto de colapso a móvil: el breakpoint de 1000 px puede quedarse corto y
  quizá haya que subirlo, o reducir el `letter-spacing` del wordmark.
- "Aula" refuerza el posicionamiento real del producto —aprendizaje técnico práctico,
  no red social— que es justo el diferenciador que describe la especificación §2.
- Las capturas de `docs/design/screenshots/` siguen mostrando "ESCALA.". Son
  referencia de layout y color, no de copy.
