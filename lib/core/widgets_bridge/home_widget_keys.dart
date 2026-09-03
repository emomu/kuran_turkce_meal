/// Ana ekran araçlarının (widget) okuduğu anahtarlar.
///
/// Bu dosya Dart tarafındaki tek doğruluk kaynağıdır; Kotlin ve Swift
/// tarafındaki karşılıkları aynı dizeleri kullanır. Anahtar adı değişirse
/// üç yerde birden değişmeli — bu yüzden hepsi tek yerde toplandı.
///
/// Not: Bu adlar veri deposunda saklandığı için değiştirmek, güncelleme
/// alan kullanıcılarda araçların bir tur boş kalmasına yol açar. Eski
/// anahtarı silmek yerine yenisini eklemek daha güvenli.
abstract final class HomeWidgetKeys {
  /// Android'de araç sağlayıcı sınıflarının adı, iOS'ta widget türünün adı.
  /// `updateWidget` çağrısı bunlarla hangi aracın yenileneceğini söyler.
  static const androidDailyAyahProvider = 'DailyAyahWidgetProvider';
  static const androidContinueProvider = 'ContinueReadingWidgetProvider';
  static const androidStreakProvider = 'StreakWidgetProvider';

  static const iosDailyAyahKind = 'DailyAyahWidget';
  static const iosContinueKind = 'ContinueReadingWidget';
  static const iosStreakKind = 'StreakWidget';

  /// iOS'ta uygulama ile araçların ortak veri alanı. Xcode'da her iki
  /// hedefe de bu grup tanımlanmalı, yoksa araçlar veriyi göremez.
  static const iosAppGroupId = 'group.com.emirhansoylu.kuranmeal';

  // ------------------------------------------------------- Günün ayeti

  /// Ayetin meal metni.
  static const dailyAyahText = 'daily_ayah_text';

  /// "Bakara 255" gibi gösterilecek künye.
  static const dailyAyahReference = 'daily_ayah_reference';

  /// Dokunulduğunda gidilecek uygulama içi yol.
  static const dailyAyahRoute = 'daily_ayah_route';

  /// Verinin hangi güne ait olduğu (gün numarası). Araç, kendi hesapladığı
  /// günle karşılaştırıp verinin bayatladığını anlar.
  static const dailyAyahDayNumber = 'daily_ayah_day';

  /// Yenile düğmesinin dolaşacağı yedek ayetler.
  ///
  /// Araç veritabanına erişemez — kendi sürecinde çalışır ve Flutter motorunu
  /// başlatmaz. Yenile düğmesinin bir işe yaraması için gösterilecek ayetlerin
  /// önceden yazılmış olması gerekir. Uygulama her eşitlemede küçük bir küme
  /// yazar; araç bunlar arasında sırayla döner.
  ///
  /// Kümeyi büyük tutmanın anlamı yok: kullanıcı araçta arka arkaya onlarca
  /// ayet gezmez ve her değer ayrı bir kayıt olarak ortak depoya yazılıyor.
  static const dailyAyahPoolSize = 12;

  /// Havuzdaki [index]. ayetin metni.
  static String dailyAyahPoolText(int index) => 'daily_ayah_pool_${index}_text';

  /// Havuzdaki [index]. ayetin künyesi.
  static String dailyAyahPoolReference(int index) =>
      'daily_ayah_pool_${index}_ref';

  /// Havuzdaki [index]. ayetin yolu.
  static String dailyAyahPoolRoute(int index) =>
      'daily_ayah_pool_${index}_route';

  /// Havuzda kaç ayet yazıldığı. Araç bunun ötesine geçmez.
  static const dailyAyahPoolCount = 'daily_ayah_pool_count';

  // --------------------------------------------------------- Devam et

  static const continueSurahName = 'continue_surah_name';
  static const continueAyahLabel = 'continue_ayah_label';
  static const continueRoute = 'continue_route';

  /// Surenin okunmuş kesri, 0–100 arası tam sayı. Kesirli sayı yerine
  /// tam sayı yazılır; native taraf ilerleme çubuğunu doğrudan bu değerle
  /// çizer, ayrıca ondalık ayracı yerelleştirme sorunu çıkarmaz.
  static const continuePercent = 'continue_percent';

  // ------------------------------------------------------ Plan / seri

  static const streakPlanName = 'streak_plan_name';
  static const streakCurrent = 'streak_current';
  static const streakLongest = 'streak_longest';
  static const streakRoute = 'streak_route';

  /// Bugünün plan görevi tamamlandı mı — araç halkayı buna göre doldurur.
  static const streakTodayDone = 'streak_today_done';

  // ---------------------------------------------------------- Ortak

  /// Araçlarda gösterilecek etiketlerin dili. Uygulama iki dilli, araçlar
  /// ise Flutter çeviri katmanına erişemez; bu yüzden dil kodu yazılır ve
  /// native taraf kendi kaynaklarından karşılığı seçer.
  static const languageCode = 'language_code';

  /// Verinin en son ne zaman yazıldığı (epoch, ms). Araç bunu "veri hiç
  /// yazılmamış" durumunu ayırt etmek için kullanır.
  static const updatedAt = 'updated_at';
}
