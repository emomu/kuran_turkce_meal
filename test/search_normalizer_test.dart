import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/db/search_normalizer.dart';

void main() {
  group('normalize', () {
    test('Türkçe büyük I harfini ı yapar', () {
      // Dart'ın toLowerCase() metodu burada 'i' üretir ve arama bozulur.
      expect(SearchNormalizer.normalize('IŞIK'), 'ışık');
      expect(SearchNormalizer.normalize('İMAN'), 'iman');
    });

    test('şapkalı harfleri sadeleştirir', () {
      expect(SearchNormalizer.normalize('adâlet'), 'adalet');
      expect(SearchNormalizer.normalize('îmân'), 'iman');
      expect(SearchNormalizer.normalize('Kur’ân'), 'kuran');
    });

    test('diğer Türkçe harfleri korur', () {
      expect(SearchNormalizer.normalize('ÖĞÜŞÇ'), 'öğüşç');
    });
  });

  group('toFtsQuery', () {
    test('kelimeleri önek eşleşmesi ve AND ile bağlar', () {
      expect(SearchNormalizer.toFtsQuery('rahmet melek'), '"rahmet"* AND "melek"*');
    });

    test('FTS özel karakterlerini temizler', () {
      expect(SearchNormalizer.toFtsQuery('"rahmet" -melek*'), '"rahmet"* AND "melek"*');
    });

    test('boş ve tek harflik sorguyu reddeder', () {
      expect(SearchNormalizer.toFtsQuery('   '), isNull);
      expect(SearchNormalizer.toFtsQuery('a'), isNull);
      expect(SearchNormalizer.toFtsQuery('!!'), isNull);
    });
  });

  group('matchRanges', () {
    test('şapkalı metinde sade sorguyu bulur', () {
      final ranges = SearchNormalizer.matchRanges('Allah âdil olandır', 'adil');
      expect(ranges, hasLength(1));
      expect(ranges.first.$1, 6);
    });

    test('çakışan aralıkları birleştirir', () {
      final ranges = SearchNormalizer.matchRanges('rahmetli', 'rahmet rahmetli');
      expect(ranges, hasLength(1));
      expect(ranges.first, (0, 8));
    });

    test('eşleşme yoksa boş döner', () {
      expect(SearchNormalizer.matchRanges('selam', 'melek'), isEmpty);
    });
  });
}
