import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/pressable.dart';
import '../providers/donation_provider.dart';

/// Ana ekranda arada bir çıkan bağış hatırlatması.
///
/// Kart, uygulamayı bir süredir kullanan kullanıcıya gösterilir (eşikler
/// [DonationThresholds] içinde). Kapatılabilir ve kapatıldığında uzun süre
/// geri gelmez — hatırlatmanın rahatsız etmemesi için tek yol, ısrar
/// etmemek.
///
/// Görsel olarak "devam et" ve "günün ayeti" kartlarından bilerek daha
/// sessiz: kenarlıklı, düz zeminli, vurgu rengini yalnızca ikonda kullanır.
/// Bağış isteği ekranın en dikkat çeken öğesi olmamalı.
class DonationCard extends ConsumerWidget {
  const DonationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(donationProvider.notifier);

    return Pressable(
      onTap: () => context.push('/destek'),
      scale: 0.99,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          Insets.sm + 2,
          Insets.sm,
          Insets.xs,
          Insets.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volunteer_activism_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'donate.cardTitle'.tr(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'donate.cardBody'.tr(),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // Kapatma kartın kendi dokunma alanının içinde ayrı bir düğme;
            // kullanıcı hatırlatmayı ekrandan tek dokunuşla kaldırabilmeli.
            IconButton(
              onPressed: () {
                notifier.dismissCard();
                ref.invalidate(showDonationCardProvider);
              },
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              tooltip: 'donate.dismiss'.tr(),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
