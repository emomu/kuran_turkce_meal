import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/surah.dart';
import '../../../data/models/user_marks.dart';

/// Kaydedilenler ekranındaki sekmeler.
enum SavedTab { bookmarks, notes, highlights }

final savedTabProvider = StateProvider<SavedTab>((ref) => SavedTab.bookmarks);

/// İşaretli bir ayet: metin, sure adı ve işaretin kendisi bir arada.
class SavedEntry {
  const SavedEntry({
    required this.ayah,
    required this.surah,
    required this.mark,
  });

  final Ayah ayah;
  final Surah surah;
  final AyahMark mark;
}

/// Seçili sekmeye göre kaydedilmiş ayetleri yükler.
///
/// İşaret kayıtları önce çekilir, ardından ilgili ayetler tek sorguda alınır
/// (bkz. `ayahsByIds`) — ayet başına sorgu atmak listeyi yavaşlatırdı.
final savedEntriesProvider =
    FutureProvider.family<List<SavedEntry>, SavedTab>((ref, tab) async {
  final marksRepo = ref.watch(marksRepositoryProvider);
  final quran = ref.watch(quranRepositoryProvider);

  final marks = switch (tab) {
    SavedTab.bookmarks => await marksRepo.bookmarks(),
    SavedTab.notes => await marksRepo.notes(),
    SavedTab.highlights => await marksRepo.highlights(),
  };

  if (marks.isEmpty) return const [];

  final ayahs = await quran.ayahsByIds(marks.map((m) => m.ayahId).toList());
  final ayahById = {for (final a in ayahs) a.id: a};

  // Sure künyeleri tekrar tekrar sorgulanmasın diye bir kez alınıp haritalanır.
  final surahs = await quran.surahs(byRevelation: false);
  final surahByNumber = {for (final s in surahs) s.number: s};

  // İşaretlerin sırası korunur — repository zaten en yeniyi başa koydu.
  return [
    for (final mark in marks)
      if (ayahById[mark.ayahId] case final ayah?)
        if (surahByNumber[ayah.surahNumber] case final surah?)
          SavedEntry(ayah: ayah, surah: surah, mark: mark),
  ];
});
