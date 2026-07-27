export type { Database, Json } from './database.types.ts'
export { Constants } from './database.types.ts'

import type { Database } from './database.types.ts'

export type Tier = Database['public']['Enums']['subscription_tier']

/**
 * Jerarquia de tramos, espejo de `public.tier_rank()` en la base de datos.
 *
 * §4 avisa de que "los tramos no anidan solos". Comparar rangos lo resuelve:
 * todo lo que autoriza a `pro` autoriza tambien a `modelista`.
 *
 * OJO: esto es para pintar la UI (candados, CTAs), NUNCA para autorizar. La
 * autorizacion la impone la RLS en Postgres (§13); el cliente no es la ultima
 * linea de defensa.
 */
export const TIER_RANK: Record<Tier, number> = {
  subscriber: 1,
  pro: 2,
  modelista: 3,
}

export function isAtLeast(tier: Tier | null | undefined, min: Tier): boolean {
  if (!tier) return false
  return TIER_RANK[tier] >= TIER_RANK[min]
}

export const LOCALES = ['es'] as const
export type Locale = (typeof LOCALES)[number]
export const DEFAULT_LOCALE: Locale = 'es'
