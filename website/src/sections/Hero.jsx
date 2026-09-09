import { HeroPhone } from '../mockups/HeroPhone'
import { IconApple, IconPlayStore } from '../components/Icons'
import { links } from '../data/links'

/** Açılış bölümü: başlık, indirme düğmeleri ve etkileşimli telefon. */
export function Hero({ t, lang }) {
  return (
    <section className="hero" id="top">
      <div className="shell hero__grid">
        <div>
          <span className="hero__badge">
            <i />
            {t.hero.badge}
          </span>

          <h1 className="hero__title">{t.hero.title}</h1>
          <p className="hero__lede">{t.hero.lede}</p>

          <div className="hero__actions" id="download">
            <a className="btn btn--primary" href={links.appStore}>
              <IconApple size={18} />
              {t.hero.primary}
            </a>
            <a className="btn btn--ghost" href={links.playStore}>
              <IconPlayStore size={18} />
              {t.hero.secondary}
            </a>
          </div>

          <p className="hero__note">{t.hero.note}</p>
        </div>

        <div className="hero__phone">
          <HeroPhone lang={lang} />
        </div>
      </div>

      <div className="shell">
        <div className="stats">
          {t.stats.map((s) => (
            <div key={s.label} className="stats__cell">
              <div className="stats__value">{s.value}</div>
              <div className="stats__label">{s.label}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
