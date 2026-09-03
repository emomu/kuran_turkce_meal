# Planlar bölümü — geliştirme promptları

Her bölüm ayrı bir oturuma verilecek bağımsız bir prompttur. Sıra önemlidir:
**2 → 1 → 3 → 4 → 5**. (Gerekçe en altta.)

Promptu olduğu gibi kopyalayıp yapıştırın.

---

## Ortak bağlam (her promptun başına ekleyin)

```
Bu bir Flutter projesi: Kur'an-ı Kerim Türkçe meali, tamamen çevrimdışı.
Riverpod (StateNotifier), go_router, sqflite, easy_localization kullanıyor.

Uyman gereken kurallar:
- Yorumlar ve kullanıcıya görünen metinler TÜRKÇE.
- Kullanıcı metni asla koda gömülmez; assets/translations/tr.json ve en.json
  içine anahtar eklenir, `'anahtar'.tr()` ile okunur. İKİ dosyayı da güncelle.
- Yorumlar "ne" değil "neden" anlatır. Mevcut dosyalardaki yorum yoğunluğunu
  ve üslubunu taklit et — bu projede bir kararın gerekçesi ve denenip
  elenen alternatif yazılır.
- Renk/boşluk/yarıçap sabittir: lib/core/theme/ altındaki AppColors, Insets,
  Radii, Motion, AppTypography kullanılır. Sabit sayı yazma.
- Açık ve koyu tema ikisi de çalışmalı.
- İş bitince `flutter analyze` temiz olmalı ve `flutter test` tamamen
  geçmeli (şu an 255 test geçiyor, hiçbirini kırma).
- Yaptığın her davranış için test yaz. Testin gerçekten işe yaradığını
  kanıtla: düzeltmeyi geçici geri alıp testin KIRMIZI olduğunu gör, sonra
  geri koyup YEŞİL olduğunu gör. Bu adımı atlama.
- Emin olmadığın bir davranışı tahmin etme, ölç (küçük bir geçici test yazıp
  değeri yazdır, sonra sil).
```

---

## PROMPT 2 — Plan başlangıç tarihi ve "bugün kaçıncı gün"

```
Okuma planlarına takvim bağı ekle.

BUGÜNKÜ DURUM
lib/data/models/reading_plan.dart içinde ReadingPlan (id, titleKey,
descriptionKey, dayCount, order) ve PlanDay (index, ayahIds, label,
isCompleted) var. Planın günleri sadece sıra numarası; gerçek takvimle
hiçbir bağı yok. Kullanıcı "kaçıncı gündeyim, geride miyim" göremiyor.

YAPILACAK
1. Plan başlangıç tarihini sakla. Kullanıcı bir plana ilk kez gün
   tamamladığında ya da planı açıkça başlattığında tarih kaydedilsin.
   Saklama yeri: lib/data/repositories/progress_repository.dart içine
   planStartDate(planId) / setPlanStartDate(planId, date) ekle.
   ÖNEMLİ: plan_progress tablosu (plan_id, day_index, completed_at) plan
   BAŞINA tek satır değil, GÜN başına satır tutuyor. Başlangıç tarihi için
   ayrı bir tablo ya da SharedPreferences kullan; hangisini seçtiğini
   yorumda gerekçelendir.
2. "Bugün planın kaçıncı günü" hesabını yap. Takvim günü farkı kullan,
   çıplak saat farkı DEĞİL: kullanıcı 23:59'da başlayıp 00:01'de baksa
   2. günde olmalı. Saat dilimi ve yaz saati sınır durumlarını düşün.
3. Plan detay ekranında (lib/features/plans/view/plan_detail_screen.dart)
   göster: "Bugün 42. gün" ve gerideyse "3 gün geridesiniz".
   Öndeyse suçlayıcı bir dil kurma; öndelik ayrıca vurgulanmasın.
4. "Bugünden devam et" eylemi ekle: başlangıç tarihini bugüne göre yeniden
   hesaplar, böylece biriken borç sıfırlanır. Tamamlanan günler SİLİNMEZ.
   Bu, plan bırakmanın en yaygın sebebine (biriken borç hissi) karşı
   konuyor — yorumda bunu yaz.

DİKKAT
- Plan hiç başlatılmadıysa takvim bilgisi gösterilmesin; kart eskisi gibi
  görünsün.
- Tarih hesabını saf bir fonksiyona ayır ki testten doğrudan çağrılabilsin.

TEST
- Gün hesabı: aynı gün, ertesi gün, gece yarısını geçen sınır, 100. gün.
- Geride/ilerideyken doğru metin.
- "Bugünden devam et" sonrası tamamlanan günlerin korunduğu.
```

---

## PROMPT 1 — Seri (streak) ve aylık takvim görünümü

```
Okuma planlarına seri takibi ve aylık takvim görünümü ekle.

BUGÜNKÜ DURUM — ÖNEMLİ
plan_progress tablosunda `completed_at` sütunu ZATEN VAR
(lib/data/db/app_database.dart, CREATE TABLE plan_progress) ve
markDayComplete onu DateTime.now().millisecondsSinceEpoch olarak yazıyor.
Ama hiç okunmuyor: completedDays(planId) sadece day_index döndürüyor.
YANİ ŞEMA DEĞİŞİKLİĞİ GEREKMİYOR. Migration yazma.
(app_database.dart'ta onUpgrade içerik tablolarını silip yeniden kuruyor,
kullanıcı verisi korunuyor — oraya dokunma.)

YAPILACAK
1. progress_repository.dart'a completion tarihlerini döndüren bir sorgu
   ekle (day_index + completed_at).
2. Seri hesabı: art arda kaç GÜN okundu. Takvim günü bazlı olmalı —
   aynı gün iki gün tamamlansa seri 1 artar, 2 değil. Bugün henüz
   okunmadıysa seri kırılmış sayılmaz (dün okunduysa seri sürüyor);
   bu kararı yorumda gerekçelendir.
   Saf fonksiyon olarak yaz, testten doğrudan çağrılabilsin.
3. Plan detay ekranında göster: güncel seri ve en uzun seri.
4. Aylık takvim/ısı haritası: hangi günlerde okunduğu. Ay ay gezilebilsin.
   Yoğunluk için tek renk (tema vurgu rengi) üzerinde opaklık kullan;
   yeni renk uydurma.

DİKKAT
- Seri 0 iken cesaret kırıcı bir boşluk gösterme; ilk okumaya davet et.
- Takvim küçük ekranda taşmamalı; hücreler esnesin.
- Ekran okuyucu için her günün semantik etiketi olsun (tarih + okundu mu).

TEST
- Seri: boş, tek gün, art arda 5 gün, arada boşluk, bugün okunmamış ama
  dün okunmuş (seri sürmeli), aynı gün iki tamamlama (seri 1 artmalı).
- En uzun serinin güncel seriden farklı olduğu durum.
- Takvim doğru günleri işaretliyor.
```

---

## PROMPT 3 — Plan hatırlatma bildirimi

```
Okuma planı için günlük hatırlatma bildirimi ekle.

BUGÜNKÜ DURUM VE EN KRİTİK TUZAK
lib/core/notifications/daily_ayah_notifications.dart "günün ayeti"
bildirimini kuruyor. Ama:
  - Tek sabit kimlik var: `static const _notificationId = 1001;`
  - schedule() metodu ilk iş olarak `await cancel();` çağırıyor ve
    cancel() o tek kimliği iptal ediyor.
Yani ŞU AN İKİ BİLDİRİM AYNI ANDA YAŞAYAMAZ. Plan hatırlatmasını olduğu
gibi eklersen günün ayeti bildirimini sessizce iptal eder — kullanıcı
bunu asla fark etmez, sadece bildirimleri kesilir.

Bu yüzden ÖNCE bildirim altyapısını çok bildirimli hale getir:
her bildirim türünün kendi kimliği olsun, cancel() yalnızca kendi
kimliğini iptal etsin. Mevcut günün ayeti davranışı AYNEN korunmalı.

YAPILACAK
1. Altyapıyı çok bildirimli yap (yukarıdaki gerekçeyle, yorumda anlat).
2. Plan hatırlatması kur: kullanıcı saat seçsin, her gün o saatte
   "bugünkü okumanız hazır" bildirimi gelsin.
3. Bildirime dokununca doğrudan O GÜNÜN okumasına gitsin. Rota yönlendirme
   zaten var: notifications.onSelectRoute main.dart'ta appRouter.go'ya
   bağlı, schedule() `payload` alıyor. Plan okuma rotasını payload ver.
4. Ayarı planlar tarafına koy (ayarlar ekranına değil) — plan hatırlatması
   plana ait bir tercih. Nereye koyduğunu gerekçelendir.
5. İzin akışı: açılışta izin İSTEME. Mevcut kod da istemiyor (main.dart'ta
   yorumu var, mağaza incelemelerinde eleştiriliyor). Kullanıcı hatırlatmayı
   açtığında iste; reddedilirse anlaşılır bir mesaj göster ve anahtarı
   kapalı bırak.
6. Plan bittiğinde ya da hatırlatma kapatıldığında bildirimi iptal et.

DİKKAT
- Bildirim gövdesinde o günün aralığı yazsın ("Alak 1 – Kalem 12" gibi);
  PlanDay.label zaten bunu tutuyor.
- Bildirimler masaüstünde desteklenmiyor; kodda `_supported` kontrolü var,
  ona uy.

TEST
- Günün ayeti ve plan hatırlatması AYNI ANDA kurulabiliyor, biri
  diğerini iptal etmiyor. (Bu testi mutlaka yaz — asıl tuzak bu.)
- Hatırlatma kapatılınca yalnızca kendi bildirimi iptal oluyor.
- İzin reddedilince anahtar kapalı kalıyor.
```

---

## PROMPT 4 — Gün içi kısmi ilerleme

```
Plan günlerinde kısmi ilerleme göster.

BUGÜNKÜ DURUM
Bir plan günü ya tamamlanmış ya değil (plan_progress tablosu ikili durum).
30 günlük planda bir gün ~208 ayet; kullanıcı yarıda bırakırsa hiçbir iz
kalmıyor ve ertesi gün nereden devam edeceğini bilmiyor.

ELDEKİ VERİ
progress_repository.dart'ta saveProgress(surahNumber, ayahNumber) ve
allProgress() var — sure başına son okunan ayet zaten tutuluyor.
PlanDay.ayahIds o günün ayet kimliklerini SIRALI tutuyor (aralık değil
liste; iniş sırasında bir gün bitişik olmayan sureleri kapsayabildiği için
böyle — bkz. reading_plan.dart yorumu). Bu ikisinden "günün kaç ayeti
okundu" çıkarılabilir. Yeni tablo gerekmeyebilir; önce mevcut veriyle
çözmeyi dene, yetmezse gerekçesini yaz.

YAPILACAK
1. Gün başına "kaç ayet okundu / toplam" hesapla.
2. Plan detayındaki gün satırında ince bir ilerleme göstergesi ve
   "78/208" gibi sayı göster. Tamamlanan günde gösterge yerine mevcut
   tik ikonu kalsın.
3. Yarım kalan güne dokunulduğunda kalınan ayetten devam etsin,
   günün başından değil.

DİKKAT
- Gösterge gürültü yapmasın: hiç okunmamış günde hiç gösterilmesin.
- İlerleme %100 olduğunda gün otomatik tamamlanmış SAYILMASIN; kullanıcı
  kendi işaretlesin (mevcut davranış korunsun). Otomatik işaretleme,
  metni atlayıp kaydıran kullanıcıda yanlış kayıt üretir — yorumda yaz.

TEST
- Hiç okunmamış, yarısı okunmuş, tamamı okunmuş gün.
- Yarım günde doğru ayetten devam.
- Birleşik meal blokları (bir kayıt birden çok ayet) sayımda bozulmuyor.
```

---

## PROMPT 5 — Esnek plan süresi

```
Kullanıcının kendi plan süresini seçebilmesini sağla.

BUGÜNKÜ DURUM
lib/data/models/reading_plan.dart içinde ReadingPlans.all sabit dört plan
tutuyor (revelation_365, revelation_180, mushaf_30, mushaf_90). Model
zaten dayCount + order alıyor, yani bölme mantığı esnek süreyi kaldırır
(plans_provider.dart'taki _buildDays dayCount'a göre bölüyor).

ASIL KISIT
Plan kimliği sabit String ve plan_progress tablosunun birincil anahtarı
(plan_id, day_index). Kullanıcı planı oluşturup sonra süresini değiştirirse
gün indeksleri kayar ve eski ilerleme yanlış günlere denk gelir.
Bunu çöz: ya süre değişince ilerlemeyi sıfırla (kullanıcıya sor), ya da
kimliği süreyi de içerecek şekilde üret. Seçimini gerekçelendir.

YAPILACAK
1. Kullanıcı gün sayısı girsin (ya da "günde N ayet" verip gün sayısı
   hesaplansın — hangisi daha anlaşılırsa, gerekçelendir).
2. Sıralama seçilsin: iniş sırası / mushaf sırası (PlanOrder zaten var).
3. Oluşturulan plan listede hazır planlarla birlikte görünsün, ama
   ayırt edilebilsin. Silinebilsin.
4. Makul sınır koy (örn. 7–1000 gün) ve sınır dışını anlaşılır biçimde
   reddet. Ramazan için 29/30 gibi yaygın süreleri hazır öner.

DİKKAT
- Hazır dört plan kaldırılmayacak; bunlar çoğu kullanıcının ihtiyacı.
- Kullanıcı planı silinince plan_progress kayıtları da temizlensin.
- ReadingPlans.byId artık kullanıcı planlarını da bulmalı; byId'i çağıran
  her yeri kontrol et (plan_detail_screen, plans_provider, router).

TEST
- Oluşturma, listede görünme, silme (ilerleme de siliniyor).
- Sınır dışı değer reddediliyor.
- Kullanıcı planında gün bölme doğru (toplam ayet sayısı korunuyor).
- Hazır planlar bozulmadı.
```

---

## Sıra neden böyle

- **2 önce**: takvim bağı diğerlerinin temeli. Seri (1) "gün" kavramına,
  hatırlatma (3) "bugünün okuması"na dayanıyor.
- **1 sonra**: `completed_at` zaten yazılıyor, sadece okunacak — ucuz ve
  görünür kazanç.
- **3 orta**: altyapı düzeltmesi gerektiriyor (tek bildirim kimliği), o
  yüzden acele edilmemeli.
- **4 sonra**: 2 ile birlikte anlamlı. Tek başına "gerideyim" hissi
  suçluluk üretir; kısmi ilerleme onu yumuşatır. İkisi eşleşmeli.
- **5 en son**: en çok yeri etkileyen, en az acil olan.
