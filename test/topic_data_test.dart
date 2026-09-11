import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';
import 'package:kuran_turkce_meal/data/repositories/topic_repository.dart';
import 'package:kuran_turkce_meal/features/search/data/verse_reference.dart';

import 'helpers/localized_app.dart';

/// Konu fihristi verisi gerçek asset üzerinde.
///
/// Veri `tool/build_topics.py` ile üretiliyor ve meal metnine bağlı; meal
/// değişirse ya da araç yeniden çalıştırılırsa bozulmalar burada görünür.
void main() async {
  await TestApp.ensureInitialized();

  late TopicRepository repo;
  late Map<int, Ayah> ayahsById;

  setUpAll(() async {
    repo = TopicRepository();
    await repo.ensureLoaded();

    final rawAyahs = await rootBundle.loadString('assets/data/ayahs.json');
    ayahsById = {
      for (final m in (jsonDecode(rawAyahs) as List)
          .cast<Map<String, Object?>>())
        m['id']! as int: Ayah.fromMap(m),
    };
  });

  group('veri bütünlüğü', () {
    test('konu listesi boş değil', () {
      expect(repo.all.length, greaterThanOrEqualTo(40));
    });

    test('bölümler tanımlı ve her konu bir bölüme bağlı', () {
      final categoryIds = repo.categories.map((c) => c.id).toSet();
      expect(categoryIds, isNotEmpty);

      for (final topic in repo.all) {
        expect(
          categoryIds,
          contains(topic.categoryId),
          reason: '${topic.id} bilinmeyen bir bölüme bağlı',
        );
      }
    });

    test('her bölümde en az bir konu var', () {
      // Boş bir bölüm arayüzde başlıksız bir boşluk olurdu.
      for (final category in repo.categories) {
        expect(
          repo.inCategory(category.id),
          isNotEmpty,
          reason: '${category.id} bölümü boş',
        );
      }
    });

    test('konu kimlikleri benzersiz', () {
      final ids = repo.all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('her konunun ayeti var', () {
      for (final topic in repo.all) {
        expect(
          topic.ayahIds,
          isNotEmpty,
          reason: '${topic.id} hiç ayet taşımıyor',
        );
      }
    });

    test('bütün ayet kimlikleri meal verisinde bulunur', () {
      for (final topic in repo.all) {
        for (final id in topic.ayahIds) {
          expect(
            ayahsById.containsKey(id),
            isTrue,
            reason: '${topic.id} konusunda geçersiz ayet kimliği: $id',
          );
        }
      }
    });

    test('bir konuda aynı ayet iki kez geçmez', () {
      for (final topic in repo.all) {
        expect(
          topic.ayahIds.toSet().length,
          topic.ayahIds.length,
          reason: '${topic.id} konusunda tekrar eden ayet var',
        );
      }
    });
  });

  group('çekirdek ve tarama ayrımı', () {
    test('her konunun kürasyonlu çekirdeği var', () {
      // Çekirdeksiz bir konu yalnızca kelime taramasından ibaret olurdu ve
      // fihristin verdiği sözü tutmazdı.
      for (final topic in repo.all) {
        expect(
          topic.coreCount,
          greaterThan(0),
          reason: '${topic.id} konusunun çekirdeği yok',
        );
      }
    });

    test('çekirdek sayısı listeyi aşmaz', () {
      for (final topic in repo.all) {
        expect(
          topic.coreCount,
          lessThanOrEqualTo(topic.ayahIds.length),
          reason: '${topic.id}: coreCount ayet sayısından büyük',
        );
      }
    });

    test('core ve scanned birlikte listenin tamamını verir', () {
      for (final topic in repo.all) {
        expect([...topic.core, ...topic.scanned], topic.ayahIds);
      }
    });

    test('her iki bölüm de kendi içinde mushaf sırasında', () {
      // Sıralama fihristin sözü: kullanıcı Nisâ'yı beklediği yerde arar.
      int position(int id) {
        final a = ayahsById[id]!;
        return a.surahNumber * 1000 + a.ayahNumber;
      }

      for (final topic in repo.all) {
        for (final part in [topic.core, topic.scanned]) {
          for (var i = 1; i < part.length; i++) {
            expect(
              position(part[i]),
              greaterThan(position(part[i - 1])),
              reason: '${topic.id} sırası bozuk',
            );
          }
        }
      }
    });
  });

  group('ilgili konular', () {
    test('bütün bağlar çözülür', () {
      for (final topic in repo.all) {
        for (final id in topic.relatedIds) {
          expect(
            repo.byId(id),
            isNotNull,
            reason: '${topic.id} çözülemeyen bir konuya bağlı: $id',
          );
        }
      }
    });

    test('bağlar karşılıklı', () {
      // Tek yönlü bir bağ kullanıcıyı gittiği yerden geri döndürmez.
      for (final topic in repo.all) {
        for (final id in topic.relatedIds) {
          expect(
            repo.byId(id)!.relatedIds,
            contains(topic.id),
            reason: '${topic.id} → $id bağı tek yönlü',
          );
        }
      }
    });

    test('hiçbir konu kendisine bağlı değil', () {
      for (final topic in repo.all) {
        expect(topic.relatedIds, isNot(contains(topic.id)));
      }
    });
  });

  group('konu arama', () {
    test('boş sorgu bütün konuları döndürür', () {
      expect(repo.search('', fold: foldSurahName).length, repo.all.length);
    });

    test('şapkasız ve küçük harfli yazım eşleşir', () {
      final hits = repo.search('sukur', fold: foldSurahName);
      expect(hits.map((t) => t.id), contains('sukur'));
    });

    test('başlangıç eşleşmesi önce gelir', () {
      // "borç" yazan kullanıcı "Borç ve Ticaret"i listenin başında görmeli.
      final hits = repo.search('borc', fold: foldSurahName);
      expect(hits.first.id, 'borc');
    });

    test('tek harf de daraltır', () {
      // Fihrist gezilen bir liste; peygamber aramasındaki üç harf eşiği
      // burada kullanıcıyı bekletirdi.
      final hits = repo.search('z', fold: foldSurahName);
      expect(hits, isNotEmpty);
      expect(hits.length, lessThan(repo.all.length));
    });

    test('eşleşmeyen sorgu boş döner', () {
      expect(repo.search('xyzqw', fold: foldSurahName), isEmpty);
    });

    test('İngilizce ad da bulunur', () {
      final hits = repo.search('patience', fold: foldSurahName);
      expect(hits.map((t) => t.id), contains('sabir'));
    });
  });

  group('kart görselleri', () {
    test('her konunun görseli pakette var', () async {
      // Dosya adı konu kimliğidir. Bir harf kayarsa kart sessizce düz renge
      // düşer ve kimse fark etmez — üretimde bir kez "yaradilis/yaratilis"
      // olarak kaydı ve ancak elle denetimde görüldü.
      for (final topic in repo.all) {
        final path = 'assets/images/topics/${topic.id}.png';
        await expectLater(
          rootBundle.load(path),
          completes,
          reason: '$path pakette yok',
        );
      }
    });
  });

  group('bilinen konular', () {
    test('temel konular fihristte var', () {
      // Bu kimlikler rotalarda geçiyor; kaybolurlarsa bağlantılar kırılır.
      for (final id in ['sabir', 'namaz', 'adalet', 'miras', 'olum']) {
        expect(repo.byId(id), isNotNull, reason: '$id konusu kayıp');
      }
    });

    test('miras çekirdeği Nisâ 11-12 ayetlerini içerir', () {
      // Fihristin kürasyon sözünün somut sınaması: bu ayetlerde "miras"
      // kelimesi geçmez, paylar sayılır. Tarama onları bulamaz.
      final miras = repo.byId('miras')!;
      final core = miras.core.map((id) => ayahsById[id]!).toList();
      final nisa = core.where((a) => a.surahNumber == 4).map(
        (a) => a.ayahNumber,
      );
      expect(nisa, containsAll([11, 12]));
    });

    test('sabır çekirdeği Eyyûb kıssasını içerir', () {
      // Enbiyâ 83-84 sabrın en bilinen anlatımı ama orada "sabır" kelimesi
      // geçmez. Kürasyon olmasa kaçardı.
      final sabir = repo.byId('sabir')!;
      final core = sabir.core.map((id) => ayahsById[id]!).toList();
      final enbiya = core.where((a) => a.surahNumber == 21).map(
        (a) => a.ayahNumber,
      );
      expect(enbiya, containsAll([83, 84]));
    });
  });
}
