import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../onboarding/providers/tour_provider.dart';

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
///
/// [hideDuringTour] verilirse o tur açıkken düğme gizlenir. Tur karartması
/// [Overlay]'de yaşıyor ama sekmeli kabuğun düğmesi o katmanın dışında
/// çizildiği için karartmanın üstünde parlak kalıyor ve baloncuğun
/// düğmelerine biniyordu. Gizlemek yalnızca çakışmayı çözmüyor: tur tek bir
/// şeye odaklanmak için var, basılabilir bir düğmenin kullanıcıyı asistana
/// götürmesi onu yarıda keserdi.
class AssistantFab extends ConsumerWidget {
  const AssistantFab({super.key, this.bottomOffset = 0, this.hideDuringTour});

  /// Düğmenin normal yerinden ne kadar yukarı alınacağı.
  ///
  /// Tilavet çubuğu ya da başka bir alt şerit varken verilir; sıfırsa düğme
  /// güvenli alanın hemen üstünde durur.
  final double bottomOffset;

  /// Açıkken düğmenin gizleneceği tur.
  ///
  /// Ekranın *kendi* turu verilir, "herhangi bir tur" değil: "ipuçlarını
  /// tekrar göster" bütün turları sıfırlıyor ve görünmeyen sekmelerin
  /// katmanları açık kalabiliyor. Genel bir bayrak dinlenseydi kullanıcı
  /// ayarlardayken bile düğme kayıp görünürdü.
  final TourId? hideDuringTour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tour = hideDuringTour;
    final isTourActive =
        tour != null && ref.watch(isTourActiveProvider(tour));

    final fab = FloatingActionButton(
      onPressed: () => context.push('/asistan'),
      tooltip: 'assistant.title'.tr(),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      // Yükseklik düşük tutuldu: uygulamanın geri kalanı düz yüzeylerle
      // kurulu, belirgin bir gölge yabancı dururdu.
      elevation: 2,
      highlightElevation: 4,
      child: const Icon(Icons.auto_awesome_rounded, size: 22),
    );

    // Tur boyunca düğme solarak çekilir; anlık kaybolsaydı karartma açılırken
    // ekranda bir şey söndürülmüş gibi görünürdü. Saydamken dokunuşlara da
    // kapatılır: görünmeyen bir düğme basılabilir kalmamalı.
    return IgnorePointer(
      ignoring: isTourActive,
      child: AnimatedOpacity(
        opacity: isTourActive ? 0 : 1,
        duration: Motion.fast,
        curve: Motion.standard,
        // Tilavet çubuğu kayarak girip çıkıyor; düğme aynı süre ve eğriyle
        // birlikte kayar. Anlık sıçrasaydı çubuk daha yerine oturmadan düğme
        // yukarıda belirir, iki ayrı hareket gibi okunurdu.
        child: AnimatedPadding(
          duration: Motion.normal,
          curve: Motion.standard,
          padding: EdgeInsets.only(bottom: bottomOffset),
          child: fab,
        ),
      ),
    );
  }
}
