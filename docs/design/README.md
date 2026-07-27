# Handoff: Escala — Plataforma Comunitaria de Modelismo Estático

## Overview
**Escala** es una plataforma comunitaria para modelismo estático a escala (maquetas, dioramas, figuras, blindados, aviación, naval). Su núcleo son las **bitácoras de montaje**: proyectos (builds) documentados paso a paso, con técnicas etiquetadas, pensados como aprendizaje técnico práctico. No es un foro ni una red social genérica: es "el build-log estructurado premium" del nicho.

El prototipo cubre 8 pantallas navegables entre sí, con 3 niveles de suscripción (tramos) cuyo estado de bloqueo se refleja en toda la app, tema claro/oscuro, y navegación responsive (header completo en escritorio, menú off-canvas en móvil/tablet).

## About the Design Files
Los archivos de este bundle son **referencias de diseño creadas en HTML** — un prototipo que muestra el aspecto y comportamiento pretendidos, **no código de producción para copiar directamente**.

El archivo `Escala.dc.html` es un "Design Component": HTML con un pequeño runtime propio (`support.js`) que ofrece plantillas con `{{ interpolación }}`, bucles (`<sc-for>`), condicionales (`<sc-if>`) y una clase de lógica `Component extends DCLogic` (patrón similar a un componente de clase de React, con `state` / `setState` / `renderVals()`). **No uses ese runtime en producción.**

La tarea es **recrear estos diseños en el entorno del codebase destino** siguiendo sus patrones y librerías establecidos. Si no existe entorno todavía, el stack objetivo definido con el equipo es **WordPress + Elementor Pro sobre plantilla Astra** (ver "Mapeo a WordPress/Elementor" más abajo); alternativamente, para una SPA, React + CSS-in-JS o Tailwind reproduce el diseño con fidelidad.

## Fidelity
**Alta fidelidad (hi-fi).** Colores, tipografía, espaciados, radios, sombras e interacciones son finales. Recrea la UI de forma fiel al píxel usando las librerías y patrones del codebase. Los valores exactos están en la sección "Design Tokens".

## Design System — ModelMarket "Blueprint / Industrial"
La app adopta el sistema de diseño ModelMarket, estética de plano técnico de ingeniería:
- **Fondo de rejilla**: retícula de ingeniería de 40×40px sutil sobre toda la página (dos gradientes lineales de 1px en `--grid`).
- **Sombra "blueprint"**: sombra dura de offset **`4px 4px 0 0 var(--bpborder)`** SIN desenfoque (no una sombra difusa). Se usa en tarjetas destacadas y en hover.
- **Bordes técnicos** de 2px en elementos estructurales; radios pequeños (6–8px) en tarjetas, mayores (13px) en subtarjetas de contenido.
- **Color estructural**: azul plano técnico (primary). **Acento/CTA**: naranja precisión. Estados: Terminado = azul, WIP = naranja.
- **Tipografía**: titulares en Raleway 800 (mayúsculas en nav, botones y eyebrows); cuerpo en Montserrat; TODO lo técnico (escalas, tiempos, precios, referencias de kit, metadatos) en JetBrains Mono.

## Design Tokens

### Fuentes (Google Fonts)
```
Display / titulares: 'Raleway', weight 800 (uppercase, letter-spacing .02–.04em)
Cuerpo:             'Montserrat', weights 400/500/600/700
Monoespaciada:      'JetBrains Mono', weights 400/500/600
```
Import: `https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&family=Montserrat:wght@400;500;600;700&family=Raleway:wght@800&display=swap`

### Colores — Tema Claro
```
--bg               hsl(210 20% 98%)     Fondo de página
--surface          hsl(0 0% 100%)       Tarjetas / superficies
--surface-2        hsl(210 14% 93%)     Superficie secundaria (chips, campos)
--text             hsl(213 31% 15%)     Texto principal
--muted            hsl(213 16% 45%)     Texto secundario
--faint            hsl(213 16% 58%)     Texto terciario / placeholders
--border           hsl(213 20% 86%)     Bordes estándar
--bpborder         hsl(213 20% 82%)     Borde/sombra blueprint
--grid             hsl(213 30% 92%)     Líneas de la rejilla de fondo
--primary          hsl(213 56% 24%)     Azul estructural
--primary-contrast hsl(210 40% 98%)
--accent           hsl(32 95% 52%)      Naranja precisión (CTA)
--accent-contrast  #ffffff
--rust             hsl(0 74% 52%)       Peligro / eliminar
--pa / --pb        hsl(213 34% 90%) / hsl(213 28% 95%)   Rayas de placeholders de foto
--shadow           hsl(213 31% 15% / .09)
Derivados:
--accent-soft   = color-mix(in srgb, var(--accent) 14%, var(--bg))
--primary-soft  = color-mix(in srgb, var(--primary) 12%, var(--bg))
--bp-shadow     = 4px 4px 0 0 var(--bpborder)
```

### Colores — Tema Oscuro
```
--bg               hsl(213 31% 10%)
--surface          hsl(213 31% 13%)
--surface-2        hsl(213 31% 18%)
--text             hsl(210 20% 95%)
--muted            hsl(213 16% 62%)
--faint            hsl(213 16% 48%)
--border           hsl(213 31% 24%)
--bpborder         hsl(213 31% 28%)
--grid             hsl(213 31% 16%)
--primary          hsl(213 56% 58%)
--primary-contrast hsl(213 31% 10%)
--accent           hsl(32 95% 54%)
--accent-contrast  #1a1205
--rust             hsl(0 62% 52%)
--pa / --pb        hsl(213 31% 19%) / hsl(213 31% 14%)
--shadow           rgba(0,0,0,.5)
```
El acento es configurable (tweak): paleta de marca #F7941D (naranja, default), #1E4A7B (azul), #22A852 (verde), #8B5CF6 (violeta). En oscuro el acento se aclara con `color-mix(... 82%, #fff)`.

### Espaciado, radios y motion
```
Radios:   6px (tarjetas/botones), 8px (tarjetas destacadas/precios), 13px (subtarjetas de contenido), 999px (chips/pills), 50% (avatares)
Ancho máximo de contenido: 1200px (feed, proyecto, técnica, paso); 1120px (precios, creador, perfil); 820px (editor de paso)
Padding de página: clamp(16px,4vw,40px) horizontal
Altura del header: 64px
Breakpoint responsive: <1000px activa el header móvil + menú off-canvas
Transiciones: transform/box-shadow/border-color .18–.2s ease; tema .35s ease
Hover de tarjeta: translateY(-4px) + --bp-shadow + border-color:var(--primary)
Animación de entrada por pantalla: fadeUp .4s ease (opacity 0→1, translateY 8px→0)
Drawer móvil: slideIn .28s ease (translateX 100%→0)
```

## Screens / Views

Un estado global `view` conmuta entre pantallas: `feed`, `project`, `step`, `stepEdit`, `technique`, `pricing`, `creator`, `profile`. Header y footer son persistentes.

### 1. Header (persistente)
- Sticky top, `z-index:50`, fondo translúcido con `backdrop-filter:blur(14px)`, borde inferior 2px.
- Izquierda: logo = chip "1/35" (36×36, `--primary`, texto mono, offset naranja `2px 2px 0`) + wordmark "ESCALA." (Raleway 800 uppercase, punto en `--accent`).
- **Escritorio (≥1000px)**: nav (Feed, Técnicas, Precios, Mis proyectos — mono uppercase 12px, subrayado activo en acento) · selector "VER COMO" (Suscriptor/Pro/Modelista, segmented control en `--surface-2`) · toggle de tema (sol/luna) · avatar "MV".
- **Móvil (<1000px)**: logo + toggle de tema + botón hamburguesa que abre un **drawer off-canvas** desde la derecha (overlay oscuro, `width:min(86vw,330px)`), con nav, selector de tramo y acceso al perfil.

### 2. Feed de progreso (home) — `view:'feed'`
Muro visual que prioriza el progreso real. Ancho 1200px, layout de 2 columnas (contenido `flex:1 1 620px` + sidebar `flex:1 1 268px` sticky).
- **Eyebrow** mono uppercase en acento + **H1** "Progreso reciente" (Raleway) + tabs de filtro (Todo / Pasos / Terminados).
- **Tarjeta destacada** (featured): borde 2px `--bpborder`, radio 8px, `--bp-shadow`, barra superior de 4px en `--primary`. Miniatura grande (placeholder de rayas) + badge de tipo ("Nuevo paso") + título del paso + proyecto padre + autor (avatar + nombre) + chip de técnica destacada.
- **Rejilla** de tarjetas de actividad `repeat(auto-fill,minmax(260px,1fr))`, gap 18px. Cada tarjeta: miniatura 16/11, badge "Terminado" (check, azul) si aplica, botón de favorito (corazón) esquina superior derecha, tipo+tiempo (mono), título, línea de proyecto, autor + chip de técnica. Hover: `translateY(-4px)` + `--bp-shadow` + borde primary.
- **Candado Pro**: algunas tarjetas de paso muestran overlay con `backdrop-filter:blur(5px)`, icono de candado y píldora "Hazte Pro" cuando el tramo es gratuito y el paso es de pago.
- **Sidebar**: "Técnicas en tendencia" (chips), "Modelistas a seguir" (avatar + nombre + meta + botón Seguir), y CTA "Documenta tu build → Hazte Modelista".

### 3. Página de Proyecto (bitácora) — `view:'project'`
- **Portada** full-bleed (`height:clamp(240px,38vw,400px)`, placeholder de rayas + degradado inferior). Sobre ella: botón "← Feed", píldora de estado (punto de color + WIP/Terminado), temática (mono), **H1** título (Raleway 800 hasta 56px), subtítulo (mono), y botón **Favorito** ("Guardar"/"Guardado", corazón que se rellena en acento).
- **Barra de atributos**: fila de 6 celdas (Escala, Temática, Fabricante, Referencia, Dificultad, Estado), cada una con label mono uppercase + valor. Separadores de 1px, contenedor con borde y radio 12px.
- **Galería del build**: rejilla de fotos del resultado final (`minmax(150px,1fr)`), con encabezado "Galería del build / Fotos del resultado final".
- **Bitácora de montaje**: lista de pasos numerados. Cada fila: número grande (Raleway), miniatura 90×66 (con candado si bloqueado), título, duración (mono, con icono de reloj), chips de técnicas, botón editar (lápiz, solo Modelista) y chevron. Cabecera con contador de pasos y botón "+ Nuevo paso" (solo Modelista).
- **Comentarios**: input para comentar + lista. Cada comentario es una **tarjeta** (fondo surface, borde 1px, radio 13px, padding 15/18, hover borde acento) con avatar, autor, tiempo, texto, acciones **Me gusta** (corazón + contador, se rellena en acento) y **Responder** (abre caja de respuesta; respuestas anidadas con filete lateral izquierdo).
- **Sidebar (Accordion)**: dos paneles plegables — "Sobre el autor" (avatar, nombre, botón Seguir) y "Materiales descargables" (lista de archivos con icono + tamaño). Los materiales están **bloqueados para no-Pro**: overlay con blur + botón "Desbloquear con Pro" y badge "Pro" en la cabecera del panel. Chevron que rota 180° al abrir.
- Botón **"Exportar bitácora a PDF"**: activo (naranja) para Pro; para gratis muestra candado y lleva a precios.

### 4. Página de Paso — `view:'step'`
Tutorial limpio. Ancho 1200px.
- "← [proyecto]" · eyebrow "Paso NN de NN" (mono, acento) · botón "Editar paso" (solo Modelista).
- **H1** título del paso (Raleway 800).
- Fila de metadatos: píldora de **duración** (mono, icono reloj) + chips de técnicas asociadas (clicables → archivo por técnica).
- Encabezado "Galería de proceso / Trabajo en progreso" + **galería** de fotos del proceso (`repeat(auto-fit,minmax(140px,1fr))`).
- **Descripción**: tarjeta a ancho completo (surface, borde 1px, radio 13px, hover acento) con párrafos (17.5px, line-height 1.72). Debajo, **bloque de nota/consejo**: caja en `--accent-soft` con icono, a ancho completo.
- **Navegación anterior/siguiente**: dos tarjetas (izq. "← Anterior", der. "Siguiente →") con label mono + título; misma tarjeta base que comentarios y descripción.
- **Comentarios del paso**: igual patrón de tarjeta que en el proyecto.

### 5. Estado de bloqueo / teaser — `view:'step'` con tramo gratuito y paso de pago (índice ≥ 2)
La misma página de Paso vista por usuario gratuito:
- Contenido **teaser difuminado** (`filter:blur(9px); opacity:.6`) detrás.
- **Muro de upgrade elegante** centrado: tarjeta con icono de candado, "Desbloquea todos los pasos", descripción, lista de beneficios (checks), CTA "Hazte Pro — 6 €/mes" y enlace secundario "o previsualiza como Pro en esta demo".

### 6. Archivo por Técnica — `view:'technique'`
Página de descubrimiento por técnica (Aerografía, Lavados con óleos, Dry brushing, etc.).
- Eyebrow "Archivo por técnica" + **H1** nombre de la técnica + descripción.
- **Switcher** de técnicas (chips; el activo en `--accent`).
- **Rejilla** de proyectos/pasos que usan la técnica (`minmax(240px,1fr)`), cada tarjeta con miniatura, badge de tipo (Paso N / Proyecto), título y meta (autor · temática).

### 7. Precios — `view:'pricing'`
Tres tramos, rejilla `repeat(auto-fit,minmax(280px,1fr))`.
- **Suscriptor (Gratis)**: feed completo, ver proyectos y primeros pasos, comentar, favoritos, perfil básico.
- **Pro (6 €/mes)** — destacada: borde 2px `--primary`, `--bp-shadow`, badge "Más popular". Todo lo anterior + acceso a todos los pasos + PDF + materiales/plantillas + funciones sociales completas.
- **Modelista (12 €/mes)**: todo lo de Pro + crear bitácoras propias + editor de pasos/materiales + portafolio destacado + estadísticas.
- Cada tarjeta: nombre (Raleway), blurb, precio grande (Raleway) + periodo (mono), CTA (naranja en la destacada, ghost en las demás), lista de features con checks. El CTA del plan activo muestra "Tu plan actual".

### 8. Panel del creador (Modelista): "Mis proyectos" — `view:'creator'`
Totalmente integrado en el frontend (sin aspecto de admin).
- **Si el tramo no es Modelista**: estado de bloqueo con CTA "Ver plan Modelista" + "Previsualizar como Modelista".
- **Si es Modelista**: eyebrow "Panel del modelista" + H1 "Mis proyectos" + botón "Nuevo proyecto" (abre/cierra el editor).
- **Stats**: 4 tarjetas (Bitácoras, En progreso, Pasos, Favoritos).
- **Formulario de creación/edición de proyecto** (colapsable, borde en acento): Título · subida de Fotos (dropzone + miniaturas) · Escala / Temática (select) / Dificultad (select) · Fabricante / Referencia · **Técnicas** (chips toggle) · **Pasos** (filas reordenables con flechas ↑/↓ y eliminar; título editable inline; botón "+ Añadir paso" que **abre la pantalla de creación de paso**) · botones "Publicar bitácora" / "Guardar borrador".
- **Lista de proyectos propios**: filas con miniatura, título, meta, píldora de estado, botones "Ver" y "Editar".

### 8b. Editor de paso — `view:'stepEdit'`
Formulario integrado en frontend (ancho 820px). Se llega desde: lápiz de un paso en la bitácora, "Editar paso" en la página de paso, "+ Nuevo paso" en la cabecera de la bitácora, o "+ Añadir paso" en el formulario de nueva bitácora.
- "← [proyecto o borrador]" + eyebrow "Editor de bitácora" + H1 ("Nuevo paso" o "Editar paso NN").
- Campos: **Título** · **Galería de proceso** (dropzone "Subir foto" + miniaturas con botón de quitar; fotos del trabajo en progreso de ESE paso) · **Tiempo total de trabajo** (input mono con icono reloj + presets rápidos: 1 h / 1 h 30 min / 2 h / 3 h / 4 h+) · **Técnicas asociadas** (chips toggle) · **Instrucciones** (textarea) · botones "Guardar paso" / "Cancelar" (vuelven al proyecto o al panel según origen).

### 9. Perfil / portafolio de modelista — `view:'profile'`
- Banner de rejilla + avatar 96×96 (radio 24px) solapado + nombre (Raleway) + meta (mono: handle · ubicación · "Desde AAAA") + botón Seguir.
- Bio + **redes sociales** (chips con icono: Instagram, YouTube, Web) + stats (builds / pasos / seguidores).
- **Tabs**: Builds · Actividad · Favoritos (N).
  - **Builds**: rejilla de tarjetas (miniatura, píldora de estado, título, meta).
  - **Actividad**: timeline de eventos (icono + texto + tiempo).
  - **Favoritos**: rejilla de builds guardados (corazón relleno) o estado vacío elegante si no hay ninguno.

### Footer (persistente)
Borde superior 1px, wordmark "ESCALA." + línea mono "Bitácoras de modelismo estático · prototipo".

## Interactions & Behavior
- **Navegación**: SPA por estado `view`; cada cambio hace scroll al top y anima con `fadeUp .4s`.
- **Tramos (paywall)**: variable `tier` ∈ {free, pro, modelista}. Regla de bloqueo: en una bitácora, los pasos con índice ≥ 2 están bloqueados para `free` (candado en lista y feed; página de paso muestra el teaser difuminado + muro). Materiales y PDF requieren Pro. El panel del creador requiere Modelista.
- **Tema**: toggle claro/oscuro global, transición .35s. Selector inicial vía prop `defaultTheme`.
- **Favoritos**: alternable por proyecto; estado compartido entre feed, página de proyecto y pestaña Favoritos del perfil. Botón en tarjeta usa `stopPropagation` para no abrir la tarjeta. Disponible en todos los tramos.
- **Me gusta**: alternable por comentario, contador +1/−1, corazón se rellena en acento.
- **Responder**: abre caja de respuesta bajo el comentario; al enviar, añade respuesta anidada firmada por el usuario actual ("ahora"). Estado por comentario, independiente.
- **Accordion** (materiales/autor): paneles plegables, chevron rota 180°.
- **Editor de pasos**: reordenar con flechas ↑/↓, añadir/eliminar filas, edición inline de títulos; galería con añadir/quitar; presets de duración.
- **Responsive**: <1000px → header colapsa a hamburguesa + drawer off-canvas (`slideIn .28s`, overlay cierra al tocar fuera).

## State Management
Estado principal (raíz):
- `view` — pantalla activa.
- `theme` — 'light' | 'dark'.
- `tier` — 'free' | 'pro' | 'modelista' (controla todos los paywalls).
- `feedFilter` — 'all' | 'step' | 'done'.
- `projectId`, `stepIndex` — navegación de contenido.
- `technique` — técnica activa en el archivo.
- `profileTab` — 'builds' | 'activity' | 'favorites'.
- `isNarrow`, `menuOpen` — estado responsive / drawer (listener de `resize`, breakpoint 1000px).
- `acc:{autor,materiales}` — paneles del accordion.
- `ci:{}` — interacciones de comentarios por id: `{liked, replyOpen, draft, replies[]}`.
- `favs:{}` — favoritos por projectId (boolean).
- `editor:{...}` — borrador de proyecto (título, temática, escala, fabricante, ref, dificultad, techniques[], steps[]).
- `stepEd:{title,duration,techniques[],photos,body}` + `stepIndex` (-1 = nuevo) + `stepEdFrom` ('project'|'creator', decide el retorno).

Props tweakables (configuración): `accentColor` (color), `defaultTheme` (Claro/Oscuro), `previewTier` (Suscriptor/Pro/Modelista).

Datos: hay una "DB" en memoria con varios proyectos (Panther, Spitfire, diorama, Yamato, figura, Sherman), cada uno con steps[], finishedGallery[], materials[], comments[]. En producción esto viene de la API/CMS.

## Responsive behavior
- Contenedores con `max-width` + `clamp()` en paddings y tamaños de fuente.
- Rejillas con `repeat(auto-fill/auto-fit, minmax(...))` — reflujo automático.
- Header conmuta a móvil <1000px; el resto de layouts usan flex-wrap y se apilan de forma natural.
- Objetivos táctiles ≥ 38–44px.

## Assets
- **Fotos**: todas son **placeholders** (patrón de rayas diagonales con `repeating-linear-gradient` en `--pa`/`--pb`, con etiqueta de texto). Sustituir por fotos reales de miniaturas y trabajos en progreso. Cada slot lleva una etiqueta descriptiva del contenido esperado.
- **Iconos**: SVG inline (stroke), estilo lineal 2px. Redes sociales, reloj (duración), candado (paywall), corazón (favorito/like), flechas, lápiz (editar), documento (materiales), check.
- **Fuentes**: Google Fonts (Raleway, Montserrat, JetBrains Mono).
- Sin imágenes binarias ni logos externos en el prototipo.

## Mapeo a WordPress + Elementor Pro (Astra) — si es el stack destino
El diseño ya está estructurado para mapear 1:1 a widgets nativos:
- **Header + menú móvil** → Astra Header Builder con off-canvas.
- **Feed y Archivo por técnica** → Elementor **Loop Grid** con plantilla de tarjeta (Card Template).
- **Materiales + Sobre el autor** → widget **Accordion**.
- **Perfil (Builds / Actividad / Favoritos)** → widget **Tabs**.
- **Precios** → **Pricing Table** (3 tramos, destacado "Más popular").
- **Editor de bitácoras/pasos** → **Elementor Forms** (o formulario a medida) — requiere backend para CRUD de builds/pasos y control de acceso por rol (paywall).
- **Fuentes y color** → Astra Global Fonts (Raleway/Montserrat/JetBrains Mono) y Global Colors (azul primary, naranja accent).
- El **paywall por tramo** y los **CRUD del creador** necesitan lógica de servidor (membresías + custom post types "build" y "step"); Elementor solo cubre la capa visual.

## Files
- `Escala.dc.html` — el prototipo completo (las 8 pantallas + editor de paso). Contiene la plantilla y la clase de lógica con todos los viewmodels y datos de ejemplo.
- `support.js` — runtime del Design Component. **Solo para ver el prototipo**; no portar a producción.
- `screenshots/` — capturas de referencia de cada pantalla (feed, proyecto, lista de pasos, paso, teaser/bloqueo, archivo por técnica, precios, panel del creador, formulario de creación, editor de paso, perfil).
