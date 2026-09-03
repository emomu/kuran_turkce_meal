import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/surah.dart';
import '../../settings/providers/preferences_provider.dart';

/// Ana ekranda gösterilen sure listesi.
///
/// Sıralama tercihi değiştiğinde bu sağlayıcı kendini yeniler; ekran ayrıca
/// bir şey yapmak zorunda kalmaz.
final surahListProvider = FutureProvider<List<Surah>>((ref) {
  final sortByRevelation = ref.watch(
    preferencesProvider.select((p) => p.sortByRevelation),
  );
  return ref.watch(quranRepositoryProvider).surahs(
        byRevelation: sortByRevelation,
      );
});

/// Günün ayeti. Tarih değiştiğinde yeniden hesaplanır.
final ayahOfTheDayProvider = FutureProvider<AyahWithSurah?>((ref) async {
  final quran = ref.watch(quranRepositoryProvider);
  final ayah = await quran.ayahOfTheDay(DateTime.now());
  if (ayah == null) return null;

  final surah = await quran.surah(ayah.surahNumber);
  if (surah == null) return null;

  return AyahWithSurah(ayah: ayah, surah: surah);
});

/// Kullanıcının en son okuduğu yer — "Devam et" kartı için.
final lastReadProvider = FutureProvider<LastRead?>((ref) async {
  final progress = await ref.watch(progressRepositoryProvider).lastRead();
  if (progress == null) return null;

  final surah = await ref
      .watch(quranRepositoryProvider)
      .surah(progress.surahNumber);
  if (surah == null) return null;

  return LastRead(surah: surah, ayahNumber: progress.ayahNumber);
});

/// Okunmuş surelerin ilerleme haritası — liste satırlarındaki ince çubuk için.
final surahProgressProvider = FutureProvider<Map<int, int>>(
  (ref) => ref.watch(progressRepositoryProvider).allProgress(),
);

class AyahWithSurah {
  const AyahWithSurah({required this.ayah, required this.surah});
  final Ayah ayah;
  final Surah surah;
}

class LastRead {
  const LastRead({required this.surah, required this.ayahNumber});
  final Surah surah;
  final int ayahNumber;

  double get fraction => (ayahNumber / surah.ayahCount).clamp(0.0, 1.0);
}
