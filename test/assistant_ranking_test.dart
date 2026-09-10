import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';
import 'package:kuran_turkce_meal/features/assistant/data/assistant_intent.dart';
import 'package:kuran_turkce_meal/features/assistant/domain/result_ranker.dart';

AnswerAyah entry(int id, String text) => AnswerAyah(
      ayah: Ayah(
        id: id,
        surahNumber: 2,
        ayahNumber: id,
        translation: text,
      ),
      surahName: 'Bakara',
    );

void main() {
  group('sonuç sıralaması', () {
    test('çok terim eşleşen ayet öne çıkar', () {
      // Tek terim geçen uzun ayet ile iki terim geçen ayet: ikincisi
      // konuya daha yakındır.
      final results = ResultRanker.rank(
        [
          entry(1, 'Onlar namazlarını dosdoğru kılarlar ve verdiğimiz '
              'rızıktan başkalarına da harcarlar bu böyledir.'),
          entry(2, 'Sabredenlere ve namaz kılanlara müjde ver, onlar '
              'zorluk anında da sabrederler ve namazı bırakmazlar.'),
        ],
        terms: ['namaz', 'sabr'],
      );

      expect(results.first.ayah.id, 2);
    });

    test('çok kısa ayet geriye alınır', () {
      final results = ResultRanker.rank(
        [
          entry(1, 'Sabret.'),
          entry(2, 'Ey iman edenler! Sabredin, sabır yarışında öne geçin '
              've Allah\'a karşı gelmekten sakının ki kurtuluşa eresiniz.'),
        ],
        terms: ['sabr'],
      );

      expect(results.first.ayah.id, 2);
    });

    test('eşleşmeyen ayet sona düşer', () {
      final results = ResultRanker.rank(
        [
          entry(1, 'Bu ayette aranan kelimelerin hiçbiri yok, alakasız '
              'bir metin olarak burada duruyor sadece.'),
          entry(2, 'Sabredenlerle beraberdir, sabır güzeldir ve sabır '
              'kurtuluşa götürür diye bildirilmiştir.'),
        ],
        terms: ['sabr'],
      );

      expect(results.first.ayah.id, 2);
      expect(results.last.ayah.id, 1);
    });

    test('eşit puanda özgün sıra korunur', () {
      // Kararlı sıralama: bm25 ikincil ölçüt olarak kalmalı.
      final input = [
        entry(1, 'Sabredenler için hazırlanmış olan mükâfat büyüktür '
            've onlar hesapsız verilir diye bildirilmiştir burada.'),
        entry(2, 'Sabredenler için hazırlanmış olan mükâfat büyüktür '
            've onlar hesapsız verilir diye bildirilmiştir burada.'),
      ];
      final results = ResultRanker.rank(input, terms: ['sabr']);

      expect(results.map((r) => r.ayah.id), [1, 2]);
    });

    test('tek sonuç olduğu gibi döner', () {
      final input = [entry(1, 'Sabredin.')];
      expect(ResultRanker.rank(input, terms: ['sabr']), same(input));
    });

    test('terim yoksa sıra değişmez', () {
      final input = [entry(1, 'a'), entry(2, 'b')];
      expect(ResultRanker.rank(input, terms: const []), same(input));
    });

    test('şapkalı yazım da eşleşir', () {
      // Normalleştirme iki tarafta da uygulanır: "adalet" araması
      // "adâlet" geçen ayeti bulmalı.
      final results = ResultRanker.rank(
        [
          entry(1, 'Bu ayette hiçbir eşleşme yok, uzun bir metin olarak '
              'burada duruyor ve konuyla ilgisi bulunmuyor.'),
          entry(2, 'Şüphesiz Allah adâleti ve iyiliği emreder, adâletten '
              'ayrılmamanızı öğütler.'),
        ],
        terms: ['adalet'],
      );

      expect(results.first.ayah.id, 2);
    });
  });
}
