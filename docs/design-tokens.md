# Tokens de diseño — "Blueprint / Industrial"

Extraídos del prototipo `docs/design/Escala.dc.html`. Los valores son **finales**
(handoff hi-fi): colores, tipografía, espaciados, radios, sombras e interacciones.

El prototipo trae su propio runtime (`support.js`). **No se porta**: se recrean los
diseños con los patrones de Next.js.

## Fuentes

```
Display / titulares : Raleway 800        (uppercase, letter-spacing .02–.04em)
Cuerpo              : Montserrat         (400 / 500 / 600 / 700)
Monoespaciada       : JetBrains Mono     (400 / 500 / 600)
```

**Todo lo técnico va en mono**: escalas, tiempos, precios, referencias de kit,
metadatos, eyebrows y etiquetas de la nav. Es lo que da el aire de plano de ingeniería.

## Color

| Token | Claro | Oscuro |
|---|---|---|
| `--bg` | `hsl(210 20% 98%)` | `hsl(213 31% 10%)` |
| `--surface` | `hsl(0 0% 100%)` | `hsl(213 31% 13%)` |
| `--surface-2` | `hsl(210 14% 93%)` | `hsl(213 31% 18%)` |
| `--text` | `hsl(213 31% 15%)` | `hsl(210 20% 95%)` |
| `--muted` | `hsl(213 16% 45%)` | `hsl(213 16% 62%)` |
| `--faint` | `hsl(213 16% 58%)` | `hsl(213 16% 48%)` |
| `--border` | `hsl(213 20% 86%)` | `hsl(213 31% 24%)` |
| `--bpborder` | `hsl(213 20% 82%)` | `hsl(213 31% 28%)` |
| `--grid` | `hsl(213 30% 92%)` | `hsl(213 31% 16%)` |
| `--primary` | `hsl(213 56% 24%)` | `hsl(213 56% 58%)` |
| `--primary-contrast` | `hsl(210 40% 98%)` | `hsl(213 31% 10%)` |
| `--accent` | `hsl(32 95% 52%)` | `hsl(32 95% 54%)` |
| `--accent-contrast` | `#ffffff` | `#1a1205` |
| `--rust` | `hsl(0 74% 52%)` | `hsl(0 62% 52%)` |
| `--pa` / `--pb` | `hsl(213 34% 90%)` / `hsl(213 28% 95%)` | `hsl(213 31% 19%)` / `hsl(213 31% 14%)` |
| `--shadow` | `hsl(213 31% 15% / .09)` | `rgba(0,0,0,.5)` |

Derivados:

```css
--accent-soft:  color-mix(in srgb, var(--accent) 14%, var(--bg));
--primary-soft: color-mix(in srgb, var(--primary) 12%, var(--bg));
--bp-shadow:    4px 4px 0 0 var(--bpborder);
```

**Semántica:** azul `--primary` = estructural y **Terminado**. Naranja `--accent` =
CTA y **WIP**.

## Las dos señas de identidad

**1. Rejilla de ingeniería** — 40×40 px sobre toda la página:

```css
background-image:
  linear-gradient(var(--grid) 1px, transparent 1px),
  linear-gradient(90deg, var(--grid) 1px, transparent 1px);
background-size: 40px 40px;
```

**2. Sombra blueprint** — dura, **sin desenfoque**. No es una sombra difusa:

```css
box-shadow: 4px 4px 0 0 var(--bpborder);
```

Se usa en tarjetas destacadas y en hover. Si aparece un `blur` en ese `box-shadow`,
está mal.

## Medidas

```
Radios      : 6px tarjetas/botones · 8px destacadas/precios · 13px subtarjetas
              999px chips/pills · 50% avatares
Anchos      : 1200px feed/proyecto/técnica/paso · 1120px precios/creador/perfil
              820px editor de paso
Padding     : clamp(16px, 4vw, 40px) horizontal
Header      : 64px de alto, sticky, z-index 50, backdrop-filter blur(14px)
Breakpoint  : <1000px → header móvil + drawer off-canvas
Táctil      : ≥ 38–44px
```

## Movimiento

```
Transiciones : transform/box-shadow/border-color .18–.2s ease · tema .35s ease
Hover tarjeta: translateY(-4px) + var(--bp-shadow) + border-color var(--primary)
Entrada      : fadeUp .4s ease (opacity 0→1, translateY 8px→0)
Drawer       : slideIn .28s ease (translateX 100%→0)
Muro de pago : contenido detrás con filter: blur(9px); opacity: .6
Candado feed : overlay con backdrop-filter: blur(5px)
```

## Estados de bloqueo

Tres tratamientos distintos, no intercambiables:

| Contexto | Tratamiento |
|---|---|
| Tarjeta del feed | Overlay `backdrop-filter: blur(5px)` + candado + píldora "Hazte Pro" |
| Fila de paso en la bitácora | Candado sobre la miniatura de 90×66 |
| Página de paso completa | Teaser difuminado detrás + muro centrado con beneficios y CTA |
| Panel de materiales | Overlay con blur + botón "Desbloquear con Pro" + badge "Pro" en la cabecera |

## Placeholders

Todas las fotos del prototipo son marcadores: rayas diagonales con
`repeating-linear-gradient` entre `--pa` y `--pb`, con una etiqueta que describe el
contenido esperado. Conviene conservar ese componente para los estados de carga y de
vacío.

## Nota sobre el acento configurable

El prototipo expone `accentColor` como propiedad ajustable (naranja `#F7941D` por
defecto, más azul, verde y violeta). En oscuro lo aclara con
`color-mix(in srgb, <color> 82%, #fff)`. Merece la pena conservar ese mecanismo: es
gratis si los tokens se definen como variables CSS desde el principio.
