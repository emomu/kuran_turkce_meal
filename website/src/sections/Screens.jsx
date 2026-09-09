import { AppDemo } from '../mockups/AppDemo'
import { Reveal } from '../components/Reveal'
import { useDemoStore } from '../store/useDemoStore'
import {
  IconBook,
  IconSearch,
  IconCalendar,
  IconBookmark,
  IconSettings,
  IconRoot,
} from '../components/Icons'

/**
 * Ekran turu.
 *
 * Soldaki liste ile telefondaki sekme çubuğu aynı store'u yazıyor: hangisine
 * basılırsa basılsın ikisi de aynı ekrana gidiyor ve seçili satır güncelleniyor.
 * "Kök analizi" bir sekme değil, okuma ekranı içindeki bir durum — o yüzden
 * ayrı bir eylem olarak listeleniyor.
 */
const SCREENS = [
  {
    id: 'read',
    Icon: IconBook,
    tr: { name: 'Ana ekran', desc: 'Kaldığın yer, günün ayeti ve iki sıralamalı sure listesi' },
    en: { name: 'Home', desc: 'Where you left off, verse of the day and the dual-ordered surah list' },
  },
  {
    id: 'reader',
    Icon: IconRoot,
    tr: { name: 'Okuma ve kök analizi', desc: 'Meal, Arapça metin ve kelimeye dokununca açılan kök paneli' },
    en: { name: 'Reader and roots', desc: 'Translation, Arabic text and the root panel a tapped word opens' },
  },
  {
    id: 'search',
    Icon: IconSearch,
    tr: { name: 'Arama', desc: "6.236 ayette Türkçe'ye duyarlı anlık sonuçlar" },
    en: { name: 'Search', desc: 'Instant, Turkish-aware results across 6,236 verses' },
  },
  {
    id: 'plans',
    Icon: IconCalendar,
    tr: { name: 'Planlar', desc: 'Kronolojik ve mushaf sıralı dört hazır okuma planı' },
    en: { name: 'Plans', desc: 'Four presets in chronological and mushaf order' },
  },
  {
    id: 'saved',
    Icon: IconBookmark,
    tr: { name: 'Kayıtlar', desc: 'Yer imleri, beş renkli vurgular ve kendi notlarınız' },
    en: { name: 'Saved', desc: 'Bookmarks, five-colour highlights and your own notes' },
  },
  {
    id: 'settings',
    Icon: IconSettings,
    tr: { name: 'Ayarlar', desc: 'Tema, dil, Arapça metin ve canlı değişen punto' },
    en: { name: 'Settings', desc: 'Theme, language, Arabic text and live text size' },
  },
]

export function Screens({ t, lang }) {
  const tab = useDemoStore((s) => s.tab)
  const openSurah = useDemoStore((s) => s.openSurah)
  const setTab = useDemoStore((s) => s.setTab)
  const openReader = useDemoStore((s) => s.openReader)

  // Okuma ekranı açıkken listede "Okuma ve kök analizi" işaretli olmalı.
  const activeId = openSurah ? 'reader' : tab

  const select = (id) => {
    if (id === 'reader') {
      setTab('read')
      openReader(96)
    } else {
      setTab(id)
    }
  }

  return (
    <section className="section" id="screens">
      <div className="shell screens__layout">
        <Reveal>
          <span className="eyebrow">{t.nav.screens}</span>
          <h2 className="section-title" style={{ marginTop: 8 }}>
            {t.screensTitle}
          </h2>
          <p className="section-lede">{t.screensLede}</p>

          <div className="screens__list">
            {SCREENS.map((s) => {
              const label = lang === 'tr' ? s.tr : s.en
              const active = activeId === s.id
              return (
                <button
                  key={s.id}
                  type="button"
                  className={`screen-link${active ? ' screen-link--active' : ''}`}
                  onClick={() => select(s.id)}
                  aria-pressed={active}
                >
                  <span className="screen-link__icon">
                    <s.Icon size={18} />
                  </span>
                  <span>
                    <span className="screen-link__name">{label.name}</span>
                    <span className="screen-link__desc">{label.desc}</span>
                  </span>
                </button>
              )
            })}
          </div>

          <p className="screens__hint">{t.screensHint}</p>
        </Reveal>

        {/* Sticky, transform uygulayan bir atanın içinde çalışmaz —
            Reveal bu yüzden sticky sarmalayıcının içine alındı. */}
        <div className="screens__phone">
          <Reveal delay={80}>
            <AppDemo lang={lang} />
          </Reveal>
        </div>
      </div>
    </section>
  )
}
