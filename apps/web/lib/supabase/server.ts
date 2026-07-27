import { cookies } from 'next/headers'
import { createServerClient, type CookieOptions } from '@supabase/ssr'
import type { Database } from '@aulaescala/shared/database'

type CookieToSet = { name: string; value: string; options: CookieOptions }

/**
 * Cliente de Supabase para Server Components, Route Handlers y Server Actions.
 *
 * Usa la clave ANÓNIMA, nunca `service_role`. Toda consulta que salga de aquí
 * pasa por RLS con la sesión del usuario — es justamente lo que queremos (§13:
 * la RLS es la frontera de seguridad, no el código de la app).
 */
export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet: CookieToSet[]) {
          try {
            for (const { name, value, options } of cookiesToSet) {
              cookieStore.set(name, value, options)
            }
          } catch {
            // Server Component: no se pueden escribir cookies. El middleware ya
            // refresca la sesión, así que se puede ignorar sin consecuencias.
          }
        },
      },
    },
  )
}
