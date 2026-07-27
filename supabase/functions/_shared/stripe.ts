// ============================================================================
// Piezas compartidas por las tres funciones de Stripe.
// ============================================================================
import Stripe from 'https://esm.sh/stripe@17.5.0?target=denonext'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.47.10'

export function requireEnv(name: string): string {
  const value = Deno.env.get(name)
  if (!value) throw new Error(`Falta la variable de entorno ${name}`)
  return value
}

export const stripe = new Stripe(requireEnv('STRIPE_SECRET_KEY'), {
  apiVersion: '2024-12-18.acacia',
  // El runtime de Deno no trae el cliente HTTP de Node.
  httpClient: Stripe.createFetchHttpClient(),
})

/**
 * Cliente con service_role: SALTA LA RLS POR COMPLETO.
 *
 * Solo puede existir aquí dentro. §13: nada se sirve con service_role desde el
 * navegador. Estas funciones se ejecutan en el servidor y la clave nunca cruza
 * al cliente.
 */
export function adminClient() {
  return createClient(
    requireEnv('SUPABASE_URL'),
    requireEnv('SUPABASE_SERVICE_ROLE_KEY'),
    { auth: { persistSession: false, autoRefreshToken: false } },
  )
}

export type Tier = 'subscriber' | 'pro' | 'modelista'

/**
 * Traduce un price de Stripe al tramo que concede.
 *
 * El tramo se deriva SIEMPRE del price que Stripe confirma haber cobrado,
 * nunca de nada que mande el cliente. Un `tier` que llegue en el cuerpo de una
 * petición es una sugerencia, no una autorización.
 */
export function tierForPrice(priceId: string | null | undefined): Tier | null {
  if (!priceId) return null
  if (priceId === Deno.env.get('STRIPE_PRICE_PRO')) return 'pro'
  if (priceId === Deno.env.get('STRIPE_PRICE_MODELISTA')) return 'modelista'
  return null
}

/** Estados de Stripe que sí otorgan el tramo comprado. */
const ESTADOS_VIVOS = new Set(['active', 'trialing'])

export function tierForSubscription(sub: Stripe.Subscription): Tier {
  if (!ESTADOS_VIVOS.has(sub.status)) return 'subscriber'
  const priceId = sub.items.data[0]?.price?.id
  return tierForPrice(priceId) ?? 'subscriber'
}

export const corsHeaders = {
  'Access-Control-Allow-Origin': Deno.env.get('SITE_URL') ?? '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

/**
 * Resuelve el usuario a partir del JWT del header Authorization.
 *
 * Se valida contra Supabase Auth en vez de decodificar el token a mano: un JWT
 * sin verificar es texto que manda el cliente.
 */
export async function userFromRequest(req: Request) {
  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) return null

  const supabase = createClient(
    requireEnv('SUPABASE_URL'),
    requireEnv('SUPABASE_ANON_KEY'),
    { global: { headers: { Authorization: authHeader } }, auth: { persistSession: false } },
  )

  const { data, error } = await supabase.auth.getUser()
  if (error || !data.user) return null
  return data.user
}
