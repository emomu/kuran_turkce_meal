import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/repositories/root_repository.dart';

import 'helpers/localized_app.dart';

/// Kök verisi ve arama davranışı.
///
/// Testler gerçek asset üzerinde çalışır: arama mantığının doğruluğu kadar
/// verinin kendisi de sınanmalı — kök sayısı ya da hizalama bozulursa burada
/// görünsün.
void main() async {
  await TestApp.ensureInitialized();

  late RootRepository repo;

  setUpAll(() async {
    repo = RootRepository();
    await repo.ensureLoaded();
  });

  group('Kök verisi', () {
    test('kökler ve kelimeler yüklenir', () {
      expect(repo.allRoots, isNotEmpty);
      expect(repo.allRoots.length, greaterThan(1500));
      expect(repo.letters, isNotEmpty);
    });

    test('her kökün Türkçe anlamı vardır', () {
      final missing = repo.allRoots.where((r) => !r.hasMeaning).toList();
      expect(
        missing,
        isEmpty,
        reason: 'anlamsız kökler: ${missing.take(5).map((r) => r.arabic)}',
      );
    });

    test('geçiş sayısı ile geçiş listesi tutarlıdır', () {
      for (final root in repo.allRoots.take(50)) {
        expect(root.count, root.occurrences.length);
        expect(repo.occurrencesOf(root).length, root.count);
      }
    });

    test('geçişler doğru köke bağlıdır', () {
      final root = repo.rootOf('رسل')!;
      for (final word in repo.occurrencesOf(root).take(30)) {
        expect(word.root, 'رسل');
      }
    });
  });

  group('Kök arama', () {
    test('Türkçe anlamla bulunur', () {
      final hits = repo.search('elçi');
      expect(hits.map((r) => r.arabic), contains('رسل'));
    });

    test('Türkçe okunuşla bulunur', () {
      expect(repo.search('resul').map((r) => r.arabic), contains('رسل'));
      expect(repo.search('kitab').map((r) => r.arabic), contains('كتب'));
    });

    test('Arapça kökle bulunur', () {
      final hits = repo.search('رسل');
      expect(hits.first.arabic, 'رسل');
    });

    test('latin iskeletle bulunur', () {
      expect(repo.search('rsl').map((r) => r.arabic), contains('رسل'));
    });

    test('ayraçlı iskelet aynı sonucu verir', () {
      final plain = repo.search('rsl').map((r) => r.arabic).toList();
      final dashed = repo.search('r-s-l').map((r) => r.arabic).toList();
      expect(dashed, plain);
    });

    test('tek harflik sorgu sonuç döndürmez', () {
      expect(repo.search('r'), isEmpty);
    });

    test('boş sorgu sonuç döndürmez', () {
      expect(repo.search('   '), isEmpty);
    });

    test('tam eşleşme öne alınır', () {
      // "ilim" arayan kullanıcı علم kökünü ilk sırada görmeli.
      final hits = repo.search('bilgi');
      expect(hits.first.arabic, 'علم');
    });
  });

  group('Harf filtresi', () {
    test('seçilen harfleri içeren kökleri getirir', () {
      final hits = repo.byLetters({'ر', 'س', 'ل'});
      expect(hits.map((r) => r.arabic), contains('رسل'));
      for (final root in hits) {
        expect(root.letters, containsAll(<String>['ر', 'س', 'ل']));
      }
    });

    test('harf eklendikçe sonuç daralır', () {
      final wide = repo.byLetters({'ر'}).length;
      final narrow = repo.byLetters({'ر', 'س'}).length;
      expect(narrow, lessThanOrEqualTo(wide));
    });

    test('boş seçim sonuç döndürmez', () {
      expect(repo.byLetters(const {}), isEmpty);
    });
  });

  group('Ayet kelimeleri', () {
    test('Fâtiha 1 kelimeleri çözümlenir', () {
      final words = repo.wordsOfVerse(1, 1);
      expect(words, isNotEmpty);
      // Kelime sırası artan olmalı; okuma ekranı bu sıraya güvenir.
      for (var i = 1; i < words.length; i++) {
        expect(words[i].wordIndex, greaterThan(words[i - 1].wordIndex));
      }
    });

    test('kelime kökü sözlükte bulunur', () {
      for (final word in repo.wordsOfVerse(1, 1)) {
        expect(repo.rootOf(word.root), isNotNull);
      }
    });

    test('olmayan ayet boş döner', () {
      expect(repo.wordsOfVerse(999, 999), isEmpty);
    });
  });
}
