import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/plan_schedule.dart';
import '../../data/models/reading_plan.dart';
import '../providers/app_providers.dart';
import 'home_widget_data.dart';
import 'home_widget_keys.dart';
import 'home_widget_service.dart';

/// Ana ekran araçlarının verisini toplayıp yazan eşitleyici.
///
/// Araçlar uygulamanın veritabanını okuyamaz — kendi süreçlerinde çalışırlar.
/// Bu yüzden gösterecekleri her şey önceden düzleştirilip ortak depoya
/// yazılmalı. Bu sınıf o toplama işini yapar.
///
/// Eşitleme, verinin değişebileceği anlarda tetiklenir: açılışta, uygulama
/// öne geldiğinde, okuma ilerlediğinde ve plan günü işaretlendiğinde.
/// Sürekli izleyip yazmak yerine bu noktalar seçildi çünkü yazma işlemi
/// diske dokunuyor; okuma ekranında her kaydırmada tetiklenseydi gereksiz
/// disk trafiği doğardı.
class HomeWidgetSync {
  HomeWidgetSync(this._ref);

  final Ref _ref;

  /// Aynı anda birden çok eşitleme başlamasın diye tutulur. Uygulama öne
  /// geldiğinde ve aynı anda okuma kaydedildiğinde iki eşitleme çakışıp
  /// araçlara yarım veri yazabilirdi.
  Future<void>? _inFlight;

  /// Araçların verisini tazeler.
  ///
  /// Hata durumunda sessizce geçer: araç ikincil bir özellik, veritabanı
  /// henüz hazır değilse ya da içerik yüklenmemişse uygulamanın akışını
  /// bozmamalı.
  Future<void> sync({required String languageCode}) {
    return _inFlight ??= _run(languageCode).whenComplete(() {
      _inFlight = null;
    });
  }

  Future<void> _run(String languageCode) async {
    try {
      final payload = await _collect(languageCode);
      await HomeWidgetService.instance.update(payload);
    } catch (_) {
      // Yutulur; HomeWidgetService zaten kendi hatalarını günlüğe yazıyor.
    }
  }

  Future<HomeWidgetPayload> _collect(String languageCode) async {
    // İçerik yüklenmemişse ayet metni yok; araçlara boş veri yazılır ki
    // eski içerik ekranda kalmasın.
    final hasContent = await _ref.read(databaseProvider).hasContent();
    if (!hasContent) {
      return HomeWidgetPayload(languageCode: languageCode);
    }

    // Üç bölüm birbirinden bağımsız; paralel toplanır. Sıralı yapılsaydı
    // eşitleme üç veritabanı gidiş-dönüşü kadar uzardı ve uygulama öne
    // geldiği anda gecikme hissedilirdi.
    final results = await Future.wait([
      _dailyAyahPool(languageCode),
      _continueReading(languageCode),
      _streak(),
    ]);

    final pool = results[0] as List<DailyAyahWidgetData>;

    return HomeWidgetPayload(
      languageCode: languageCode,
      dailyAyah: pool.isEmpty ? null : pool.first,
      dailyAyahPool: pool,
      continueReading: results[1] as ContinueReadingWidgetData?,
      streak: results[2] as StreakWidgetData?,
    );
  }

  /// Günün ayeti ve onu izleyen birkaç ayet.
  ///
  /// İlk öğe günün ayetidir; araç normalde onu gösterir, "yenile"
  /// düğmesiyle sonrakilere geçer.
  Future<List<DailyAyahWidgetData>> _dailyAyahPool(
    String languageCode,
  ) async {
    final quran = _ref.read(quranRepositoryProvider);
    final now = DateTime.now();
    final dayNumber = DailyAyahWidgetData.dayNumberOf(now);

    final ayahs = await quran.ayahPoolFrom(
      now,
      count: HomeWidgetKeys.dailyAyahPoolSize,
    );
    if (ayahs.isEmpty) return const [];

    // Sure künyeleri tekrar tekrar sorgulanmasın diye önbelleğe alınır;
    // havuzdaki ayetler aynı sureden gelebiliyor.
    final surahCache = <int, String?>{};

    final pool = <DailyAyahWidgetData>[];
    for (final ayah in ayahs) {
      final name = surahCache.containsKey(ayah.surahNumber)
          ? surahCache[ayah.surahNumber]
          : surahCache[ayah.surahNumber] =
              (await quran.surah(ayah.surahNumber))?.nameFor(languageCode);
      if (name == null) continue;

      pool.add(
        DailyAyahWidgetData(
          text: ayah.translationFor(languageCode),
          reference: '$name ${ayah.numberLabel}',
          route: '/sure/${ayah.surahNumber}?ayet=${ayah.ayahNumber}',
          // Havuzun tamamı aynı güne ait sayılır: araç bayatlık kontrolünü
          // gösterilen ayete göre değil, verinin yazıldığı güne göre yapar.
          dayNumber: dayNumber,
        ),
      );
    }

    return pool;
  }

  Future<ContinueReadingWidgetData?> _continueReading(
    String languageCode,
  ) async {
    final progress = await _ref.read(progressRepositoryProvider).lastRead();
    if (progress == null) return null;

    final surah = await _ref
        .read(quranRepositoryProvider)
        .surah(progress.surahNumber);
    if (surah == null) return null;

    final fraction =
        (progress.ayahNumber / surah.ayahCount).clamp(0.0, 1.0);

    return ContinueReadingWidgetData(
      surahName: surah.nameFor(languageCode),
      // Etiket burada kurulur, native tarafta değil: sure adı zaten dile
      // göre seçiliyor, ayet numarasının biçimini de aynı yerde tutmak
      // araçların çeviri taşımasını gereksiz kılıyor.
      ayahLabel: languageCode == 'en'
          ? 'Verse ${progress.ayahNumber}'
          : '${progress.ayahNumber}. ayet',
      route:
          '/sure/${progress.surahNumber}?ayet=${progress.ayahNumber}',
      percent: (fraction * 100).round(),
    );
  }

  Future<StreakWidgetData?> _streak() async {
    final progress = _ref.read(progressRepositoryProvider);

    final planId = await progress.mostRecentPlanId();
    if (planId == null) return null;

    final plan = ReadingPlans.byId(planId);
    if (plan == null) return null;

    final now = DateTime.now();
    final completions = await progress.completionDates(planId);
    final streak = calculateStreak(
      [for (final row in completions) row.completedAt],
      today: now,
    );

    return StreakWidgetData(
      // Plan adı uygulamada çeviri anahtarı olarak tutulur; araç çeviri
      // katmanına erişemediği için anahtar burada çözülüp düz metin
      // gönderilir. Aksi halde araçta "plans.mushaf30" yazardı.
      planName: plan.titleKey.tr(),
      current: streak.current,
      longest: streak.longest,
      route: '/plan/$planId',
      todayDone: await progress.hasCompletionOn(planId, now),
    );
  }
}

final homeWidgetSyncProvider = Provider<HomeWidgetSync>(
  (ref) => HomeWidgetSync(ref),
);
