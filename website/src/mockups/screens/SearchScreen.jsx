import quran from '../../data/quran.json'
import { IconSearch } from '../../components/Icons'

/**
 * Arama ekranı.
 *
 * Aranan terim sonuç metninde vurgulanır. Örnek olarak "sabır" seçildi:
 * Türkçe arama normalizasyonunun ne yaptığını göstermek için sonuçlarda
 * hem "sabır" hem "sabredenler" eşleşiyor.
 */
export function SearchScreen({ lang }) {
  const tr = lang === 'tr'
  const term = tr ? 'sabır' : 'steadfast'

  return (
    <div className="screen">
      <h3 className="screen__title">{tr ? 'Mealde ara' : 'Search'}</h3>

      <label className="search-field" style={{ marginTop: 'var(--md)' }}>
        <IconSearch size={16} />
        <input
          readOnly
          value={term}
          aria-label={tr ? 'Mealde ara' : 'Search the translation'}
        />
      </label>

      {/* Sonuç sayısı — bodySmall */}
      <p
        style={{
          fontSize: 13,
          lineHeight: 1.4,
          color: 'var(--ink-muted)',
          marginTop: 'var(--sm)',
        }}
      >
        {tr ? '142 sonuç' : '142 results'}
      </p>

      <div style={{ marginTop: 4 }}>
        {quran.searchResults.map((r) => (
          <div key={`${r.surah}-${r.n}`} className="search-result">
            <div className="search-result__src">
              {tr ? `${r.surah} · ${r.n}. ayet` : `${r.surahEn} · verse ${r.n}`}
            </div>
            <p
              className="search-result__text"
              dangerouslySetInnerHTML={{ __html: mark(tr ? r.tr : r.en, tr) }}
            />
          </div>
        ))}
      </div>
    </div>
  )
}

/**
 * Eşleşen kısımları <mark> ile sarar.
 *
 * Uygulamadaki arama normalizasyonunun (search_normalizer.dart) basitleştirilmiş
 * karşılığı: Türkçe'de "sabır" kökünden türeyen biçimler de vurgulanmalı,
 * yoksa sonuç listesinde eşleşmenin nerede olduğu görünmez.
 */
function mark(text, tr) {
  const pattern = tr ? /(sabr?[ıieaû]?\w*)/gi : /(steadfast\w*)/gi
  return text.replace(pattern, '<mark>$1</mark>')
}
