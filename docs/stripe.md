# Stripe — montaje y operación

El tramo de pago es lo único que separa el contenido gratuito del de pago, así que
esta pieza es tan sensible como la RLS. La regla de §5 es corta:

> **`subscriptions` no tiene ninguna política de escritura.** Ningún cliente puede
> tocarla. La escribe el webhook con `service_role`, y nadie más.

## Las tres funciones

| Función | JWT | Qué hace |
|---|:---:|---|
| `stripe-checkout` | ✅ requerido | Abre una sesión de Checkout para `pro` o `modelista` |
| `stripe-portal` | ✅ requerido | Abre el Customer Portal (cambio de plan, tarjeta, facturas, baja) |
| `stripe-webhook` | ❌ **desactivado** | Recibe los eventos de Stripe y escribe el tramo |

El webhook va **sin verificación de JWT** porque Stripe no manda uno. Lo que lo
autentica es la firma `stripe-signature`, verificada con `constructEventAsync`. Con
`verify_jwt = true` el gateway rechazaría todas las entregas antes de llegar al
código; sin verificar la firma, cualquiera con la URL se regala Modelista con un POST.
Ambas mitades hacen falta.

## Variables de entorno

En el panel de Supabase → Edge Functions → Secrets:

```
STRIPE_SECRET_KEY          sk_live_... (o sk_test_ mientras se prueba)
STRIPE_WEBHOOK_SECRET      whsec_...   (lo da Stripe AL CREAR el endpoint)
STRIPE_PRICE_PRO           price_...
STRIPE_PRICE_MODELISTA     price_...
SITE_URL                   https://aulaescala.com
```

`SUPABASE_URL`, `SUPABASE_ANON_KEY` y `SUPABASE_SERVICE_ROLE_KEY` las inyecta la
plataforma sola.

> `SUPABASE_SERVICE_ROLE_KEY` salta la RLS por completo. Vive solo en el servidor y
> **nunca** con prefijo `NEXT_PUBLIC_`.

## Productos y precios

Dos productos con precio recurrente mensual, en EUR (§10, precios del diseño):

| Producto | Precio | Concede |
|---|---|---|
| AULAESCALA Pro | 6 €/mes | `pro` |
| AULAESCALA Modelista | 12 €/mes | `modelista` |

**El tramo se deriva del `price` que Stripe confirma haber cobrado**, nunca de lo que
mande el cliente. `tierForPrice()` traduce `price_id → tramo` leyendo el entorno; un
price desconocido cae a `subscriber` en vez de conceder nada.

## Endpoint del webhook

URL:

```
https://yyigaxclclxanlovxarh.supabase.co/functions/v1/stripe-webhook
```

Eventos a suscribir:

```
customer.subscription.created
customer.subscription.updated
customer.subscription.deleted
checkout.session.completed
invoice.paid
invoice.payment_failed
```

`invoice.payment_failed` no es opcional: es lo que degrada el tramo cuando una tarjeta
deja de funcionar. Sin él, un impago mantiene el acceso Pro indefinidamente.

## Despliegue

Las tres están **desplegadas y verificadas** en `yyigaxclclxanlovxarh` (v2), con
`verify_jwt` correcto en cada una. Para redesplegar desde una máquina con el CLI:

```bash
supabase functions deploy stripe-webhook --no-verify-jwt
```

```bash
supabase functions deploy stripe-checkout stripe-portal
```

### Todas las variables se exigen AL ARRANCAR

`_shared/stripe.ts` resuelve las cinco con `requireEnv` en el momento de cargar el
módulo, no dentro de los handlers. Si falta una, las tres funciones dejan de
responder — un fallo imposible de pasar por alto.

Antes no era así con los price y con `SITE_URL`, y el modo de fallo era el peor
posible para un producto de pago: `tierForPrice()` no encontraba el price, caía a
`subscriber`, el webhook devolvía 200 y Stripe lo daba por bueno. **El cliente pagaba
y no recibía el tramo, sin que saltara ninguna alarma.**

Además, si algún día llega un price que la app no sabe traducir —un plan nuevo creado
en el panel sin actualizar el entorno—, `tierForSubscription()` sigue degradando a
`subscriber` (lo seguro) pero deja un `console.error` bien visible en los logs.

### Cómo comprobar que arranca

Un POST sin firma tiene que devolver **400**, no 500:

```bash
curl -i -X POST https://yyigaxclclxanlovxarh.supabase.co/functions/v1/stripe-webhook -d '{}'
```

- `400 Falta la cabecera stripe-signature` → el módulo cargó: las cinco variables están.
- `500` → falta alguna. El log de la función dice cuál.

Y con una firma inventada tiene que responder `400 Firma invalida`. Si respondiera 200,
la verificación de firma no está funcionando y cualquiera podría regalarse Modelista.

## Cómo degrada un tramo

`public.user_tier()` solo concede el tramo comprado si la suscripción está **viva**:

```sql
status in ('active','trialing')
and (current_period_end is null or current_period_end > now())
```

Todo lo demás —`past_due`, `canceled`, `unpaid`, o un periodo vencido— cae a
`subscriber` automáticamente, sin proceso de limpieza ni cron. Verificado: alta,
upgrade, `past_due`, periodo caducado y renovación.

**El contenido del Modelista degradado sigue publicado** y solo pierde crear/editar:
las políticas de `projects` piden `modelista` para escribir, pero la lectura solo mira
`status = 'published'`.

## Idempotencia

Stripe entrega "al menos una vez" y reintenta ante cualquier fallo o timeout. La tabla
`stripe_events` tiene `event_id` como clave primaria, así que dos entregas simultáneas
del mismo evento compiten por el `INSERT` y solo una sigue adelante.

Detalle que importa: si el procesado **falla**, la función **borra** el registro antes
de devolver 500. Si no lo hiciera, el reintento de Stripe vería el evento como "ya
procesado" y el usuario se quedaría sin el tramo que ha pagado.

## Prueba en local

```bash
stripe listen --forward-to http://127.0.0.1:54321/functions/v1/stripe-webhook
```

```bash
stripe trigger customer.subscription.created
```

## Pendiente

- [ ] **Dar de alta el endpoint del webhook en el panel de Stripe** con los seis
      eventos de arriba. Mientras `stripe_events` siga a 0 filas, Stripe no está
      llamando: es el indicador de que falta este paso.
- [ ] **Prueba de punta a punta**: un pago real en modo test que acabe con la fila
      correcta en `subscriptions`.
- [ ] **Confirmar precios** con producto (el diseño usa 6 € y 12 €).
- [ ] **IVA UE/OSS** — `automatic_tax` está activado en Checkout y la dirección de
      facturación es obligatoria, pero hay que **activar Stripe Tax en el panel** y
      registrar las obligaciones fiscales. Confirmar con asesoría fiscal (§10).
