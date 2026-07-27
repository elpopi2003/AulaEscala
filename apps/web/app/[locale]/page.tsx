import Link from 'next/link'
import type { Metadata } from 'next'
import { isAtLeast } from '@aulaescala/shared'
import { ActivityCard, type ActivityRow } from '@/components/activity-card'
import { createClient } from '@/lib/supabase/server'
import { getViewer } from '@/lib/tier'
import styles from './feed.module.css'

export const metadata: Metadata = {
  title: 'Progreso reciente',
  description:
    'Lo último que se ha montado, pintado y terminado en la comunidad: pasos nuevos, técnicas y bitácoras completas de modelismo estático.',
}

// El feed público es cacheable: `activity.snapshot` es teaser-seguro, así que
// no hay nada personalizado en el HTML (§6).
export const revalidate = 60

type FeedFilter = 'todo' | 'pasos' | 'terminados'

const FILTERS: { key: FeedFilter; label: string }[] = [
  { key: 'todo', label: 'Todo' },
  { key: 'pasos', label: 'Pasos' },
  { key: 'terminados', label: 'Terminados' },
]

export default async function FeedPage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string }>
  searchParams: Promise<{ filtro?: string }>
}) {
  const { locale } = await params
  const { filtro } = await searchParams

  const active: FeedFilter = FILTERS.some((f) => f.key === filtro)
    ? (filtro as FeedFilter)
    : 'todo'

  const supabase = await createClient()
  const viewer = await getViewer()
  const unlocked = isAtLeast(viewer.tier, 'pro')

  // El orden es el índice: score precomputado en escritura, nunca calculado
  // aquí (§3.5).
  let query = supabase
    .from('activity')
    .select('id, type, created_at, snapshot')
    .order('score', { ascending: false })
    .order('created_at', { ascending: false })
    .limit(25)

  if (active === 'pasos') query = query.eq('type', 'step_published')
  if (active === 'terminados') query = query.eq('type', 'project_finished')

  const { data, error } = await query

  // Un feed roto y un feed vacío se ven igual si se traga el error. Se
  // distinguen: el vacío es un estado legítimo del producto, el error no.
  if (error) {
    console.error('[feed] no se pudo leer activity:', error.message, error.details)
  }

  const rows = (data ?? []) as ActivityRow[]

  const [featured, ...rest] = rows

  const { data: techniques } = await supabase
    .from('techniques')
    .select('slug, name')
    .neq('moderation_status', 'merged')
    .limit(8)

  return (
    <div className={`page ${styles.wrap}`}>
      <div className={styles.head}>
        <div>
          <p className="eyebrow">El banco de trabajo</p>
          <h1 className={styles.title}>Progreso reciente</h1>
        </div>

        <nav className={styles.filters} aria-label="Filtrar los proyectos">
          {FILTERS.map((f) => (
            <Link
              key={f.key}
              href={f.key === 'todo' ? `/${locale}` : `/${locale}?filtro=${f.key}`}
              className={`${styles.filter} ${active === f.key ? styles.filterActive : ''}`}
              aria-current={active === f.key ? 'true' : undefined}
            >
              {f.label}
            </Link>
          ))}
        </nav>
      </div>

      <div className={styles.columns}>
        <div>
          {rows.length === 0 ? (
            <EmptyFeed locale={locale} />
          ) : (
            <>
              {featured && (
                <ActivityCard activity={featured} unlocked={unlocked} featured />
              )}

              {rest.length > 0 && (
                <div className={styles.grid}>
                  {rest.map((row) => (
                    <ActivityCard key={row.id} activity={row} unlocked={unlocked} />
                  ))}
                </div>
              )}
            </>
          )}
        </div>

        <aside className={styles.sidebar}>
          {techniques && techniques.length > 0 && (
            <section className={styles.panel}>
              <h2 className={styles.panelTitle}>Técnicas</h2>
              <div className={styles.chips}>
                {techniques.map((t) => (
                  <Link key={t.slug} href={`/${locale}/tecnicas/${t.slug}`} className={styles.chip}>
                    {t.name}
                  </Link>
                ))}
              </div>
            </section>
          )}

          {!isAtLeast(viewer.tier, 'modelista') && (
            <section className={styles.ctaPanel}>
              <h2 className={styles.ctaTitle}>Documenta tu build</h2>
              <p className={styles.ctaText}>
                Publica tu bitácora paso a paso y deja constancia de cómo lo hiciste.
              </p>
              <Link href={`/${locale}/precios`} className={styles.ctaButton}>
                Hazte Modelista
              </Link>
            </section>
          )}
        </aside>
      </div>
    </div>
  )
}

function EmptyFeed({ locale }: { locale: string }) {
  return (
    <div className={styles.empty}>
      <p className="eyebrow">Aún no hay movimiento</p>
      <h2 className={styles.emptyTitle}>Este muro se llena con progreso real</h2>
      <p className={styles.emptyText}>
        Aquí aparece cada paso nuevo que alguien publica y cada build que se da por
        terminado — ordenados para que el trabajo en curso pese más que el ruido. En
        cuanto se publique la primera bitácora, empieza a moverse.
      </p>
      <Link href={`/${locale}/precios`} className={styles.chip}>
        Ver cómo publicar la tuya
      </Link>
    </div>
  )
}
