import { useEffect } from 'react'
import { content } from './data/content'
import { useAppStore } from './store/useAppStore'
import { TopBar } from './sections/TopBar'
import { Hero } from './sections/Hero'
import { Features } from './sections/Features'
import { Screens } from './sections/Screens'
import { Privacy } from './sections/Privacy'
import { Faq } from './sections/Faq'
import { Cta } from './sections/Cta'

export default function App() {
  const theme = useAppStore((s) => s.theme)
  const lang = useAppStore((s) => s.lang)
  const t = content[lang]

  // Tema ve dil DOM'a yazılır: CSS değişkenleri `[data-theme]` üzerinde
  // tanımlı, `lang` niteliği de ekran okuyucular ve tarayıcı tireleme için
  // gerekli.
  useEffect(() => {
    document.documentElement.dataset.theme = theme
    document.documentElement.lang = lang
    document.title =
      lang === 'tr'
        ? "Kur'an Meal — Kur'an'ı indiği sırayla okuyun"
        : 'Qur’an Meal — Read the Qur’an in the order it was revealed'
  }, [theme, lang])

  return (
    <>
      <TopBar t={t} lang={lang} />
      <main>
        <Hero t={t} lang={lang} />
        <Features t={t} />
        <Screens t={t} lang={lang} />
        <Privacy t={t} />
        <Faq t={t} />
        <Cta t={t} lang={lang} />
      </main>
    </>
  )
}
