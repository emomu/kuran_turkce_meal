import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/features/search/data/verse_reference.dart';

/// Test için sabit bir ad→numara eşlemesi.
///
/// Gerçek çözümleme sure listesinden gelir; burada ayrıştırıcının kendi
/// kuralları sınanıyor, ad eşleştirmesi değil.
int? _resolve(String name) {
  const names = {
    'bakara': 2,
    'al-baqarah': 2,
    'yasin': 36,
    'ihlas': 112,
    'alak': 96,
  };
  return names[name.trim().toLowerCase()];
}

VerseReference? parse(String input) =>
    parseVerseReference(input, resolveSurahName: _resolve);

void main() {
  group('sayısal referans', () {
    test('iki nokta ile ayrılan referans çözülür', () {
      final r = parse('2:255')!;
      expect(r.surahNumber, 2);
      expect(r.ayahNumber, 255);
      expect(r.isExplicitAyah, isTrue);
    });

    test('eğik çizgi ve nokta da ayırıcı sayılır', () {
      // Kullanıcı referansı gördüğü yerden kopyalar; kaynaklar farklı
      // ayırıcı kullanıyor.
      expect(parse('2/255')?.ayahNumber, 255);
      expect(parse('2.255')?.ayahNumber, 255);
    });

    test('ayırıcı çevresindeki boşluk sorun çıkarmaz', () {
      expect(parse('2 : 255')?.ayahNumber, 255);
    });

    test('tek sayı sure referansı sayılır', () {
      final r = parse('36')!;
      expect(r.surahNumber, 36);
      expect(r.ayahNumber, isNull);
      expect(r.isExplicitAyah, isFalse);
    });

    test('114 üstü sure numarası reddedilir', () {
      // "1453" yazan kullanıcı sure aramıyordur.
      expect(parse('115'), isNull);
      expect(parse('999'), isNull);
    });

    test('sıfır ve negatif değerler reddedilir', () {
      expect(parse('0'), isNull);
      expect(parse('0:5'), isNull);
      expect(parse('2:0'), isNull);
    });
  });

  group('adla referans', () {
    test('sure adı ve ayet numarası çözülür', () {
      final r = parse('bakara 255')!;
      expect(r.surahNumber, 2);
      expect(r.ayahNumber, 255);
      expect(r.isExplicitAyah, isTrue);
    });

    test('yalnızca sure adı çözülür', () {
      final r = parse('yasin')!;
      expect(r.surahNumber, 36);
      expect(r.ayahNumber, isNull);
      expect(r.isExplicitAyah, isFalse);
    });

    test('İngilizce ad da çözülür', () {
      expect(parse('al-baqarah 10')?.surahNumber, 2);
    });

    test('tanınmayan ad referans üretmez', () {
      // Tam metin aramasına düşmeli; "sabır 5" bir referans değil.
      expect(parse('sabır 5'), isNull);
      expect(parse('merhamet'), isNull);
    });
  });

  group('referans olmayan girdiler', () {
    test('boş metin', () {
      expect(parse(''), isNull);
      expect(parse('   '), isNull);
    });

    test('düz kelime aramaları', () {
      expect(parse('rahmet'), isNull);
      expect(parse('gökleri ve yeri'), isNull);
    });

    test('sayı içeren ama referans olmayan sorgu', () {
      // "7 kat gök" arayan kullanıcı 7. sureye gitmek istemiyor.
      expect(parse('7 kat gök'), isNull);
    });

    test('üçten fazla haneli sayı', () {
      expect(parse('1453'), isNull);
    });
  });

  group('eşitlik', () {
    test('aynı referanslar eşit sayılır', () {
      expect(parse('2:255'), parse('2/255'));
    });

    test('sure ile sure:ayet farklıdır', () {
      expect(parse('2'), isNot(parse('2:1')));
    });
  });
}
