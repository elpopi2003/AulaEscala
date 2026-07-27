import { createClient } from '@/lib/supabase/server'
import type { Tier } from '@aulaescala/shared'

export type Viewer = {
  userId: string | null
  tier: Tier | null
  displayName: string | null
  initials: string | null
}

/**
 * Quién está mirando: identidad y tramo.
 *
 * Sirve SOLO para pintar la interfaz — qué candado mostrar, qué CTA ofrecer.
 * **No autoriza nada.** La autorización la impone la RLS en Postgres (§13); si
 * esta función mintiera y dijera `pro`, la consulta seguiría devolviendo cero
 * filas. El cliente nunca es la última línea de defensa.
 */
export async function getViewer(): Promise<Viewer> {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return { userId: null, tier: null, displayName: null, initials: null }
  }

  const [{ data: tier }, { data: profile }] = await Promise.all([
    supabase.rpc('user_tier'),
    supabase.from('profiles').select('display_name').eq('id', user.id).maybeSingle(),
  ])

  const displayName = profile?.display_name ?? user.email?.split('@')[0] ?? null

  return {
    userId: user.id,
    tier: (tier as Tier | null) ?? 'subscriber',
    displayName,
    initials: displayName ? initialsOf(displayName) : null,
  }
}

export function initialsOf(name: string): string {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((word) => word[0] ?? '')
    .join('')
    .toUpperCase()
}
