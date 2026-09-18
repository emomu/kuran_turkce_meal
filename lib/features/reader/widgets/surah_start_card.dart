import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../data/models/surah.dart';
import '../../../shared/widgets/pressable.dart';

/// Surenin başında listenin en üstünde görünen geri geçiş kartı.
///
/// [SurahEndCard]'ın aynası: o kart okuma akışını ileri sürdürür, bu kart
/// geri alır. Kullanıcı yanlış sureye girdiğinde ya da bir önceki sureye
/// dönmek istediğinde listeden çıkıp arama yapmak zorunda kalmasın diye
/// var. Kart iki yolla çalışır — dokunarak ya da yukarı kaydırmayı
/// sürdürerek (bkz. okuma ekranındaki eşik mekaniği).
///
/// [previousSurah] null ise (mushaf/iniş sırasının ilk suresi) kart hiç
/// çizilmez; okuma ekranı bu durumda kartı listeye eklemez.
class SurahStartCard extends StatelessWidget {
  const SurahStartCard({
    super.key,
    required this.previousSurah,
    required this.showRevelationOrder,
    required this.onTap,
    this.pullProgress = 0,
  });

  /// Bir önceki sure. İlk surede null.
  final Surah? previousSurah;

  /// Aktif sıralama — kartta hangi sıra numarasının gösterileceğini belirler.
  final bool showRevelationOrder;

  final VoidCallback onTap;

  /// Kaydırarak geçişin ilerlemesi (0–1).
  ///
  /// Kullanıcı sure başında yukarı kaydırmayı sürdürdükçe artar; 1'e
  /// ulaştığında geçiş tetiklenir.
  final double pullProgress;

  @override
  Widget build(BuildContext context) {
    final previous = previousSurah;
    if (previous == null) return const SizedBox.shrink();

    final lang = context.locale.languageCode;
    final progress = pullProgress.clamp(0.0, 1.0);

    // Kart, yukarı çekildikçe ortaya çıkar. Sürekli görünseydi sure
    // başlığının üstünde kalıcı bir kutu dururdu ve sureye girince ilk
    // görülen şey "önceki sure" olurdu; oysa kart geri dönmek isteyene
    // lazım, okumaya başlayana değil.
    //
    // Açılma çekme oranına bağlıdır, kendi animasyonu yoktur: kullanıcının
    // parmağı kartı açar, bırakınca kapanır. Araya bir süre girseydi kart
    // parmağın gerisinde kalır ve hareket ağırlaşırdı.
    return ClipRect(
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: progress,
        child: Opacity(
          // Son çeyrekte tam görünür olur: baştan sonuna soluk açılsaydı
          // kart çoğu zaman yarı saydam görünür ve arkasındaki metinle
          // karışırdı.
          opacity: (progress * 1.6).clamp(0.0, 1.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: Insets.lg),
            child: _PreviousSurahTile(
              previous: previous,
              lang: lang,
              showRevelationOrder: showRevelationOrder,
              pullProgress: pullProgress,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }
}

/// Önceki sureye geçiş kartı.
class _PreviousSurahTile extends StatelessWidget {
  const _PreviousSurahTile({
    required this.previous,
    required this.lang,
    required this.showRevelationOrder,
    required this.pullProgress,
    required this.onTap,
  });

  final Surah previous;
  final String lang;
  final bool showRevelationOrder;
  final double pullProgress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReady = pullProgress >= 1;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.standard,
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          // Eşiğe ulaşıldığında kart vurgu rengine döner; kullanıcı
          // parmağını kaldırdığında ne olacağını önceden görür.
          color: isReady
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(
            color: isReady ? theme.colorScheme.primary : theme.dividerColor,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            _PullIndicator(progress: pullProgress, isReady: isReady),
            const SizedBox(width: Insets.sm),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'reader.previous'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: isReady
                          ? theme.colorScheme.onPrimary
                              .withValues(alpha: 0.75)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    previous.nameFor(lang),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isReady ? theme.colorScheme.onPrimary : null,
                    ),
                  ),
                  Text(
                    _subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isReady
                          ? theme.colorScheme.onPrimary
                              .withValues(alpha: 0.75)
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: isReady
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  String get _subtitle {
    final order = showRevelationOrder
        ? 'home.revealedNth'.tr(args: ['${previous.revelationOrder}'])
        : 'home.mushafNth'.tr(args: ['${previous.number}']);
    final count = 'common.verseCount'.tr(args: ['${previous.ayahCount}']);
    return '${previous.meaningFor(lang)} · $order · $count';
  }
}

/// Kaydırma ilerlemesini gösteren halka.
///
/// [SurahEndCard]'ın göstergesiyle aynı dil; yalnızca ok aşağı bakar, çünkü
/// hareket yukarı kaydırma ile tetiklenir ve varış noktası listenin
/// yukarısındaki suredir.
class _PullIndicator extends StatelessWidget {
  const _PullIndicator({required this.progress, required this.isReady});

  final double progress;
  final bool isReady;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // İlerleme halkası. Kaydırma başlamadan görünmez durur.
          if (progress > 0 && !isReady)
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 2,
                backgroundColor: theme.colorScheme.surfaceContainer,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),

          AnimatedContainer(
            duration: Motion.fast,
            width: isReady ? 30 : 26,
            height: isReady ? 30 : 26,
            decoration: BoxDecoration(
              color: isReady
                  ? theme.colorScheme.onPrimary.withValues(alpha: 0.2)
                  : theme.colorScheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReady
                  ? Icons.check_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 17,
              color: isReady
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
