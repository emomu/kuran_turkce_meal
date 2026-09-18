import 'package:flutter/material.dart';

/// Ayetin Arapça metni; tilavette okunan kelime vurgulanır.
///
/// Metin tek bir [Text] olarak da çizilebilirdi ama o zaman vurgulanacak
/// kelime seçilemezdi. Burada kelimelere bölünüp her biri ayrı bir
/// [TextSpan] olur; yalnızca okunan kelimenin rengi ve zemini değişir.
/// Bölme, satır kırılmasını bozmaz: parçalar tek bir paragraf içinde akar.
class ArabicVerseText extends StatelessWidget {
  const ArabicVerseText({
    super.key,
    required this.text,
    required this.fontSize,
    this.highlightedWord,
  });

  final String text;
  final double fontSize;

  /// Vurgulanacak kelimenin sırası (0 tabanlı); vurgu yokken null.
  final int? highlightedWord;

  /// Ayet metnini kelimelere böler.
  ///
  /// Bölme kuralı zamanlama verisini üreten araçla aynı olmalı
  /// (`tool/build_segments.py` → `split_words`): tenvin işaretinden sonra
  /// gelen boşluk kelimeyi ikiye ayırıyor gibi görünür ama tek kelimedir.
  /// Kural ayrılsaydı vurgu metnin ilerisine kayardı.
  static List<String> splitWords(String text) {
    final out = <String>[];
    for (final token in text.split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      if (out.isNotEmpty &&
          _roundTanween.hasMatch(out.last) &&
          _tanweenTail.hasMatch(token)) {
        out[out.length - 1] = '${out.last}$token';
      } else {
        out.add(token);
      }
    }
    return out;
  }

  /// Kelimede kopuk kuyruk üreten yuvarlak tenvin var mı.
  ///
  /// Kural `tool/build_roots.py` içindeki ROUND_TANWEEN ile birebir aynı
  /// tutulur; orada kelime sonu değil kelimenin herhangi bir yeri aranır.
  static final _roundTanween = RegExp('[\u08F0\u08F1\u08F2]');

  /// Bir öncekinin tenvininden kopmuş kuyruk mu.
  ///
  /// `tool/build_roots.py` içindeki TANWEEN_TAIL'in karşılığı: elif ya da
  /// elif maksûre ile başlar, kalanı yalnızca harekedir.
  static final _tanweenTail = RegExp(
    '^[\u0627\u0649]'
    '[\u0610-\u061A\u06D6-\u06ED\u08F0-\u08FF]*\$',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = TextStyle(
      fontSize: fontSize,
      height: 1.9,
      color: theme.colorScheme.onSurface,
    );

    final index = highlightedWord;

    // Vurgu yokken metin tek parça çizilir: bölme işi ve span yığını
    // tilavet kapalıyken boşuna yapılmasın.
    if (index == null) {
      return Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: baseStyle,
        ),
      );
    }

    final words = splitWords(text);
    final highlightStyle = baseStyle.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    return Align(
      alignment: Alignment.centerRight,
      child: Text.rich(
        TextSpan(
          children: [
            for (var i = 0; i < words.length; i++) ...[
              TextSpan(
                text: words[i],
                style: i == index ? highlightStyle : baseStyle,
              ),
              // Kelimeler arası boşluk ayrı bir span: vurgulanan kelimenin
              // zemini boşluğa taşmasın, vurgu kelimenin kendisinde dursun.
              if (i != words.length - 1)
                TextSpan(text: ' ', style: baseStyle),
            ],
          ],
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
      ),
    );
  }
}
