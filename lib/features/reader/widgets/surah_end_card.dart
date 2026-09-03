import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../data/models/surah.dart';
import '../../../shared/widgets/pressable.dart';

/// Sure bittiğinde listenin sonunda görünen geçiş kartı.
///
/// Amaç okuma akışını sürdürmek: kullanıcı sure sonuna geldiğinde listeye
/// geri dönüp yeni sure aramak zorunda kalmasın. Kart iki yolla çalışır —
/// dokunarak ya da kaydırmaya devam ederek (bkz. okuma ekranındaki eşik
/// mekaniği).
///
/// [nextSurah] null ise (mushaf/iniş sırasının son suresi) geçiş yerine
/// tamamlama mesajı gösterilir.
class SurahEndCard extends StatelessWidget {
  const SurahEndCard({
    super.key,
    required this.current,
    required this.nextSurah,
    required this.showRevelationOrder,
    required this.onTap,
    this.pullProgress = 0,
  });

  /// Yeni bitirilen sure.
  final Surah current;

  /// Sıradaki sure. Son surede null.
  final Surah? nextSurah;

  /// Aktif sıralama — kartta hangi sıra numarasının gösterileceğini belirler.
  final bool showRevelationOrder;

  final VoidCallback onTap;

  /// Kaydırarak geçişin ilerlemesi (0–1).
  ///
  /// Kullanıcı sure sonunda kaydırmayı sürdürdükçe artar; 1'e ulaştığında
  /// geçiş tetiklenir. Kart bu değeri görsel geri bildirime çevirir: halka
  /// dolar ve ok yukarı kayar, böylece kullanıcı ne kadar çekmesi
  /// gerektiğini görür.
  final double pullProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = nextSurah;
    final lang = context.locale.languageCode;

    return Padding(
      padding: const EdgeInsets.only(top: Insets.lg),
      child: Column(
        children: [
          // Sure sonu işareti — ince bir ayraç ve künye.
          Row(
            children: [
              Expanded(child: Divider(color: theme.dividerColor, height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
                child: Text(
                  'reader.surahFinished'.tr(args: [current.nameFor(lang)]),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Expanded(child: Divider(color: theme.dividerColor, height: 1)),
            ],
          ),
          const SizedBox(height: Insets.lg),

          if (next == null)
            _CompletionNote(showRevelationOrder: showRevelationOrder)
          else
            _NextSurahTile(
              next: next,
              lang: lang,
              showRevelationOrder: showRevelationOrder,
              pullProgress: pullProgress,
              onTap: onTap,
            ),
        ],
      ),
    );
  }
}

/// Sıradaki sureye geçiş kartı.
class _NextSurahTile extends StatelessWidget {
  const _NextSurahTile({
    required this.next,
    required this.lang,
    required this.showRevelationOrder,
    required this.pullProgress,
    required this.onTap,
  });

  final Surah next;
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
                    'reader.next'.tr(),
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
                    next.nameFor(lang),
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
              Icons.arrow_forward_rounded,
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
        ? 'home.revealedNth'.tr(args: ['${next.revelationOrder}'])
        : 'home.mushafNth'.tr(args: ['${next.number}']);
    final count = 'common.verseCount'.tr(args: ['${next.ayahCount}']);
    return '${next.meaningFor(lang)} · $order · $count';
  }
}

/// Kaydırma ilerlemesini gösteren halka.
///
/// Dolmamışken ince bir çember ve aşağı ok; dolduğunda içi dolu bir daire
/// ve ileri oku olur. Yüzde metni gösterilmez — hareketin kendisi zaten
/// ne kadar kaldığını anlatır.
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
                  : Icons.keyboard_arrow_up_rounded,
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

/// Son sureye gelindiğinde gösterilen tamamlama notu.
class _CompletionNote extends StatelessWidget {
  const _CompletionNote({required this.showRevelationOrder});

  final bool showRevelationOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.sm,
      ),
      child: Column(
        children: [
          Icon(
            Icons.done_all_rounded,
            size: 28,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: Insets.xs),
          Text(
            showRevelationOrder
                ? 'reader.completedRevelation'.tr()
                : 'reader.completedMushaf'.tr(),
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
