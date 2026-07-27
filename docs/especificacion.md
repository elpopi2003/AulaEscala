# CLAUDE.md — AULAESCALA

> Plataforma comunitaria de modelismo estático a escala.
> Stack: **React (Next.js) + Supabase + Resend + Stripe**.
> Archivo de contexto para Claude Code. Léelo entero antes de escribir código. Nada está construido todavía.

---

## 1. Qué construimos

**AULAESCALA** es una plataforma comunitaria para **modelismo estático a escala** (maquetas, dioramas, figuras, blindados, aviación, naval). El núcleo son las **bitácoras de montaje**: proyectos documentados paso a paso, con técnicas etiquetadas, orientados al aprendizaje técnico práctico. No es un foro ni una red social genérica: es un "build-log estructurado premium".

**Diferenciador:** un **feed que prioriza el progreso real** (nuevos pasos publicados, proyectos terminados) sobre publicaciones genéricas. El feed es además el motor de conversión: el usuario gratuito ve el evento "nuevo paso publicado", pero al abrirlo encuentra el muro de Pro.

**Idioma:** contenido **en español** en el MVP, pero el esquema nace **preparado para multiidioma** (§3.4). No se implementa i18n ahora; se evita que sea imposible después.

---

## 2. Stack

| Capa | Tecnología | Rol |
|---|---|---|
| Frontend | **Next.js (App Router, TypeScript)** | SSG/ISR para lo público e indexable; SSR/CSR para lo personalizado |
| Backend / datos | **Supabase** | Postgres, Auth, Storage, Realtime, Edge Functions, **RLS** |
| Búsqueda | **Postgres FTS** (`tsvector` + `unaccent` + `pg_trgm`) | Decidido: RLS se aplica nativamente, un servicio menos |
| Email | **Resend** | Transaccional + notificaciones y digests |
| Pagos | **Stripe** | Checkout + Customer Portal + webhooks → escriben el tramo en Supabase |

**Por qué Next.js y no un SPA:** el contenido público (proyectos, feed, archivos por técnica) debe ser **indexable por Google** — es la puerta de entrada del embudo.

---

## 3. Modelo de datos (Postgres)

### 3.1 El split crítico: metadatos públicos vs. cuerpo de pago

RLS es **row-level**, no column-level: sobre una fila, o se ve entera o no se ve. Pero la búsqueda pública debe devolver el **título** de un paso a un anónimo (como teaser), mientras que el **cuerpo** es contenido de pago.

**Solución: separar en dos tablas.**

- `steps` → metadatos **públicos** (título, posición, proyecto padre, miniatura). Política pública. Indexado para búsqueda pública.
- `step_bodies` → **cuerpo de pago**. Política Pro/Modelista. Indexado aparte para búsqueda dentro del contenido (solo Pro).

Así la fuga de contenido de pago es **estructuralmente imposible**: el dato no está en la tabla que el anónimo puede consultar. Aplicar el mismo criterio a cualquier campo protegido que aparezca en el futuro.

### 3.2 Tablas

```
profiles          id (=auth.users), display_name, slug, avatar_url, bio,
                  preferred_scales[], preferred_subjects[], created_at

subscriptions     user_id, tier ('subscriber'|'pro'|'modelista'), status,
                  stripe_customer_id, stripe_subscription_id, current_period_end

projects          id, author_id, title, slug, body, cover_url,
                  manufacturer, kit_ref, difficulty, build_status ('wip'|'finished'),
                  scale_id, subject_id, status ('draft'|'published'), published_at,
                  locale, translation_group_id, search_vector
                  → UNIQUE (locale, slug)

steps             id, project_id (FK), position int, title, thumb_url,
                  status, published_at, locale, translation_group_id, search_vector
                  → UNIQUE (project_id, position)      -- METADATOS PÚBLICOS

step_bodies       step_id PK/FK, body, search_vector    -- CUERPO DE PAGO (Pro+)

techniques        id, slug, name, moderation_status, search_vector
scales            id, name (1/35, 1/48, 1/72…)
subjects          id, name (blindados, aviación, figuras, naval…)

project_techniques (project_id, technique_id)   -- N:M
step_techniques    (step_id, technique_id)      -- N:M

media             id, owner_id, project_id?, step_id?, storage_path, kind, position
materials         id, project_id, storage_path, filename, mime, size   -- PAGO (Pro+)

comments          id, author_id, project_id?, step_id?, body, created_at
                  → CHECK: exactamente uno de project_id / step_id no nulo

activity          id, actor_id, type, project_id?, step_id?,
                  snapshot jsonb (TEASER-SEGURO), score numeric, created_at
                  → INDEX (score DESC, created_at DESC)

follows           (follower_id, followee_id)
favorites         (user_id, project_id)

conversations     id, created_at
conversation_participants (conversation_id, user_id)
messages          id, conversation_id, sender_id, body, created_at, read_at

notifications     id, user_id, type, payload jsonb, read_at, created_at

reports           id, reporter_id, target_type, target_id, reason, status, created_at
                  → diferido en producto, pero la tabla nace ya (§8)
```

### 3.3 Búsqueda en español (FTS)

```sql
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Configuración: stemmer español + insensible a tildes
CREATE TEXT SEARCH CONFIGURATION es_unaccent (COPY = spanish);
ALTER TEXT SEARCH CONFIGURATION es_unaccent
  ALTER MAPPING FOR hword, hword_part, word
  WITH unaccent, spanish_stem;
```

- `search_vector` como **columna generada** `GENERATED ALWAYS AS (to_tsvector('es_unaccent', ...)) STORED` + índice **GIN**. Es válido porque `to_tsvector(regconfig, text)` es IMMUTABLE con configuración fija.
- ⚠️ Cuando llegue el multiidioma, la configuración dependerá de `locale` y **habrá que pasar de columna generada a trigger** (el cast `text::regconfig` no es immutable).
- `pg_trgm` (índice GIN sobre títulos y nombres de técnica) para tolerancia a erratas y para la **detección de duplicados de técnicas** (§7.2).
- `unaccent` es imprescindible: "aerografia" debe encontrar "aerografía".

### 3.4 Preparación para multiidioma (sin implementarlo)

- `locale text NOT NULL DEFAULT 'es'` en `projects` y `steps`.
- `translation_group_id uuid` — todas las traducciones de un mismo contenido comparten valor. `UNIQUE (translation_group_id, locale)`.
- Slugs únicos **por locale**, no globalmente: `UNIQUE (locale, slug)`.
- **Rutas:** decidir ya si las URLs llevan prefijo de idioma (`/es/proyectos/...`) desde el día uno. Añadirlo después obliga a redirecciones y tiene coste SEO. *Recomendado: prefijo desde el inicio.*
- **Nombres de taxonomías**: se quedan en columna `name` (español). Migrar a `technique_translations` cuando toque es aditivo y barato (los IDs no cambian). No se hace ahora.

### 3.5 Principios

- El orden de los pasos es `position` (entero indexado).
- `activity.snapshot` contiene **solo** lo que pinta la tarjeta del feed. **Nunca** el cuerpo del paso.
- `activity.score` se **precomputa al escribir** (trigger), nunca en lectura. El feed es una `SELECT ... ORDER BY score DESC, created_at DESC` sobre una tabla indexada.
- Migraciones versionadas en `/supabase/migrations`. Nada de cambios de esquema a mano en el panel.

---

## 4. Tramos y matriz de acceso

Modelo **freemium de tres tramos**:

| Capacidad | Anónimo | Suscriptor (gratis) | Pro (pago) | Modelista (pago+) |
|---|---|---|---|---|
| Ver feed y proyectos | ✓ | ✓ | ✓ | ✓ |
| **Búsqueda** (proyectos, títulos de paso, técnicas, usuarios) | ✓ | ✓ | ✓ | ✓ |
| Búsqueda **dentro del cuerpo** de los pasos | ✗ | ✗ | ✓ | ✓ |
| Comentar / favoritos / follows | ✗ | ✓ | ✓ | ✓ |
| **Notificaciones** (in-app + email) | ✗ | ✗ | ✓ | ✓ |
| **Mensajería privada** | ✗ | ✗ | ✓ | ✓ |
| Ver **cuerpo de pasos**, PDF, materiales | ✗ | ✗ | ✓ | ✓ |
| Crear/editar proyectos, pasos, técnicas, materiales | ✗ | ✗ | ✗ | ✓ |

- **El límite de pago está en el cuerpo del Paso.** El proyecto y los títulos de los pasos son públicos e indexables; el paso a paso es de pago. Eso hace del feed y de la búsqueda motores de conversión.
- **Suscriptor fuera de la mensajería en ambos sentidos:** ni envía ni recibe. Un Pro **no puede contactarle**. Los Suscriptores **no aparecen** en el selector de destinatarios (filtrar en la búsqueda de contactos, no solo rechazar el envío).
- Los tramos **no anidan solos**: toda política que autorice a Pro debe autorizar también a Modelista.

---

## 5. Control de acceso — RLS es la frontera de seguridad

Todo el acceso se aplica con **Row Level Security en Postgres**. La base de datos lo impone aunque la petición llegue directa desde el navegador.

**Consecuencia crítica:** una política RLS mal escrita **es** una fuga de contenido de pago. Se testean explícitamente, por tramo, en CI (§12).

| Tabla | SELECT | INSERT / UPDATE / DELETE |
|---|---|---|
| `projects` | Público si `status='published'` | Solo autor **y** tramo `modelista` |
| `steps` (metadatos) | **Público** si el proyecto está publicado | Solo autor **y** `modelista` |
| `step_bodies` | **Solo `pro` o `modelista`** (+ autor sobre lo suyo) | Solo autor **y** `modelista` |
| `materials` | **Solo `pro` o `modelista`** | Solo autor **y** `modelista` |
| `techniques` | Público | Crear: `modelista` (directo, §7.2) |
| `comments` | Público (sobre contenido visible) | Autenticado; editar/borrar solo lo propio |
| `activity` | Público (snapshot teaser-seguro) | Solo por trigger/servicio, nunca por cliente |
| `messages`, `conversations` | Solo participantes **y** `pro`/`modelista` | Igual |
| `notifications` | Solo el propio usuario | Solo por servicio |
| `subscriptions` | Solo el propio usuario (lectura) | **Solo `service_role`** (webhook de Stripe) |
| `reports` | Solo `admin` | Crear: autenticado |

**Resolución del tramo:** función `auth.user_tier()` (SECURITY DEFINER) que lee `subscriptions`. *Decidido: siempre fresca.* Optimizar a custom claims del JWT es posible después (más rápido, pero el claim se queda obsoleto al cambiar la suscripción y obliga a forzar refresh del token).

**Storage:**
- Bucket **público**: portadas de proyecto, miniaturas de paso, imágenes del feed.
- Bucket **privado**: imágenes del cuerpo de los pasos y **materiales descargables**. Se sirven con **signed URLs de vida corta** generadas tras verificar el tramo. Nunca URLs públicas permanentes para contenido de pago.

---

## 6. Feed de progreso

- Tabla `activity` con eventos (`step_published`, `project_finished`, `project_updated`, …).
- **Peso precomputado en la escritura** (trigger). El progreso real pesa más que la publicación genérica. La tabla de pesos se documenta en `/docs` para poder afinarla.
- El feed público es cacheable (ISR); el personalizado se resuelve en runtime.
- **`snapshot` teaser-seguro**: título, miniatura, autor, proyecto padre. Nunca el cuerpo del paso.

---

## 7. Publicación y moderación

### 7.1 Publicación directa (decidido)

Lo que publica un Modelista **se publica directo**, sin cola de revisión: son creadores que pagan y la fricción no compensa. `status` distingue `draft` / `published` (borradores sí, moderación previa no).

**Consecuencia:** sin filtro previo, **moderación y reportes suben de prioridad** para el lanzamiento público (§8).

### 7.2 Técnicas: directo, pero con anti-duplicados

Las técnicas son **taxonomía**, y su riesgo no es la calidad sino la **contaminación estructural** de los archivos por técnica (que son puertas de SEO y el eje del filtrado). Sin control, aparecerán "dry brushing", "drybrush" y "pincel seco" como tres términos distintos.

Solución **sin añadir espera**:
- Al escribir una técnica, autocompletado sobre las existentes con **similitud `pg_trgm`**: "¿querías decir *Dry brushing*?".
- Si aun así crea una nueva, se publica **directa** (sin cola) pero queda marcada para revisión del operador.
- **Herramienta de fusión** en el panel de operador: unificar términos duplicados reasignando las relaciones N:M.

---

## 8. Alcance del MVP

| Pieza | ¿MVP? | Notas |
|---|---|---|
| Bitácoras: proyectos, pasos, técnicas, materiales | **SÍ** (núcleo) | §3 |
| Feed de progreso | **SÍ** (núcleo) | §6 |
| Búsqueda pública (Postgres FTS) | **SÍ** (inexcusable) | §3.3 |
| Autoría desde el frontend (Modelista) | **SÍ** | §9 |
| Notificaciones (in-app + email vía Resend) | **SÍ** — Pro+ | Plantillas y digests propios |
| Mensajería privada (Realtime) | **SÍ** — Pro+ | Supabase Realtime abarata mucho esta pieza |
| Perfiles / portafolio, comentarios, favoritos, follows | **SÍ** | Modelos simples |
| Exportar bitácora a PDF | **SÍ** — Pro+ | Acción **bajo demanda**, nunca en cada visita. Motor por decidir (§10) |
| **Grupos** | **NO** | Fuera del MVP |
| **Moderación y reportes** | **Diferido en producto** | ⚠️ La tabla `reports` nace ya. **Requerido antes del lanzamiento público**: en la UE, reporte y retirada de UGC entra en terreno regulatorio (DSA), y con publicación directa no hay filtro previo. Confirmar con asesoría legal |
| **App móvil nativa** | **Fase 2** | Sobre la misma API/Supabase (PWA o React Native) |
| **Multiidioma** | **Fase 2** | Esquema preparado (§3.4), no implementado |

---

## 9. Autoría y panel de creador

- Crear y editar proyectos, pasos, técnicas y materiales es **exclusivo del tramo Modelista** y ocurre **íntegramente en el frontend**. No existe un "backend" al que ningún usuario acceda.
- El **panel de operador** (moderación, fusión de técnicas, gestión) es una zona propia de la app con rol `admin`. Supabase Studio solo para tareas puntuales de arranque, nunca como interfaz de producto.
- Formularios con validación compartida (esquemas Zod reutilizados en cliente y servidor). El orden de los pasos se edita con drag & drop sobre `position`.
- Al crear un paso se escriben **dos tablas** (`steps` + `step_bodies`) — encapsularlo en una función/RPC transaccional.
- Subida de media directa a Supabase Storage con validación de tipo y tamaño, y saneado de nombres. Las imágenes del cuerpo van al bucket **privado**; la miniatura del paso, al **público**.

---

## 10. Decisiones abiertas

- [ ] **Rutas i18n:** ¿prefijo `/es/` desde el día uno (recomendado) o raíz sin prefijo?
- [ ] **Motor de PDF:** cliente (`@react-pdf/renderer`) vs servidor (función serverless con renderizado headless).
- [ ] **Precio de Pro y de Modelista.**
- [ ] **Contenido de la página de precios** (el social de Pro es notificaciones + mensajería + acceso completo).
- [ ] **Downgrade:** el contenido del Modelista permanece visible y pierde crear/editar *(asumido por defecto; confirmar)*.
- [ ] **IVA UE/OSS:** las suscripciones digitales tributan según ubicación del cliente. Stripe Tax lo cubre. Confirmar con asesoría fiscal.

---

## 11. Estructura de repositorio

```
/apps/web            → Next.js (App Router, TypeScript)
/supabase
  /migrations        → esquema versionado (SQL)
  /functions         → Edge Functions (webhooks Stripe, emails Resend, scoring del feed)
  /tests             → tests de políticas RLS
/packages/shared     → tipos generados de la BD, esquemas Zod, utilidades
/docs                → ADRs, esquema, matriz de acceso, tabla de pesos del feed
```

Comandos previstos (crear durante el scaffolding):

```
supabase start                  # entorno local
supabase db reset               # migraciones + seed
supabase gen types typescript   # tipos TS desde el esquema
pnpm dev                        # Next.js en desarrollo
pnpm test                       # incluye tests de RLS
pnpm lint && pnpm build
```

---

## 12. Primeras tareas

1. **Esquema y RLS.** Migraciones de §3 (incluido el split `steps` / `step_bodies`, extensiones FTS y campos i18n) + políticas de §5. Es el cimiento: barato ahora, caro con datos dentro.
2. **Tests de RLS por tramo, antes de construir UI.** Incluye el **test de no-fuga** (§13).
3. **Auth + Stripe.** Supabase Auth; Checkout y Customer Portal; **webhook → `subscriptions`** con `service_role`. El tramo lo escribe solo el webhook, nunca el cliente.
4. **Scaffolding Next.js** + cliente Supabase + tipos generados + Zod compartido.
5. **Pantallas núcleo, en este orden:** feed → detalle de proyecto → **estado bloqueado / teaser** (las tres que definen el producto) → detalle de paso → archivo por técnica → búsqueda → precios → panel del creador → perfil.
6. **Feed:** tabla `activity`, trigger de scoring, tabla de pesos documentada.
7. **Subsistemas Pro:** notificaciones (Resend) → mensajería (Realtime) → export PDF.

---

## 13. Convenciones y principios

- **RLS es la seguridad.** El cliente nunca es la última línea de defensa. Toda tabla lleva RLS activo; nada se sirve con `service_role` desde el navegador.
- **Test de no-fuga obligatorio en CI:** verificar que anónimo y Suscriptor **no** obtienen el cuerpo de un paso ni un material por **ninguna** vía (consulta directa, feed, búsqueda, Storage). Bloquea el merge.
- **Separar por tabla lo protegido de lo público** (§3.1) en lugar de confiar en filtrar columnas.
- **Teaser-seguro por construcción:** `activity.snapshot`, resultados de búsqueda y respuestas públicas contienen solo metadatos. Si dudas, no lo incluyas.
- **Esquema como código:** migraciones versionadas y tipos generados. Nada de cambios manuales en el panel.
- **Precomputar en escritura, no en lectura** (el score del feed es el caso canónico).
- **SEO:** el contenido público se renderiza estático/SSR para ser indexable. El registro gratuito se exige para participar, nunca para ver.
- **Storage:** contenido de pago siempre en bucket privado con signed URLs de vida corta.
