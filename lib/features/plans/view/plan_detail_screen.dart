import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../data/models/plan_schedule.dart';
import '../../../data/models/reading_plan.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pressable.dart';
import '../providers/plans_provider.dart';
import '../widgets/streak_summary.dart';
import 'plan_reader_screen.dart';

/// Bir planın gün gün dökümü.
class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plan = ReadingPlans.byId(planId);

    if (plan == null) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'plans.notFound'.tr(),
          message: 'plans.notFoundHint'.tr(),
        ),
      );
    }

    final days = ref.watch(planDaysProvider(planId));
    final completed = ref.watch(planProgressProvider(planId)).valueOrNull ?? 0;
    final schedule = ref.watch(planScheduleProvider(planId)).valueOrNull;
    final streak = ref.watch(planStreakProvider(planId)).valueOrNull;
    final completions =
        ref.watch(planCompletionsProvider(planId)).valueOrNull ??
        const <DateTime>[];

    // Araçtan doğrudan açıldığında geride yığın olmaz; sistem geri jesti
    // uygulamayı kapatmak yerine ana sayfaya dönsün (bkz. [popOrHome]).
    return PopScope(
      canPop: canPopRoute(context),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) popOrHome(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(plan.titleKey.tr()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            onPressed: () => popOrHome(context),
          ),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          left: false,
          right: false,
          child: days.when(
            loading: () => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'plans.loadFailed'.tr(),
              message: '$error',
            ),
            data: (list) {
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'home.noContent'.tr(),
                  message: 'plans.needsContent'.tr(),
                );
              }

              return ListView.separated(
                padding: centeredContentPadding(
                  context,
                  bottom: MediaQuery.paddingOf(context).bottom + Insets.lg,
                ),
                itemCount: list.length + 1,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: theme.dividerColor),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _PlanSummary(
                      plan: plan,
                      completedDays: completed,
                      schedule: schedule,
                      onRestart: () => _confirmRestart(context, ref),
                      streak: streak,
                      completions: completions,
                    );
                  }

                  final day = list[index - 1];
                  return _DayRow(
                    day: day,
                    onToggle: () => ref
                        .read(planActionsProvider)
                        .toggleDay(planId, day.index, day.isCompleted),
                    onOpen: () => _openDay(context, ref, day),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// Günün okuma ekranını açar.
  ///
  /// Surenin tamamı değil yalnızca o günün aralığı gösterilir; sonuna
  /// gelindiğinde sıradaki güne geçilir.
  void _openDay(BuildContext context, WidgetRef ref, PlanDay day) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlanReaderScreen(planId: planId, dayIndex: day.index),
      ),
    );
  }

  /// "Bugünden devam et" için onay ister.
  ///
  /// Eylem geri alınamaz (eski başlangıç tarihi kaybolur) ve kullanıcı
  /// "ilerlemem silinecek mi" diye tereddüt eder; onay metni bu soruyu
  /// açıkça yanıtlar. Yıkıcı bir eylem olmadığı için kırmızı renk
  /// kullanılmaz — burada vurgulanan şey kayıp değil, devam etme.
  Future<void> _confirmRestart(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('plans.restartTitle'.tr()),
        content: Text('plans.restartMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('plans.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('plans.restartConfirm'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(planActionsProvider).restartFromToday(planId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('plans.restartDone'.tr())));
  }
}

/// Planın üstündeki özet: yüzde, kalan gün ve takvim durumu.
class _PlanSummary extends StatelessWidget {
  const _PlanSummary({
    required this.plan,
    required this.completedDays,
    required this.schedule,
    required this.onRestart,
    required this.streak,
    required this.completions,
  });

  final ReadingPlan plan;
  final int completedDays;

  /// Plan hiç başlatılmadıysa null — o zaman takvim satırı hiç çizilmez ve
  /// özet eskisi gibi görünür.
  final PlanSchedule? schedule;

  final VoidCallback onRestart;

  /// Seri henüz yüklenmediyse null; o ana kadar hiç yer tutulmaz ki
  /// liste yükleme sırasında zıplamasın.
  final ReadingStreak? streak;

  final List<DateTime> completions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = (completedDays / plan.dayCount).clamp(0.0, 1.0);
    final remaining = plan.dayCount - completedDays;

    return Padding(
      padding: const EdgeInsets.only(top: Insets.xs, bottom: Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.descriptionKey.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.5,
            ),
          ),
          const SizedBox(height: Insets.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '%${(fraction * 100).round()}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: Insets.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  remaining == 0
                      ? 'plans.completed'.tr()
                      : 'plans.daysLeft'.tr(args: ['$remaining']),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          if (schedule case final s?) ...[
            const SizedBox(height: Insets.sm),
            _ScheduleRow(schedule: s, onRestart: onRestart),
          ],
          if (streak case final st?) ...[
            const SizedBox(height: Insets.md),
            StreakSummary(streak: st),
          ],
        ],
      ),
    );
  }
}

/// Takvim satırı: bugün kaçıncı gün, geride mi, gerekiyorsa telafi eylemi.
///
/// Kendi kartı ya da uyarı kutusu yok. Gecikme bir hata değil, bir durumdur;
/// çerçeveye alıp renklendirmek onu ekrandaki en yüksek sesli öge yapar ve
/// her açılışta kullanıcıyı azarlar. Bunun yerine ilerleme çubuğunun altında
/// sakin bir bilgi satırı olarak durur.
class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.schedule, required this.onRestart});

  final PlanSchedule schedule;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    // Plan süresi dolduysa "bugün 412. gün" demek anlamsızlaşır; o noktada
    // gün sayacı bilgi değil gürültüdür.
    final dayText = schedule.isPastEnd
        ? 'plans.planPeriodOver'.tr()
        : 'plans.todayNthDay'.tr(args: ['${schedule.currentDay}']);

    return Row(
      children: [
        Icon(Icons.event_available_outlined, size: 15, color: muted),
        const SizedBox(width: Insets.xxs + 2),
        Flexible(
          child: Text(
            dayText,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Öndelik ayrıca vurgulanmaz: takvimin önünde olmak bir başarı
        // rozeti değil, planın zaten beklediği şeydir. Yalnızca gecikme
        // gösterilir, çünkü yalnızca o bir eylem gerektirir.
        if (schedule.isBehind) ...[
          _Dot(color: muted),
          Flexible(
            child: Text(
              'plans.daysBehind'.tr(args: ['${schedule.daysBehind}']),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        const Spacer(),
        if (schedule.isBehind)
          Pressable(
            onTap: onRestart,
            scale: 0.96,
            hapticOnTap: true,
            child: Padding(
              // Metin düğmesinin dokunma hedefi görsel sınırından büyük
              // olsun diye dolgu verilir; 44pt kuralı.
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.xxs,
                vertical: Insets.xs,
              ),
              child: Text(
                'plans.restartFromToday'.tr(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Bilgi parçalarını ayıran orta nokta.
class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.xs),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Plan günü satırı. Onay kutusu tamamlama, satırın kalanı okumaya gider.
class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.onToggle,
    required this.onOpen,
  });

  final PlanDay day;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xs),
      child: Row(
        children: [
          // Onay kutusu ayrı bir dokunma hedefi; 44pt kuralına uyması için
          // ikonun etrafına dolgu verilir.
          Pressable(
            onTap: onToggle,
            scale: 0.85,
            hapticOnTap: true,
            child: Padding(
              padding: const EdgeInsets.all(Insets.xs),
              child: AnimatedContainer(
                duration: Motion.fast,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: day.isCompleted
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: day.isCompleted
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                    width: 1.5,
                  ),
                ),
                child: day.isCompleted
                    ? Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: theme.colorScheme.onPrimary,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: Insets.xs),

          Expanded(
            child: Pressable(
              onTap: onOpen,
              scale: 0.99,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Insets.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'plans.nthDay'.tr(args: ['${day.index}']),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: day.isCompleted
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                      ),
                    ),
                    Text(
                      day.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: day.isCompleted
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                            : theme.colorScheme.onSurface,
                        decoration: day.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}
