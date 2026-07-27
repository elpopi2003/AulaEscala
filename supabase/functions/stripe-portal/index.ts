// ============================================================================
// stripe-portal — abre el Customer Portal de Stripe.
//
// Desde ahí el usuario cambia de plan, actualiza su tarjeta, descarga facturas
// y cancela. Todo lo que haga vuelve como webhook: el portal no escribe
// `subscriptions` directamente.
//
// El customer se resuelve SIEMPRE desde el user_id del JWT. Aceptar un
// customer_id de la petición dejaría a cualquiera abrir la facturación de otro.
// ============================================================================
import { adminClient, corsHeaders, json, requireEnv, stripe, userFromRequest } from '../_shared/stripe.ts'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return json({ error: 'Método no permitido' }, 405)

  const user = await userFromRequest(req)
  if (!user) return json({ error: 'No autenticado' }, 401)

  const admin = adminClient()
  const { data } = await admin
    .from('subscriptions')
    .select('stripe_customer_id')
    .eq('user_id', user.id)
    .maybeSingle()

  if (!data?.stripe_customer_id) {
    return json({ error: 'Todavía no tienes una suscripción que gestionar' }, 404)
  }

  try {
    const session = await stripe.billingPortal.sessions.create({
      customer: data.stripe_customer_id,
      return_url: `${requireEnv('SITE_URL')}/es/cuenta`,
      locale: 'es',
    })
    return json({ url: session.url })
  } catch (err) {
    console.error('No se pudo abrir el Customer Portal', err)
    return json({ error: 'No se pudo abrir la gestión de la suscripción' }, 500)
  }
})
