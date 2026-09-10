import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/db/search_normalizer.dart';
import 'package:kuran_turkce_meal/features/assistant/data/topic_lexicon.dart';

/// Konu sözlüğünün ürettiği FTS ifadelerini denetler.
///
/// Sözlüğün en sinsi hata biçimi sessiz olanıdır: terim mealde hiç geçmez,
/// arama boş döner, asistan "bulamadım" der ve kimse sebebini anlamaz.
/// Bu testler ifadenin en azından kurulabildiğini ve OR ile bağlandığını
/// güvenceye alır; terimlerin metinde gerçekten geçtiği ise veri üzerinde
/// ayrıca doğrulanmıştır.
void main() {
  group('OR sorgusu', () {
    test('terimler OR ile bağlanır', () {
      final query = SearchNormalizer.toFtsOrQuery(['sabr', 'katlan']);
      expect(query, isNotNull);
      expect(query, contains(' OR '));
      // AND kullanılırsa üç terimi birden içeren ayet aranır ve sonuç
      // neredeyse her zaman boş döner — konu araması için yanlış.
      expect(query, isNot(contains(' AND ')));
    });

    test('tek kelimeli terim önek eşleşmesi olur', () {
      // "sabr" hem "sabrı" hem "sabrederek" biçimlerini yakalamalı.
      expect(SearchNormalizer.toFtsOrQuery(['sabr']), '"sabr"*');
    });

    test('çok kelimeli terim öbek olarak aranır', () {
      // "ortak koş" iki kelimenin yan yana geçmesini ister; ayrı ayrı
      // arandığında "ortak" ve "koş" alakasız ayetlerde eşleşirdi.
      expect(SearchNormalizer.toFtsOrQuery(['ortak koş']), '"ortak koş"');
    });

    test('boş liste null döner', () {
      expect(SearchNormalizer.toFtsOrQuery([]), isNull);
      expect(SearchNormalizer.toFtsOrQuery(['', '  ']), isNull);
    });

    test('tek harflik terim elenir', () {
      expect(SearchNormalizer.toFtsOrQuery(['a']), isNull);
    });
  });

  group('konu sözlüğü', () {
    test('her konunun terimi ve tetikleyicisi var', () {
      for (final topic in TopicLexicon.all) {
        expect(topic.terms, isNotEmpty, reason: '${topic.id} terimsiz');
        expect(topic.triggers, isNotEmpty, reason: '${topic.id} tetiksiz');
        expect(topic.termsEn, isNotEmpty, reason: '${topic.id} EN terimsiz');
      }
    });

    test('her konunun terimleri geçerli bir sorgu kurar', () {
      for (final topic in TopicLexicon.all) {
        final query = SearchNormalizer.toFtsOrQuery(topic.terms);
        expect(query, isNotNull, reason: '${topic.id} sorgu kuramadı');
      }
    });

    test('konu kimlikleri benzersiz', () {
      final ids = TopicLexicon.all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('tetikleyiciler normalleştirilmiş biçimde yazılmış', () {
      // Tetikleyiciler normalleştirilmiş metinle karşılaştırılır. ASCII
      // yazılmış bir tetikleyici ("sabir") hiçbir zaman eşleşmez ve konu
      // sessizce ölür — bu testin yakaladığı hata tam olarak buydu.
      for (final topic in TopicLexicon.all) {
        for (final trigger in topic.triggers) {
          expect(
            SearchNormalizer.normalize(trigger),
            trigger,
            reason: '${topic.id}: "$trigger" normalleştirilmiş hâlde değil',
          );
        }
      }
    });

    test('durum konuları işaretli', () {
      for (final topic in TopicLexicon.situations) {
        expect(topic.isSituational, isTrue, reason: topic.id);
      }
      for (final topic in TopicLexicon.concepts) {
        expect(topic.isSituational, isFalse, reason: topic.id);
      }
    });
  });

  group('terimler gerçek metinde', () {
    // Sözlüğün en sinsi hatası sessiz olanıdır: terim mealde hiç geçmez,
    // arama boş döner, asistan "bulamadım" der ve kimse sebebini anlamaz.
    // Bu test o hatayı derleme zamanına yakın bir yere çeker — sözlüğe
    // yeni konu ekleyen biri, terimin gerçekten metinde olduğunu bilir.
    late final String corpus;
    late final String corpusEn;

    setUpAll(() {
      final raw = File('assets/data/ayahs.json').readAsStringSync();
      final ayahs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

      corpus = ayahs
          .map((a) => SearchNormalizer.normalize(a['translation'] as String))
          .join(' ');
      corpusEn = ayahs
          .map((a) => SearchNormalizer.normalize(
                (a['translation_en'] as String?) ?? '',
              ))
          .join(' ');
    });

    test('her Türkçe terim mealde geçiyor', () {
      final dead = <String>[];

      for (final topic in TopicLexicon.all) {
        for (final term in topic.terms) {
          if (!corpus.contains(SearchNormalizer.normalize(term))) {
            dead.add('${topic.id}: "$term"');
          }
        }
      }

      expect(dead, isEmpty, reason: 'mealde geçmeyen terimler: $dead');
    });

    test('her konunun en az bir İngilizce terimi metinde geçiyor', () {
      // İngilizce tarafta terim başına ısrar edilmez: çeviri farklı
      // kelimeler kullanabilir. Aranan, konunun bütünüyle ölü olmaması.
      final dead = <String>[];

      for (final topic in TopicLexicon.all) {
        final anyHit = topic.termsEn.any(
          (t) => corpusEn.contains(SearchNormalizer.normalize(t)),
        );
        if (!anyHit) dead.add(topic.id);
      }

      expect(dead, isEmpty, reason: 'İngilizce karşılığı olmayan: $dead');
    });
  });
}
