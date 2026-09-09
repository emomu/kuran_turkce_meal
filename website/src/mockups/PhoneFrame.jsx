import { IconBook, IconSearch, IconCalendar, IconBookmark, IconSettings } from '../components/Icons'
import { useDemoStore } from '../store/useDemoStore'
import { StatusBar } from './StatusBar'

const TABS = [
  { id: 'read', Icon: IconBook, tr: 'Oku', en: 'Read' },
  { id: 'search', Icon: IconSearch, tr: 'Ara', en: 'Search' },
  { id: 'plans', Icon: IconCalendar, tr: 'Planlar', en: 'Plans' },
  { id: 'saved', Icon: IconBookmark, tr: 'Kayıtlar', en: 'Saved' },
  { id: 'settings', Icon: IconSettings, tr: 'Ayarlar', en: 'Settings' },
]

/**
 * Telefon kasası, durum çubuğu ve sekme çubuğu.
 *
 * Ekran içeriği `children` olarak gelir; kasa hangi ekranın çizildiğini
 * bilmez. Sekme çubuğu doğrudan demo store'a yazar — böylece ekranlar
 * arası geçiş prop zincirinden değil tek bir yerden yönetilir.
 */
export function PhoneFrame({ lang, children }) {
  const tab = useDemoStore((s) => s.tab)
  const setTab = useDemoStore((s) => s.setTab)

  return (
    <div className="phone">
      <div className="phone__screen">
        {/* Ada ekranın içinde: konumu ekran kenarına göre ölçülmeli,
            kasanın dolgusu hesaba karışmamalı. */}
        <div className="phone__island" />
        <StatusBar />

        {children}

        <nav className="tabbar" aria-label={lang === 'tr' ? 'Uygulama sekmeleri' : 'App tabs'}>
          {TABS.map(({ id, Icon, tr, en }) => (
            <button
              key={id}
              type="button"
              className={`tabbar__item${tab === id ? ' tabbar__item--active' : ''}`}
              onClick={() => setTab(id)}
              aria-current={tab === id ? 'page' : undefined}
            >
              <Icon size={21} />
              <span>{lang === 'tr' ? tr : en}</span>
            </button>
          ))}
        </nav>
      </div>
    </div>
  )
}
