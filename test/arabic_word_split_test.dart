import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/features/reader/widgets/arabic_verse_text.dart';

/// Kelime vurgusu iki ayrı yerde bölünen metne dayanır: zamanlama verisi
/// `tool/build_segments.py` içindeki kurala göre üretilir, ekrandaki metin
/// ise [ArabicVerseText.splitWords] ile bölünür. İkisi ayrışırsa vurgu
/// sessizce yanlış kelimenin üstünde durur — ayetin ortasında bir kelime
/// kayması gözle kolay fark edilmez.
///
/// Bu test iki kuralı mushafın tamamı üzerinde karşılaştırır. Beklenen
/// değerler `tool/` tarafındaki bölücüyle üretilip dosyaya yazılır.
void main() {
  test('kelime bölme kuralı üretim aracıyla birebir aynı', () {
    final file = File('test/data/word_splits.json');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Beklenen değerler yok; tool/dump_word_splits.py çalıştırın',
    );

    final expected = json.decode(file.readAsStringSync()) as List<dynamic>;
    expect(expected, isNotEmpty);

    var mismatches = 0;
    final examples = <String>[];

    for (final entry in expected) {
      final row = entry as Map<String, dynamic>;
      final text = row['t'] as String;
      final count = row['n'] as int;

      final actual = ArabicVerseText.splitWords(text).length;
      if (actual != count) {
        mismatches++;
        if (examples.length < 5) {
          examples.add('beklenen $count, bulunan $actual: ${_head(text)}');
        }
      }
    }

    expect(
      mismatches,
      0,
      reason: 'Bölme kuralı ayrıştı (${expected.length} satırda $mismatches):\n'
          '${examples.join('\n')}',
    );
  });

  test('tenvin kuyruğu önceki kelimeye yapışır', () {
    // "هُدࣰ ى" tek kelimedir: tenvinden sonraki boşluk yazım kaynaklıdır,
    // kelime sınırı değil. Bakara 2'nin bu parçası kuralın tipik örneği.
    const text = 'ذَٰلِكَ ٱلۡكِتَٰبُ لَا رَيۡبَۛ فِيهِۛ هُدࣰ ى لِّلۡمُتَّقِينَ';
    expect(ArabicVerseText.splitWords(text).length, 7);
  });

  test('boşluklar kelime üretmez', () {
    expect(ArabicVerseText.splitWords('  '), isEmpty);
    expect(ArabicVerseText.splitWords(''), isEmpty);
    expect(ArabicVerseText.splitWords('  بِسۡمِ   ٱللَّهِ '), hasLength(2));
  });
}

String _head(String text) =>
    text.length <= 40 ? text : '${text.substring(0, 40)}…';
