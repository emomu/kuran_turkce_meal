/**
 * Kayıtlar ekranı: yer imleri, vurgular ve notlar tek listede.
 *
 * Vurgu rengi soldaki ince şeritle gösterilir — uygulamada ayet metninin
 * arkasına düşük alfa ile uygulanan rengin liste karşılığı.
 */
const ITEMS = [
  {
    color: 'var(--hl-yellow)',
    src: { tr: 'Alak · 5. ayet', en: 'Al-Alaq · verse 5' },
    text: {
      tr: 'İnsana bilmediği şeyleri öğretti',
      en: 'Taught man what he did not know',
    },
    note: {
      tr: 'İlk inen ayetlerin konusu öğrenme. Bu kök Kur\'an\'da 854 yerde geçiyor.',
      en: 'The first verses are about learning. This root appears 854 times.',
    },
  },
  {
    color: 'var(--hl-green)',
    src: { tr: 'Bakara · 153. ayet', en: 'Al-Baqarah · verse 153' },
    text: {
      tr: 'Ey iman edenler! Sabır ve namazla yardım isteyin. Şüphe yok ki Allah, sabredenlerle beraberdir',
      en: 'You who believe, seek help through steadfastness and prayer, for God is with the steadfast',
    },
  },
  {
    color: 'var(--hl-blue)',
    src: { tr: 'Kalem · 1. ayet', en: 'Al-Qalam · verse 1' },
    text: {
      tr: 'Nûn. Kaleme ve yazdıklarına andolsun',
      en: 'Nun. By the pen and what they write',
    },
  },
  {
    color: 'var(--hl-purple)',
    src: { tr: 'Müzzemmil · 4. ayet', en: 'Al-Muzzammil · verse 4' },
    text: {
      tr: "Kur'an'ı ağır ağır, tane tane oku",
      en: 'Recite the Qur’an slowly and distinctly',
    },
  },
]

export function SavedScreen({ lang }) {
  const tr = lang === 'tr'
  // _TabBar'daki üç sekme: Tümü / Notlar / Vurgular.
  const tabs = tr
    ? ['Yer imleri', 'Notlar', 'Vurgular']
    : ['Bookmarks', 'Notes', 'Highlights']

  return (
    <div className="screen">
      <h3 className="screen__title">{tr ? 'Kaydedilenler' : 'Saved'}</h3>

      <div className="segmented">
        {tabs.map((label, i) => (
          <button
            key={label}
            type="button"
            className={`segmented__item${i === 0 ? ' segmented__item--active' : ''}`}
          >
            {label}
          </button>
        ))}
      </div>

      <div style={{ marginTop: 4 }}>
        {ITEMS.map((it) => (
          <div key={it.src.en} className="saved-item">
            <span className="saved-item__swatch" style={{ background: it.color }} />
            <div style={{ minWidth: 0 }}>
              <div className="saved-item__src">{tr ? it.src.tr : it.src.en}</div>
              <p className="saved-item__text">{tr ? it.text.tr : it.text.en}</p>
              {it.note && (
                <p className="saved-item__note">{tr ? it.note.tr : it.note.en}</p>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
