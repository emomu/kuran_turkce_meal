import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/plan_schedule.dart';
import '../../../data/models/reading_plan.dart';
import '../../../data/models/surah.dart';

/// Bir planın günlere bölünmüş hâli.
///
/// Bölme her açılışta hesaplanır, veritabanında saklanmaz: hesap ucuzdur
/// (114 sure üzerinde tek geçiş) ve saklamak plan tanımı değişince eskimiş
/// veri riski getirirdi.
final planDaysProvider = FutureProvider.family<List<PlanDay>, String>((
  ref,
  planId,
) async {
  final plan = ReadingPlans.byId(planId);
  if (plan == null) return const [];

  final quran = ref.watch(quranRepositoryProvider);
  final progress = ref.watch(progressRepositoryProvider);

  final surahs = await quran.surahs(
    byRevelation: plan.order == PlanOrder.revelation,
  );
  final completed = await progress.completedDays(planId);
  // Ayet dizini veritabanından okunur; künyedeki ayet sayısından
  // hesaplanamaz (bkz. QuranRepository.ayahIndex).
  final index = await quran.ayahIndex();

  return _buildDays(plan, surahs, index, completed);
});

/// Planı günlere böler.
///
/// Bölme sure sınırlarını gözetmez — günlük yük dengeli olsun diye ayet
/// sayısına göre eşit bölünür. Sure ortasında bitmek okuma akışını bozmaz
/// çünkü kullanıcı zaten kaldığı ayetten devam eder.
///
/// Aralıklar global ayet kimliği üzerinden verilir; plan iniş sırasını
/// izlese bile kimlikler mushaf sırasındadır, bu yüzden her gün için
/// başlangıç ve bitiş surelerin gerçek kimliklerinden türetilir.
List<PlanDay> _buildDays(
  ReadingPlan plan,
  List<Surah> surahs,
  List<({int id, int surahNumber, int ayahNumber})> index,
  Set<int> completed,
) {
  // Kayıtlar sure numarasına göre gruplanır; plan sıralaması bu grupları
  // istediği düzende dizer.
  final bySurah = <int, List<({int id, int surahNumber, int ayahNumber})>>{};
  for (final row in index) {
    bySurah.putIfAbsent(row.surahNumber, () => []).add(row);
  }

  // Planın sıralamasına göre okunacak kayıtları düz bir listeye aç.
  //
  // Kimlikler ve ayet numaraları veritabanından gelir. Daha önce sure
  // künyesindeki `ayahCount` üzerinden birikimli hesaplanıyordu; birleşik
  // meal blokları yüzünden kayıt sayısı ayet sayısından az olduğu için fark
  // sure sure birikiyor ve 96. sureye gelindiğinde 45 kaydı buluyordu.
  // Sonuç: kullanıcı Alak'a dokunduğunda Âdiyât açılıyordu.
  final sequence = <(int ayahId, Surah surah, int ayahNumber)>[];
  for (final surah in surahs) {
    for (final row in bySurah[surah.number] ?? const []) {
      sequence.add((row.id, surah, row.ayahNumber));
    }
  }

  if (sequence.isEmpty) return const [];

  final perDay = (sequence.length / plan.dayCount).ceil();
  final days = <PlanDay>[];

  for (var dayIndex = 0; dayIndex < plan.dayCount; dayIndex++) {
    final from = dayIndex * perDay;
    if (from >= sequence.length) break;
    final to = ((dayIndex + 1) * perDay - 1).clamp(0, sequence.length - 1);

    final first = sequence[from];
    final last = sequence[to];

    days.add(
      PlanDay(
        index: dayIndex + 1,
        // Kimlikler liste olarak taşınır: iniş sırasında gün mushafta bitişik
        // olmayan sureleri kapsayabilir, aralık verilseydi arada kalan tüm
        // sureler de güne dahil olurdu.
        ayahIds: [for (var i = from; i <= to; i++) sequence[i].$1],
        label: _rangeLabel(first, last),
        isCompleted: completed.contains(dayIndex + 1),
      ),
    );
  }

  return days;
}

String _rangeLabel((int, Surah, int) first, (int, Surah, int) last) {
  final (_, startSurah, startAyah) = first;
  final (_, endSurah, endAyah) = last;

  if (startSurah.number == endSurah.number) {
    return startAyah == endAyah
        ? '${startSurah.name} $startAyah'
        : '${startSurah.name} $startAyah–$endAyah';
  }
  return '${startSurah.name} $startAyah – ${endSurah.name} $endAyah';
}

/// Bir planda tamamlanmış gün sayısı.
final planProgressProvider = FutureProvider.family<int, String>((ref, planId) {
  return ref.watch(progressRepositoryProvider).completedDayCount(planId);
});

/// Planın takvim durumu: bugün kaçıncı gün, geride mi.
///
/// Plan hiç başlatılmadıysa null döner; ekran o zaman takvim bilgisini hiç
/// göstermez. "0. gün" ya da "0 gün geride" göstermek başlamamış bir planı
/// borçluymuş gibi sunardı.
final planScheduleProvider = FutureProvider.family<PlanSchedule?, String>((
  ref,
  planId,
) async {
  final plan = ReadingPlans.byId(planId);
  if (plan == null) return null;

  final repo = ref.watch(progressRepositoryProvider);
  final startDate = repo.planStartDate(planId);
  if (startDate == null) return null;

  return PlanSchedule.from(
    startDate: startDate,
    today: DateTime.now(),
    completedDays: await repo.completedDayCount(planId),
    dayCount: plan.dayCount,
  );
});

/// Planın tamamlanma tarihleri — seri ve takvim ısı haritası bunu kullanır.
///
/// Tek sorgu iki görünümü de besler; ayrı ayrı çekilseydi aynı tabloyu iki
/// kez okurduk.
final planCompletionsProvider = FutureProvider.family<List<DateTime>, String>((
  ref,
  planId,
) async {
  final rows = await ref
      .read(progressRepositoryProvider)
      .completionDates(planId);
  return [for (final r in rows) r.completedAt];
});

/// Planın okuma serisi.
final planStreakProvider = FutureProvider.family<ReadingStreak, String>((
  ref,
  planId,
) async {
  final completions = await ref.watch(planCompletionsProvider(planId).future);
  return calculateStreak(completions, today: DateTime.now());
});

/// Plan gününün tamamlanma durumunu değiştirir.
final planActionsProvider = Provider((ref) => PlanActions(ref));

class PlanActions {
  PlanActions(this._ref);
  final Ref _ref;

  Future<void> toggleDay(String planId, int dayIndex, bool isCompleted) async {
    final repo = _ref.read(progressRepositoryProvider);
    if (isCompleted) {
      await repo.markDayIncomplete(planId, dayIndex);
    } else {
      await repo.markDayComplete(planId, dayIndex);
      // Takvim bağı ilk tamamlamada kurulur. Ayrı bir "planı başlat" adımı
      // istemek, kullanıcının okumaya başlamadan önce bir söz vermesini
      // beklemek olurdu; oysa plan zaten okundukça sahiplenilir.
      await repo.ensurePlanStarted(planId, DateTime.now());
    }
    _invalidate(planId);
  }

  /// Planı bugünden yeniden başlatır.
  ///
  /// Tamamlanan günler SİLİNMEZ; yalnızca başlangıç tarihi bugüne çekilir.
  /// Plan bırakmanın en yaygın sebebi biriken "borç" hissidir: 12 gün geride
  /// kalan kullanıcı için plan artık bir okuma programı değil, bir suçluluk
  /// listesidir. Borcu sıfırlamak okumayı sürdürmenin önünü açar; ilerlemeyi
  /// de silmek ise kullanıcıyı iki kez cezalandırırdı.
  Future<void> restartFromToday(String planId) async {
    await _ref
        .read(progressRepositoryProvider)
        .setPlanStartDate(planId, DateTime.now());
    _invalidate(planId);
  }

  void _invalidate(String planId) {
    _ref.invalidate(planDaysProvider(planId));
    _ref.invalidate(planProgressProvider(planId));
    _ref.invalidate(planScheduleProvider(planId));
    _ref.invalidate(planCompletionsProvider(planId));
    _ref.invalidate(planStreakProvider(planId));
  }
}
