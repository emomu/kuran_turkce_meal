# Mağaza Yayın Bilgileri

Bu dosya App Store Connect ve Google Play Console formlarına girilecek
metinleri toplar. Uygulamanın parçası değildir.

---

## Temel bilgiler

| Alan | Değer |
|---|---|
| Uygulama adı (iOS/Android) | Kur'an Meal |
| Bundle ID / Application ID | `com.emirhansoylu.kuranmeal` |
| Sürüm | 1.0.0 (build 1) |
| Birincil dil | Türkçe |
| Ek dil | İngilizce |
| Kategori | Yaşam Tarzı (alternatif: Kitaplar / Referans) |
| Yaş sınırı | 4+ / Herkes |
| Fiyat | Ücretsiz |
| Uygulama içi satın alma | Yok |
| Reklam | Yok |

---

## Kısa açıklama (Play — en fazla 80 karakter)

```
Kur'an'ı iniş sırasına göre okuyun. Tamamen çevrimdışı, reklamsız, hesapsız.
```

## Alt başlık (App Store — en fazla 30 karakter)

```
İniş sırasına göre meal
```

---

## Tam açıklama

```
Kur'an-ı Kerim'i iniş sırasına göre okumak için tasarlanmış, sade ve
tamamen çevrimdışı bir uygulama.

Giriş yok, hesap yok, reklam yok, internet gerekmez. Uygulamayı açın ve
okumaya başlayın.

İNİŞ SIRASI OKUMA
Sureler indikleri sıraya göre dizilir. Ayetleri indikleri sırayla okumak,
metnin nasıl bir süreç içinde geldiğini görmeyi kolaylaştırır. Dilerseniz
tek dokunuşla mushaf sırasına dönebilirsiniz; her sure kartında iki numara
da görünür.

TAM METİN ARAMA
6.236 ayet içinde anında arama. Türkçe'ye özgü karakter farklarını gözetir:
"ISIK" araması "ışık"ı, "adalet" araması "adâlet"i bulur.

KÖK ANALİZİ
Bir kelimeye dokunun, Arapça kökünü ve o kökün Kur'an'da geçtiği bütün
ayetleri görün. Aynı kökten gelen kelimelerin nasıl farklı anlamlar
kazandığını izleyebilirsiniz.

OKUMA PLANLARI
Dört hazır plan: kronolojik 365 ve 180 gün, mushaf sırasıyla 30 ve 90 gün.
İlerlemeniz gün gün takip edilir.

KENDİ NOTLARINIZ
Ayetleri beş renkle vurgulayın, yer imi ekleyin, kendi notlarınızı yazın.
Hepsi yalnızca sizin cihazınızda kalır.

OKUMA İÇİN TASARLANDI
Uzun okumada göz yormayan sıcak renkler, ayet metni için serif yazı yüzü,
açık ve koyu tema, ayarlanabilir punto ve satır aralığı.

GİZLİLİK
Hiçbir veri toplanmaz. Notlarınız, yer imleriniz ve okuma ilerlemeniz
cihazınızdan çıkmaz. Analitik yok, takip yok, sunucu yok.
```

---

## Anahtar kelimeler (App Store — en fazla 100 karakter)

```
kuran,meal,ayet,sure,türkçe,çevrimdışı,iniş sırası,kök,tefsir,okuma planı
```

---

## Gizlilik formu cevapları

### App Store Connect — App Privacy

**"Do you or your third-party partners collect data from this app?"**
→ **No, we do not collect data from this app.**

Uygulama hiçbir veri toplamaz. Tüm kullanıcı verisi (notlar, yer imleri,
ilerleme, tercihler) yalnızca cihazda kalır ve geliştiriciye ulaşmaz.
Analitik SDK'sı, reklam ağı veya çökme raporlama aracı kullanılmaz.

### Google Play — Data safety

| Soru | Cevap |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | Yok sayılır (veri aktarımı yok) |
| Do you provide a way for users to request that their data is deleted? | Veri toplanmadığı için geçerli değil; cihazdaki veriler uygulama içinden ya da uygulama silinerek kaldırılır |

### Gizlilik politikası bağlantısı

Her iki mağaza da erişilebilir bir URL ister. Politika metni uygulamanın
içinde (Ayarlar → Gizlilik Politikası) bulunur; mağaza formu için aynı
metnin `store/privacy-policy.html` dosyasından yayımlanması gerekir.

Ücretsiz barındırma seçenekleri: GitHub Pages, Netlify, Cloudflare Pages.

---

## İçerik derecelendirme notları

- Uygulama dinî bir metin (Kur'an meali) sunar.
- Şiddet, müstehcenlik, kumar, alkol/uyuşturucu içeriği yoktur.
- Kullanıcılar arası iletişim, paylaşım akışı veya kullanıcı üretimi
  içerik paylaşımı yoktur.
- Konum, kamera, mikrofon, rehber erişimi istenmez.
- Tek izin: bildirim (isteğe bağlı günlük hatırlatma).

---

## İnceleme notu (App Review Notes)

```
Uygulama tamamen çevrimdışı çalışır; giriş veya test hesabı gerekmez.

Tüm özellikler ilk açılışta erişilebilirdir. "Günün ayeti" bildirimi
Ayarlar ekranından açılabilir; açıldığında sistem bildirim izni istenir ve
seçilen saatte cihazda yerel bir hatırlatma planlanır. Sunucu ya da push
altyapısı kullanılmaz.

Kullanıcı verisi toplanmaz. Notlar, yer imleri ve okuma ilerlemesi yalnızca
cihazdaki yerel veritabanında tutulur.
```

---

## Ekran görüntüsü listesi

App Store zorunlu boyutlar:
- 6.9" (1290 × 2796) — iPhone 16 Pro Max
- 6.5" (1242 × 2688) — iPhone 11 Pro Max

Play Store:
- En az 2, en fazla 8 telefon görüntüsü (min. 1080 px kenar)
- Öne çıkan grafik: 1024 × 500

Önerilen ekranlar:
1. Ana ekran — sure listesi ve "günün ayeti"
2. Okuma ekranı — meal ve Arapça metin bir arada
3. Arama sonuçları — vurgulu eşleşmeler
4. Kök analizi — bir kökün geçtiği ayetler
5. Okuma planları
6. Ayarlar — okuma tercihleri ve canlı örnek
