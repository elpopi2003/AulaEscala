import type { NextConfig } from 'next'

const supabaseHost = process.env.NEXT_PUBLIC_SUPABASE_URL
  ? new URL(process.env.NEXT_PUBLIC_SUPABASE_URL).hostname
  : undefined

const nextConfig: NextConfig = {
  reactStrictMode: true,

  // packages/shared se publica como TypeScript sin compilar: Next lo transpila.
  transpilePackages: ['@aulaescala/shared'],

  // El monorepo vive fuera de apps/web; sin esto el trazado de ficheros falla
  // al empaquetar packages/shared.
  outputFileTracingRoot: new URL('../../', import.meta.url).pathname,

  images: {
    remotePatterns: supabaseHost
      ? [{ protocol: 'https', hostname: supabaseHost, pathname: '/storage/v1/object/**' }]
      : [],
  },

  async redirects() {
    return [
      // §3.4 / ADR 0002: las rutas publicas llevan prefijo de idioma desde el
      // dia uno. La raiz redirige al locale por defecto.
      { source: '/', destination: '/es', permanent: false },
    ]
  },
}

export default nextConfig
