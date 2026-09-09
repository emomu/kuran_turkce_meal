import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/pressable.dart';
import '../providers/donation_provider.dart';

/// Ayarların en üstündeki destek daveti.
///
/// Ana ekrandaki [DonationCard]'dan farklı bir iş görür ve farklı görünür:
/// o kart arada bir çıkıp kaybolan bir hatırlatma, bu ise ayarlarda her zaman
/// duran kalıcı bir giriş. Kullanıcı "acaba nasıl destek olabilirim" diye
/// aradığında bulacağı yer burası, o yüzden ertelenmez ve kapatılmaz.
///
/// Vurgu rengiyle dolu bir yüzey kullanır — ayarlar listesindeki nötr gri
/// grupların arasında ilk göze çarpan öğe olsun diye. Ekranın geri kalanı
/// zaten sessiz; tek bir renkli blok sayfayı gürültülü yapmaz.
class SupportBanner extends ConsumerWidget {
  const SupportBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final hasDonated = ref.watch(
      donationProvider.select((s) => s.hasDonated),
    );

    return Pressable(
      onTap: () => context.push('/destek'),
      scale: 0.99,
      child: Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          // Düz renk yerine çok hafif bir geçiş: yüzeye derinlik verir ama
          // metnin kontrastını bozacak kadar koyulaşmaz.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.14),
              accent.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(
            color: accent.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                // Bağış yapmış kullanıcıya dolu kalp: sessiz bir teşekkür.
                hasDonated
                    ? Icons.favorite_rounded
                    : Icons.volunteer_activism_outlined,
                size: 21,
                color: accent,
              ),
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasDonated
                        ? 'donate.bannerTitleDonated'.tr()
                        : 'donate.bannerTitle'.tr(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDonated
                        ? 'donate.bannerBodyDonated'.tr()
                        : 'donate.bannerBody'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Insets.xs),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: accent.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
