/**
 * Iconografía: SVG en línea, trazo lineal de 2px, sin relleno.
 *
 * Un solo estilo en toda la app. `currentColor` siempre, para que hereden el
 * color del contexto y funcionen en ambos temas sin duplicar nada.
 */

type IconProps = {
  size?: number
  className?: string
  strokeWidth?: number
}

function Svg({
  size = 18,
  className,
  strokeWidth = 2,
  children,
}: IconProps & { children: React.ReactNode }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
      className={className}
    >
      {children}
    </svg>
  )
}

export function IconLock(props: IconProps) {
  return (
    <Svg {...props}>
      <rect x="4" y="10.5" width="16" height="9.5" rx="2" />
      <path d="M8 10.5V7a4 4 0 0 1 8 0v3.5" />
    </Svg>
  )
}

export function IconClock(props: IconProps) {
  return (
    <Svg {...props}>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7v5l3 2" />
    </Svg>
  )
}

export function IconHeart({ filled, ...props }: IconProps & { filled?: boolean }) {
  return (
    <svg
      width={props.size ?? 18}
      height={props.size ?? 18}
      viewBox="0 0 24 24"
      fill={filled ? 'currentColor' : 'none'}
      stroke="currentColor"
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
      className={props.className}
    >
      <path d="M11.5 4.7a4.2 4.2 0 0 0-6 0 4.3 4.3 0 0 0 0 6L12 17.2l6.5-6.5a4.3 4.3 0 0 0 0-6 4.2 4.2 0 0 0-6 0l-.5.5z" />
    </svg>
  )
}

export function IconCheck(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="m4.5 12.5 5 5 10-11" />
    </Svg>
  )
}

export function IconChevronRight(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="m9 5 7 7-7 7" />
    </Svg>
  )
}

export function IconArrowLeft(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M19 12H5m0 0 6-6m-6 6 6 6" />
    </Svg>
  )
}

export function IconArrowRight(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M5 12h14m0 0-6-6m6 6-6 6" />
    </Svg>
  )
}

export function IconSun(props: IconProps) {
  return (
    <Svg {...props}>
      <circle cx="12" cy="12" r="4" />
      <path d="M12 2v2m0 16v2M2 12h2m16 0h2M4.9 4.9l1.5 1.5m11.2 11.2 1.5 1.5M19.1 4.9l-1.5 1.5M6.4 17.6l-1.5 1.5" />
    </Svg>
  )
}

export function IconMoon(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M20 14.5A8.5 8.5 0 0 1 9.5 4a8.5 8.5 0 1 0 10.5 10.5z" />
    </Svg>
  )
}

export function IconMenu(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M4 7h16M4 12h16M4 17h16" />
    </Svg>
  )
}

export function IconClose(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M6 6l12 12M18 6L6 18" />
    </Svg>
  )
}

export function IconDocument(props: IconProps) {
  return (
    <Svg {...props}>
      <path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z" />
      <path d="M14 3v5h5" />
    </Svg>
  )
}
