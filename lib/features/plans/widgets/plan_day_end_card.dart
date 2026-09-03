import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../data/models/reading_plan.dart';
import '../../../shared/widgets/pressable.dart';

/// Plan günü bittiğinde listenin sonunda görünen geçiş kartı.
///
/// Sure sonu kartıyla aynı mekaniği izler (dokunarak ya da kaydırmayı
/// sürdürerek geçiş) ama plan diliyle konuşur: kullanıcı sure değil gün
/// bitiriyor, sıradaki de bir sure değil ertesi günün aralığı.
///
/// [nextDay] null ise plan tamamlanmıştır; geçiş yerine tamamlama mesajı
/// gösterilir.
class PlanDayEndCard extends StatelessWidget {
  const PlanDayEndCard({
    super.key,
    required this.day,
    required this.nextDay,
    required this.isCompleted,
    required this.onContinue,
    this.pullProgress = 0,
  });

  /// Yeni bitirilen gün.
  final PlanDay day;

  /// Sıradaki gün. Planın son gününde null.
  final PlanDay? nextDay;

  /// Bu gün tamamlandı olarak işaretli mi.
  ///
  /// İşaretleme kullanıcıdan istenmez: gün sonuna inmek zaten okumanın
  /// bittiği anlamına gelir, ekranın kendisi işaretler. Kart yalnızca sonucu
  /// gösterir.
  final bool isCompleted;

  final VoidCallback onContinue;

  /// Kaydırarak geçişin ilerlemesi (0–1). Kullanıcı listenin sonunda
  /// kaydırmayı sürdürdükçe artar; halka dolarak ne kadar çekmesi
  /// gerektiğini gösterir.
  final double pullProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = nextDay;
    final progress = pullProgress.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(top: Insets.lg, bottom: Insets.xl),
      child: Column(
        children: [
          // Gün sonu işareti.
          Row(
            children: [
              Expanded(child: Divider(color: theme.dividerColor, height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
                child: Text(
                  'plans.dayFinished'.tr(args: ['${day.index}']),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(child: Divider(color: theme.dividerColor, height: 1)),
            ],
          ),
          const SizedBox(height: Insets.lg),

          // Tamamlandı rozeti — kullanıcının basması gereken bir düğme
          // değil, olan bitenin bildirimi.
          _CompletedBadge(isCompleted: isCompleted),

          if (next != null) ...[
            const SizedBox(height: Insets.lg),
            Pressable(
              scale: 0.98,
              hapticOnTap: true,
              onTap: onContinue,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Insets.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(Radii.lg),
                  border: Border.all(color: theme.dividerColor, width: 0.5),
                ),
                child: Row(
                  children: [
                    // Çekme ilerlemesini gösteren halka; dolduğunda geçiş
                    // kendiliğinden tetiklenir.
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (progress > 0)
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                              backgroundColor: theme.dividerColor,
                            ),
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Insets.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'plans.continueNext'.tr(args: ['${next.index}']),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            next.label,
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.25),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: Insets.md),
            Text(
              'plans.planFinished'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Günün tamamlandığını bildiren rozet.
///
/// Dokunulabilir değildir: gün sonuna inmek okumanın bittiği anlamına gelir
/// ve işaretleme kendiliğinden yapılır. Ayrıca bir düğmeye basmak istemek,
/// kullanıcıya zaten yaptığı işi bir kez daha onaylatmak olurdu.
class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedOpacity(
      duration: Motion.normal,
      curve: Motion.standard,
      opacity: isCompleted ? 1 : 0,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: Insets.xs),
            Text(
              'plans.markedDone'.tr(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
