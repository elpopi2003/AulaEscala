import styles from './photo.module.css'

type PhotoProps = {
  src?: string | null
  /** Qué se espera ver aquí. Se usa como alt real y como texto del marcador. */
  label: string
  /** CSS aspect-ratio, p. ej. "16 / 11". */
  ratio?: string
  className?: string
  priority?: boolean
  /**
   * Miniaturas pequeñas (90×66 en la lista de pasos): se pintan solo las rayas,
   * sin etiqueta. El texto no cabe, se apelmaza en tres líneas cortadas y hace
   * ruido justo donde el ojo está recorriendo una lista.
   */
  compact?: boolean
}

/**
 * Imagen con marcador de reserva.
 *
 * Mientras no haya fotos reales, pinta las rayas diagonales del handoff con una
 * etiqueta de lo que debería ir ahí. No es solo andamiaje de maqueta: sirve
 * igual como estado vacío cuando un modelista aún no ha subido la foto de un
 * paso, que es una situación real y permanente del producto.
 */
export function Photo({
  src,
  label,
  ratio = '16 / 11',
  className,
  priority,
  compact = false,
}: PhotoProps) {
  return (
    <div
      className={[styles.photo, className].filter(Boolean).join(' ')}
      style={{ aspectRatio: ratio }}
    >
      {src ? (
        /* Se usa <img> a propósito, no next/image: Storage sirve las imágenes
           privadas con signed URL de vida corta, y el optimizador de Next las
           cachearía más allá de su validez. */
        /* eslint-disable-next-line @next/next/no-img-element */
        <img
          src={src}
          alt={label}
          className={styles.image}
          loading={priority ? 'eager' : 'lazy'}
          decoding="async"
        />
      ) : compact ? (
        <span className="sr-only">{label}</span>
      ) : (
        <span className={styles.label}>{label}</span>
      )}
    </div>
  )
}
