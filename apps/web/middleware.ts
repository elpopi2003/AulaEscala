import { NextResponse, type NextRequest } from 'next/server'
import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { DEFAULT_LOCALE, LOCALES, type Locale } from '@aulaescala/shared'

type CookieToSet = { name: string; value: string; options: CookieOptions }

/**
 * Dos trabajos, en este orden:
 *
 *  1. Refrescar la sesión de Supabase. Los Server Components no pueden escribir
 *     cookies, así que si el token no se renueva aquí, el usuario acaba
 *     deslogueado sin motivo aparente.
 *  2. Garantizar el prefijo de idioma (ADR 0002).
 */
export async function middleware(request: NextRequest) {
  let response = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet: CookieToSet[]) {
          for (const { name, value } of cookiesToSet) {
            request.cookies.set(name, value)
          }
          response = NextResponse.next({ request })
          for (const { name, value, options } of cookiesToSet) {
            response.cookies.set(name, value, options)
          }
        },
      },
    },
  )

  // No quitar: esta llamada es la que dispara el refresco del token.
  await supabase.auth.getUser()

  const { pathname } = request.nextUrl
  const hasLocale = LOCALES.some(
    (locale: Locale) => pathname === `/${locale}` || pathname.startsWith(`/${locale}/`),
  )

  if (!hasLocale) {
    const url = request.nextUrl.clone()
    url.pathname = `/${DEFAULT_LOCALE}${pathname === '/' ? '' : pathname}`
    return NextResponse.redirect(url)
  }

  return response
}

export const config = {
  matcher: [
    // Todo menos estáticos, imágenes y las rutas de API.
    '/((?!_next/static|_next/image|api|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp|avif|ico)$).*)',
  ],
}
