import logo from '/logo.png'

/**
 * Uygulama logosu.
 *
 * Uygulamanın kendi ikon dosyası kullanılıyor (1024×1024 kaynaktan
 * 512'ye indirildi) — yeniden çizilmiş bir vektör yerine gerçek varlık,
 * sitede ve mağaza sayfasında aynı işaret görünsün diye.
 *
 * Logo koyu zeminli ve kendi köşe yuvarlaklığını taşıyor; bu yüzden
 * ek bir çerçeve ya da renk uygulanmıyor.
 */
export function Logo({ size = 32, className = '' }) {
  return (
    <img
      src={logo}
      width={size}
      height={size}
      className={className}
      alt=""
      /* Metnin yanındaki dekoratif işaret: adı zaten yazı olarak var,
         ekran okuyucuya iki kez okutmanın anlamı yok. */
      aria-hidden="true"
      style={{ display: 'block', borderRadius: size * 0.22 }}
    />
  )
}
