import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/surah.dart';
import 'package:kuran_turkce_meal/features/search/data/verse_reference.dart';

import 'helpers/localized_app.dart';

/// Referans çözümlemesi gerçek sure verisi üzerinde.
///
/// [verse_reference_test.dart] ayrıştırıcının kurallarını sabit bir adlar
/// tablosuyla sınar; buradaki testler ise asıl riskli kısmı kapsar: 114
/// gerçek sure adının, kullanıcının klavyeden yazabileceği hâlleriyle
/// eşleşip eşleşmediği. Veri değişirse (ad düzeltmesi, yeni yazım) burada
/// görünür.
void main() async {
  await TestApp.ensureInitialized();

  late List<Surah> surahs;

  setUpAll(() async {
    final raw = await rootBundle.loadString('assets/data/surahs.json');
    surahs = (jsonDecode(raw) as List)
        .cast<Map<String, dynamic>>()
        .map(Surah.fromMap)
        .toList();
  });

  /// Arama sağlayıcısındaki ad çözümlemesiyle aynı kural.
  int? resolve(String name) {
    final needle = foldSurahName(name);
    if (needle.length < 2) return null;

    for (final s in surahs) {
      final candidates = [
        s.name,
        s.nameEn ?? '',
        s.meaning,
        s.meaningEn ?? '',
      ].map(foldSurahName);
      if (candidates.any((c) => c == needle)) return s.number;
    }

    for (final s in surahs) {
      final candidates = [s.name, s.nameEn ?? ''].map(foldSurahName);
      if (candidates.any((c) => c.isNotEmpty && c.startsWith(needle))) {
        return s.number;
      }
    }
    return null;
  }

  VerseReference? parse(String input) =>
      parseVerseReference(input, resolveSurahName: resolve);

  test('veri 114 sure içerir', () {
    expect(surahs, hasLength(114));
  });

  group('şapkasız yazım gerçek adları bulur', () {
    // Kullanıcının klavyesinde â, î, û yok; düzeltme işareti olmadan
    // yazacaktır. Bunlar eşleşmezse özellik pratikte çalışmaz.
    const cases = {
      'yasin': 36,
      'fatiha': 1,
      'ihlas': 112,
      'al-i imran': 3,
      'nis': 4, // Nisâ, başlangıç eşleşmesi
      'kehf': 18,
      'rahman': 55,
      'mulk': 67,
      'alak': 96,
      'nas': 114,
      'nur': 24,
      'sura': 42,
      'aliimran': 3,
    };

    for (final entry in cases.entries) {
      test('"${entry.key}" -> ${entry.value}', () {
        expect(parse(entry.key)?.surahNumber, entry.value);
      });
    }
  });

  group('ad ve ayet birlikte', () {
    test('bakara 255 çözülür', () {
      final r = parse('bakara 255')!;
      expect(r.surahNumber, 2);
      expect(r.ayahNumber, 255);
    });

    test('büyük harfle yazım da çözülür', () {
      // Türkçe büyük İ/I ayrımı normalize edilmezse "İHLAS" eşleşmez.
      expect(parse('İHLAS')?.surahNumber, 112);
      expect(parse('YASİN')?.surahNumber, 36);
    });
  });

  group('mushaf numarası', () {
    test('her sure numarası kendi suresini verir', () {
      for (final s in surahs) {
        expect(parse('${s.number}')?.surahNumber, s.number, reason: s.name);
      }
    });

    test('sure:ayet biçimi her surede çalışır', () {
      for (final s in surahs) {
        final r = parse('${s.number}:1');
        expect(r?.surahNumber, s.number, reason: s.name);
        expect(r?.ayahNumber, 1, reason: s.name);
      }
    });
  });

  group('yanlış eşleşme olmamalı', () {
    test('mealde geçen sıradan kelimeler referans üretmez', () {
      // Bu kelimeler sure adı değil; referans sayılırlarsa kullanıcı arama
      // yapmak isterken bambaşka bir sureye yönlendirilir.
      for (final word in ['sabır', 'merhamet', 'gökler', 'namaz', 'oruç']) {
        expect(parse(word), isNull, reason: word);
      }
    });

    test('tek harf referans üretmez', () {
      // İki harften kısa girdi elenmezse neredeyse her şey bir sureye
      // eşleşirdi.
      expect(parse('a'), isNull);
      expect(parse('n'), isNull);
    });
  });
}
