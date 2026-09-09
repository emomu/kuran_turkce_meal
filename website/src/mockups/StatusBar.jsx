/**
 * Telefon mockup'ının durum çubuğu: saat, sinyal, wifi ve pil.
 *
 * Hem hero'daki telefon hem "Ekranlar" bölümündeki tur aynı çubuğu
 * kullanır. Ayrı ayrı kopyalandığında ikisi birbirinden ayrışıyordu
 * (hero'da wifi ikonu eksik kalmıştı), bu yüzden tek bileşen.
 */
export function StatusBar() {
  return (
    <div className="phone__status">
      <span>9:41</span>
      <span className="phone__status-icons">
        <Signal />
        <Wifi />
        <Battery />
      </span>
    </div>
  )
}

const Signal = () => (
  <svg width="17" height="11" viewBox="0 0 17 11" fill="currentColor" aria-hidden="true">
    <rect x="0" y="7" width="3" height="4" rx="1" />
    <rect x="4.6" y="5" width="3" height="6" rx="1" />
    <rect x="9.2" y="2.7" width="3" height="8.3" rx="1" />
    <rect x="13.8" y="0" width="3" height="11" rx="1" />
  </svg>
)

const Wifi = () => (
  <svg
    width="15"
    height="11"
    viewBox="0 0 15 11"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.5"
    strokeLinecap="round"
    aria-hidden="true"
  >
    <path d="M1 3.6a9.5 9.5 0 0 1 13 0M3.5 6.3a6 6 0 0 1 8 0" />
    <circle cx="7.5" cy="9.3" r="1" fill="currentColor" stroke="none" />
  </svg>
)

const Battery = () => (
  /* viewBox uçtaki kontağı da kapsayacak kadar geniş; daha darken
     kontağın sağ kenarı kırpılıyordu. */
  <svg width="25" height="11" viewBox="0 0 25 11" fill="none" aria-hidden="true">
    <rect x="0.6" y="0.6" width="20" height="9.8" rx="3.2" stroke="currentColor" strokeOpacity=".4" />
    <rect x="2.2" y="2.2" width="15" height="6.6" rx="1.8" fill="currentColor" />
    <path d="M22.4 4.1c1 .3 1 3.5 0 3.8Z" fill="currentColor" fillOpacity=".4" />
  </svg>
)
