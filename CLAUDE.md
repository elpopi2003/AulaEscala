# CLAUDE.md — AULAESCALA

> Plataforma comunitaria de modelismo estático a escala.
> Stack: **Next.js + Supabase + Resend + Stripe**.
> Léelo entero antes de escribir código.

La especificación de producto completa está en [`docs/especificacion.md`](docs/especificacion.md).
Este fichero es el **estado vivo**: qué hay construido, qué se decidió y qué queda.

---

## 1. Estado actual

| Pieza | Estado |
|---|---|
| Esquema Postgres (§3) | **Hecho** — 13 migraciones en `/supabase/migrations` |
| Políticas RLS por tramo (§5) | **Hecho** — co-locadas con cada tabla |
| Test de no-fuga (§13) | **Hecho** — `/supabase/tests`, bloquea el merge en CI |
| Storage: buckets y políticas | **Hecho** |
| Stripe: webhook, Checkout y Portal (§12.3) | **Hecho y probado de punta a punta** — pago en modo test → tramo → muro abierto. Ver [docs/stripe.md](docs/stripe.md) |
| Auth (Supabase) | **Hecho** — login y alta automática de perfil verificados en producción |
| Taxonomías sembradas en remoto | **Hecho** — 11 escalas, 8 temáticas, 20 técnicas |
| Scaffolding Next.js (§12.4) | **Hecho** — App Router con `/[locale]`, clientes Supabase, tokens Blueprint/Industrial, tema claro/oscuro |
| Pantallas núcleo (§12.5) | **Las 3 que definen el producto**: feed → proyecto → paso con muro. Faltan técnica, búsqueda, precios, panel del creador y perfil |

### Aviso de entorno

`next/font/google` **descarga las fuentes en tiempo de build** y las sirve desde el
propio dominio (bien para el RGPD: no se envía la IP del visitante a Google). Si la
red interpone TLS, esa descarga falla con `UNABLE_TO_VERIFY_LEAF_SIGNATURE` y Next cae
a fuentes del sistema — la app funciona, pero se ve con la tipografía equivocada.
Ocurre en local, no en CI ni en despliegue. Si pasa: `node --use-system-ca`.

El proyecto Supabase es `yyigaxclclxanlovxarh` (región `eu-central-1`, Postgres 17).
**Las migraciones ya están aplicadas ahí.** El esquema del repo y el remoto coinciden.

---

## 2. Reglas que no se negocian

- **La RLS es la seguridad.** El cliente nunca es la última línea de defensa. Toda tabla lleva RLS activo; nada se sirve con `service_role` desde el navegador.
- **Lo protegido se separa por tabla, no por columna** (§3.1). `steps` es público; `step_bodies` es de pago. Si aparece un campo protegido nuevo, va a una tabla con su política — **jamás** como columna de una tabla pública.
- **Teaser-seguro por construcción.** `activity.snapshot`, los resultados de búsqueda y toda respuesta pública contienen solo metadatos. Si dudas, no lo incluyas.
- **Precomputar en escritura, no en lectura.** El `score` del feed es el caso canónico: se calcula en un trigger, nunca al leer.
- **Esquema como código.** Migraciones versionadas y tipos generados. Nada de cambios a mano en el panel de Supabase.
- **El test de no-fuga bloquea el merge.** Si `supabase test db` falla, hay contenido de pago accesible gratis.

---

## 3. Cómo funciona el control de acceso

Todo cuelga de dos funciones (`20260726090300_subscriptions_and_tier.sql`):

```sql
public.user_tier()            -- tramo del usuario actual; NULL si es anónimo
public.is_at_least('pro')     -- predicado que usan las políticas
```

`is_at_least` compara **rangos numéricos** (`anon 0 < subscriber 1 < pro 2 < modelista 3`).
Eso resuelve §4 —"los tramos no anidan solos"— de forma estructural: toda política
que autoriza a Pro autoriza automáticamente a Modelista, sin escribirlo dos veces.

**Dos reglas al escribir políticas:**

1. **Envuelve siempre las funciones en un `select`:**
   ```sql
   using ( (select public.is_at_least('pro')) )   -- ✅ InitPlan, se evalúa 1 vez
   using ( public.is_at_least('pro') )            -- ❌ se evalúa 1 vez POR FILA
   ```

2. **`revoke ... from anon, authenticated` no basta en funciones.** Postgres concede
   `EXECUTE` a `PUBLIC` por defecto y Supabase expone `public` entero como
   `/rest/v1/rpc/*`. Hay que revocar **de `PUBLIC`**. Ver
   `20260726091400_harden_function_privileges.sql`: ese descuido dejaba
   `build_step_snapshot()` accesible a cualquiera, y esa función salta la RLS.

**El único punto de decisión sobre el cuerpo de pago es `public.can_view_step_body(step_id)`.**
Lo usan la política de `step_bodies`, la de `media` privada y la de Storage. Si alguna
de las tres divergiera, habría fuga por una vía y no por otra. No la dupliques: llámala.

### Privilegios de columna

La RLS es *row*-level. La política de UPDATE de `profiles` permite editar
**cualquier** columna de la fila propia, incluida `role`. Lo único que impide que un
usuario se ascienda a admin es el privilegio de columna
(`20260726090200_profiles.sql`). Cuidado: un `GRANT UPDATE` a nivel de tabla implica
todas las columnas y revocar unas pocas no surte efecto — hay que revocar la tabla
entera y volver a conceder la allowlist.

---

## 4. Decisiones cerradas

| Decisión | Valor | Dónde |
|---|---|---|
| Marca en la UI | **AULAESCALA.** (punto en `--accent`) | [ADR 0001](docs/adr/0001-marca.md) |
| Rutas i18n | **Prefijo `/es/` desde el día uno** | [ADR 0002](docs/adr/0002-rutas-i18n.md) |
| Resolución de tramo | `public.user_tier()`, no `auth.user_tier()` | [ADR 0003](docs/adr/0003-tramo-en-esquema-public.md) |
| Teaser de pasos gratis | **Los 2 primeros pasos abiertos** (`free_preview_steps = 2`) | [ADR 0004](docs/adr/0004-teaser-de-pasos.md) |
| Publicación | Directa, sin cola de revisión (§7.1) | spec §7 |
| Downgrade | El contenido sigue visible; se pierde crear/editar | implementado en las políticas |

### Abiertas

- [ ] **Motor de PDF:** cliente (`@react-pdf/renderer`) vs. serverless headless.
- [ ] **Precio de Pro y Modelista** — el diseño usa 6 €/mes y 12 €/mes.
- [ ] **IVA UE/OSS** — Stripe Tax lo cubre. Confirmar con asesoría fiscal.
- [ ] **Moderación y reportes** — diferido en producto, pero la tabla `reports` ya existe. **Requerido antes del lanzamiento público** (DSA + publicación directa). Confirmar con asesoría legal.

---

## 5. Estructura

```
/apps/web            → Next.js (App Router, TypeScript), rutas bajo /[locale]
/supabase
  /migrations        → esquema versionado
  /functions         → Edge Functions (webhook Stripe, Resend, scoring)
  /tests             → pgTAP: no-fuga + matriz de escritura
  seed.sql           → taxonomías (escalas, temáticas, técnicas)
/packages/shared     → tipos generados, esquemas Zod, utilidades
/docs                → especificación, ADRs, matriz de acceso, pesos del feed
/docs/design         → handoff de diseño (prototipo HTML + capturas)
```

## 6. Comandos

```bash
pnpm db:start      # Supabase local (requiere Docker)
pnpm db:reset      # migraciones + seed
pnpm db:types      # regenera packages/shared/src/database.types.ts
pnpm test:rls      # test de no-fuga + matriz de escritura
pnpm dev           # Next.js
pnpm lint && pnpm build
```

Tras **cualquier** cambio de esquema: `pnpm db:types`. CI falla si los tipos generados
no coinciden con el esquema.

---

## 7. Sistema de diseño — "Blueprint / Industrial"

Tokens exactos en [`docs/design-tokens.md`](docs/design-tokens.md); prototipo navegable
en `docs/design/Escala.dc.html`. Lo esencial:

- Rejilla de ingeniería de 40×40 px sobre toda la página.
- Sombra blueprint: `4px 4px 0 0 var(--bpborder)` — **dura, sin desenfoque**.
- Titulares en Raleway 800; cuerpo en Montserrat; **todo lo técnico** (escalas,
  tiempos, precios, referencias de kit, metadatos) en JetBrains Mono.
- Azul estructural = `--primary`; naranja precisión = `--accent` (CTA).
  Terminado = azul, WIP = naranja.

⚠️ El prototipo trae su propio runtime (`support.js`) con `<sc-for>`, `<sc-if>` y una
clase `DCLogic`. **No se porta a producción**: es solo para ver el diseño. El handoff
también menciona WordPress + Elementor como stack alternativo — **descartado**, el
stack es el de este documento.
