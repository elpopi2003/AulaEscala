import Link from 'next/link'
import { Photo } from './photo'
import { IconCheck, IconLock } from './icons'
import { formatRelative } from '@/lib/format'
import { initialsOf } from '@/lib/tier'
import styles from './activity-card.module.css'

/**
 * Forma del `activity.snapshot`.
 *
 * Es teaser-seguro por construcción (§13): el trigger que lo escribe solo mete
 * lo que pinta esta tarjeta. Nunca el cuerpo del paso. Si aquí hiciera falta un
 * campo nuevo, se añade al trigger — no se consulta step_bodies desde el feed.
 */
export type ActivitySnapshot = {
  step_title?: string
  step_position?: number
  step_thumb_url?: string | null
  duration_minutes?: number | null
  project_title?: string
  project_slug?: string
  project_locale?: string
  subtitle?: string | null
  cover_url?: string | null
  build_status?: 'wip' | 'finished'
  author_name?: string
  author_slug?: string
  author_avatar?: string | null
  step_count?: number
  is_paywalled?: boolean
}

export type ActivityRow = {
  id: string
  type: 'step_published' | 'project_published' | 'project_finished' | 'project_updated'
  created_at: string
  snapshot: ActivitySnapshot
}

type Props = {
  activity: ActivityRow
  /** Si el usuario ya puede leer el contenido de pago, no se pinta candado. */
  unlocked: boolean
  featured?: boolean
}

export function ActivityCard({ activity, unlocked, featured = false }: Props) {
  const s = activity.snapshot
  const isStep = activity.type === 'step_published'
  const isFinished = activity.type === 'project_finished'

  const locked = isStep && Boolean(s.is_paywalled) && !unlocked

  const projectHref = `/${s.project_locale ?? 'es'}/proyectos/${s.project_slug}`
  const href = isStep && s.step_position ? `${projectHref}/pasos/${s.step_position}` : projectHref

  const title = isStep ? s.step_title : s.project_title
  const label = isStep
    ? (s.step_thumb_url ?? `${s.step_title ?? 'paso'} · proceso`)
    : (s.cover_url ?? `${s.project_title ?? 'proyecto'} · portada`)

  return (
    <article className={`${styles.card} ${featured ? styles.featured : ''}`}>
      <div className={`${styles.media} ${featured ? styles.featuredMedia : ''}`}>
        <Photo
          src={isStep ? s.step_thumb_url : s.cover_url}
          label={typeof label === 'string' ? label : 'Fotografía del build'}
          ratio={featured ? '4 / 3' : '16 / 11'}
          priority={featured}
        />

        {isFinished && (
          <span className={`${styles.badge} ${styles.badgeDone}`}>
            <IconCheck size={13} strokeWidth={2.5} />
            Terminado
          </span>
        )}

        {isStep && featured && (
          <span className={`${styles.badge} ${styles.badgeStep}`}>Nuevo paso</span>
        )}

        {locked && (
          <div className={styles.lock}>
            <IconLock size={26} strokeWidth={1.9} />
            <span className={styles.lockPill}>Hazte Pro</span>
          </div>
        )}
      </div>

      <div className={featured ? styles.featuredBody : styles.body}>
        <p className={styles.meta}>
          {!featured && <span>{isStep ? 'Nuevo paso' : isFinished ? 'Terminado' : 'Bitácora'}</span>}
          <time dateTime={activity.created_at}>{formatRelative(activity.created_at)}</time>
        </p>

        <h3 className={`${styles.title} ${featured ? styles.titleFeatured : ''}`}>
          <Link href={href} className={styles.link}>
            {title ?? 'Sin título'}
          </Link>
        </h3>

        {isStep && s.project_title && (
          <p className={styles.parent}>
            en <span className={styles.parentName}>{s.project_title}</span>
          </p>
        )}

        {/* El subtítulo, no el número de pasos: `step_count` se congela en el
            snapshot al publicar, cuando la bitácora todavía no tiene pasos, así
            que casi siempre diría "0 pasos documentados". Un dato que cambia
            con el tiempo no pinta nada en un snapshot inmutable. */}
        {!isStep && s.subtitle && <p className={styles.parent}>{s.subtitle}</p>}

        {s.author_name && (
          <p className={styles.author}>
            <span className={styles.avatar} aria-hidden="true">
              {initialsOf(s.author_name)}
            </span>
            {s.author_name}
          </p>
        )}
      </div>
    </article>
  )
}
