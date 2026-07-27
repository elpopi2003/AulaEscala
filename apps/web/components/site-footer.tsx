import styles from './site-footer.module.css'

export function SiteFooter() {
  return (
    <footer className={styles.footer}>
      <div className={`page ${styles.inner}`}>
        <span className={styles.wordmark}>
          <span className={styles.aula}>Aula</span>
          <span className={styles.escala}>escala.</span>
        </span>
        <p className={styles.tagline}>
          Bitácoras de modelismo estático · maquetas, dioramas y figuras
        </p>
      </div>
    </footer>
  )
}
