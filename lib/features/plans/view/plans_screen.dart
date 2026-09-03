import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../data/models/reading_plan.dart';
import '../../../shared/widgets/pressable.dart';
import '../providers/plans_provider.dart';
import '../../../shared/widgets/tab_bar_inset.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../onboarding/providers/tour_provider.dart';
import '../../onboarding/widgets/coach_mark.dart';
import '../../onboarding/widgets/tour_host.dart';

/// Planlar turunun işaret ettiği öğeler.
///
/// Ekran tek örnektir (sekme dalının kökü) ve durumsuz bir
/// `ConsumerWidget`; anahtarlar bu yüzden dosya düzeyinde tutulur.
final _firstPlanKey = GlobalKey();
final _firstBadgeKey = GlobalKey();

/// Okuma planları listesi.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: TourHost(
        tour: TourId.plans,
        steps: _tourSteps,
        child: SafeArea(
          bottom: false,
          left: false,
          right: false,
          child: ListView(
          padding: centeredContentPadding(
            context,
            top: Insets.md,
            bottom: bottomInsetFor(context) + Insets.lg,
          ),
          children: [
            Text('nav.plans'.tr(), style: theme.textTheme.displaySmall),
            Text(
              'plans.subtitle'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: Insets.lg),

            for (final (index, plan) in ReadingPlans.all.indexed) ...[
              _PlanCard(
                // İlk kart tanıtımın hedefi.
                key: index == 0 ? _firstPlanKey : null,
                plan: plan,
                badgeKey: index == 0 ? _firstBadgeKey : null,
                onTap: () => context.push('/plan/${plan.id}'),
              ),
              const SizedBox(height: Insets.sm),
            ],
          ],
          ),
        ),
      ),
    );
  }

  /// Planlar ekranının tanıtım adımları.
  ///
  /// Planın ne olduğu karttan anlaşılıyor; asıl açıklanması gereken iki
  /// sıralamanın farkı ve ilerlemenin saklandığı. İkisi de kullanıcının
  /// kendi başına fark etmesi zor şeyler.
  static List<TourStep> _tourSteps() {
    return [
      TourStep(
        targetKey: _firstPlanKey,
        icon: Icons.calendar_today_rounded,
        title: 'tour.plans.cardTitle'.tr(),
        body: 'tour.plans.cardBody'.tr(),
      ),
      TourStep(
        targetKey: _firstBadgeKey,
        icon: Icons.swap_vert_rounded,
        title: 'tour.plans.orderTitle'.tr(),
        body: 'tour.plans.orderBody'.tr(),
      ),
      TourStep(
        icon: Icons.check_circle_outline_rounded,
        title: 'tour.plans.progressTitle'.tr(),
        body: 'tour.plans.progressBody'.tr(),
      ),
    ];
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    this.badgeKey,
  });

  final ReadingPlan plan;
  final VoidCallback onTap;

  /// Tanıtımın sıralama rozetini işaret edebilmesi için.
  final GlobalKey? badgeKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final completed = ref.watch(planProgressProvider(plan.id)).valueOrNull ?? 0;
    final fraction = (completed / plan.dayCount).clamp(0.0, 1.0);
    final isStarted = completed > 0;

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: theme.dividerColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(plan.titleKey.tr(), style: theme.textTheme.titleMedium),
                ),
                _OrderBadge(key: badgeKey, order: plan.order),
              ],
            ),
            const SizedBox(height: Insets.xxs),
            Text(
              plan.descriptionKey.tr(),
              style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
            ),
            const SizedBox(height: Insets.sm),

            Row(
              children: [
                Text(
                  'plans.dayCount'.tr(args: ['${plan.dayCount}']),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'plans.versesPerDay'.tr(args: ['${plan.ayahsPerDay}']),
                  style: theme.textTheme.labelMedium,
                ),
                const Spacer(),
                if (isStarted)
                  Text(
                    '$completed/${plan.dayCount}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),

            // İlerleme çubuğu yalnızca başlanmış planlarda görünür; boş
            // çubuklar kart listesini gereksiz kalabalıklaştırır.
            if (isStarted) ...[
              const SizedBox(height: Insets.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.pill),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 3,
                  backgroundColor: theme.colorScheme.surfaceContainer,
                  valueColor:
                      AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Planın hangi sıralamayı izlediğini gösteren küçük rozet.
class _OrderBadge extends StatelessWidget {
  const _OrderBadge({super.key, required this.order});
  final PlanOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRevelation = order == PlanOrder.revelation;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.xs, vertical: 3),
      decoration: BoxDecoration(
        color: isRevelation
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(
        isRevelation ? 'home.orderRevelation'.tr() : 'plans.badgeMushaf'.tr(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: isRevelation
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
