import 'home_widget_keys.dart';

/// Ana ekran araçlarına yazılacak verinin tamamı.
///
/// Araçların okuduğu depo düz bir anahtar-değer haritası; bu sınıf o haritayı
/// tek yerde kurar. Ara katman olmadan çağrı yerinde harita elle yazılsaydı,
/// bir anahtarın unutulması araçta sessizce boş alan olarak görünürdü —
/// derleyicinin yakalayamayacağı bir hata.
///
/// Alanların hepsi isteğe bağlı: kullanıcı hiç okumamış olabilir, planı
/// olmayabilir, veri henüz yüklenmemiş olabilir. Boş alan native tarafta
/// aracın kendi boş durumunu göstermesine yol açar.
class HomeWidgetPayload {
  const HomeWidgetPayload({
    required this.languageCode,
    this.dailyAyah,
    this.dailyAyahPool = const [],
    this.continueReading,
    this.streak,
  });

  /// Android tarafındaki paket adı. Araç sağlayıcılarının tam nitelikli
  /// adı bundan türetilir.
  static const androidPackage = 'com.emirhansoylu.kuranmeal';

  final String languageCode;
  final DailyAyahWidgetData? dailyAyah;

  /// Aracın "yenile" düğmesiyle dolaşacağı ayetler. İlk öğe günün ayetidir.
  final List<DailyAyahWidgetData> dailyAyahPool;

  final ContinueReadingWidgetData? continueReading;
  final StreakWidgetData? streak;

  /// Ortak depoya yazılacak harita.
  ///
  /// Boş alanlar `null` olarak yazılır, atlanmaz: kullanıcı son okumasını
  /// silerse ya da planı bırakırsa eski değerin depoda kalıp araçta
  /// gösterilmeye devam etmesi gerekirdi. `null` yazmak eski veriyi temizler.
  Map<String, Object?> toMap() => {
    HomeWidgetKeys.languageCode: languageCode,
    HomeWidgetKeys.updatedAt: DateTime.now().millisecondsSinceEpoch,

    HomeWidgetKeys.dailyAyahText: dailyAyah?.text,
    HomeWidgetKeys.dailyAyahReference: dailyAyah?.reference,
    HomeWidgetKeys.dailyAyahRoute: dailyAyah?.route,
    HomeWidgetKeys.dailyAyahDayNumber: dailyAyah?.dayNumber,

    HomeWidgetKeys.continueSurahName: continueReading?.surahName,
    HomeWidgetKeys.continueAyahLabel: continueReading?.ayahLabel,
    HomeWidgetKeys.continueRoute: continueReading?.route,
    HomeWidgetKeys.continuePercent: continueReading?.percent,

    HomeWidgetKeys.streakPlanName: streak?.planName,
    HomeWidgetKeys.streakCurrent: streak?.current,
    HomeWidgetKeys.streakLongest: streak?.longest,
    HomeWidgetKeys.streakRoute: streak?.route,
    HomeWidgetKeys.streakTodayDone: streak?.todayDone,

    ..._poolEntries(),
  };

  /// Yenile havuzunun kayıtları.
  ///
  /// Havuz kısaldığında artan yuvalara `null` yazılır; aksi halde araç
  /// önceki eşitlemeden kalmış bir ayete ulaşabilirdi. Bu yüzden döngü
  /// havuzun boyu kadar değil, sabit üst sınır kadar döner.
  Map<String, Object?> _poolEntries() {
    final entries = <String, Object?>{
      HomeWidgetKeys.dailyAyahPoolCount: dailyAyahPool.length,
    };

    for (var i = 0; i < HomeWidgetKeys.dailyAyahPoolSize; i++) {
      final item = i < dailyAyahPool.length ? dailyAyahPool[i] : null;
      entries[HomeWidgetKeys.dailyAyahPoolText(i)] = item?.text;
      entries[HomeWidgetKeys.dailyAyahPoolReference(i)] = item?.reference;
      entries[HomeWidgetKeys.dailyAyahPoolRoute(i)] = item?.route;
    }

    return entries;
  }
}

/// Günün ayeti aracının içeriği.
class DailyAyahWidgetData {
  const DailyAyahWidgetData({
    required this.text,
    required this.reference,
    required this.route,
    required this.dayNumber,
  });

  /// Meal metni. Araçta kırpılır — kırpma native tarafta yapılır çünkü
  /// sığacak satır sayısı araç boyutuna göre değişir.
  final String text;

  /// "Bakara 255" gibi künye.
  final String reference;

  /// Dokunulduğunda gidilecek yol.
  final String route;

  /// Verinin ait olduğu gün. Epoch gün sayısı — araç kendi gününü hesaplayıp
  /// karşılaştırır ve bayat veriyi anlar.
  final int dayNumber;

  /// Bir tarihin epoch gün sayısı.
  ///
  /// `QuranRepository.ayahOfTheDay` ile aynı hesap: yerel gün başı alınır ve
  /// gün uzunluğuna bölünür. İkisi ayrışırsa araç ile uygulama farklı ayet
  /// gösterir, bu yüzden hesap değişirse iki yer birlikte güncellenmeli.
  static int dayNumberOf(DateTime date) =>
      DateTime(date.year, date.month, date.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}

/// "Devam et" aracının içeriği.
class ContinueReadingWidgetData {
  const ContinueReadingWidgetData({
    required this.surahName,
    required this.ayahLabel,
    required this.route,
    required this.percent,
  });

  final String surahName;

  /// "12. ayet" gibi, dile göre biçimlenmiş etiket.
  final String ayahLabel;

  final String route;

  /// Surenin okunmuş yüzdesi, 0–100.
  final int percent;
}

/// Plan serisi aracının içeriği.
class StreakWidgetData {
  const StreakWidgetData({
    required this.planName,
    required this.current,
    required this.longest,
    required this.route,
    required this.todayDone,
  });

  final String planName;

  /// Kesintisiz gün sayısı.
  final int current;

  final int longest;

  final String route;

  /// Bugünün görevi tamamlandı mı.
  final bool todayDone;
}
