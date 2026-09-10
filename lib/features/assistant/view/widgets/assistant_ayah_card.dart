import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
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
  });

  final AnswerAyah answer;
  final String languageCode;

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
                Text(
                  ayah.translationFor(languageCode),
                  style: AppTypography.reading(
                    fontSize: 15,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
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
