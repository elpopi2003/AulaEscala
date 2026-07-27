// ============================================================================
// stripe-checkout — abre una sesión de Checkout para Pro o Modelista.
//
// El cliente elige QUÉ PLAN quiere, no qué tramo recibe. La petición manda un
// nombre de plan; el price lo pone el servidor desde su entorno. Aceptar un
// price_id del cliente permitiría comprar Modelista al precio de Pro.
//
// El tramo no se escribe aquí: lo escribe el webhook cuando Stripe confirma el
// cobro (§5, §12.3). Volver de Checkout con éxito no es prueba de pago.
// ============================================================================
import { adminClient, corsHeaders, json, requireEnv, stripe, userFromRequest } from '../_shared/stripe.ts'

const PLANES = {
  pro:       { env: 'STRIPE_PRICE_PRO',       etiqueta: 'Pro' },
  modelista: { env: 'STRIPE_PRICE_MODELISTA', etiqueta: 'Modelista' },
} as const

type Plan = keyof typeof PLANES

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return json({ error: 'Método no permitido' }, 405)

  const user = await userFromRequest(req)
  if (!user) return json({ error: 'No autenticado' }, 401)

  let plan: Plan
  try {
    const body = await req.json()
    plan = body?.plan
    if (!(plan in PLANES)) {
      return json({ error: 'Plan no válido. Usa "pro" o "modelista".' }, 400)
    }
  } catch {
    return json({ error: 'Cuerpo JSON no válido' }, 400)
  }

  const priceId = requireEnv(PLANES[plan].env)
  const siteUrl = requireEnv('SITE_URL')

  const admin = adminClient()

  // Reutilizar el customer evita duplicarlo en Stripe cada vez que alguien
  // cambia de plan, y mantiene el historial de facturación en un solo sitio.
  const { data: existing } = await admin
    .from('subscriptions')
    .select('stripe_customer_id')
    .eq('user_id', user.id)
    .maybeSingle()

  let customerId = existing?.stripe_customer_id ?? undefined

  if (!customerId) {
    const { data: profile } = await admin
      .from('profiles')
      .select('display_name')
      .eq('id', user.id)
      .maybeSingle()

    const customer = await stripe.customers.create({
      email: user.email,
      name: profile?.display_name ?? undefined,
      metadata: { supabase_user_id: user.id },
    })
    customerId = customer.id
  }

  try {
    const session = await stripe.checkout.sessions.create({
      mode: 'subscription',
      customer: customerId,
      line_items: [{ price: priceId, quantity: 1 }],
      client_reference_id: user.id,

      // Esta metadata viaja en la SUSCRIPCIÓN, así que llega en todos los
      // eventos posteriores (renovación, cambio de plan, cancelación) y el
      // webhook siempre sabe de quién es sin tener que buscarlo.
      subscription_data: {
        metadata: { supabase_user_id: user.id },
      },

      // §10 / IVA UE-OSS: las suscripciones digitales tributan según la
      // ubicación del cliente. Stripe Tax lo calcula y recoge la dirección.
      automatic_tax: { enabled: true },
      customer_update: { address: 'auto', name: 'auto' },
      billing_address_collection: 'required',

      allow_promotion_codes: true,
      locale: 'es',

      success_url: `${siteUrl}/es/cuenta?checkout=ok&session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${siteUrl}/es/precios?checkout=cancelado`,
    })

    return json({ url: session.url })
  } catch (err) {
    console.error('No se pudo crear la sesión de Checkout', err)
    return json({ error: 'No se pudo iniciar el pago' }, 500)
  }
})
