import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../data/models/plan_schedule.dart';

/// Seri özeti: güncel ve en uzun seri.
///
/// Rakam büyük, etiket küçük — kullanıcı ekrana bakınca tek bir sayı görsün.
/// İki sayı eşit ağırlıkta gösterilseydi hangisinin bugünü anlattığı
/// karışırdı; en uzun seri ikincil bir bilgi olarak yanında durur.
class StreakSummary extends StatelessWidget {
  const StreakSummary({super.key, required this.streak});

  final ReadingStreak streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    // Hiç okuma yokken sıfır göstermek cesaret kırıcıdır: boş bir sayaç,
    // henüz başlamamış kullanıcıya başarısızlık gibi görünür. Onun yerine
    // davet edilir.
    if (streak.isEmpty) {
      return Row(
        children: [
          Icon(Icons.local_fire_department_outlined, size: 18, color: muted),
          const SizedBox(width: Insets.xs),
          Expanded(
            child: Text(
              'plans.streakEmpty'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: Insets.xs),
        Text(
          'plans.streakDays'.tr(args: ['${streak.current}']),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: Insets.xs),
        Expanded(
          child: Text(
            'plans.streakLongest'.tr(args: ['${streak.longest}']),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
