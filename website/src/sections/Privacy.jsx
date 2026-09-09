import { Reveal } from '../components/Reveal'
import { IconCheck, IconLock, IconGithub } from '../components/Icons'
import { links } from '../data/links'

/** Gizlilik bölümü. Mağaza metnindeki "veri toplanmıyor" iddiasını açar. */
export function Privacy({ t }) {
  return (
    <section className="section section--sunken" id="privacy">
      <div className="shell privacy__layout">
        <Reveal>
          <span className="eyebrow">
            <IconLock size={13} style={{ verticalAlign: '-2px', marginRight: 4 }} />
            {t.nav.privacy}
          </span>
          <h2 className="section-title" style={{ marginTop: 8 }}>
            {t.privacyTitle}
          </h2>
          <p className="section-lede">{t.privacyLede}</p>

          <p className="privacy__footnote">{t.privacyFootnote}</p>

          <div className="privacy__links">
            <a href="/privacy-policy.html">{t.privacyLinks.policy}</a>
            <a href="/terms.html">{t.privacyLinks.terms}</a>
            <a
              href={links.github}
              target="_blank"
              rel="noreferrer"
            >
              <IconGithub size={13} style={{ verticalAlign: '-2px', marginRight: 4 }} />
              {t.privacyLinks.source}
            </a>
          </div>
        </Reveal>

        <Reveal className="privacy__points" delay={80}>
          {t.privacyPoints.map((p) => (
            <div key={p.title} className="privacy__point">
              <div className="privacy__point-title">
                <IconCheck size={16} />
                {p.title}
              </div>
              <p className="privacy__point-body">{p.body}</p>
            </div>
          ))}
        </Reveal>
      </div>
    </section>
  )
}
