# Kur'an — Türkçe Meal

**Kur'an'ı iniş sırasına göre okumak için tasarlanmış, tamamen çevrimdışı bir Flutter uygulaması.**

Giriş yok. Hesap yok. Reklam yok. Analitik yok. Sunucu yok.
Uygulama açılır ve okumaya başlanır.

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Lisans](https://img.shields.io/badge/Lisans-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey.svg)](#)
[![Testler](https://img.shields.io/badge/testler-322%20geçiyor-brightgreen.svg)](#geliştirme)

---

## Açık kaynak

Bu proje **açık kaynaktır** ve [MIT Lisansı](LICENSE) ile dağıtılır. Kodu
okuyabilir, çatallayabilir, değiştirebilir ve kendi uygulamanızı
üretebilirsiniz.

Açık kaynak olması bilinçli bir tercih. Bir Kur'an uygulamasının kullanıcıdan
ne topladığı, verisini nereye gönderdiği ve metni nasıl sunduğu güven
gerektiren konular. Bu soruların cevabı iddia edilecek değil, **okunabilecek**
bir şey olmalı: veri toplanmadığını söylemek yerine, toplanmadığını
gösterebilmek daha sağlam bir taahhüt.

Katkılar açıktır — bkz. [Katkıda bulunma](#katkıda-bulunma).

> **Not:** Kod MIT ile lisanslıdır; **meal ve tefsir metinleri kapsam
> dışıdır**. Depo bu metinleri içermez ve içeremez. Ayrıntı için
> [Telif](#telif--okumadan-meal-eklemeyin) bölümünü mutlaka okuyun.

---

## Neden bu uygulama?

Mevcut Kur'an uygulamalarının çoğu hesap ister, reklam gösterir, arka planda
veri toplar ya da açılmak için internet bekler. Bu uygulama bunların hiçbirini
yapmaz.

Bir de okuma sırası meselesi var. Mushaf sırası kabaca uzunluğa göredir;
metnin hangi sırayla geldiğini göstermez. **İniş sırasına göre okumak**,
sürecin nasıl ilerlediğini takip etmeyi kolaylaştırır — kısa ve yoğun Mekke
sureleriyle başlayıp, giderek uzayan Medine surelerine doğru. Uygulama
varsayılan olarak bu sırayı sunar, ama tek dokunuşla mushaf sırasına
dönebilirsiniz.

---

## Özellikler

### Okuma

- **İniş sırası** — Sureler indikleri sıraya dizilir (Alak, Kalem, Müzzemmil…).
  Ayarlardan mushaf sırasına geçilebilir; her sure kartında iki numara da görünür.
- **Ayet etkileşimleri** — Ayete uzun basınca beş renkle vurgulama, yer imi,
  serbest metin notu, paylaşma ve kopyalama.
- **Tefsir** — Ayete dokununca açılır ya da ayarlardan sürekli görünür yapılır.
- **Arapça metin** — İsteğe bağlı, varsayılan kapalı.
- **Okuma ayarları** — Punto ve satır aralığı, okurken canlı değişir.

### Keşif

- **Tam metin arama** — SQLite FTS5 üzerinde 6.236 ayet içinde anında.
  Türkçe'ye özgü karakter farklarını gözetir: `IŞIK` araması `ışık`'ı,
  `adalet` araması `adâlet`'i bulur.
- **Kök analizi** — Bir kelimeye dokunun, Arapça kökünü ve o kökün Kur'an'da
  geçtiği bütün ayetleri görün. Aynı kökten türeyen kelimelerin farklı
  bağlamlarda nasıl anlam kazandığını izleyebilirsiniz.

### Takip

- **Okuma planları** — Dört hazır plan (kronolojik 365/180 gün, mushaf 30/90
  gün), gün gün ilerleme takibi.
- **Günün ayeti** — Tarihten türetilen sabit bir tohumla seçilir; gün içinde
  değişmez, ertesi gün yenilenir.
- **Günlük hatırlatma** — İsteğe bağlı bildirim, tamamen cihazda planlanır.
  Push altyapısı, sunucu ya da ağ erişimi kullanılmaz.
- **Ana ekran araçları** — iOS ve Android için üç araç: günün ayeti, kaldığın
  yer, okuma serisi. Flutter motorunu çalıştırmadan, paylaşılan veri deposunu
  okuyarak anında görünürler.

### Destek

- **Gönüllü bağış** — Ayarların en üstündeki "Destek ol" girişi ve bağış
  sayfası. Bağış karşılığında hiçbir özellik açılmaz; uygulamanın tamamı
  bağıştan bağımsız olarak ücretsizdir. Ödeme uygulamanın dışında,
  tarayıcıda tamamlanır — uygulama hiçbir ödeme bilgisi görmez.
- **Sessiz hatırlatma** — Uygulama 14 gün ve 20 açılış eşiğini geçtikten
  sonra ana ekranda kapatılabilir bir kart çıkar. Kapatılırsa 30, ertelenirse
  60 gün susar; "destekledim" denirse bir daha hiç çıkmaz.
- **Basamaklı bildirim** — Kurulumdan sonraki 1, 3, 7, 10, 14, 21, 30, 60,
  120 ve 240. günlerde birer kez düşer, sonra tamamen durur. Yalnızca günün
  ayeti bildirimi açıksa planlanır ve ayrı bir bildirim kanalında durur —
  kullanıcı yalnızca bunu kapatabilir.

### Arayüz

- **Açık / koyu tema** — Sistem tercihine uyar ya da elle seçilir.
- **İki dil** — Türkçe ve İngilizce arayüz.
- **Erişilebilirlik** — Kontrastlar WCAG AA (4.5:1) üzerinde, testlerle
  doğrulanır. Dokunma hedefleri en az 44pt.

---

## Gizlilik

Bu bölüm bir vaat değil, kodun doğrulanabilir bir özeti:

| | |
|---|---|
| Toplanan veri | **Hiç** |
| Ağ istekleri | **Yok** — uygulama internet izni bile kullanmaz |
| Analitik / çökme raporu SDK'sı | **Yok** |
| Reklam ağı | **Yok** |
| Hesap / giriş | **Yok** |
| Verinin bulunduğu yer | Yalnızca cihaz — SQLite ve SharedPreferences |

Notlarınız, yer imleriniz, vurgularınız ve okuma ilerlemeniz cihazınızdan
çıkmaz. Uygulamayı silerseniz veriler de silinir; başka hiçbir yerde kopyası
yoktur.

---

## Kurulum

**Gereksinimler:** Flutter 3.41+ · Dart 3.11+ · iOS 14+ / Android 7.0 (API 24)+

```bash
git clone https://github.com/<kullanici>/kuran_turkce_meal.git
cd kuran_turkce_meal
flutter pub get
```

### Meal verisini yükleme

Uygulama meal metnini **içermez** ([sebebi](#telif--okumadan-meal-eklemeyin)).
Elinizdeki meal dosyasını içe aktarma aracıyla dönüştürün:

```bash
dart run tool/import_meal.dart --meal <meal.json> \
                               [--arapca <arapca.json>] \
                               [--tefsir <tefsir.json>]
```

Kabul edilen girdi biçimi:

```json
{"quran": [{"chapter": 1, "verse": 1, "text": "..."}]}
```

Doğrudan aynı yapıdaki bir dizi de olur. Araç 114 sure / 6.236 ayet
bütünlüğünü doğrular; eksik ayet varsa hata verip durur.

Üretilen `assets/data/ayahs.json` sürüm kontrolüne dahil **edilmez**.

### Çalıştırma

```bash
flutter run
```

Veritabanı ilk açılışta asset'lerden oluşturulur. Meal verisini
değiştirdiğinizde uygulamayı cihazdan silip yeniden kurun.

---

## Telif — okumadan meal eklemeyin

**Kur'an'ın Arapça metni** telif konusu değildir, serbestçe kullanılabilir.

**Meal ve tefsir metinleri** ayrı bir eser sayılır ve telif korumasına
tabidir. Bir metnin GitHub'da veya herhangi bir sitede bulunuyor olması,
onu yayınlama hakkı vermez.

| Meal | Durum |
|---|---|
| Elmalılı Hamdi Yazır — **orijinal** 1935 metni | Kamu malı (vefat 1942) |
| Elmalılı — sadeleştirilmiş sürümler | Sadeleştirenin telifi altında |
| Ömer Nasuhi Bilmen | 2041'e kadar korumalı |
| Hasan Basri Çantay | 2034'e kadar korumalı |
| Diyanet İşleri, Esed, İslamoğlu, Öztürk, Bayraklı ve diğer çağdaş mealler | Yazılı izin gerekir |

Dikkat: internette "Elmalılı" adıyla dolaşan dosyaların çoğu
**sadeleştirilmiştir** ve kamu malı değildir. Kamu malı olan, 1930'ların
özgün dilindeki metindir.

Diyanet meali için Diyanet İşleri Başkanlığı'na başvurup yazılı izin
isteyebilirsiniz; ücretsiz ve eğitim amaçlı uygulamalara izin verildiği olur.

---

## Mimari

```
lib/
├── core/
│   ├── theme/            Renk paleti, tipografi, tema tanımları
│   ├── router/           go_router yapılandırması, sekme kabuğu
│   ├── providers/        Paylaşılan Riverpod sağlayıcıları
│   ├── notifications/    Günlük hatırlatma (yerel, cihazda planlanır)
│   └── widgets_bridge/   Ana ekran araçlarıyla veri köprüsü
├── data/
│   ├── models/           Surah, Ayah, AyahMark, ReadingPlan, tercihler
│   ├── db/               SQLite şeması, Türkçe arama normalleştiricisi
│   └── repositories/     Sorgu katmanı
├── features/
│   ├── splash/           Açılış animasyonu
│   ├── onboarding/       İlk kullanım tanıtımı
│   ├── home/             Sure listesi, günün ayeti, kaldığın yer
│   ├── reader/           Okuma akışı, ayet eylemleri, tefsir
│   ├── search/           FTS5 araması, vurgulu sonuçlar
│   ├── roots/            Kök analizi ve kök arama
│   ├── plans/            Okuma planları ve gün takibi
│   ├── bookmarks/        Yer imleri, notlar, vurgular
│   ├── legal/            Gizlilik politikası ve kullanım şartları
│   ├── donate/           Gönüllü bağış ve hatırlatma
│   └── settings/         Tercihler
└── shared/widgets/       Ortak bileşenler

ios/KuranWidgets/         WidgetKit araçları (Swift)
android/…/widgets/        App Widget sağlayıcıları (Kotlin)
tool/                     İçe aktarma ve üretim araçları
```

**Veri akışı** — Meal `assets/data/`'dan ilk açılışta SQLite'a aktarılır.
Arama FTS5 sanal tablosu üzerinden çalışır. Kullanıcının yer imleri, notları,
vurguları ve okuma ilerlemesi aynı veritabanında, tercihleri
SharedPreferences'ta tutulur. Hiçbir veri cihaz dışına çıkmaz.

**Durum yönetimi** — Riverpod. Navigasyon go_router; beş sekme ayrı gezinme
yığını tutar, okuma ekranı sekme çubuğunun dışında tam ekran açılır.

**Ana ekran araçları** — Uygulama ve araçlar belleği paylaşmaz. Aralarındaki
tek köprü, iOS'ta App Group üzerinden paylaşılan `UserDefaults`, Android'de
ortak bir veri deposudur. Araçlar Flutter motorunu çalıştırmaz; içerik günde
bir kez, gün dönümünde kurulan alarmla tazelenir.

---

## Geliştirme

```bash
flutter test        # 322 test
flutter analyze     # statik analiz
```

Kod değişikliği sonrası ikisinin de temiz geçmesi beklenir.

`tool/screens_preview.dart` ekranları simülatörde hızlıca gezmek için bir
yardımcıdır; uygulamanın parçası değildir.

---

## Katkıda bulunma

Katkılar memnuniyetle karşılanır.

1. Depoyu çatallayın ve bir dal açın (`git checkout -b ozellik/aciklama`)
2. Değişikliğinizi yapın, testlerinizi ekleyin
3. `flutter test` ve `flutter analyze` temiz geçsin
4. Pull request açın, neyi neden değiştirdiğinizi anlatın

**Öncelikli alanlar:** erişilebilirlik iyileştirmeleri, çeviri düzeltmeleri,
performans, yeni okuma planları.

**Kabul edilmeyen:** telifli meal veya tefsir metni içeren katkılar; analitik,
reklam ya da ağ isteği ekleyen değişiklikler. Uygulamanın çevrimdışı ve
veri toplamayan yapısı tartışmaya kapalı bir tasarım kararıdır.

Büyük bir değişiklik düşünüyorsanız, önce bir issue açıp tartışmak zaman
kazandırır.

---

## Yayın

Mağaza formlarına girilecek metinler, gizlilik formu cevapları ve ekran
görüntüsü listesi için [`store/STORE_LISTING.md`](store/STORE_LISTING.md).

| | |
|---|---|
| Uygulama adı | Kur'an Meal |
| Bundle / Application ID | `com.emirhansoylu.kuranmeal` |
| Sürüm | `pubspec.yaml` içindeki `version:` alanı |

### Android imzalama

Yayın yapısı kendi anahtarınızla imzalanır; hata ayıklama anahtarıyla
imzalanmış paketleri Play Store kabul etmez.

```bash
keytool -genkey -v -keystore ~/kuranmeal-release.jks \
        -keyalg RSA -keysize 2048 -validity 10000 -alias kuranmeal

cp android/key.properties.example android/key.properties
# dosyayı kendi değerlerinizle doldurun
```

`android/key.properties` ve `.jks` dosyaları `.gitignore` içindedir ve asla
depoya girmemelidir. **Anahtarı kaybetmeyin** — yüklenen bir uygulamanın
sonraki güncellemeleri aynı anahtarla imzalanmak zorundadır.

### Yapı üretme

```bash
flutter build appbundle --release   # Play Store (.aab)
flutter build ipa --release         # App Store (.ipa)
```

iOS tarafında ana uygulama ve araç uzantısı **aynı App Group'a** üye olmalıdır
(`group.com.emirhansoylu.kuranmeal`), yoksa araçlar boş görünür.

### Gizlilik politikası

Politika ve şartlar metni uygulamanın içinde (Ayarlar → Yasal) bulunur.
Mağaza formları ayrıca herkese açık bir URL ister; sayfalar aynı kaynaktan
üretilir:

```bash
dart run tool/build_privacy_html.dart   # store/*.html
```

Üretilen dosyaları GitHub Pages, Netlify ya da benzeri bir yere koyup URL'yi
mağaza formuna girin. Metin değişirse aracı yeniden çalıştırın.

---

## Tasarım notları

- **Renk** — Saf siyah/beyaz yerine sıcak kırık tonlar; uzun okumada göz
  yormaz. Vurgu rengi düşük doygunluklu, arayüz metnin önüne geçmez.
- **Tipografi** — Ayet metni serif (Source Serif 4), arayüz sans (Inter).
  Serif uzun okumada satır takibini kolaylaştırır.
- **Hareket** — Kısa ve amaçlı. Material dalga efekti yerine dokunuşta hafif
  ölçek küçülmesi; iOS'ta daha doğal durur.

---

## Lisans

Kod [MIT Lisansı](LICENSE) ile dağıtılır.

Meal ve tefsir metinleri bu lisansın **kapsamı dışındadır** ve depoda yer
almaz; kendi metninizi eklerken ilgili eserin telif durumundan siz
sorumlusunuz.
