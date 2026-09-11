import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/prophet.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../reader/view/reader_screen.dart';
import '../widgets/topic_app_bar.dart';

/// Kıssası anlatılan peygamberlerin listesi.
///
/// Bu ekran bir boşluğu kapatıyor: `/kissa/:id` rotası vardı ama ona giden
/// gezilebilir bir yol yoktu. Kıssalara yalnızca arama kutusuna bir peygamber
/// adı yazınca beliren karttan ulaşılabiliyordu, yani adı bilmeyen kullanıcı
/// o ekranları hiç görmüyordu.
///
/// Sıra veri dosyasındaki sıradır — Kur'an anlatısındaki geleneksel sıralama,
/// Âdem'den Muhammed'e. Alfabetik dizmek o anlamı silerdi.
class ProphetsScreen extends ConsumerWidget {
  const ProphetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(prophetDataProvider);

    return Scaffold(
      body: PopScope(
        canPop: canPopRoute(context),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) popOrHome(context);
        },
        child: SafeArea(
          bottom: false,
          child: asyncData.when(
            loading: () => const Center(child: CupertinoStyleLoader()),
            error: (error, _) => EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'prophets.loadFailed'.tr(),
              message: '$error',
            ),
            data: (repo) => _Body(prophets: repo.all),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.prophets});

  final List<Prophet> prophets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.locale.languageCode;

    return Column(
      children: [
        TopicAppBar(title: 'discover.prophetsTitle'.tr()),
        Expanded(
          child: ListView.separated(
            padding: centeredContentPadding(
              context,
              maxWidth: ContentWidth.reading,
              top: Insets.xs,
              bottom: MediaQuery.paddingOf(context).bottom + Insets.xl,
            ),
            itemCount: prophets.length + 1,
            separatorBuilder: (_, index) => index == 0
                ? const SizedBox.shrink()
                : Divider(height: 1, color: theme.dividerColor),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(
                    top: Insets.md,
                    bottom: Insets.md,
                  ),
                  child: Text(
                    'prophets.chronologicalNote'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                );
              }

              final prophet = prophets[index - 1];
              return Pressable(
                onTap: () => context.push('/kissa/${prophet.id}'),
                scale: 0.99,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          prophet.nameFor(lang),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      Text(
                        'discover.ayahCount'.tr(args: ['${prophet.ayahCount}']),
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(width: Insets.xs),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
