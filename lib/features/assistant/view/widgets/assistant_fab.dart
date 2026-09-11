import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';

/// Asistanı açan yüzen düğme.
///
/// Asistan bir sekme değil: kullanıcı oraya "gitmez", okuduğu ya da aradığı
/// şeyin üstüne bir soru sorar ve geri döner. Sekme çubuğundaki bir yuva
/// bunu varış noktası gibi gösterirdi; yüzen düğme araya giren yardımcı
/// olduğunu söylüyor — ve altı sekmeyle sıkışan çubuğu beşe indirdi.
///
/// Her ekranda görünür, okuma ekranı dahil. Orada metnin üstünde durur ama
/// [bottomOffset] ile tilavet çubuğunun üstüne alınabilir; ayet kartlarının
/// son satırını örtmemesi için çağıran ekran bu payı verir.
class AssistantFab extends StatelessWidget {
  const AssistantFab({super.key, this.bottomOffset = 0});

  /// Düğmenin normal yerinden ne kadar yukarı alınacağı.
  ///
  /// Tilavet çubuğu ya da başka bir alt şerit varken verilir; sıfırsa düğme
  /// güvenli alanın hemen üstünde durur.
  final double bottomOffset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Tilavet çubuğu kayarak girip çıkıyor; düğme aynı süre ve eğriyle
    // birlikte kayar. Anlık sıçrasaydı çubuk daha yerine oturmadan düğme
    // yukarıda belirir, iki ayrı hareket gibi okunurdu.
    return AnimatedPadding(
      duration: Motion.normal,
      curve: Motion.standard,
      padding: EdgeInsets.only(bottom: bottomOffset),
      child: FloatingActionButton(
        onPressed: () => context.push('/asistan'),
        tooltip: 'assistant.title'.tr(),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        // Yükseklik düşük tutuldu: uygulamanın geri kalanı düz yüzeylerle
        // kurulu, belirgin bir gölge yabancı dururdu.
        elevation: 2,
        highlightElevation: 4,
        child: const Icon(Icons.auto_awesome_rounded, size: 22),
      ),
    );
  }
}
