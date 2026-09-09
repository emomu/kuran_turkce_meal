import { useState } from 'react'
import { Reveal } from '../components/Reveal'
import { IconPlus } from '../components/Icons'

/**
 * Sık sorulanlar.
 *
 * Aynı anda tek bir soru açık kalır; ikinci bir soruya basmak öncekini
 * kapatır, böylece liste kısa kalır ve kullanıcı sayfada kaybolmaz.
 */
export function Faq({ t }) {
  const [open, setOpen] = useState(0)

  return (
    <section className="section" id="faq">
      <div className="shell">
        <Reveal className="section-head">
          <span className="eyebrow">{t.nav.faq}</span>
          <h2 className="section-title" style={{ marginTop: 8 }}>
            {t.faqTitle}
          </h2>
        </Reveal>

        <Reveal className="faq">
          {t.faq.map((item, i) => (
            <div key={item.q} className={`faq__item${open === i ? ' faq__item--open' : ''}`}>
              <button
                type="button"
                className="faq__q"
                onClick={() => setOpen(open === i ? -1 : i)}
                aria-expanded={open === i}
              >
                <span>{item.q}</span>
                <IconPlus size={19} className="faq__sign" />
              </button>
              <div className="faq__a">
                <div>
                  <p>{item.a}</p>
                </div>
              </div>
            </div>
          ))}
        </Reveal>
      </div>
    </section>
  )
}
