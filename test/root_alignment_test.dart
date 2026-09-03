import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/repositories/root_repository.dart';
import 'package:kuran_turkce_meal/features/roots/widgets/root_highlight.dart';

import 'helpers/localized_app.dart';

/// Kelime hizalaması.
///
/// Kök verisindeki `wordIndex`, ayet metni kelimelere bölündüğünde aynı
/// kelimeye denk gelmeli. Denk gelmezse okuma ekranı yanlış kelimeyi
/// vurgular — bu, kullanıcının doğrudan yanlış bilgi görmesi demektir.
/// Bu yüzden hizalama tüm Kuran üzerinde sınanır, örneklemle değil.
void main() async {
  await TestApp.ensureInitialized();

  late RootRepository repo;
  late Map<(int, int), String> verses;

  setUpAll(() async {
    repo = RootRepository();
    await repo.ensureLoaded();

    final raw = await rootBundle.loadString('assets/data/ayahs.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    verses = {};
    for (final a in list) {
      final surah = a['surah_number'] as int;
      final start = a['ayah_number'] as int;
      final end = (a['end_ayah_number'] as int?) ?? start;
      final arabic = a['arabic'] as String?;
      if (arabic == null) continue;

      // Birleşik meal blokları satır başıyla ayrılır; her satır bir ayettir.
      final lines = arabic.split('\n');
      for (var i = 0; i < lines.length && start + i <= end; i++) {
        verses[(surah, start + i)] = lines[i];
      }
    }
  });

  test('kelime konumları ayet metniyle birebir hizalıdır', () {
    var checked = 0;
    final mismatches = <String>[];

    for (final entry in verses.entries) {
      final (surah, ayah) = entry.key;
      final words = HighlightedArabic.splitWords(entry.value);

      for (final word in repo.wordsOfVerse(surah, ayah)) {
        checked++;
        if (word.wordIndex >= words.length) {
          mismatches.add('$surah:$ayah #${word.wordIndex} sınır dışı');
          continue;
        }
        if (words[word.wordIndex] != word.arabic) {
          mismatches.add(
            '$surah:$ayah #${word.wordIndex} '
            'beklenen "${word.arabic}" bulunan "${words[word.wordIndex]}"',
          );
        }
      }
    }

    expect(checked, greaterThan(45000), reason: 'çok az kelime sınandı');
    expect(
      mismatches,
      isEmpty,
      reason: '${mismatches.length} hizasız kelime. '
          'İlk 5: ${mismatches.take(5).join(" | ")}',
    );
  });

  test('bölme kuralı tenvin artığını birleştirir', () {
    // Bakara 2: "هُدࣰ" ve "ى" ayrı yazılır ama tek kelimedir.
    final words = HighlightedArabic.splitWords(verses[(2, 2)]!);
    expect(words.length, 7);
    expect(words.any((w) => w.contains('ى')), isTrue);
  });

  test('vurgulanan kelime kökün kendisidir', () {
    final root = repo.rootOf('رحم')!;
    for (final word in repo.occurrencesOf(root).take(100)) {
      final text = verses[(word.surahNumber, word.ayahNumber)];
      if (text == null) continue;
      final words = HighlightedArabic.splitWords(text);
      expect(words[word.wordIndex], word.arabic);
    }
  });
}
