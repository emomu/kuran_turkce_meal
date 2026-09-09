import { useEffect, useState } from 'react'
import { Logo } from '../components/Logo'
import { IconSun, IconMoon } from '../components/Icons'
import { useAppStore } from '../store/useAppStore'

/** Yapışkan üst çubuk: gezinme, tema ve dil düğmeleri. */
export function TopBar({ t, lang }) {
  const theme = useAppStore((s) => s.theme)
  const toggleTheme = useAppStore((s) => s.toggleTheme)
  const toggleLang = useAppStore((s) => s.toggleLang)

  // Sayfa kaydırılınca çubuğun altına ince bir çizgi gelir; en üstteyken
  // çizgi yok, hero zeminiyle kesintisiz görünüyor.
  const [scrolled, setScrolled] = useState(false)
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8)
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  return (
    <header className={`topbar${scrolled ? ' topbar--scrolled' : ''}`}>
      <div className="shell topbar__inner">
        <a href="#top" className="topbar__brand">
          <Logo size={32} />
          {lang === 'tr' ? "Kur'an Meal" : 'Qur’an Meal'}
        </a>

        <nav className="topbar__nav">
          <a href="#features">{t.nav.features}</a>
          <a href="#screens">{t.nav.screens}</a>
          <a href="#privacy">{t.nav.privacy}</a>
          <a href="#faq">{t.nav.faq}</a>
        </nav>

        <div className="topbar__actions">
          <button
            type="button"
            className="lang-btn"
            onClick={toggleLang}
            aria-label={lang === 'tr' ? 'Switch to English' : "Türkçe'ye geç"}
          >
            {lang === 'tr' ? 'EN' : 'TR'}
          </button>
          <button
            type="button"
            className="icon-btn"
            onClick={toggleTheme}
            aria-label={
              theme === 'dark'
                ? lang === 'tr' ? 'Açık temaya geç' : 'Switch to light theme'
                : lang === 'tr' ? 'Koyu temaya geç' : 'Switch to dark theme'
            }
          >
            {theme === 'dark' ? <IconSun size={19} /> : <IconMoon size={19} />}
          </button>
          <a className="btn btn--primary" href="#download" style={{ padding: '0 18px', minHeight: 38 }}>
            {t.nav.download}
          </a>
        </div>
      </div>
    </header>
  )
}
