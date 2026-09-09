# Kur'an Meal — tanıtım sitesi

`kuran_turkce_meal` Flutter uygulamasının tanıtım sitesi. React + Vite ile
yazıldı; durum yönetimi Zustand.

## Çalıştırma

```bash
npm install
npm run dev      # geliştirme sunucusu
npm run build    # dist/ altına üretim derlemesi
npm run preview  # derlemeyi yerelde sun
```

## Tasarım kaynağı

Site kendi paletini uydurmuyor; değerler doğrudan uygulamadan geliyor:

| Site | Uygulama |
|---|---|
| `src/styles/tokens.css` | `lib/core/theme/app_colors.dart`, `app_typography.dart` |
| `src/components/Logo.jsx` | `android/app/src/main/res/playstore-icon.png` (SVG olarak yeniden çizildi) |
| `src/data/quran.json` | `assets/data/surahs.json`, `assets/data/ayahs.json` (üretildi) |
| `src/data/content.js` | `store/app_store_tr.md`, `store/STORE_LISTING.md` |
| `public/privacy-policy.html`, `public/terms.html` | `store/` altından kopyalandı |

Renk, boşluk ölçeği (`Insets`), köşe yarıçapları (`Radii`) ve hareket
süreleri (`Motion`) uygulamayla birebir aynı. Uygulamanın teması
değişirse `tokens.css` de güncellenmeli.

Mockup'lardaki her ölçü ilgili widget'tan alındı; CSS'te hangi widget'a
karşılık geldiği yorumda yazıyor. Öne çıkan birkaçı:

| Ölçü | Kaynak |
|---|---|
| Ekran gutter'ı 20 | `gutterFor()` → `Insets.screenGutter` |
| Sure listesi ayırıcısı soldan 46 içeriden | `SliverList.separated` → `Divider(indent: 46)` |
| Ayet kutucuğu 8 yatay / 24 dikey (Arapça açık) | `AyahTile` |
| Ayet rozeti min 24×24 hap | `_AyahHeader` |
| Okuma çubuğu 48 yüksek, çizgisiz | `_ReaderAppBar` |
| Ayarlar satırı 16/12, ayırıcı soldan 16 | `_SwitchTile`, `_SettingsSection` |
| Tipografi ölçeği (32/24/20/17/15/13/11) | `AppTypography.textTheme` |

Ekran metinleri de uydurma değil: `assets/translations/tr.json` ve
`en.json` dosyalarındaki gerçek karşılıklar kullanıldı (plan adları,
ayar etiketleri, sekme adları).

## Durum yönetimi

İki ayrı store var; ayrılma nedeni kalıcılık:

- **`src/store/useAppStore.js`** — tema ve dil. `persist` ara katmanıyla
  `localStorage`'a yazılır, ziyaretçi geri geldiğinde tercihi korunur.
  Tema `<html data-theme>` üzerinden uygulanır; `index.html` içindeki küçük
  betik React yüklenmeden önce bunu okur, böylece koyu tema seçen biri ilk
  karede açık zemin görmez.

- **`src/store/useDemoStore.js`** — telefon mockup'ının durumu (etkin sekme,
  açık sure, sıralama, punto, seçili kök). Kalıcı **değil**: sayfa
  yenilendiğinde tur baştan başlamalı.

Bileşenler tüm store'u değil yalnızca ihtiyaç duydukları alanı izler
(`useAppStore((s) => s.theme)`), böylece dil değişimi tema izleyen
bileşenleri yeniden çizmez.

## Ekran mockup'ları

`src/mockups/` altındaki ekranlar ekran görüntüsü değil, HTML/CSS ile
yeniden çizilmiş arayüzler. Bunun üç sonucu var: site temasıyla birlikte
koyu/açık moda geçiyorlar, dil değiştiğinde metinleri çevriliyor ve
ziyaretçi gerçekten tıklayabiliyor (sekme değiştirme, sıralamayı çevirme,
bir sureyi açma, kelimeye basıp kök panelini görme).

Uygulamadaki karşılıkları:

| Mockup | Uygulama |
|---|---|
| `screens/ReadScreen.jsx` | `lib/features/home/view/home_screen.dart` |
| `screens/ReaderScreen.jsx` | `lib/features/reader/`, `lib/features/roots/` |
| `screens/SearchScreen.jsx` | `lib/features/search/` |
| `screens/PlansScreen.jsx` | `lib/features/plans/` |
| `screens/SavedScreen.jsx` | `lib/features/bookmarks/` |
| `screens/SettingsScreen.jsx` | `lib/features/settings/` |
| `PhoneFrame.jsx` (sekme çubuğu) | `lib/core/router/app_shell.dart` |

Hero'daki telefon (`HeroPhone.jsx`) demo store'u paylaşmaz: ziyaretçi
"Ekranlar" bölümüne indiğinde turu baştan görmeli.

## Veriyi yenileme

`src/data/quran.json` uygulamanın asset'lerinden üretildi. Meal güncellenirse
proje kökünden yeniden üretilebilir — sure listesi iniş sırasına göre ilk 14
sure, okuma ekranı için Alak suresinin ilk 8 ayeti ve bir arama sonucu örneği
içerir.

## Yayın

### Railway

Proje Railway'e hazır. Depo Railway'e bağlandığında dikkat edilecek tek
şey **Root Directory**: site depo kökünde değil `website/` altında, bu
yüzden servis ayarlarında root dizini `website` olarak verilmeli. Aksi
halde Railway kökteki Flutter projesini derlemeye çalışır.

| Ayar | Değer |
|---|---|
| Root Directory | `website` |
| Build Command | `npm ci && npm run build` (railway.json'da tanımlı) |
| Start Command | `npm start` (railway.json'da tanımlı) |
| Node | 20+ (`.nvmrc` ve `engines`) |

Ortam değişkeni gerekmez. Railway `PORT`'u kendi atar; `server.js` bu
değişkeni okur ve `0.0.0.0`'a bağlanır — konteynerde `localhost`'a
bağlanan bir sunucu dışarıdan erişilemez.

Yerelde üretim davranışını denemek için:

```bash
npm run build
npm start          # http://localhost:3000
```

`server.js` yalnızca `dist/` klasörünü servis eder. Vite çıktısındaki
dosya adları içerik özeti taşıdığı için bir yıl önbelleklenir;
`index.html` ise `no-cache` ile işaretlenir, yoksa yeni dağıtım
eski varlıkları işaret eden bir HTML'de takılı kalırdı.

### Diğer statik barındırıcılar

`npm run build` sonrası `dist/` klasörü olduğu gibi GitHub Pages,
Netlify ya da Cloudflare Pages'e de yüklenebilir; bu durumda `server.js`
gerekmez. Mağaza formlarının istediği gizlilik politikası URL'i, yayından
sonra `/privacy-policy.html` olur.

## Bağlantılar

Dış adresler `src/data/links.js` içinde toplandı; aynı bağlantı birden
fazla bölümde geçtiği için tek yerden güncellenir.

## Yapılacak

- `links.appStore` ve `links.playStore` şu an `#download`'a gidiyor;
  uygulama yayınlanınca gerçek mağaza URL'leriyle değiştirilmeli.
- `public/og.png` (1200×630 paylaşım görseli) henüz eklenmedi;
  `index.html` içinde referansı hazır.
