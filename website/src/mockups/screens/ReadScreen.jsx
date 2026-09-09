import quran from '../../data/quran.json'
import { useDemoStore } from '../../store/useDemoStore'
import { IconSwap, IconChevron, IconSearch, IconPlay } from '../../components/Icons'

/**
 * Ana ekran (Oku sekmesi).
 *
 * lib/features/home/view/home_screen.dart düzeninin birebir karşılığı:
 * başlık, "kaldığın yer" kartı, günün ayeti, liste başlığı + sıralama
 * düğmesi, sure süzme alanı, sure listesi.
 */
export function ReadScreen({ lang }) {
  const sortByRevelation = useDemoStore((s) => s.sortByRevelation)
  const toggleSort = useDemoStore((s) => s.toggleSort)
  const openReader = useDemoStore((s) => s.openReader)
  const query = useDemoStore((s) => s.query)
  const setQuery = useDemoStore((s) => s.setQuery)

  const tr = lang === 'tr'

  // Sıralama düğmesi listeyi gerçekten yeniden diziyor — mockup'ın
  // etkileşimli olmasının bütün amacı bu farkı göstermek.
  const list = [...quran.surahs]
    .sort((a, b) =>
      sortByRevelation ? a.revelationOrder - b.revelationOrder : a.number - b.number,
    )
    .filter((s) => {
      const q = query.trim().toLocaleLowerCase(tr ? 'tr' : 'en')
      if (!q) return true
      return (tr ? s.name : s.nameEn).toLocaleLowerCase(tr ? 'tr' : 'en').includes(q)
    })

  return (
    <div className="screen">
      <h3 className="screen__title">{tr ? "Kur'an" : 'Qur’an'}</h3>
      <p className="screen__subtitle">{tr ? 'Türkçe meal' : 'Turkish translation'}</p>

      {/* Kaldığın yer kartı — yalnızca okuma geçmişi olduğunda çizilir. */}
      <button type="button" className="card-continue" onClick={() => openReader(96)}>
        <div className="card-continue__row">
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="card-continue__label">{tr ? 'KALDIĞIN YER' : 'LAST READ'}</div>
            <div className="card-continue__name">{tr ? 'Alak' : 'Al-Alaq'}</div>
            <div className="card-continue__meta">
              {tr ? '5. ayet · 19 ayetten' : 'verse 5 · of 19'}
            </div>
          </div>
          <span className="card-continue__play">
            <IconPlay size={20} />
          </span>
        </div>
        <div className="card-continue__bar">
          <i style={{ width: '26%' }} />
        </div>
      </button>

      <div className="card-verse">
        <div className="card-verse__label">{tr ? 'GÜNÜN AYETİ' : 'VERSE OF THE DAY'}</div>
        <p className="card-verse__text">
          {tr
            ? 'Ey iman edenler! Sabır ve namazla yardım isteyin. Şüphe yok ki Allah, sabredenlerle beraberdir'
            : 'You who believe, seek help through steadfastness and prayer, for God is with the steadfast'}
        </p>
        <div className="card-verse__source">
          {tr ? 'Bakara · 153. ayet' : 'Al-Baqarah · verse 153'}
        </div>
      </div>

      <div className="list-head">
        <span className="list-head__title">{tr ? 'Sureler' : 'Surahs'}</span>
        <button type="button" className="order-toggle" onClick={toggleSort}>
          <IconSwap size={14} />
          {sortByRevelation
            ? tr ? 'İniş sırası' : 'Revelation'
            : tr ? 'Mushaf sırası' : 'Mushaf'}
        </button>
      </div>

      <label className="search-field">
        <IconSearch size={16} />
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder={tr ? 'Sure ara' : 'Search surah'}
          aria-label={tr ? 'Sure ara' : 'Search surah'}
        />
      </label>

      <div style={{ marginTop: 4 }}>
        {list.map((s) => (
          <SurahRow
            key={s.number}
            surah={s}
            tr={tr}
            showRevelationOrder={sortByRevelation}
            progress={s.number === 96 ? 5 / s.ayahCount : null}
            onOpen={() => openReader(s.number)}
          />
        ))}
        {list.length === 0 && (
          <p style={{ padding: '20px 0', fontSize: 13, color: 'var(--ink-muted)' }}>
            {tr ? 'Bu ada uyan sure yok.' : 'No surah matches that name.'}
          </p>
        )}
      </div>
    </div>
  )
}

/** Sure listesindeki tek satır — surah_row.dart karşılığı. */
function SurahRow({ surah, tr, showRevelationOrder, progress, onOpen }) {
  const primary = showRevelationOrder ? surah.revelationOrder : surah.number
  const counterpart = showRevelationOrder
    ? `Mushaf ${surah.number}`
    : tr ? `${surah.revelationOrder}. iniş` : `${surah.revelationOrder}th revealed`
  const place = surah.place === 'mekke' ? (tr ? 'Mekke' : 'Meccan') : tr ? 'Medine' : 'Medinan'
  const count = tr ? `${surah.ayahCount} ayet` : `${surah.ayahCount} verses`

  return (
    <button type="button" className="surah-row" onClick={onOpen}>
      <span className="surah-row__no">{primary}</span>
      <span className="surah-row__body">
        <span className="surah-row__name">{tr ? surah.name : surah.nameEn}</span>
        <span className="surah-row__meta">
          {(tr ? surah.meaning : surah.meaningEn)} · {place} · {count} · {counterpart}
        </span>
        {progress != null && (
          <span className="surah-row__bar">
            <i style={{ width: `${progress * 100}%` }} />
          </span>
        )}
      </span>
      <IconChevron size={17} className="surah-row__chevron" />
    </button>
  )
}
