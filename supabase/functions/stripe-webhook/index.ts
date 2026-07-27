// ============================================================================
// stripe-webhook — la ÚNICA vía por la que se concede un tramo de pago (§5)
//
// `subscriptions` no tiene ninguna política de escritura: ningún cliente puede
// tocarla. Este endpoint, con service_role, es el único camino. Eso lo
// convierte en la superficie más sensible del sistema, y de ahí las tres
// defensas:
//
//   1. Firma. Sin `constructEventAsync` verificado, cualquiera con la URL se
//      regala Modelista con un POST.
//   2. Idempotencia. Stripe entrega "al menos una vez"; el PK de
//      `stripe_events` resuelve las reentregas y las carreras.
//   3. El tramo se deriva del `price` que Stripe confirma, jamás de metadata
//      que hubiera podido manipular el cliente al abrir el Checkout.
//
// IMPORTANTE: desplegar con --no-verify-jwt. Stripe no manda un JWT de
// Supabase; la autenticación aquí es la firma del webhook.
// ============================================================================
import type Stripe from 'https://esm.sh/stripe@17.5.0?target=denonext'
import { adminClient, requireEnv, stripe, tierForSubscription } from '../_shared/stripe.ts'

const webhookSecret = requireEnv('STRIPE_WEBHOOK_SECRET')

/** Estados de Stripe → enum subscription_status. */
function mapStatus(status: Stripe.Subscription.Status): string {
  const permitidos = new Set([
    'trialing', 'active', 'past_due', 'canceled',
    'incomplete', 'incomplete_expired', 'unpaid', 'paused',
  ])
  return permitidos.has(status) ? status : 'canceled'
}

/**
 * Localiza al usuario de AULAESCALA dueño de esta suscripción.
 *
 * Dos caminos, en este orden:
 *   1. `metadata.supabase_user_id`, que stripe-checkout graba en la propia
 *      suscripción. Es el camino normal.
 *   2. El `stripe_customer_id` ya guardado, para suscripciones creadas a mano
 *      desde el panel de Stripe o migradas.
 */
async function resolveUserId(
  admin: ReturnType<typeof adminClient>,
  sub: Stripe.Subscription,
): Promise<string | null> {
  const fromMetadata = sub.metadata?.supabase_user_id
  if (fromMetadata) return fromMetadata

  const customerId = typeof sub.customer === 'string' ? sub.customer : sub.customer?.id
  if (!customerId) return null

  const { data } = await admin
    .from('subscriptions')
    .select('user_id')
    .eq('stripe_customer_id', customerId)
    .maybeSingle()

  return data?.user_id ?? null
}

async function handleSubscription(
  admin: ReturnType<typeof adminClient>,
  sub: Stripe.Subscription,
) {
  const userId = await resolveUserId(admin, sub)
  if (!userId) {
    // No se lanza excepción: reintentar no arreglaría una suscripción huérfana
    // y Stripe seguiría reenviando el evento indefinidamente.
    console.error('Suscripción sin usuario asociado', { subscription: sub.id })
    return
  }

  const customerId = typeof sub.customer === 'string' ? sub.customer : sub.customer?.id
  const periodEnd = sub.items.data[0]?.current_period_end ?? null

  const { error } = await admin.rpc('apply_stripe_subscription', {
    p_user_id: userId,
    // Derivado del price cobrado, no de lo que dijera el cliente.
    p_tier: tierForSubscription(sub),
    p_status: mapStatus(sub.status),
    p_stripe_customer_id: customerId ?? null,
    p_stripe_subscription_id: sub.id,
    p_current_period_end: periodEnd ? new Date(periodEnd * 1000).toISOString() : null,
    p_cancel_at_period_end: sub.cancel_at_period_end ?? false,
  })

  if (error) throw new Error(`apply_stripe_subscription falló: ${error.message}`)
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 })
  }

  const signature = req.headers.get('stripe-signature')
  if (!signature) {
    return new Response('Falta la cabecera stripe-signature', { status: 400 })
  }

  // El cuerpo CRUDO: cualquier reserialización invalida la firma.
  const body = await req.text()

  let event: Stripe.Event
  try {
    // En Deno hay que usar la variante async: la verificación usa WebCrypto.
    event = await stripe.webhooks.constructEventAsync(body, signature, webhookSecret)
  } catch (err) {
    console.error('Firma de webhook inválida', err)
    return new Response('Firma inválida', { status: 400 })
  }

  const admin = adminClient()

  // Idempotencia. El PK hace que dos entregas simultáneas del mismo evento
  // compitan por este INSERT y solo una siga adelante.
  const { error: dedupeError } = await admin
    .from('stripe_events')
    .insert({ event_id: event.id, type: event.type })

  if (dedupeError) {
    if (dedupeError.code === '23505') {
      // Ya procesado. 200 para que Stripe deje de reintentar.
      return new Response(JSON.stringify({ received: true, duplicate: true }), { status: 200 })
    }
    console.error('No se pudo registrar el evento', dedupeError)
    return new Response('Error de registro', { status: 500 })
  }

  try {
    switch (event.type) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated':
      case 'customer.subscription.deleted':
        await handleSubscription(admin, event.data.object as Stripe.Subscription)
        break

      case 'checkout.session.completed': {
        const session = event.data.object as Stripe.Checkout.Session
        if (session.mode === 'subscription' && session.subscription) {
          const subId = typeof session.subscription === 'string'
            ? session.subscription
            : session.subscription.id
          // Se relee de la API en vez de fiarse del objeto embebido: así el
          // tramo sale siempre del estado real de la suscripción.
          const sub = await stripe.subscriptions.retrieve(subId)
          await handleSubscription(admin, sub)
        }
        break
      }

      case 'invoice.payment_failed':
      case 'invoice.paid': {
        const invoice = event.data.object as Stripe.Invoice
        const subId = (invoice as { subscription?: string | { id: string } }).subscription
        if (subId) {
          const sub = await stripe.subscriptions.retrieve(
            typeof subId === 'string' ? subId : subId.id,
          )
          await handleSubscription(admin, sub)
        }
        break
      }

      default:
        // Evento no relevante: ya está registrado, no hay nada que hacer.
        break
    }

    return new Response(JSON.stringify({ received: true }), { status: 200 })
  } catch (err) {
    console.error('Fallo procesando el evento', event.type, err)

    // Se borra el registro para que el reintento de Stripe SÍ vuelva a
    // procesarlo. Si no, el fallo quedaría marcado como "ya hecho" y el
    // usuario se quedaría sin el tramo que ha pagado.
    await admin.from('stripe_events').delete().eq('event_id', event.id)

    return new Response('Error procesando el evento', { status: 500 })
  }
})
