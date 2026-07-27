import Link from 'next/link'
import { notFound } from 'next/navigation'
import type { Metadata } from 'next'
import { Photo } from '@/components/photo'
import {
  IconArrowLeft,
  IconArrowRight,
  IconCheck,
  IconClock,
  IconLock,
} from '@/components/icons'
import { createClient } from '@/lib/supabase/server'
import { formatDuration } from '@/lib/format'
import styles from './step.module.css'

export const revalidate = 300

const BENEFITS = [
  'Todos los pasos de cada bitácora',
  'Materiales y plantillas descargables',
  'Exportar la bitácora a PDF',
  'Notificaciones y mensajería con otros modelistas',
]

async function loadStep(locale: string, slug: string, position: number) {
  const supabase = await createClient()

  const { data: project } = await supabase
    .from('projects')
    .select('id, title, slug, locale')
    .eq('slug', slug)
    .eq('locale', locale)
    .maybeSingle()

  if (!project) return null

  const { data: steps } = await supabase
    .from('steps')
    .select('id, position, title, thumb_url, duration_minutes')
    .eq('project_id', project.id)
    .order('position')

  const step = steps?.find((s) => s.position === position)
  if (!step) return null

  const index = steps!.findIndex((s) => s.position === position)

  return {
    project,
    step,
    total: steps!.length,
    prev: index > 0 ? steps![index - 1] : null,
    next: index < steps!.length - 1 ? steps![index + 1] : null,
  }
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string; slug: string; position: string }>
}): Promise<Metadata> {
  const { locale, slug, position } = await params
  const data = await loadStep(locale, slug, Number(position))

  if (!data) return { title: 'Paso no encontrado' }

  return {
    title: `${data.step.title} — ${data.project.title}`,
    description: `Paso ${data.step.position} de ${data.total} de la bitácora de ${data.project.title}.`,
    alternates: { canonical: `/${locale}/proyectos/${slug}/pasos/${position}` },
  }
}

export default async function StepPage({
  params,
}: {
  params: Promise<{ locale: string; slug: string; position: string }>
}) {
  const { locale, slug, position } = await params
  const positionNumber = Number(position)

  if (!Number.isInteger(positionNumber) || positionNumber < 1) notFound()

  const data = await loadStep(locale, slug, positionNumber)
  if (!data) notFound()

  const { project, step, total, prev, next } = data
  const supabase = await createClient()

  // ─────────────────────────────────────────────────────────────────────────
  // AQUÍ ESTÁ EL MURO.
  //
  // No hay ningún `if (tier === 'pro')`. Se pide el cuerpo y la RLS decide: si
  // el usuario no tiene derecho, `body` llega null y no existe en ningún punto
  // del servidor, del HTML ni del bundle. El muro es la consecuencia de no
  // tener el dato, no una decisión de la interfaz (§13).
  // ─────────────────────────────────────────────────────────────────────────
  const { data: body } = await supabase
    .from('step_bodies')
    .select('body, tip')
    .eq('step_id', step.id)
    .maybeSingle()

  const locked = !body

  const [{ data: media }, { data: techniques }] = await Promise.all([
    supabase
      .from('media')
      .select('id, storage_path, alt_text')
      .eq('step_id', step.id)
      .order('position'),
    supabase
      .from('step_techniques')
      .select('technique:techniques ( slug, name )')
      .eq('step_id', step.id),
  ])

  const duration = formatDuration(step.duration_minutes)
  const projectHref = `/${locale}/proyectos/${project.slug}`

  return (
    <div className={`page ${styles.wrap}`}>
      <div className={styles.top}>
        <Link href={projectHref} className={styles.back}>
          <IconArrowLeft size={15} />
          {project.title}
        </Link>
      </div>

      {/* Encabeza el titulo, igual que el numero en la lista de pasos: la misma
          jerarquia en las dos pantallas donde aparece un paso. */}
      <p className={styles.counter}>
        Paso {step.position} de {total}
      </p>
      <h1 className={styles.title}>{step.title}</h1>

      <div className={styles.meta}>
        {duration && (
          <span className={styles.duration}>
            <IconClock size={14} />
            {duration}
          </span>
        )}
        {techniques?.map(
          (t) =>
            t.technique && (
              <Link
                key={t.technique.slug}
                href={`/${locale}/tecnicas/${t.technique.slug}`}
                className={styles.tech}
              >
                {t.technique.name}
              </Link>
            ),
        )}
      </div>

      {media && media.length > 0 && (
        <>
          <p className={styles.sectionLabel}>Galería de proceso</p>
          <div className={styles.gallery}>
            {media.map((m) => (
              <div key={m.id} className={styles.galleryItem}>
                <Photo src={null} label={m.alt_text ?? 'Trabajo en progreso'} ratio="4 / 3" />
              </div>
            ))}
          </div>
        </>
      )}

      {locked ? (
        <Paywall locale={locale} />
      ) : (
        <>
          <article className={styles.body}>
            <div className={styles.prose}>
              {body.body
                ?.split(/\n{2,}/)
                .filter(Boolean)
                .map((paragraph, i) => <p key={i}>{paragraph}</p>)}
            </div>

            {body.tip && (
              <aside className={styles.tip}>
                <IconCheck size={20} className={styles.tipIcon} />
                <p className={styles.tipText}>{body.tip}</p>
              </aside>
            )}
          </article>

          <nav className={styles.nav} aria-label="Navegación entre pasos">
            {prev ? (
              <Link href={`${projectHref}/pasos/${prev.position}`} className={styles.navCard}>
                <span className={styles.navLabel}>
                  <IconArrowLeft size={13} /> Anterior
                </span>
                <span className={styles.navTitle}>{prev.title}</span>
              </Link>
            ) : (
              <span />
            )}

            {next && (
              <Link
                href={`${projectHref}/pasos/${next.position}`}
                className={`${styles.navCard} ${styles.navNext}`}
              >
                <span className={styles.navLabel}>
                  Siguiente <IconArrowRight size={13} />
                </span>
                <span className={styles.navTitle}>{next.title}</span>
              </Link>
            )}
          </nav>
        </>
      )}
    </div>
  )
}

function Paywall({ locale }: { locale: string }) {
  return (
    <div className={styles.wallWrap}>
      {/* Barras decorativas, no el texto real: el cuerpo nunca llegó al
          servidor. El desenfoque comunica "hay algo aquí", no lo esconde. */}
      <div className={styles.teaser} aria-hidden="true">
        {[92, 100, 78, 96, 88, 64, 98, 82, 90, 70].map((width, i) => (
          <div key={i} className={styles.teaserLine} style={{ width: `${width}%` }} />
        ))}
      </div>

      <div className={styles.wall}>
        <span className={styles.wallIcon}>
          <IconLock size={26} strokeWidth={1.9} />
        </span>

        <h2 className={styles.wallTitle}>Desbloquea todos los pasos</h2>
        <p className={styles.wallText}>
          Los dos primeros pasos de cada bitácora son abiertos. A partir del tercero, el
          paso a paso completo es contenido Pro.
        </p>

        <ul className={styles.benefits}>
          {BENEFITS.map((benefit) => (
            <li key={benefit} className={styles.benefit}>
              <IconCheck size={15} strokeWidth={2.5} className={styles.benefitIcon} />
              {benefit}
            </li>
          ))}
        </ul>

        <Link href={`/${locale}/precios`} className={styles.wallCta}>
          Ver planes
        </Link>
        <p className={styles.wallNote}>Puedes cancelar cuando quieras.</p>
      </div>
    </div>
  )
}
