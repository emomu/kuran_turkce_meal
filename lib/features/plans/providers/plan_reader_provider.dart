import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/reading_plan.dart';
import '../../../data/models/surah.dart';
import '../../../data/models/user_marks.dart';
import '../../bookmarks/providers/bookmarks_provider.dart';
import 'plans_provider.dart';

/// Bir plan gününün okunacak metni.
///
/// Gün bir sure değil bir *aralıktır*: "Kalem 52 – Müzzemmil 16" gibi birden
/// çok sureye yayılabilir ya da bir surenin ortasında başlayıp ortasında
/// bitebilir. Bu yüzden okuma ekranı sure listesi yerine bu aralığı çizer.
class PlanDayReading {
  const PlanDayReading({
    required this.plan,
    required this.day,
    required this.ayahs,
    required this.surahsByNumber,
    required this.nextDay,
  });

  final ReadingPlan plan;
  final PlanDay day;

  /// Günün ayetleri, mushaf kimliği sırasında.
  final List<Ayah> ayahs;

  /// Aralıkta geçen surelerin künyeleri. Liste sure değiştikçe başlık
  /// çizeceği için ada ve numaraya erişmesi gerekir.
  final Map<int, Surah> surahsByNumber;

  /// Sıradaki gün. Planın son gününde null.
  final PlanDay? nextDay;

  bool get isEmpty => ayahs.isEmpty;

  /// Aralıkta birden çok sure var mı — liste başlık çizip çizmeyeceğine
  /// bununla karar verir.
  bool get spansMultipleSurahs =>
      ayahs.isNotEmpty &&
      ayahs.first.surahNumber != ayahs.last.surahNumber;
}

/// Plan gününün metnini yükler.
///
/// Anahtar (planId, dayIndex) çiftidir; gün numarası 1'den başlar.
final planDayReadingProvider =
    FutureProvider.family<PlanDayReading, (String planId, int dayIndex)>(
        (ref, key) async {
  final (planId, dayIndex) = key;

  final plan = ReadingPlans.byId(planId);
  if (plan == null) {
    throw StateError('$planId planı bulunamadı');
  }

  // `read` kullanılır, `watch` değil: gün tamamlandı olarak işaretlenince
  // planDaysProvider geçersiz kılınır ve izlenseydi bu sağlayıcı da yeniden
  // yüklenirdi. Liste yeni bir nesneyle kurulur, kaydırma konumu sıfırlanır
  // ve kullanıcı okuduğu yerden başa atılırdı. Günün ayet aralığı zaten
  // tamamlanma durumundan bağımsızdır.
  final days = await ref.read(planDaysProvider(planId).future);
  final day = days.firstWhere(
    (d) => d.index == dayIndex,
    orElse: () => throw StateError('$dayIndex. gün bulunamadı'),
  );

  final quran = ref.watch(quranRepositoryProvider);
  // Kimlik listesi kullanılır; aralık sorgusu iniş sırasında arada kalan
  // sureleri de getirirdi (bkz. PlanDay.ayahIds).
  final ayahs = await quran.ayahsByIds(day.ayahIds);

  // Aralıkta geçen sureler tek tek değil, gereken numaralar için çekilir.
  final numbers = {for (final a in ayahs) a.surahNumber};
  final surahs = await Future.wait(numbers.map(quran.surah));
  final byNumber = <int, Surah>{
    for (final s in surahs) ?s?.number: ?s,
  };

  return PlanDayReading(
    plan: plan,
    day: day,
    ayahs: ayahs,
    surahsByNumber: byNumber,
    nextDay: days.where((d) => d.index == dayIndex + 1).firstOrNull,
  );
});

/// Plan günündeki ayetlerin işaretleri (yer imi, vurgu, not).
///
/// Sure okuma ekranındaki [surahMarksProvider]'ın plan karşılığı: orada
/// anahtar sure numarasıdır, burada gün aralığı. Gün sure sınırını aşabildiği
/// için sure başına sorgu atmak yerine kimlik aralığı sorgulanır.
class PlanDayMarksNotifier extends StateNotifier<Map<int, AyahMark>> {
  PlanDayMarksNotifier(this._ref, this._planId, this._dayIndex)
      : super(const {}) {
    _load();
  }

  final Ref _ref;
  final String _planId;
  final int _dayIndex;

  Future<void> _load() async {
    final days = await _ref.read(planDaysProvider(_planId).future);
    final day = days.where((d) => d.index == _dayIndex).firstOrNull;
    if (day == null) return;

    state = await _ref
        .read(marksRepositoryProvider)
        .marksForIds(day.ayahIds);
  }

  Future<void> toggleBookmark(int ayahId) async {
    final updated =
        await _ref.read(marksRepositoryProvider).toggleBookmark(ayahId);
    _apply(ayahId, updated);
  }

  Future<void> setHighlight(int ayahId, int? color) async {
    final updated =
        await _ref.read(marksRepositoryProvider).setHighlight(ayahId, color);
    _apply(ayahId, updated);
  }

  Future<void> setNote(int ayahId, String? note) async {
    final updated =
        await _ref.read(marksRepositoryProvider).setNote(ayahId, note);
    _apply(ayahId, updated);
  }

  /// Aynı veriyi gösteren diğer ekranlar tazelenir; Kayıtlar sekmesi kendi
  /// sorgusuyla okur ve haber verilmezse eski listeyi göstermeye devam eder.
  void _apply(int ayahId, AyahMark updated) {
    final next = Map<int, AyahMark>.from(state);
    if (updated.isEmpty) {
      next.remove(ayahId);
    } else {
      next[ayahId] = updated;
    }
    state = next;

    _ref.invalidate(savedEntriesProvider);
  }
}

final planDayMarksProvider = StateNotifierProvider.family<PlanDayMarksNotifier,
    Map<int, AyahMark>, (String planId, int dayIndex)>(
  (ref, key) => PlanDayMarksNotifier(ref, key.$1, key.$2),
);
