import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';
import 'package:kuran_turkce_meal/data/models/prophet.dart';
import 'package:kuran_turkce_meal/data/models/surah.dart';
import 'package:kuran_turkce_meal/data/repositories/prophet_repository.dart';
import 'package:kuran_turkce_meal/features/search/data/verse_reference.dart';

import 'helpers/localized_app.dart';

/// Peygamber-ayet verisi gerçek asset üzerinde.
///
/// Veri `tool/build_prophets.py` ile üretiliyor ve meal metnine bağlı; meal
/// değişirse ya da araç yeniden çalıştırılırsa bozulmalar burada görünür.
void main() async {
  await TestApp.ensureInitialized();

  late List<Prophet> prophets;
  late Map<int, Ayah> ayahsById;
  late Map<int, Surah> surahs;

  setUpAll(() async {
    final rawProphets =
        await rootBundle.loadString('assets/data/prophets.json');
    prophets = (jsonDecode(rawProphets) as List)
        .cast<Map<String, Object?>>()
        .map(Prophet.fromMap)
        .toList();

    final rawAyahs = await rootBundle.loadString('assets/data/ayahs.json');
    ayahsById = {
      for (final m in (jsonDecode(rawAyahs) as List)
          .cast<Map<String, Object?>>())
        m['id']! as int: Ayah.fromMap(m),
    };

    final rawSurahs = await rootBundle.loadString('assets/data/surahs.json');
    surahs = {
      for (final m in (jsonDecode(rawSurahs) as List)
          .cast<Map<String, dynamic>>())
        m['number'] as int: Surah.fromMap(m),
    };
  });

  group('veri bütünlüğü', () {
    test('peygamber listesi boş değil', () {
      expect(prophets.length, greaterThanOrEqualTo(20));
    });

    test('kimlikler benzersiz', () {
      final ids = prophets.map((p) => p.id).toSet();
      expect(ids.length, prophets.length);
    });

    test('her peygamberin en az bir ayeti var', () {
      for (final p in prophets) {
        expect(p.ayahIds, isNotEmpty, reason: p.name);
      }
    });

    test('adlar iki dilde de dolu', () {
      for (final p in prophets) {
        expect(p.name.trim(), isNotEmpty, reason: p.id);
        expect(p.nameEn.trim(), isNotEmpty, reason: p.id);
      }
    });

    test('bütün ayet kimlikleri gerçek ayetlere karşılık gelir', () {
      // Veri elle düzenlenirse ya da meal yeniden üretilirse kimlikler
      // kayabilir; o durumda ekran boş satırlar gösterirdi.
      for (final p in prophets) {
        for (final id in p.ayahIds) {
          expect(ayahsById.containsKey(id), isTrue,
              reason: '${p.name} -> $id');
        }
      }
    });

    test('bir peygamberin ayetleri tekrarlanmaz', () {
      for (final p in prophets) {
        expect(p.ayahIds.toSet().length, p.ayahIds.length, reason: p.name);
      }
    });
  });

  group('kronolojik sıralama', () {
    test('ayetler iniş sırasına göre dizili', () {
      // Ekranın bütün varlık sebebi bu sıra; bozulursa liste mushaf sırasına
      // döner ve kıssanın gelişimi görünmez olur.
      for (final p in prophets) {
        var previousOrder = 0;
        var previousAyah = 0;

        for (final id in p.ayahIds) {
          final ayah = ayahsById[id]!;
          final order = surahs[ayah.surahNumber]!.revelationOrder;

          if (order == previousOrder) {
            expect(ayah.ayahNumber, greaterThanOrEqualTo(previousAyah),
                reason: '${p.name}: aynı surede ayet sırası bozuk');
          } else {
            expect(order, greaterThan(previousOrder),
                reason: '${p.name}: iniş sırası geriye gitti');
          }

          previousOrder = order;
          previousAyah = ayah.ayahNumber;
        }
      }
    });

    test('Mûsâ kıssası en erken inen surelerden birinde başlar', () {
      // Mûsâ Kur'an'da en çok anılan peygamber ve kıssası Mekke döneminin
      // başlarında başlar. Sıralama bozulursa bu değer büyür.
      final musa = prophets.firstWhere((p) => p.id == 'musa');
      final first = ayahsById[musa.ayahIds.first]!;
      final order = surahs[first.surahNumber]!.revelationOrder;

      expect(order, lessThan(20));
    });
  });

  group('eşleştirme doğruluğu', () {
    /// Bir peygamberin ayetlerinde adının gerçekten geçip geçmediği.
    int mentionRate(Prophet p, List<String> spellings) {
      var hits = 0;
      for (final id in p.ayahIds) {
        final text = ayahsById[id]!.translation;
        if (spellings.any(text.contains)) hits++;
      }
      return hits;
    }

    test('Sâlih ayetleri "salih amel" ifadesini yakalamamış', () {
      // Kaba tarama 79 ayet buluyordu; bunların çoğu "salih amel" idi.
      // Büyük harf duyarlı arama bunu 16'ya indirdi.
      final salih = prophets.firstWhere((p) => p.id == 'salih');
      expect(salih.ayahCount, lessThan(30));
      expect(mentionRate(salih, ['Sâlih', 'Salih']), salih.ayahCount);
    });

    test('Muhammed ayetleri hitap kalıbından arındırılmış', () {
      // "Ey Muhammed!" çevirmenin eklediği hitap; o ayetlerin konusu kıssa
      // değil. 107 geçişin 86'sı bu kalıptaydı.
      final m = prophets.firstWhere((p) => p.id == 'muhammed');
      expect(m.ayahCount, lessThan(30));
    });

    test('her ayette peygamberin adı gerçekten geçiyor', () {
      // Örnek olarak adı tek yazımlı olanlar sınanır; çok varyantlı adlarda
      // yazım listesi burada tekrarlanmak zorunda kalırdı.
      const singleSpelling = {
        'suleyman': ['Süleyman'],
        'suayb': ['Şuayb'],
        'yusuf': ['Yûsuf', 'Yusuf'],
      };

      for (final entry in singleSpelling.entries) {
        final p = prophets.firstWhere((x) => x.id == entry.key);
        expect(mentionRate(p, entry.value), p.ayahCount, reason: p.name);
      }
    });
  });

  group('ad ile arama', () {
    late ProphetRepository repo;

    setUp(() async {
      repo = ProphetRepository();
      await repo.ensureLoaded();
    });

    test('şapkasız yazım bulur', () {
      expect(repo.byName('musa', fold: foldSurahName)?.id, 'musa');
      expect(repo.byName('yusuf', fold: foldSurahName)?.id, 'yusuf');
      expect(repo.byName('ibrahim', fold: foldSurahName)?.id, 'ibrahim');
    });

    test('büyük harf sorun çıkarmaz', () {
      expect(repo.byName('MUSA', fold: foldSurahName)?.id, 'musa');
      expect(repo.byName('İBRAHİM', fold: foldSurahName)?.id, 'ibrahim');
    });

    test('İngilizce ad bulur', () {
      expect(repo.byName('moses', fold: foldSurahName)?.id, 'musa');
      expect(repo.byName('joseph', fold: foldSurahName)?.id, 'yusuf');
    });

    test('alakasız kelime eşleşmez', () {
      // Bu kelimeler peygamber adı değil; eşleşirlerse kullanıcı arama
      // yaparken kıssa ekranına yönlendirilirdi.
      for (final w in ['sabır', 'namaz', 'merhamet', 'rahmet']) {
        expect(repo.byName(w, fold: foldSurahName), isNull, reason: w);
      }
    });

    test('çok kısa girdi eşleşmez', () {
      // İki harfle neredeyse her ad eşleşirdi.
      expect(repo.byName('mu', fold: foldSurahName), isNull);
      expect(repo.byName('y', fold: foldSurahName), isNull);
    });
  });
}
