/**
 * Duración de un paso: "4 h 20 min".
 *
 * En mono y con el formato del handoff. Es dato técnico, no prosa.
 */
export function formatDuration(minutes: number | null | undefined): string | null {
  if (minutes == null || minutes <= 0) return null

  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60

  if (hours === 0) return `${mins} min`
  if (mins === 0) return `${hours} h`
  return `${hours} h ${mins} min`
}

const DIVISIONS: { amount: number; unit: Intl.RelativeTimeFormatUnit }[] = [
  { amount: 60, unit: 'second' },
  { amount: 60, unit: 'minute' },
  { amount: 24, unit: 'hour' },
  { amount: 7, unit: 'day' },
  { amount: 4.34524, unit: 'week' },
  { amount: 12, unit: 'month' },
  { amount: Number.POSITIVE_INFINITY, unit: 'year' },
]

const rtf = new Intl.RelativeTimeFormat('es', { numeric: 'auto', style: 'long' })

/** "hace 3 h", "hace 2 d". */
export function formatRelative(iso: string | null | undefined): string {
  if (!iso) return ''

  let duration = (new Date(iso).getTime() - Date.now()) / 1000

  for (const division of DIVISIONS) {
    if (Math.abs(duration) < division.amount) {
      return rtf.format(Math.round(duration), division.unit)
    }
    duration /= division.amount
  }
  return ''
}

/** Fecha absoluta para <time dateTime>. */
export function formatDate(iso: string | null | undefined): string {
  if (!iso) return ''
  return new Intl.DateTimeFormat('es', { dateStyle: 'long' }).format(new Date(iso))
}
