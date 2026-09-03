import 'package:flutter/material.dart';


/// Arapça ayet metnini çizer ve kökün geçtiği kelimeleri vurgular.
///
/// Vurgu kesindir: hangi kelimenin hangi köke ait olduğu morfolojik
/// çözümlemeden gelir, tahmin yoktur. Kelime sırası (`wordIndex`) ayet
/// metnindeki sırayla birebir hizalanmıştır.
class HighlightedArabic extends StatelessWidget {
  const HighlightedArabic({
    super.key,
    required this.text,
    required this.highlightIndexes,
    this.fontSize = 22,
  });

  final String text;

  /// Vurgulanacak kelimelerin ayet içindeki sıraları.
  final Set<int> highlightIndexes;

  final double fontSize;

  /// Yuvarlak tenvin işareti. Ardından gelen yalın elif ayrı kelime değildir;
  /// veri üretiminde de aynı kural uygulandığı için sıralar hizalı kalır.
  static final _roundTanween = RegExp('[ࣰࣱࣲ]');
  static final _tanweenTail = RegExp(
    r'^[اى][ؐ-ؚۖ-ࣰۭ-ࣿ]*$',
  );

  /// Ayet metnini kelimelere böler. Üretici betikle aynı kuralı uygular.
  static List<String> splitWords(String text) {
    final out = <String>[];
    for (final token in text.split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      if (out.isNotEmpty &&
          _roundTanween.hasMatch(out.last) &&
          _tanweenTail.hasMatch(token)) {
        out[out.length - 1] = out.last + token;
      } else {
        out.add(token);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final words = splitWords(text);

    final base = TextStyle(
      fontSize: fontSize,
      height: 1.9,
      color: theme.colorScheme.onSurface,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(
          children: [
            for (var i = 0; i < words.length; i++) ...[
              TextSpan(
                text: words[i],
                style: highlightIndexes.contains(i)
                    ? base.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.10),
                      )
                    : base,
              ),
              if (i != words.length - 1) TextSpan(text: ' ', style: base),
            ],
          ],
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}
