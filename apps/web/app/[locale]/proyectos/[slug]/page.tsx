import Link from 'next/link'
import { notFound } from 'next/navigation'
import type { Metadata } from 'next'
import { isAtLeast } from '@aulaescala/shared'
import { Photo } from '@/components/photo'
import {
  IconArrowLeft,
  IconChevronRight,
  IconClock,
  IconDocument,
  IconLock,
} from '@/components/icons'
import { createClient } from '@/lib/supabase/server'
import { getViewer, initialsOf } from '@/lib/tier'
import { formatDuration } from '@/lib/format'
import styles from './project.module.css'

export const revalidate = 300

const DIFFICULTY: Record<string, string> = {
  iniciacion: 'Iniciación',
  intermedio: 'Intermedio',
  avanzado: 'Avanzado',
  experto: 'Experto',
}

async function loadProject(slug: string, locale: string) {
  const supabase = await createClient()

  const { data } = await supabase
    .from('projects')
    .select(
      `id, title, subtitle, slug, body, cover_url, manufacturer, kit_ref,
       difficulty, build_status, locale,
       scale:scales ( name ),
       subject:subjects ( name, slug ),
       author:profiles!projects_author_id_fkey ( display_name, slug, avatar_url )`,
    )
    .eq('slug', slug)
    .eq('locale', locale)
    .maybeSingle()

  return data
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string; slug: string }>
}): Promise<Metadata> {
  const { locale, slug } = await params
  const project = await loadProject(slug, locale)

  if (!project) return { title: 'Bitácora no encontrada' }

  return {
    title: project.title,
    description:
      project.subtitle ??
      `Bitácora de montaje paso a paso de ${project.title}. Técnicas, tiempos y fotografías del proceso.`,
    alternates: { canonical: `/${locale}/proyectos/${project.slug}` },
  }
}

export default async function ProjectPage({
  params,
}: {
  params: Promise<{ locale: string; slug: string }>
}) {
  const { locale, slug } = await params

  const supabase = await createClient()
  const viewer = await getViewer()
  const project = await loadProject(slug, locale)

  // Puede ser que no exista, o que exista y sea borrador ajeno: la RLS no
  // distingue, y está bien que no lo haga.
  if (!project) notFound()

  const [{ data: steps }, { data: materials }] = await Promise.all([
    supabase
      .from('steps')
      .select('id, position, title, thumb_url, duration_minutes')
      .eq('project_id', project.id)
      .order('position'),
    supabase
      .from('materials')
      .select('id, filename, byte_size')
      .eq('project_id', project.id)
      .order('position'),
  ])

  const { data: previewCount } = await supabase.rpc('free_preview_steps')
  const freeSteps = previewCount ?? 0
  const canReadPaid = isAtLeast(viewer.tier, 'pro')

  const author = project.author
  const finished = project.build_status === 'finished'

  const attrs = [
    { label: 'Escala', value: project.scale?.name },
    { label: 'Temática', value: project.subject?.name },
    { label: 'Fabricante', value: project.manufacturer },
    { label: 'Referencia', value: project.kit_ref },
    { label: 'Dificultad', value: project.difficulty ? DIFFICULTY[project.difficulty] : null },
    { label: 'Estado', value: finished ? 'Terminado' : 'En progreso' },
  ].filter((a) => a.value)

  return (
    <>
      <header className={styles.cover}>
        {/* `compact`: la portada ya lleva el título encima. Una etiqueta
            centrada aquí se cruza con la píldora de estado y la temática. */}
        <Photo
          src={project.cover_url}
          label={`${project.title} — portada`}
          className={styles.coverPhoto}
          priority
          compact
        />
        <div className={styles.coverVeil} />

        <div className={`page ${styles.coverInner}`}>
          <Link href={`/${locale}`} className={styles.back}>
            <IconArrowLeft size={15} />
            Proyectos
          </Link>

          <div className={styles.status}>
            <span className={styles.pill}>
              <span className={`${styles.dot} ${finished ? styles.dotDone : ''}`} />
              {finished ? 'Terminado' : 'WIP'}
            </span>
            {project.subject && <span className={styles.subject}>{project.subject.name}</span>}
          </div>

          <h1 className={styles.title}>{project.title}</h1>
          {project.subtitle && <p className={styles.subtitle}>{project.subtitle}</p>}
        </div>
      </header>

      <div className="page">
        {attrs.length > 0 && (
          <dl className={styles.attrs}>
            {attrs.map((a) => (
              <div key={a.label} className={styles.attr}>
                <dt className={styles.attrLabel}>{a.label}</dt>
                <dd className={styles.attrValue}>{a.value}</dd>
              </div>
            ))}
          </dl>
        )}

        <div className={styles.columns}>
          <section>
            {project.body && <p className={styles.intro}>{project.body}</p>}

            <div className={styles.sectionHead}>
              <h2 className={styles.sectionTitle}>Bitácora de montaje</h2>
              <span className={styles.count}>
                {steps?.length ?? 0} {steps?.length === 1 ? 'paso' : 'pasos'}
              </span>
            </div>

            {!steps || steps.length === 0 ? (
              <p className={styles.intro}>
                Esta bitácora aún no tiene pasos publicados. Cuando su autor documente el
                primero, aparecerá aquí y en Proyectos.
              </p>
            ) : (
              <ol className={styles.steps}>
                {steps.map((step) => {
                  const locked = step.position > freeSteps && !canReadPaid
                  const duration = formatDuration(step.duration_minutes)

                  return (
                    <li key={step.id} className={styles.step}>
                      <div className={styles.stepThumb}>
                        <Photo
                          src={step.thumb_url}
                          label={step.title}
                          ratio="90 / 66"
                          compact
                        />
                        {locked && (
                          <span className={styles.stepLock}>
                            <IconLock size={16} strokeWidth={2} />
                          </span>
                        )}
                      </div>

                      <div>
                        <span className={styles.stepNumber} aria-hidden="true">
                          {String(step.position).padStart(2, '0')}
                        </span>

                        <h3 className={styles.stepTitle}>
                          <Link
                            href={`/${locale}/proyectos/${project.slug}/pasos/${step.position}`}
                            className={styles.stepLink}
                          >
                            {step.title}
                          </Link>
                        </h3>

                        <div className={styles.stepMeta}>
                          {duration && (
                            <span className={styles.duration}>
                              <IconClock size={13} />
                              {duration}
                            </span>
                          )}
                          {locked && <span className={styles.tech}>Pro</span>}
                        </div>
                      </div>

                      <IconChevronRight size={18} className={styles.chevron} />
                    </li>
                  )
                })}
              </ol>
            )}
          </section>

          <aside className={styles.aside}>
            {author && (
              <section className={styles.panel}>
                <div className={styles.panelHead}>
                  <h2 className={styles.panelTitle}>Sobre el autor</h2>
                </div>
                <div className={styles.author}>
                  <span className={styles.avatar} aria-hidden="true">
                    {initialsOf(author.display_name)}
                  </span>
                  <div>
                    <Link href={`/${locale}/modelistas/${author.slug}`} className={styles.authorName}>
                      {author.display_name}
                    </Link>
                    <p className={styles.authorMeta}>@{author.slug}</p>
                  </div>
                </div>
              </section>
            )}

            <section className={styles.panel}>
              <div className={styles.panelHead}>
                <h2 className={styles.panelTitle}>Materiales</h2>
                {!canReadPaid && <span className={styles.proBadge}>Pro</span>}
              </div>

              {canReadPaid ? (
                materials && materials.length > 0 ? (
                  <ul className={styles.files}>
                    {materials.map((m) => (
                      <li key={m.id}>
                        <a href={`/api/materiales/${m.id}`} className={styles.file}>
                          <IconDocument size={17} />
                          <span>
                            <span className={styles.fileName}>{m.filename}</span>
                            {m.byte_size && (
                              <span className={styles.fileSize}> · {formatBytes(m.byte_size)}</span>
                            )}
                          </span>
                        </a>
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className={styles.lockedText}>
                    Esta bitácora no incluye materiales descargables.
                  </p>
                )
              ) : (
                <div className={styles.filesLocked}>
                  <IconLock size={22} strokeWidth={1.9} />
                  <p className={styles.lockedText}>
                    Plantillas, listas de pinturas y referencias del autor.
                  </p>
                  <Link href={`/${locale}/precios`} className={styles.unlock}>
                    Desbloquear con Pro
                  </Link>
                </div>
              )}
            </section>
          </aside>
        </div>
      </div>
    </>
  )
}

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}
