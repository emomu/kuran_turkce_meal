import { create } from 'zustand'

/**
 * Sitedeki telefon mockup'ının durumu.
 *
 * Mockup statik bir resim değil; ziyaretçi sekmelere basıp uygulamayı
 * gerçekten gezebiliyor. Bu yüzden mockup'ın kendi durumu var ve bu durum
 * tercihlerden (tema/dil) ayrı tutuldu: kalıcı değil, sayfa yenilenince
 * baştan başlaması doğru davranış.
 *
 * Uygulamadaki karşılıkları:
 *  - tab            → go_router sekmeli kabuk (Oku / Ara / Planlar / Kayıtlar / Ayarlar)
 *  - sortByRevelation → preferencesProvider.sortByRevelation
 *  - openSurah      → /sure/:number rotası
 *  - showArabic, translationFontSize → ReaderPreferences
 */
export const useDemoStore = create((set, get) => ({
  tab: 'read',
  sortByRevelation: true,
  openSurah: null,
  query: '',
  showArabic: true,
  translationFontSize: 17,
  activeRoot: null,

  setTab: (tab) => set({ tab, openSurah: null }),
  toggleSort: () => set({ sortByRevelation: !get().sortByRevelation }),
  openReader: (surahNumber) => set({ openSurah: surahNumber }),
  closeReader: () => set({ openSurah: null }),
  setQuery: (query) => set({ query }),
  toggleArabic: () => set({ showArabic: !get().showArabic }),
  setFontSize: (translationFontSize) => set({ translationFontSize }),
  setActiveRoot: (activeRoot) => set({ activeRoot }),

  reset: () =>
    set({
      tab: 'read',
      openSurah: null,
      query: '',
      activeRoot: null,
    }),
}))
