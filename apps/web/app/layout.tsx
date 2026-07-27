import type { Metadata, Viewport } from 'next'
import { JetBrains_Mono, Montserrat, Raleway } from 'next/font/google'
import './globals.css'

// Display: Raleway 800. Solo titulares y wordmark, nunca etiquetas de UI.
const raleway = Raleway({
  subsets: ['latin'],
  weight: ['800'],
  variable: '--font-raleway',
  display: 'swap',
})

// Cuerpo: Montserrat. Humanista, contrasta con la geometrica del display.
const montserrat = Montserrat({
  subsets: ['latin'],
  weight: ['400', '500', '600', '700'],
  variable: '--font-montserrat',
  display: 'swap',
})

// Mono: todo lo tecnico. Escalas, tiempos, referencias de kit, metadatos.
const jetbrains = JetBrains_Mono({
  subsets: ['latin'],
  weight: ['400', '500', '600'],
  variable: '--font-jetbrains',
  display: 'swap',
})

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000'),
  title: {
    default: 'AULAESCALA — Bitácoras de modelismo estático',
    template: '%s · AULAESCALA',
  },
  description:
    'Bitácoras de montaje paso a paso: maquetas, dioramas, figuras, blindados, aviación y naval. Aprende técnicas de modelismo estático documentadas por quienes las practican.',
}

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: 'hsl(210 20% 98%)' },
    { media: '(prefers-color-scheme: dark)', color: 'hsl(213 31% 10%)' },
  ],
}

/**
 * Resuelve el tema antes del primer pintado.
 *
 * Sin esto hay un fogonazo blanco al cargar en oscuro — y el oscuro es el modo
 * de uso más frecuente aquí: de noche, en el banco de trabajo. Un flash blanco
 * en esa situación es agresivo de verdad, no un detalle estético.
 */
const THEME_SCRIPT = `
(function () {
  try {
    var stored = localStorage.getItem('aulaescala-theme');
    var theme = stored || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
    document.documentElement.dataset.theme = theme;
  } catch (e) {
    document.documentElement.dataset.theme = 'light';
  }
})();
`

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html
      lang="es"
      suppressHydrationWarning
      className={`${raleway.variable} ${montserrat.variable} ${jetbrains.variable}`}
    >
      <head>
        <script dangerouslySetInnerHTML={{ __html: THEME_SCRIPT }} />
      </head>
      <body>{children}</body>
    </html>
  )
}
