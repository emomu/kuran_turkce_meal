import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'

/**
 * Uygulama genelindeki kalıcı tercihler: tema ve dil.
 *
 * Tema ve dil ayrı store'lara bölünmedi çünkü ikisi de aynı yerden
 * (üst çubuktaki iki düğme) değişiyor ve ikisi de localStorage'a yazılıyor;
 * tek bir persist yapılandırması yeterli.
 *
 * Tema `<html data-theme>` üzerinden uygulanır — CSS değişkenleri orada
 * tanımlı olduğu için React ağacının yeniden çizilmesini beklemeden
 * tüm sayfa aynı anda geçiş yapar.
 */
export const useAppStore = create(
  persist(
    (set, get) => ({
      theme: 'light',
      lang: 'tr',

      setTheme: (theme) => set({ theme }),
      toggleTheme: () => set({ theme: get().theme === 'dark' ? 'light' : 'dark' }),

      setLang: (lang) => set({ lang }),
      toggleLang: () => set({ lang: get().lang === 'tr' ? 'en' : 'tr' }),
    }),
    {
      name: 'kuran-meal-site',
      storage: createJSONStorage(() => localStorage),
    },
  ),
)

/**
 * İlk boyamada doğru temayı yakalamak için seçiciler.
 * Bileşenler tüm store yerine yalnızca ihtiyaç duydukları alanı izler;
 * dil değişimi tema izleyen bileşenleri yeniden çizmesin.
 */
export const useTheme = () => useAppStore((s) => s.theme)
export const useLang = () => useAppStore((s) => s.lang)
