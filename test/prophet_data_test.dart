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

    test('Sâlih listesi "salih amel" ayetlerine savrulmamış', () {
      // Kaba tarama 79 ayet buluyordu; çoğu "salih amel" idi. Büyük harf
      // duyarlı arama bunu 16'ya indirdi, kıssa sınırları anlatı ayetlerini
      // ekleyerek 54'e çıkardı. Denetim sayının kendisi değil: 79'a
      // yaklaşmıyorsa kaba tarama geri gelmemiş demektir.
      final salih = prophets.firstWhere((p) => p.id == 'salih');
      expect(salih.ayahCount, lessThan(70));
    });

    test('Muhammed ayetleri hitap kalıbından arındırılmış', () {
      // "Ey Muhammed!" çevirmenin eklediği hitap; o ayetlerin konusu kıssa
      // değil. 107 geçişin 86'sı bu kalıptaydı.
      final m = prophets.firstWhere((p) => p.id == 'muhammed');
      expect(m.ayahCount, lessThan(30));
    });

    test('kıssasız peygamberlerde her ayette ad geçiyor', () {
      // Kıssa sınırı tanımlanmamış peygamberlerde liste yalnızca ad
      // taramasından gelir; orada ad her ayette geçmeli. Yanlış eşleşmeyi
      // yakalayan asıl denetim budur.
      //
      // Sınırlı olanlar buraya alınmaz: onlarda anlatı ayetleri de listede
      // olduğu için oran doğal olarak düşer (Yûsuf %41, Sâlih %29) ve
      // beklenen davranış budur.
      const spellings = {
        'yakub': ['Yakûb', 'Yakub', 'Yakup', 'Yâkub'],
        'ishak': ['İshâk', 'İshak'],
      };

      for (final entry in spellings.entries) {
        final p = prophets.firstWhere((x) => x.id == entry.key);
        expect(mentionRate(p, entry.value), p.ayahCount, reason: p.name);
      }
    });

    test('sınırlı kıssalar anlatının tamamını taşır', () {
      // Yûsuf kıssası tek surede baştan sona anlatılır (12:4-101). Ad
      // taraması ondan 41 ayet alıyordu; anlatının yarısından çoğu
      // düşüyordu. Sınırla birlikte blok bütünüyle gelir.
      final yusuf = prophets.firstWhere((p) => p.id == 'yusuf');
      expect(yusuf.ayahCount, greaterThan(90));

      final inSurah = yusuf.ayahIds
          .map((id) => ayahsById[id])
          .whereType<Ayah>()
          .where((a) => a.surahNumber == 12)
          .map((a) => a.ayahNumber)
          .toList();
      // 4-101 arası kesintisiz olmalı.
      expect(inSurah, contains(4));
      expect(inSurah, contains(101));
      expect(inSurah.length, greaterThan(90));
    });

    test('Îsâ kıssası doğum sahnesini içerir', () {
      // Kullanıcının bildirdiği eksiklik: Meryem 22 ve 27 listede vardı ama
      // aradaki doğum sahnesi (23-26) yoktu; okuyan kopuk bir anlatı
      // görüyordu.
      final isa = prophets.firstWhere((p) => p.id == 'isa');
      final maryam = isa.ayahIds
          .map((id) => ayahsById[id])
          .whereType<Ayah>()
          .where((a) => a.surahNumber == 19)
          .map((a) => a.ayahNumber)
          .toSet();

      for (var n = 16; n <= 34; n++) {
        expect(maryam, contains(n), reason: 'Meryem $n eksik');
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

  group('anılma listesi', () {
    // Kur'an Hz. Muhammed'e çoğunlukla adıyla değil sıfatıyla seslenir
    // ("Ey Peygamber", "Ey Rasûl") ve meal bunu "(Ey Muhammed)" diye açar.
    // Kıssa listesi bu ayetleri dışarıda bırakır — kıssa ekranı için doğru,
    // arama için değil. Arama 10 sonuç dönüyordu; gerçek sayı 140.
    Prophet muhammed() => prophets.firstWhere((p) => p.id == 'muhammed');

    test('Muhammed anılma listesi kıssa listesinden geniş', () {
      final p = muhammed();
      expect(p.hasSeparateMentions, isTrue);
      expect(p.mentionCount, greaterThan(p.ayahCount));
      // Sayı meale bağlı; eşiği düşük tutmak regresyonu yine yakalar.
      expect(p.mentionCount, greaterThan(100));
    });

    test('kıssa listesi anılma listesinin alt kümesi', () {
      final p = muhammed();
      expect(p.mentionIds.toSet().containsAll(p.ayahIds), isTrue);
    });

    test('"Ey Muhammed" hitabı anılma listesinde var', () async {
      final p = muhammed();
      final hasAddress = p.mentionIds
          .map((id) => ayahsById[id])
          .whereType<Ayah>()
          .any((a) => a.translation.contains('Ey Muhammed'));
      expect(hasAddress, isTrue);
    });

    test('"Ey Muhammed" hitabı kıssa listesinde yok', () {
      // Kıssa ekranının davranışı korunmalı: hitap ayetleri kıssa değildir.
      final p = muhammed();
      final story = p.ayahIds.map((id) => ayahsById[id]).whereType<Ayah>();
      for (final a in story) {
        expect(
          RegExp(r'[Ee]y\s+Muhammed').hasMatch(a.translation),
          isFalse,
          reason: '${a.reference} kıssa listesinde ama hitap ayeti',
        );
      }
    });

    test('diğer peygamberlerde iki liste aynı', () {
      // Ayrım yalnızca kendisine hitap edilen peygamberde anlamlı; başka
      // yerde ayrışırlarsa üretim aracında bir hata var demektir.
      for (final p in prophets.where((p) => p.id != 'muhammed')) {
        expect(p.mentionIds, p.ayahIds, reason: p.id);
        expect(p.hasSeparateMentions, isFalse, reason: p.id);
      }
    });

    test('anılma listesi iniş sırasına göre dizili', () {
      final p = muhammed();
      var previous = (-1, -1);
      for (final id in p.mentionIds) {
        final ayah = ayahsById[id];
        if (ayah == null) continue;
        final order = surahs[ayah.surahNumber]!.revelationOrder;
        final current = (order, ayah.ayahNumber);
        expect(
          current.$1 > previous.$1 ||
              (current.$1 == previous.$1 && current.$2 >= previous.$2),
          isTrue,
          reason: '${ayah.reference} sıra dışı',
        );
        previous = current;
      }
    });
  });
}
