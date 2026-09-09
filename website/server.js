import express from 'express'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import { existsSync } from 'node:fs'

/**
 * Üretim sunucusu.
 *
 * Site tamamen statik; bu sunucu yalnızca `dist/` klasörünü servis eder.
 * Railway kendi portunu `PORT` ile verir ve konteynerin dışarıdan
 * erişilebilmesi için 0.0.0.0'a bağlanmak gerekir — localhost'a
 * bağlanan bir sunucu platformun sağlık kontrolünden geçemez.
 */
const __dirname = dirname(fileURLToPath(import.meta.url))
const dist = join(__dirname, 'dist')

if (!existsSync(dist)) {
  console.error('dist/ bulunamadı — önce `npm run build` çalıştırın.')
  process.exit(1)
}

const app = express()
const port = process.env.PORT || 3000

app.disable('x-powered-by')

// Vite çıktısındaki dosya adları içerik özetini taşır (index-a1b2c3.js);
// bu yüzden uzun süre önbelleklenebilirler. index.html hariç: onun her
// istekte tazelenmesi gerekir, aksi halde yeni dağıtım eski varlıkları
// işaret eden bir HTML'e takılı kalır.
app.use(
  express.static(dist, {
    maxAge: '1y',
    index: false,
    setHeaders(res, path) {
      if (path.endsWith('.html')) {
        res.setHeader('Cache-Control', 'no-cache')
      }
    },
  }),
)

// Tek sayfalık uygulama: bilinen bir dosyaya denk gelmeyen her yol
// index.html'e düşer. Başlık burada da açıkça verilir — bu yanıt
// statik middleware'den geçmiyor, onun setHeaders'ı çalışmaz.
app.get(/.*/, (_req, res) => {
  res.setHeader('Cache-Control', 'no-cache')
  res.sendFile(join(dist, 'index.html'))
})

app.listen(port, '0.0.0.0', () => {
  console.log(`Sunucu ${port} portunda dinliyor`)
})
