# ADR 0003 — La resolución de tramo vive en `public`, no en `auth`

**Estado:** aceptado
**Fecha:** 2026-07-26

## Contexto

La especificación §5 nombra la función de resolución de tramo como
**`auth.user_tier()`** (SECURITY DEFINER, lee `subscriptions`).

El esquema `auth` de un proyecto Supabase lo gestiona el propio Supabase: es propiedad
de `supabase_auth_admin` y su contenido se sustituye en las actualizaciones de la
plataforma. Los objetos propios que se dejen ahí pueden desaparecer o entrar en
conflicto en una migración de versión de GoTrue, y la documentación de Supabase
desaconseja explícitamente crear objetos en él.

## Decisión

La función se llama **`public.user_tier()`**. Se añaden dos auxiliares en el mismo
esquema:

```sql
public.tier_rank(subscription_tier) -> int    -- anon 0 < subscriber 1 < pro 2 < modelista 3
public.is_at_least(subscription_tier) -> bool -- el predicado que usan las políticas
```

Es la única desviación respecto de la nomenclatura de la especificación, y es de
ubicación, no de comportamiento.

## Motivo del rango numérico

§4 avisa de que "los tramos no anidan solos: toda política que autorice a Pro debe
autorizar también a Modelista". Comparar rangos convierte ese aviso en una propiedad
estructural: `is_at_least('pro')` es cierto para `modelista` por construcción. La
alternativa —enumerar `tier in ('pro','modelista')` en cada política— funciona hasta
que alguien escribe una y olvida el segundo valor, y ese olvido es exactamente una
fuga de contenido de pago.

## Consecuencias

- Se mantiene "decidido: siempre fresca". La función lee `subscriptions` en cada
  evaluación en vez de confiar en un custom claim del JWT, que se quedaría obsoleto al
  cambiar la suscripción y obligaría a forzar un refresh del token.
- El coste se contiene envolviendo la llamada: `(select public.is_at_least('pro'))`
  hace que Postgres la evalúe **una vez por consulta** como InitPlan, no una vez por
  fila. Todas las políticas del esquema lo hacen así.
- Al vivir en `public`, la función queda expuesta como `/rest/v1/rpc/user_tier`. Es
  inofensivo —devuelve el tramo de quien llama— pero obligó a auditar el resto de
  funciones `SECURITY DEFINER`: ver
  `supabase/migrations/20260726091400_harden_function_privileges.sql`.
- Si algún día se optimiza a custom claims, el punto de cambio es una única función.
