import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/features/assistant/domain/fuzzy_match.dart';
import 'package:kuran_turkce_meal/features/assistant/domain/query_cleaner.dart';

void main() {
  group('düzenleme uzaklığı', () {
    test('aynı kelime sıfır', () {
      expect(FuzzyMatch.distance('sabır', 'sabır'), 0);
    });

    test('tek harf değişimi bir', () {
      expect(FuzzyMatch.distance('sabir', 'sabır'), 1);
    });

    test('harf eksikliği bir', () {
      expect(FuzzyMatch.distance('sabr', 'sabır'), 1);
    });

    test('yer değiştirme tek hata sayılır', () {
      // Damerau-Levenshtein farkı: düz Levenshtein bunu iki sayardı.
      expect(FuzzyMatch.distance('sarbı', 'sabrı'), 1);
    });

    test('eşik aşılınca erken kesilir', () {
      // Kesme, tam uzaklık yerine eşik+1 döndürür; değerin kendisi değil
      // eşiği aştığı bilgisi önemlidir.
      final d = FuzzyMatch.distance('bambaska', 'sabır', maxDistance: 1);
      expect(d, greaterThan(1));
    });

    test('boş kelime diğerinin uzunluğu kadar uzak', () {
      expect(FuzzyMatch.distance('', 'sabır'), 5);
    });
  });

  group('hata payı eşiği', () {
    test('kısa kelimede hata bağışlanmaz', () {
      // "kul" ile "kül" arasındaki fark yazım hatası değil anlam farkı.
      expect(FuzzyMatch.toleranceFor(3), 0);
      expect(FuzzyMatch.isNear('kul', 'kül'), isFalse);
    });

    test('orta uzunlukta bir hata bağışlanır', () {
      expect(FuzzyMatch.toleranceFor(6), 1);
      expect(FuzzyMatch.isNear('sabir', 'sabır'), isTrue);
    });

    test('uzun kelimede iki hata bağışlanır', () {
      expect(FuzzyMatch.toleranceFor(12), 2);
      expect(FuzzyMatch.isNear('peygamberlk', 'peygamberlik'), isTrue);
    });

    test('eşik kısa olana göre belirlenir', () {
      // Uzun kelimenin cömert eşiğiyle kısa kelime yakalanmamalı.
      expect(FuzzyMatch.isNear('ali', 'alimlerin'), isFalse);
    });

    test('alakasız kelimeler yakın sayılmaz', () {
      expect(FuzzyMatch.isNear('namaz', 'cennet'), isFalse);
      expect(FuzzyMatch.isNear('sabır', 'şükür'), isFalse);
    });
  });

  group('ekli biçim eşleşmesi', () {
    test('kök öneki tanınır', () {
      expect(FuzzyMatch.matchesWithSuffix('sabırla', 'sabır'), isTrue);
      expect(FuzzyMatch.matchesWithSuffix('namazı', 'namaz'), isTrue);
    });

    test('hatalı yazılmış kök de tanınır', () {
      expect(FuzzyMatch.matchesWithSuffix('sabirla', 'sabır'), isTrue);
    });

    test('kısa hedefte tam eşleşme istenir', () {
      expect(FuzzyMatch.matchesWithSuffix('ata', 'ana'), isFalse);
    });

    test('alakasız kelime eşleşmez', () {
      expect(FuzzyMatch.matchesWithSuffix('cennette', 'sabır'), isFalse);
    });
  });

  group('sorgu temizliği', () {
    test('soru kalıbı atılır', () {
      final cleaned = QueryCleaner.clean('sabır hakkında ne diyor');
      expect(cleaned.terms, ['sabır']);
    });

    test('istek kalıbı atılır', () {
      final cleaned = QueryCleaner.clean('bana adalet ile ilgili ayet göster');
      expect(cleaned.terms, ['adalet']);
    });

    test('alan kelimeleri atılır', () {
      final cleaned = QueryCleaner.clean('kuranda merhamet geçen ayetler');
      expect(cleaned.terms, ['merhamet']);
    });

    test('anlamlı kelimeler korunur', () {
      final cleaned = QueryCleaner.clean('anne babaya iyilik');
      expect(cleaned.terms, containsAll(['anne', 'babaya', 'iyilik']));
    });

    test('her şey elenirse ısrar edilmez', () {
      // Kullanıcı gerçekten o kelimeyi arıyor olabilir; boş sonuç
      // alakasız sonuçtan kötüdür.
      final cleaned = QueryCleaner.clean('ne nedir');
      expect(cleaned.terms, isNotEmpty);
    });

    test('temizlik olmadıysa değişmedi denir', () {
      final cleaned = QueryCleaner.clean('sabır');
      expect(cleaned.wasReduced, isFalse);
    });

    test('temizlik olduysa söylenir', () {
      final cleaned = QueryCleaner.clean('sabır hakkında ne diyor');
      expect(cleaned.wasReduced, isTrue);
    });

    test('boş girdi boş sonuç', () {
      expect(QueryCleaner.clean('').isEmpty, isTrue);
    });

    test('İngilizce soru kalıbı da atılır', () {
      final cleaned = QueryCleaner.clean('what does it say about patience');
      expect(cleaned.terms, ['patience']);
    });
  });
}
