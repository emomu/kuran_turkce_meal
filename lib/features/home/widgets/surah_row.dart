import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../data/models/surah.dart';
import '../../../shared/widgets/pressable.dart';

/// Sure listesindeki tek satır.
///
/// Sol taraftaki sayı, aktif sıralamaya göre değişir: iniş sırası açıkken
/// kronolojik numarayı, mushaf sırası açıkken resmî numarayı gösterir.
/// Diğer numara alt satırda ikincil bilgi olarak durur — kullanıcı iki
/// sıralama arasında kaybolmasın.
class SurahRow extends StatelessWidget {
  const SurahRow({
    super.key,
    required this.surah,
    required this.showRevelationOrder,
    required this.onTap,
    this.lastReadAyah,
  });

  final Surah surah;
  final bool showRevelationOrder;
  final VoidCallback onTap;

  /// Bu surede kalınan ayet. Null ise henüz okunmamış.
  final int? lastReadAyah;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.locale.languageCode;
    final primaryNumber =
        showRevelationOrder ? surah.revelationOrder : surah.number;
    final progress = lastReadAyah == null
        ? null
        : (lastReadAyah! / surah.ayahCount).clamp(0.0, 1.0);

    return Pressable(
      onTap: onTap,
      scale: 0.985,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        child: Row(
          children: [
            // Sıra numarası.
            SizedBox(
              width: 34,
              child: Text(
                '$primaryNumber',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: Insets.sm),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(surah.nameFor(lang), style: theme.textTheme.titleSmall),
                  const SizedBox(height: 1),
                  Text(
                    _subtitle(context, lang),
                    style: theme.textTheme.bodySmall,
                  ),
                  // İlerleme çubuğu yalnızca okunmuş surelerde görünür.
                  if (progress != null) ...[
                    const SizedBox(height: 6),
                    _ProgressBar(fraction: progress),
                  ],
                ],
              ),
            ),

            const SizedBox(width: Insets.xs),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  /// Alt satır: anlam, iniş yeri, ayet sayısı ve karşı sıralamadaki numara.
  String _subtitle(BuildContext context, String lang) {
    final counterpart = showRevelationOrder
        ? 'home.mushafNth'.tr(args: ['${surah.number}'])
        : 'home.nthRevelation'.tr(args: ['${surah.revelationOrder}']);
    final place = surah.revelationPlace.labelKey.tr();
    final count = 'common.verseCount'.tr(args: ['${surah.ayahCount}']);
    return '${surah.meaningFor(lang)} · $place · $count · $counterpart';
  }
}

/// İnce ilerleme çubuğu. Yüzde metni gösterilmez — satırı kalabalıklaştırır
/// ve okuma listesinde sayı hedefi hissi vermek istenmez.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction});
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.pill),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 2,
        backgroundColor: theme.colorScheme.surfaceContainer,
        valueColor: AlwaysStoppedAnimation(
          theme.colorScheme.primary.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
