import { Reveal } from '../components/Reveal'
import { featureIcons } from '../components/featureIcons'

/** Özellik kartları. */
export function Features({ t }) {
  return (
    <section className="section section--sunken" id="features">
      <div className="shell">
        <Reveal className="section-head">
          <span className="eyebrow">{t.nav.features}</span>
          <h2 className="section-title" style={{ marginTop: 8 }}>
            {t.featuresTitle}
          </h2>
          <p className="section-lede">{t.featuresLede}</p>
        </Reveal>

        <div className="feature-grid">
          {t.features.map((f, i) => {
            const Icon = featureIcons[f.icon]
            return (
              <Reveal key={f.title} className="feature" delay={i * 60}>
                <span className="feature__icon">
                  <Icon size={21} />
                </span>
                <h3 className="feature__title">{f.title}</h3>
                <p className="feature__body">{f.body}</p>
              </Reveal>
            )
          })}
        </div>
      </div>
    </section>
  )
}
