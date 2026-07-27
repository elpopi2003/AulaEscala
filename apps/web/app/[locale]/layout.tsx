import { notFound } from 'next/navigation'
import { LOCALES, isAtLeast, type Locale } from '@aulaescala/shared'
import { SiteHeader } from '@/components/site-header'
import { SiteFooter } from '@/components/site-footer'
import { getViewer } from '@/lib/tier'

export function generateStaticParams() {
  return LOCALES.map((locale) => ({ locale }))
}

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode
  params: Promise<{ locale: string }>
}) {
  const { locale } = await params

  if (!LOCALES.includes(locale as Locale)) notFound()

  const viewer = await getViewer()

  return (
    <>
      <a className="skip-link" href="#contenido">
        Saltar al contenido
      </a>

      <SiteHeader
        initials={viewer.initials}
        displayName={viewer.displayName}
        canAuthor={isAtLeast(viewer.tier, 'modelista')}
      />

      <main id="contenido">{children}</main>

      <SiteFooter />
    </>
  )
}
