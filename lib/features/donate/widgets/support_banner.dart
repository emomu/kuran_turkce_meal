import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/accent_banner.dart';
import '../providers/donation_provider.dart';

/// Ayarların en üstündeki destek daveti.
///
/// Ana ekrandaki [DonationCard]'dan farklı bir iş görür ve farklı görünür:
/// o kart arada bir çıkıp kaybolan bir hatırlatma, bu ise ayarlarda her zaman
/// duran kalıcı bir giriş. Kullanıcı "acaba nasıl destek olabilirim" diye
/// aradığında bulacağı yer burası, o yüzden ertelenmez ve kapatılmaz.
class SupportBanner extends ConsumerWidget {
  const SupportBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasDonated = ref.watch(
      donationProvider.select((s) => s.hasDonated),
    );

    return AccentBanner(
      accent: Theme.of(context).colorScheme.primary,
      // Bağış yapmış kullanıcıya dolu kalp: sessiz bir teşekkür.
      icon: hasDonated
          ? Icons.favorite_rounded
          : Icons.volunteer_activism_outlined,
      title: hasDonated
          ? 'donate.bannerTitleDonated'.tr()
          : 'donate.bannerTitle'.tr(),
      body: hasDonated
          ? 'donate.bannerBodyDonated'.tr()
          : 'donate.bannerBody'.tr(),
      onTap: () => context.push('/destek'),
    );
  }
}
