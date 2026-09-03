import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';

/// Boş liste durumları için ortak görünüm.
///
/// Metinler bilerek kısa ve yönlendirici: kullanıcıya ne olduğunu değil ne
/// yapabileceğini söyler.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: Insets.md),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Insets.xs),
            Text(
              message,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: Insets.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
