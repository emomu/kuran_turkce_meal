import { useAppStore } from '../../store/useAppStore'
import { useDemoStore } from '../../store/useDemoStore'
import { IconChevron } from '../../components/Icons'

/**
 * Ayarlar ekranı — settings_screen.dart.
 *
 * Ayarlar başlıklı gruplara bölünür (GÖRÜNÜM, DİL, OKUMA, GÜNÜN AYETİ…);
 * her grup yuvarlak köşeli bir kutu, üstünde harf aralıklı küçük bir
 * başlık taşır. Etiket ve açıklama metinleri assets/translations/tr.json
 * ve en.json dosyalarından birebir alındı.
 *
 * Buradaki denetimler gerçekten çalışıyor: tema seçimi sitenin temasını da
 * çeviriyor, Arapça metin ve yazı boyutu okuma ekranını değiştiriyor.
 */
export function SettingsScreen({ lang }) {
  const tr = lang === 'tr'

  const theme = useAppStore((s) => s.theme)
  const setTheme = useAppStore((s) => s.setTheme)
  const setLang = useAppStore((s) => s.setLang)

  const showArabic = useDemoStore((s) => s.showArabic)
  const toggleArabic = useDemoStore((s) => s.toggleArabic)
  const fontSize = useDemoStore((s) => s.translationFontSize)
  const setFontSize = useDemoStore((s) => s.setFontSize)
  const sortByRevelation = useDemoStore((s) => s.sortByRevelation)
  const toggleSort = useDemoStore((s) => s.toggleSort)

  return (
    <div className="screen">
      <h3 className="screen__title">{tr ? 'Ayarlar' : 'Settings'}</h3>
      <div style={{ height: 'var(--lg)' }} />

      <Section title={tr ? 'GÖRÜNÜM' : 'APPEARANCE'}>
        {/* Tema üç seçenekli: Açık / Koyu / Sistem. */}
        <div style={{ padding: 'var(--sm) var(--md)' }}>
          <div className="segmented" style={{ marginTop: 0 }}>
            {[
              ['light', tr ? 'Açık' : 'Light'],
              ['dark', tr ? 'Koyu' : 'Dark'],
              ['system', tr ? 'Sistem' : 'System'],
            ].map(([id, label]) => (
              <button
                key={id}
                type="button"
                className={`segmented__item${theme === id ? ' segmented__item--active' : ''}`}
                onClick={() => setTheme(id === 'system' ? 'light' : id)}
              >
                {label}
              </button>
            ))}
          </div>
        </div>
      </Section>

      <Section title={tr ? 'DİL' : 'LANGUAGE'}>
        <LinkRow
          label={tr ? 'Uygulama dili' : 'App language'}
          value={tr ? 'Türkçe' : 'English'}
          onClick={() => setLang(tr ? 'en' : 'tr')}
        />
      </Section>

      <Section title={tr ? 'OKUMA' : 'READING'}>
        <SwitchRow
          label={tr ? 'Arapça metin' : 'Arabic text'}
          hint={
            tr ? 'Mealin üstünde orijinal metni göster' : 'Show the original above the translation'
          }
          on={showArabic}
          onToggle={toggleArabic}
        />
        <SwitchRow
          label={tr ? 'İniş sırasına göre dizi' : 'Sort by revelation order'}
          hint={tr ? 'Kapalıyken mushaf sırası kullanılır' : 'When off, the Mushaf order is used'}
          on={sortByRevelation}
          onToggle={toggleSort}
        />

        <div className="settings-slider">
          <div className="settings-slider__head">
            <span className="settings-slider__label">
              {tr ? 'Yazı boyutu' : 'Text size'}
            </span>
            <span className="settings-slider__value">{fontSize}</span>
          </div>
          <input
            className="slider"
            type="range"
            min="14"
            max="22"
            step="1"
            value={fontSize}
            onChange={(e) => setFontSize(Number(e.target.value))}
            aria-label={tr ? 'Yazı boyutu' : 'Text size'}
          />
        </div>

        {/* Ayarın etkisi anında görünsün diye canlı örnek. */}
        <div className="settings-preview">
          <div className="settings-preview__label">{tr ? 'ÖRNEK' : 'PREVIEW'}</div>
          <p className="settings-preview__text" style={{ fontSize, lineHeight: 1.6 }}>
            {tr
              ? 'Rabbimiz! Bize dünyada da iyilik ver, ahirette de iyilik ver ve bizi ateş azabından koru'
              : 'Our Lord, give us good in this world and good in the Hereafter, and protect us from the torment of the Fire'}
          </p>
        </div>
      </Section>

      <Section title={tr ? 'GÜNÜN AYETİ' : 'VERSE OF THE DAY'}>
        <SwitchRow
          label={tr ? 'Bildirim' : 'Notification'}
          hint={tr ? 'Her gün bir ayet hatırlatması' : 'A verse reminder each day'}
          on
        />
        <LinkRow label={tr ? 'Bildirim saati' : 'Reminder time'} value="08:30" />
      </Section>

      <Section title={tr ? 'DİNLE' : 'AUDIO'}>
        <LinkRow label={tr ? 'Kâri' : 'Reciter'} value="Alafasy" />
      </Section>

      <Section title={tr ? 'YASAL' : 'LEGAL'}>
        <LinkRow label={tr ? 'Gizlilik Politikası' : 'Privacy Policy'} />
        <LinkRow label={tr ? 'Kullanım Şartları' : 'Terms of Use'} />
        <LinkRow label={tr ? 'Kaynaklar ve Telif' : 'Sources and Credits'} />
        <LinkRow label={tr ? 'Sürüm' : 'Version'} value="1.0.0" />
      </Section>
    </div>
  )
}

/** Başlıklı ayar grubu. */
function Section({ title, children }) {
  return (
    <div className="settings-section">
      <div className="settings-section__title">{title}</div>
      <div className="settings-group">{children}</div>
    </div>
  )
}

function SwitchRow({ label, hint, on, onToggle }) {
  return (
    <button type="button" className="settings-row" onClick={onToggle} aria-pressed={on}>
      <span className="settings-row__label">
        {label}
        {hint && <span className="settings-row__hint">{hint}</span>}
      </span>
      <span className={`switch${on ? ' switch--on' : ''}`}>
        <i />
      </span>
    </button>
  )
}

function LinkRow({ label, value, onClick }) {
  return (
    <button type="button" className="settings-row" onClick={onClick}>
      <span className="settings-row__label">{label}</span>
      {value && <span className="settings-row__value">{value}</span>}
      <IconChevron size={16} style={{ color: 'var(--ink-faint)', flex: 'none' }} />
    </button>
  )
}
