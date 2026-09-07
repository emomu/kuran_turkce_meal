import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/db/search_normalizer.dart';
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

/// Sure listesindeki arama metni.
///
/// Ekranda değil sağlayıcıda tutulur: ana ekran durumsuz bir `ConsumerWidget`
/// ve sekmeler arasında geçilirken yeniden kurulur. Metin widget durumunda
/// tutulsaydı kullanıcı Ayarlar'a gidip döndüğünde araması silinirdi.
final surahQueryProvider = StateProvider<String>((ref) => '');

/// Arama metnine göre süzülmüş sure listesi.
///
/// Süzme cihazda, bellekteki 114 kayıt üzerinde yapılır; veritabanına
/// gidilmez. Liste bu kadar kısayken sorgu başına disk okuması yapmak her
/// harfte gereksiz bir gecikme demekti.
///
/// Eşleşme sure adında, ad anlamında ve mushaf numarasında aranır: kullanıcı
/// "Bakara" da yazabilir, "İnek" de, "2" de.
final filteredSurahListProvider = Provider<AsyncValue<List<Surah>>>((ref) {
  final surahs = ref.watch(surahListProvider);
  final query = ref.watch(surahQueryProvider);

  return surahs.whenData((list) {
    final normalized = SearchNormalizer.normalize(query).trim();
    if (normalized.isEmpty) return list;

    // Sayı yazıldıysa mushaf numarası da aranır; "36" yazan kullanıcı Yâsîn'i
    // arıyordur.
    final asNumber = int.tryParse(normalized);

    return list.where((surah) {
      if (asNumber != null && surah.number == asNumber) return true;

      final name = SearchNormalizer.normalize(surah.name);
      final nameEn = SearchNormalizer.normalize(surah.nameEn ?? '');
      final meaning = SearchNormalizer.normalize(surah.meaning);
      final meaningEn = SearchNormalizer.normalize(surah.meaningEn ?? '');

      return name.contains(normalized) ||
          nameEn.contains(normalized) ||
          meaning.contains(normalized) ||
          meaningEn.contains(normalized);
    }).toList();
  });
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
