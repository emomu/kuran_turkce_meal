import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/accent_banner.dart';
import '../providers/review_prompt.dart';

/// Ayarlarda destek kartının altındaki puan daveti.
///
/// Destek kartıyla aynı biçimde, altın renginde: ikisi de uygulamaya katkının
/// yolları, renk farkı da hangisinin para hangisinin puan olduğunu ayırır.
class RateBanner extends StatelessWidget {
  const RateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AccentBanner(
      accent: isDark ? AppColors.goldDark : AppColors.goldLight,
      icon: Icons.star_outline_rounded,
      title: 'settings.rateApp'.tr(),
      body: 'settings.rateAppHint'.tr(),
      onTap: openStoreListing,
    );
  }
}
