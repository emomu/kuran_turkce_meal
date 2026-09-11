import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/topic.dart';
import '../../../shared/widgets/pressable.dart';

/// Fihrist ızgarasındaki konu kartı.
///
/// Kart, düz liste satırının yerini aldı. Elli altı konu aynı gri satırda
/// dizildiğinde göz tutunacak yer bulamıyor ve liste bir "içindekiler"
/// sayfasına dönüşüyordu; fihrist ise gezilecek bir yer olmalı.
///
/// Renk bölümden gelir, konudan değil. Aynı bölümün konuları aynı rengi
/// paylaşır: kullanıcı "Ahiret" kartlarını okumadan, mor tonundan tanır.
/// Konu başına ayrı renk verilseydi elli altı renk birbirinden ayırt
/// edilemez ve renk bilgi taşımaz, yalnızca gürültü olurdu.
class TopicCard extends StatelessWidget {
  const TopicCard({super.key, required this.topic, required this.onTap});

  final Topic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.locale.languageCode;
    final isDark = theme.brightness == Brightness.dark;
    final color = AppColors.topicColor(topic.categoryId, isDark: isDark);

    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: Container(
        padding: const EdgeInsets.all(Insets.sm + 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              topic.nameFor(lang),
              style: theme.textTheme.titleSmall?.copyWith(
                // Renkli zeminde tema mürekkebi yerine sabit açık ton:
                // kartlar açık temada da koyu zeminli ve oradaki koyu
                // mürekkep okunmuyordu.
                color: Colors.white.withValues(alpha: 0.95),
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Insets.xs),
            Text(
              'discover.ayahCount'.tr(args: ['${topic.ayahCount}']),
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.65),
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
