import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/root.dart';

/// Kök çözümleme verisini gerçek asset üzerinde denetler.
///
/// Türeyen kelimeler, fiil kalıpları ve sure dağılımı `build_roots.py`
/// tarafından Quranic Arabic Corpus'tan üretilir. Üretim tarafındaki bir
/// bozulma uygulamada hata vermez — bölüm sessizce boş çizilir ve kullanıcı
/// eksik bir ekran görür. Bu testler o sessiz kaybı yakalar.
void main() {
  late Map<String, QuranRoot> roots;

  setUpAll(() {
    final raw = jsonDecode(File('assets/data/roots.json').readAsStringSync())
        as Map<String, dynamic>;
    roots = {
      for (final r in (raw['roots'] as List))
        (r as Map<String, dynamic>)['r'] as String:
            QuranRoot.fromJson(r),
    };
  });

  group('türeyen kelimeler', () {
    test('sık köklerde dolu ve sıklığa göre sıralı', () {
      // ك-ت-ب: kitap, yazdı, yazıcı, yazılı. Kökün ne demek olduğunu
      // anlatan asıl bilgi budur; kök harfleri tek başına soyut kalır.
      final ketebe = roots['كتب']!;
      expect(ketebe.derived.length, greaterThan(3));

      for (var i = 1; i < ketebe.derived.length; i++) {
        expect(
          ketebe.derived[i].count,
          lessThanOrEqualTo(ketebe.derived[i - 1].count),
          reason: 'türevler sıklığa göre azalan sırada olmalı',
        );
      }

      // En sık türev "kitâb" olmalı: Kuran'da 200'den fazla geçer.
      expect(ketebe.derived.first.lemma, contains('كِتاب'));
      expect(ketebe.derived.first.count, greaterThan(200));
    });

    test('aynı kelime i\'rab harekesi yüzünden ikiye bölünmez', () {
      // Korpus aynı kelimeyi cümledeki görevine göre farklı yazar:
      // صابِر ve صابِرُ aynı kelimedir. Birleştirilmezse türev listesinde
      // iki satır görünür ve sayım bölünür.
      final sabr = roots['صبر']!;
      final lemmas = sabr.derived.map((d) => d.lemma).toList();
      expect(lemmas.length, lemmas.toSet().length, reason: 'yinelenen lemma');

      for (final lemma in lemmas) {
        expect(
          lemma.endsWith('ُ') ||
              lemma.endsWith('َ') ||
              lemma.endsWith('ِ'),
          isFalse,
          reason: '$lemma sonunda i\'rab harekesi kalmış',
        );
      }
    });

    test('anlam yanlış kelimeye bağlanmaz', () {
      // عالِم (bilen) ile عالَم (evren) harekesiz yazılışta aynıdır.
      // Sözlük harekesiz anahtarla sorgulanırsa ikisi çarpışır ve
      // "bilen" kelimesine "evren" anlamı düşer.
      final ilm = roots['علم']!;
      final alim = ilm.derived.where((d) => d.lemma == 'عالِم');
      for (final word in alim) {
        expect(
          word.meaning,
          isNot(contains('evren')),
          reason: 'عالِم kelimesine عالَم anlamı bağlanmış',
        );
      }
    });

    test('tür etiketleri korpusun bildiği değerlerden', () {
      const known = {
        'N', 'V', 'P', 'ADJ', 'PN', 'ACT_PCPL', 'PASS_PCPL', 'VN', '',
      };
      for (final root in roots.values) {
        for (final word in root.derived) {
          expect(known, contains(word.kind), reason: '${root.arabic} → ${word.lemma}');
        }
      }
    });
  });

  group('fiil kalıpları', () {
    test('tanınan kalıp aralığında', () {
      // Arapçada 10 yaygın kalıp vardır. Dışına çıkan bir değer korpus
      // ayrıştırmasının bozulduğunu gösterir.
      for (final root in roots.values) {
        for (final vf in root.verbForms) {
          expect(vf.form, inInclusiveRange(1, 11), reason: root.arabic);
          expect(vf.count, greaterThan(0));
        }
      }
    });

    test('kalıbın örnek fiili ve anlamı gelir', () {
      // ق-ر-أ: I. kalıp "okudu" (sözlükte var), IV. kalıp "okuttu"
      // (sözlükte yok; fiil yine de gösterilir).
      final qara = {for (final vf in roots['قرأ']!.verbForms) vf.form: vf};
      expect(qara[1]!.lemma, isNotEmpty);
      expect(qara[1]!.meaning, 'Okudu');
      expect(qara[4]!.lemma, isNotEmpty);
      expect(qara[4]!.hasMeaning, isFalse);
    });

    test('fiil olarak geçen köklerde dolu', () {
      // ع-ل-م hem I. kalıpta (bildi) hem II. kalıpta (öğretti) geçer;
      // kökün farklı anlamlara gelmesinin sebebi budur.
      final ilm = roots['علم']!;
      final forms = {for (final vf in ilm.verbForms) vf.form};
      expect(forms, containsAll(<int>[1, 2]));
    });
  });

  group('sure dağılımı', () {
    test('geçerli sure numaraları ve toplam geçişle tutarlı', () {
      for (final root in roots.values) {
        var sum = 0;
        for (final (surah, count) in root.surahDistribution) {
          expect(surah, inInclusiveRange(1, 114), reason: root.arabic);
          sum += count;
        }
        // Dağılımın toplamı kökün geçiş sayısını vermeli; vermiyorsa
        // sayım bir yerde kayboluyor demektir.
        expect(sum, root.count, reason: root.arabic);
      }
    });

    test('sure sırasında dizili', () {
      final ilm = roots['علم']!;
      final surahs = ilm.surahDistribution.map((e) => e.$1).toList();
      expect(surahs, orderedEquals(<int>[...surahs]..sort()));
    });
  });
}
