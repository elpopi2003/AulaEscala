# Matriz de acceso

Referencia única de quién puede hacer qué. Si esta tabla y una política divergen,
**la política es la que manda** — y una de las dos está mal.

Los tramos se resuelven con `public.user_tier()` y se comparan con
`public.is_at_least(tramo)`, que anida por rango:

```
anónimo (0)  <  subscriber (1)  <  pro (2)  <  modelista (3)
```

Por eso toda política que autoriza a Pro autoriza también a Modelista, sin escribirlo.

---

## Capacidades (§4)

| Capacidad | Anónimo | Suscriptor | Pro | Modelista |
|---|:---:|:---:|:---:|:---:|
| Ver feed y proyectos | ✓ | ✓ | ✓ | ✓ |
| Búsqueda (proyectos, títulos de paso, técnicas, usuarios) | ✓ | ✓ | ✓ | ✓ |
| Búsqueda **dentro del cuerpo** de los pasos | ✗ | ✗ | ✓ | ✓ |
| Comentar / favoritos / follows | ✗ | ✓ | ✓ | ✓ |
| Notificaciones (in-app + email) | ✗ | ✗ | ✓ | ✓ |
| Mensajería privada | ✗ | ✗ | ✓ | ✓ |
| Ver cuerpo de pasos, PDF, materiales | ✗ | ✗ | ✓ | ✓ |
| Crear/editar proyectos, pasos, técnicas, materiales | ✗ | ✗ | ✗ | ✓ |

> **Excepción del teaser:** `app_config.free_preview_steps` vale **2**, así que el
> cuerpo de los **dos primeros pasos** de cada bitácora está abierto a todo el mundo,
> anónimos incluidos — y por tanto es indexable. Del tercero en adelante exige Pro.
> Los **materiales no tienen esta excepción**: son de pago sin matices.
> Ver [ADR 0004](adr/0004-teaser-de-pasos.md).

---

## Políticas por tabla (§5)

| Tabla | SELECT | INSERT / UPDATE / DELETE |
|---|---|---|
| `profiles` | Público | Solo el propio perfil. `role` **no** editable (privilegio de columna) |
| `subscriptions` | Solo el propio usuario | **Ninguna política** → solo `service_role` (webhook de Stripe) |
| `projects` | `status='published'` **o** el autor | Autor **y** `modelista` |
| `steps` | Público si el proyecto está publicado; siempre el autor | Autor **y** `modelista` |
| `step_bodies` | `can_view_step_body()`: autor **o** `pro`+ **o** dentro del teaser | Autor **y** `modelista` |
| `materials` | `pro`+ **o** el autor | Autor **y** `modelista` |
| `media` (pública) | Con el contenido contenedor | Propietario **y** `modelista` |
| `media` (privada) | Mismo predicado que `step_bodies` | Propietario **y** `modelista` |
| `techniques` | Público | Crear: `modelista`. Editar/fundir: `admin` |
| `scales`, `subjects` | Público | Ninguna → solo `service_role` |
| `comments` | Público sobre contenido visible | Autenticado; editar solo lo propio; borrar el autor **o** `admin` |
| `comment_likes`, `follows`, `favorites` | Público | Solo el propio usuario |
| `activity` | Público (snapshot teaser-seguro) | **Ninguna** → solo triggers `SECURITY DEFINER` |
| `activity_weights` | Público | `admin` |
| `conversations`, `conversation_participants`, `messages` | Participante **y** `pro`+ | Igual, y el invitado debe poder recibir |
| `notifications` | Solo el propio usuario | Solo `read_at`; las crea el servicio |
| `reports` | Solo `admin` | Crear: autenticado. Resolver: `admin` |
| `app_config` | Público | `admin` |

---

## Storage

| Bucket | Público | Contenido | Lectura |
|---|:---:|---|---|
| `media-public` | sí | Portadas, miniaturas de paso, feed, galería del resultado | URL pública directa. **Sin política de listado**: no se puede enumerar el bucket |
| `media-private` | no | Fotos del cuerpo de los pasos | `can_view_step_body()` — el **mismo** predicado que la tabla |
| `materials` | no | PDF, plantillas, listas de pinturas | `pro`+ o el autor |

Escritura en los tres: `modelista`, y sólo bajo `{auth.uid()}/...`.
El contenido de pago se sirve **siempre** con signed URLs de vida corta, nunca con URL
pública permanente.

---

## Las cuatro vías de fuga que vigila el test

`supabase/tests/00_no_leak.sql` comprueba que anónimo y Suscriptor no llegan al cuerpo
de un paso ni a un material por **ninguna** de estas rutas (§13):

1. **Consulta directa** — `select * from step_bodies`.
2. **Feed** — que ningún `activity.snapshot` contenga el cuerpo.
3. **Búsqueda** — que `search_step_bodies()` devuelva 0 filas, ni siquiera un fragmento
   de `ts_headline`.
4. **Storage** — que la política de `media-private` use el mismo predicado que la tabla.

Y `01_write_matrix.sql` cubre las tres escaladas clásicas: ascenderse a `admin`,
autoconcederse un tramo, e inyectar eventos en el feed.
