import { Reveal } from '../components/Reveal'
import { Logo } from '../components/Logo'
import { IconApple, IconPlayStore, IconGithub } from '../components/Icons'
import { links } from '../data/links'

/** Kapanış çağrısı ve alt bilgi. */
export function Cta({ t, lang }) {
  return (
    <section className="section" style={{ paddingTop: 0 }}>
      <div className="shell">
        <Reveal className="cta">
          <h2 className="cta__title">{t.ctaTitle}</h2>
          <p className="cta__lede">{t.ctaLede}</p>
          <div className="cta__actions">
            <a className="btn btn--primary" href={links.appStore}>
              <IconApple size={18} />
              {t.hero.primary}
            </a>
            <a className="btn btn--ghost" href={links.playStore}>
              <IconPlayStore size={18} />
              {t.hero.secondary}
            </a>
          </div>
        </Reveal>

        <footer className="footer">
          <div className="footer__row">
            <span className="footer__brand">
              <Logo size={30} />
              {lang === 'tr' ? "Kur'an Meal" : 'Qur’an Meal'}
            </span>
            <nav className="footer__links">
              <a href="#features">{t.nav.features}</a>
              <a href="#screens">{t.nav.screens}</a>
              <a href="#support">{t.nav.support}</a>
              <a href="/privacy-policy.html">{t.privacyLinks.policy}</a>
              <a href="/terms.html">{t.privacyLinks.terms}</a>
              <a
                href={links.github}
                target="_blank"
                rel="noreferrer"
              >
                <IconGithub size={14} style={{ verticalAlign: '-2px', marginRight: 4 }} />
                GitHub
              </a>
            </nav>
          </div>
          <p className="footer__meta">
            {t.footerTagline}
            <br />
            © {new Date().getFullYear()} Emirhan Soylu · {t.footerRights}
          </p>
        </footer>
      </div>
    </section>
  )
}
