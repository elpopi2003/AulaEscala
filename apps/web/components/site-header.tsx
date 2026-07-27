'use client'

import { useEffect, useRef, useState } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { IconClose, IconMenu, IconMoon, IconSun } from './icons'
import styles from './site-header.module.css'

type NavItem = { href: string; label: string }

const NAV: NavItem[] = [
  // "Proyectos", no "Feed": el anglicismo no dice nada al publico espanol, y la
  // pagina lo que muestra son bitacoras avanzando.
  { href: '/es', label: 'Proyectos' },
  { href: '/es/tecnicas', label: 'Técnicas' },
  { href: '/es/precios', label: 'Precios' },
]

type SiteHeaderProps = {
  /** Iniciales del usuario, o null si no hay sesión. */
  initials: string | null
  displayName: string | null
  /** Modelistas ven "Mis proyectos" en la nav. */
  canAuthor: boolean
}

export function SiteHeader({ initials, displayName, canAuthor }: SiteHeaderProps) {
  const pathname = usePathname()
  const [menuOpen, setMenuOpen] = useState(false)
  const closeButtonRef = useRef<HTMLButtonElement>(null)

  const items = canAuthor ? [...NAV, { href: '/es/mis-proyectos', label: 'Mis proyectos' }] : NAV

  // El drawer se cierra al navegar: si no, queda abierto sobre la página nueva.
  useEffect(() => {
    setMenuOpen(false)
  }, [pathname])

  // Escape cierra, y el foco entra al drawer al abrirlo. Sin esto, un usuario
  // de teclado abre el menú y sigue tabulando por la página de detrás.
  useEffect(() => {
    if (!menuOpen) return

    closeButtonRef.current?.focus()
    document.body.style.overflow = 'hidden'

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setMenuOpen(false)
    }
    document.addEventListener('keydown', onKeyDown)

    return () => {
      document.removeEventListener('keydown', onKeyDown)
      document.body.style.overflow = ''
    }
  }, [menuOpen])

  const isActive = (href: string) =>
    href === '/es' ? pathname === '/es' : pathname.startsWith(href)

  return (
    <header className={styles.header}>
      <div className={styles.inner}>
        <Link href="/es" className={styles.brand}>
          <span className={styles.chip} aria-hidden="true">
            1/35
          </span>
          <span className={styles.wordmark}>
            <span className={styles.aula}>Aula</span>
            <span className={styles.escala}>escala.</span>
          </span>
        </Link>

        <nav className={styles.nav} aria-label="Principal">
          {items.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={`${styles.navLink} ${isActive(item.href) ? styles.navLinkActive : ''}`}
              aria-current={isActive(item.href) ? 'page' : undefined}
            >
              {item.label}
            </Link>
          ))}
        </nav>

        <div className={styles.actions}>
          <ThemeToggle />

          {initials ? (
            <Link
              href="/es/cuenta"
              className={`${styles.avatar} ${styles.desktopOnly}`}
              title={displayName ?? 'Mi cuenta'}
            >
              <span aria-hidden="true">{initials}</span>
              <span className="sr-only">Mi cuenta</span>
            </Link>
          ) : (
            <Link href="/es/entrar" className={`${styles.cta} ${styles.desktopOnly}`}>
              Entrar
            </Link>
          )}

          <button
            type="button"
            className={`${styles.iconButton} ${styles.menuButton}`}
            onClick={() => setMenuOpen(true)}
            aria-expanded={menuOpen}
            aria-label="Abrir menú"
          >
            <IconMenu />
          </button>
        </div>
      </div>

      {menuOpen && (
        <>
          <button
            type="button"
            className={styles.overlay}
            onClick={() => setMenuOpen(false)}
            tabIndex={-1}
            aria-hidden="true"
          />
          <aside className={styles.drawer} aria-label="Menú">
            <div className={styles.drawerHead}>
              <span className={styles.wordmark}>
                <span className={styles.aula}>Aula</span>
                <span className={styles.escala}>escala.</span>
              </span>
              <button
                ref={closeButtonRef}
                type="button"
                className={styles.iconButton}
                onClick={() => setMenuOpen(false)}
                aria-label="Cerrar menú"
              >
                <IconClose />
              </button>
            </div>

            <nav className={styles.drawerNav} aria-label="Principal">
              {items.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`${styles.drawerLink} ${isActive(item.href) ? styles.drawerLinkActive : ''}`}
                  aria-current={isActive(item.href) ? 'page' : undefined}
                >
                  {item.label}
                </Link>
              ))}
              <Link
                href={initials ? '/es/cuenta' : '/es/entrar'}
                className={styles.drawerLink}
              >
                {initials ? 'Mi cuenta' : 'Entrar'}
              </Link>
            </nav>
          </aside>
        </>
      )}
    </header>
  )
}

function ThemeToggle() {
  const [theme, setTheme] = useState<'light' | 'dark' | null>(null)

  // El tema real lo fijó el script inline del layout antes del primer pintado.
  // Aquí solo se lee, para que el icono coincida sin provocar hidratación
  // divergente.
  useEffect(() => {
    setTheme((document.documentElement.dataset.theme as 'light' | 'dark') ?? 'light')
  }, [])

  const toggle = () => {
    const next = theme === 'dark' ? 'light' : 'dark'
    document.documentElement.dataset.theme = next
    try {
      localStorage.setItem('aulaescala-theme', next)
    } catch {
      // Modo privado o almacenamiento bloqueado: el tema dura la sesión.
    }
    setTheme(next)
  }

  return (
    <button
      type="button"
      className={styles.iconButton}
      onClick={toggle}
      aria-label={theme === 'dark' ? 'Cambiar a tema claro' : 'Cambiar a tema oscuro'}
    >
      {/* Antes de montar no se sabe el tema: se reserva el hueco sin icono para
          que el botón no salte de tamaño al hidratar. */}
      {theme === null ? <span style={{ width: 18, height: 18 }} /> : theme === 'dark' ? <IconSun /> : <IconMoon />}
    </button>
  )
}
