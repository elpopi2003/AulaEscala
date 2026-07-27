import styles from './site-footer.module.css'

export function SiteFooter() {
  return (
    <footer className={styles.footer}>
      <div className={`page ${styles.inner}`}>
        <span className={styles.wordmark}>
          Aulaescala<span className={styles.dot}>.</span>
        </span>
        <p className={styles.tagline}>
          Bitácoras de modelismo estático · maquetas, dioramas y figuras
        </p>
      </div>
    </footer>
  )
}
