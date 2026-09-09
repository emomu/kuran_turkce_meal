import quran from '../../data/quran.json'
import { useDemoStore } from '../../store/useDemoStore'
import { IconBack, IconTextSize, IconHeadphones } from '../../components/Icons'

/**
 * Okuma ekranı — /sure/:number rotası.
 *
 * Alak suresi gösterilir: iniş sırasına göre ilk inen sure. Ayet numarası
 * metnin üstünde küçük bir etiket (ayah_tile.dart'taki karar), Arapça metin
 * isteğe bağlı, meal serif yüzle.
 *
 * Kelimelere tıklanabiliyor: bir kelimeye basıldığında kök analizi paneli
 * açılıyor — uygulamada word_picker_sheet.dart'ın yaptığı iş.
 */

/** Kök verisi. assets/data/roots.json'daki yapının mockup'a indirgenmiş hâli. */
const ROOTS = {
  qra: {
    // Bu kökü tetikleyen kelimeler. Meal her dilde farklı sözcük
    // kullandığı için eşleştirme dile göre ayrı tutuldu — tek bir Türkçe
    // listeye bakılsaydı İngilizce'de hiçbir kelime tıklanamazdı.
    words: { tr: ['oku'], en: ['read'] },
    root: 'ق ر أ',
    translit: 'q-r-ʾ',
    gloss: { tr: 'okumak, toplamak', en: 'to read, to recite' },
    count: 88,
    occurrences: [
      { src: { tr: 'Alak 1', en: 'Al-Alaq 1' }, tr: 'Yaratan Rabbinin adıyla oku', en: 'Read in the name of your Lord who created' },
      { src: { tr: 'Kıyâme 18', en: 'Al-Qiyamah 18' }, tr: 'Onu okuduğumuz zaman sen de okunuşunu takip et', en: 'When We have recited it, follow its recitation' },
      { src: { tr: 'İsrâ 106', en: 'Al-Isra 106' }, tr: "Onu bir Kur'an olarak parça parça indirdik", en: 'We have sent it down in parts' },
    ],
  },
  qlm: {
    words: { tr: ['kalemle'], en: ['pen'] },
    root: 'ق ل م',
    translit: 'q-l-m',
    gloss: { tr: 'kalem, kesmek', en: 'pen, to trim' },
    count: 4,
    occurrences: [
      { src: { tr: 'Alak 4', en: 'Al-Alaq 4' }, tr: 'O Rab ki kalemle yazmayı öğretti', en: 'Who taught by the pen' },
      { src: { tr: 'Kalem 1', en: 'Al-Qalam 1' }, tr: 'Nûn. Kaleme ve yazdıklarına andolsun', en: 'Nun. By the pen and what they write' },
    ],
  },
  alm: {
    words: { tr: ['öğretti'], en: ['taught'] },
    root: 'ع ل م',
    translit: 'ʿ-l-m',
    gloss: { tr: 'bilmek, öğretmek', en: 'to know, to teach' },
    count: 854,
    occurrences: [
      { src: { tr: 'Alak 5', en: 'Al-Alaq 5' }, tr: 'İnsana bilmediği şeyleri öğretti', en: 'Taught man what he did not know' },
      { src: { tr: 'Bakara 31', en: 'Al-Baqarah 31' }, tr: 'Âdem’e bütün isimleri öğretti', en: 'He taught Adam all the names' },
      { src: { tr: 'Rahmân 2', en: 'Ar-Rahman 2' }, tr: "Kur'an'ı öğretti", en: 'Taught the Qur’an' },
    ],
  },
}

export function ReaderScreen({ lang }) {
  const closeReader = useDemoStore((s) => s.closeReader)
  const showArabic = useDemoStore((s) => s.showArabic)
  const fontSize = useDemoStore((s) => s.translationFontSize)
  const activeRoot = useDemoStore((s) => s.activeRoot)
  const setActiveRoot = useDemoStore((s) => s.setActiveRoot)

  const tr = lang === 'tr'
  const root = activeRoot ? ROOTS[activeRoot] : null

  return (
    <>
      {/* Üst çubukta yalnızca sure adı var; künye listenin başında. */}
      <div className="reader-bar">
        <button
          type="button"
          className="reader-bar__btn"
          onClick={closeReader}
          aria-label={tr ? 'Geri' : 'Back'}
        >
          <IconBack size={19} />
        </button>
        <span className="reader-bar__title">{tr ? 'Alak' : 'Al-Alaq'}</span>
        <button type="button" className="reader-bar__btn" aria-label={tr ? 'Dinle' : 'Listen'}>
          <IconHeadphones size={21} />
        </button>
        <button
          type="button"
          className="reader-bar__btn"
          aria-label={tr ? 'Okuma ayarları' : 'Reading settings'}
        >
          <IconTextSize size={21} />
        </button>
      </div>

      <div className="screen" style={{ paddingTop: 0 }}>
        {/* _SurahHeader — büyük başlık, anlam, üç rozet, ayırıcı. */}
        <div className="surah-header">
          <h4 className="surah-header__name">{tr ? 'Alak' : 'Al-Alaq'}</h4>
          <p className="surah-header__meaning">{tr ? 'Kan Pıhtısı' : 'The Clot'}</p>
          <div className="surah-header__chips">
            <span className="surah-header__chip">
              {tr ? '1. sırada indi' : 'Revealed 1st'}
            </span>
            <span className="surah-header__chip">{tr ? 'Mekke' : 'Meccan'}</span>
            <span className="surah-header__chip">
              {tr ? '19 ayet' : '19 verses'}
            </span>
          </div>
          <div className="surah-header__rule" />
        </div>

        {quran.alak.map((a) => (
          <div
            key={a.n}
            className={[
              'ayah',
              // Dikey dolgu Arapça metnin çizilip çizilmediğine göre
              // değişiyor (ayah_tile.dart) — ayarı kapatınca bloklar
              // birbirine yaklaşmalı.
              showArabic ? '' : 'ayah--no-arabic',
              a.n === 5 ? 'ayah--highlight' : '',
            ]
              .filter(Boolean)
              .join(' ')}
          >
            <span className="ayah__no">{a.n}</span>
            {showArabic && <p className="ayah__arabic arabic">{a.ar}</p>}
            <p className="ayah__tr" style={{ fontSize }}>
              <Words
                text={tr ? a.tr : a.en}
                lang={lang}
                activeRoot={activeRoot}
                onPick={(w) => setActiveRoot(activeRoot === w ? null : w)}
              />
            </p>

            {/* Kök paneli, kelimenin bulunduğu ayetin hemen altında açılır. */}
            {root && isRootInAyah(activeRoot, tr ? a.tr : a.en, lang) && (
              <div className="root-sheet">
                <div className="root-sheet__head">
                  <span className="root-sheet__root">{root.root}</span>
                  <span className="root-sheet__gloss">
                    {root.translit} · {tr ? root.gloss.tr : root.gloss.en}
                  </span>
                  <span className="root-sheet__count">
                    {root.count} {tr ? 'geçiş' : 'uses'}
                  </span>
                </div>
                {root.occurrences.map((o) => (
                  <div key={o.src.en} className="root-sheet__item">
                    <span>{tr ? o.src.tr : o.src.en}</span>
                    {tr ? o.tr : o.en}
                  </div>
                ))}
              </div>
            )}
          </div>
        ))}

        <p
          style={{
            textAlign: 'center',
            fontSize: 11,
            color: 'var(--ink-faint)',
            padding: '16px 0 4px',
          }}
        >
          {tr ? 'Kelimeye dokunun · kök analizi' : 'Tap a word · root analysis'}
        </p>
      </div>
    </>
  )
}

/**
 * Meali kelimelere böler ve kök verisi olanları tıklanabilir yapar.
 * Kök verisi olmayan kelimeler dokunulabilir görünmemeli — kullanıcı
 * boşa dokunup hiçbir şey olmadığını görmesin.
 */
function Words({ text, lang, activeRoot, onPick }) {
  return text.split(' ').map((word, i) => {
    const key = rootKeyFor(word, lang)
    if (!key) return <span key={i}>{word} </span>

    return (
      <span key={i}>
        <button
          type="button"
          className={`ayah__word${activeRoot === key ? ' ayah__word--active' : ''}`}
          onClick={() => onPick(key)}
        >
          {word}
        </button>{' '}
      </span>
    )
  })
}

/** Bir kelimenin hangi köke ait olduğunu döndürür; yoksa null. */
function rootKeyFor(word, lang) {
  const w = normalise(word, lang)
  const hit = Object.entries(ROOTS).find(([, r]) => r.words[lang].includes(w))
  return hit ? hit[0] : null
}

/** Noktalama temizlenir; büyük/küçük harf dönüşümü dile göre yapılır. */
function normalise(word, lang) {
  return word.replace(/[.,!?;:'’"[\]()]/g, '').toLocaleLowerCase(lang === 'tr' ? 'tr' : 'en')
}

/** Kök paneli, o kökün geçtiği ayetin altında açılmalı. */
function isRootInAyah(rootKey, text, lang) {
  return text.split(/\s+/).some((w) => rootKeyFor(w, lang) === rootKey)
}
