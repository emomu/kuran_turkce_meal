import { PhoneFrame } from './PhoneFrame'
import { ReadScreen } from './screens/ReadScreen'
import { ReaderScreen } from './screens/ReaderScreen'
import { SearchScreen } from './screens/SearchScreen'
import { PlansScreen } from './screens/PlansScreen'
import { SavedScreen } from './screens/SavedScreen'
import { SettingsScreen } from './screens/SettingsScreen'
import { useDemoStore } from '../store/useDemoStore'

/**
 * Telefonun içinde hangi ekranın çizileceğine karar verir.
 *
 * Okuma ekranı bir sekme değil, "Oku" sekmesinin üstüne itilen bir rota;
 * bu yüzden `openSurah` sekme kontrolünden önce bakılıyor — uygulamadaki
 * go_router yığınının aynısı.
 */
export function AppDemo({ lang }) {
  const tab = useDemoStore((s) => s.tab)
  const openSurah = useDemoStore((s) => s.openSurah)

  return (
    <PhoneFrame lang={lang}>
      {openSurah ? <ReaderScreen lang={lang} /> : <Tab tab={tab} lang={lang} />}
    </PhoneFrame>
  )
}

function Tab({ tab, lang }) {
  switch (tab) {
    case 'search':
      return <SearchScreen lang={lang} />
    case 'plans':
      return <PlansScreen lang={lang} />
    case 'saved':
      return <SavedScreen lang={lang} />
    case 'settings':
      return <SettingsScreen lang={lang} />
    default:
      return <ReadScreen lang={lang} />
  }
}
