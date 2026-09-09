import { IconSwap, IconRoot, IconSearch, IconCalendar, IconAudio, IconNote } from './Icons'

/**
 * Özellik kartlarındaki ikonu ada göre seçer.
 *
 * Icons.jsx'ten ayrı bir dosyada: bileşen dosyaları yalnızca bileşen
 * dışa aktardığında hızlı yenileme (fast refresh) çalışıyor.
 */
export const featureIcons = {
  order: IconSwap,
  root: IconRoot,
  search: IconSearch,
  plan: IconCalendar,
  audio: IconAudio,
  note: IconNote,
}
