import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../data/db/search_normalizer.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../data/assistant_intent.dart';

/// Cevabın dayandığı tek bir ayet.
///
/// Görünüm arama sonuçlarıyla aynı: yeşil künye satırı, altında meal metni,
/// aralarında ince bir ayırıcı. Kutu içine alınmıyor — uygulamanın geri
/// kalanı düz yüzeylerle kurulu ve çerçeveli kartlar yabancı duruyordu.
/// Kullanıcı zaten aynı şeyi (bir ayet sonucu) iki ekranda da görüyor;
/// ikisinin farklı görünmesi için sebep yok.
///
/// Tıklanabilir: asistan bir çıkmaz sokak olmamalı, gösterdiği ayet okuma
/// ekranında yerinde görülebilmeli. Metin kısaltılmaz — dini metinde yarım
/// cümle anlamı bozar.
class AssistantAyahCard extends StatelessWidget {
  const AssistantAyahCard({
    super.key,
    required this.answer,
    required this.languageCode,
    this.showDivider = true,
    this.highlightTerms = const [],
  });

  final AnswerAyah answer;
  final String languageCode;

  /// Metinde kalın gösterilecek kelimeler.
  ///
  /// Sonucun neden geldiğini gösterir. Boşsa metin düz çizilir — doğrudan
  /// bir ayete gidildiğinde vurgulanacak bir eşleşme yoktur.
  final List<String> highlightTerms;

  /// Altına ayırıcı çizilsin mi. Listenin son öğesinde kapatılır.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ayah = answer.ayah;

    return Pressable(
      onTap: () => context.push(
        '/sure/${ayah.surahNumber}?ayet=${ayah.ayahNumber}',
      ),
      scale: 0.99,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${answer.surahName} · ${ayah.numberLabel}. ayet',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                _Translation(
                  text: ayah.translationFor(languageCode),
                  terms: highlightTerms,
                  style: AppTypography.reading(
                    fontSize: 15,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                  highlightColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
        ],
      ),
    );
  }
}

/// Meal metni; eşleşen kelimeler kalın.
///
/// Vurgu bir renk değil bir kalınlık farkıdır: dini metinde renkli kelime
/// bir yorum katmanı gibi durur. Kalınlık yeter — göz eşleşmeyi bulur,
/// metin okunmaya devam eder.
class _Translation extends StatelessWidget {
  const _Translation({
    required this.text,
    required this.terms,
    required this.style,
    required this.highlightColor,
  });

  final String text;
  final List<String> terms;
  final TextStyle style;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    if (terms.isEmpty) return Text(text, style: style);

    // Arama tarafıyla aynı normalleştirmeyi kullanan hazır aralık bulucu;
    // şapkalı yazımlar da eşleşir ("adalet" → "adâlet").
    final ranges = SearchNormalizer.matchRanges(text, terms.join(' '));
    if (ranges.isEmpty) return Text(text, style: style);

    final spans = <TextSpan>[];
    var cursor = 0;

    for (final (start, end) in ranges) {
      // Aralıklar ham metne göre hizalanır ama normalleştirme kesme
      // işaretlerini düşürdüğü için bir iki karakter kayabilir; sınırlar
      // metnin dışına taşarsa vurgu atlanır, metin bozulmaz.
      if (start < cursor || start >= text.length) continue;
      final safeEnd = end > text.length ? text.length : end;
      if (safeEnd <= start) continue;

      if (start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, start)));
      }
      spans.add(TextSpan(
        text: text.substring(start, safeEnd),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: highlightColor,
        ),
      ));
      cursor = safeEnd;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(TextSpan(children: spans), style: style);
  }
}
