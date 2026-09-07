import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/pressable.dart';
import '../providers/home_provider.dart';

/// "Kaldığın yerden devam et" kartı.
///
/// Ekranın en üstünde durur çünkü geri dönen kullanıcının ilk isteyeceği şey
/// budur. Kullanıcı hiç okumadıysa kart hiç çizilmez — boş bir yer tutucu
/// göstermek ekranı yorar.
class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({
    super.key,
    required this.lastRead,
    required this.onTap,
  });

  final LastRead lastRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Insets.sm + 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Künye ile oynatma düğmesi tek satırda.
            //
            // Önceki düzende etiket, sure adı ve ayet bilgisi alt alta üç
            // satır tutuyor ve kart ekranın üçte birini yiyordu. Bilgi aynı,
            // yalnızca yatay eksene yayıldı: "KALDIĞIN YER" etiketi sure
            // adının üstünde küçük bir üst satır, ilerleme sayısı da onun
            // yanında. Sağdaki yuvarlak düğme kartın ne işe yaradığını
            // etiketten daha hızlı anlatıyor.
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'home.lastRead'.tr(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.7,
                          ),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lastRead.surah.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      Text(
                        '${lastRead.ayahNumber}. ayet · '
                        '${lastRead.surah.ayahCount} ayetten',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Insets.sm),
                // Devam etme eylemi. Kartın tamamı zaten dokunulabilir;
                // düğme görsel bir işaret, ayrı bir hedef değil.
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 22,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.pill),
              child: LinearProgressIndicator(
                value: lastRead.fraction,
                minHeight: 3,
                backgroundColor:
                    theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(
                  theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Günün ayeti kartı.
///
/// Metin üç satırda kesilir; tam metin için kullanıcı karta dokunup ayete
/// gider. Kartın kendisi uzun bir ayeti tam gösterseydi ekranın ritmi bozulur,
/// altındaki sure listesi görünmez olurdu.
class AyahOfTheDayCard extends StatelessWidget {
  const AyahOfTheDayCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  final AyahWithSurah data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: theme.dividerColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'home.verseOfDay'.tr(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: Insets.xs),
            Text(
              data.ayah.translationFor(context.locale.languageCode),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.reading(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
                height: 1.55,
              ),
            ),
            const SizedBox(height: Insets.xs),
            Text(
              '${data.surah.name} · ${data.ayah.numberLabel}. ayet',
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sıralama değiştirme düğmesi.
///
/// Bu uygulamanın kimliği kronolojik okuma olduğu için sıralama ayarlar
/// ekranına gömülmez; liste başlığının yanında, tek dokunuşla erişilir.
class OrderToggle extends StatelessWidget {
  const OrderToggle({
    super.key,
    required this.showRevelationOrder,
    required this.onChanged,
  });

  final bool showRevelationOrder;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: () => onChanged(!showRevelationOrder),
      scale: 0.95,
      hapticOnTap: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_vert_rounded,
              size: 15,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              showRevelationOrder ? 'home.orderRevelation'.tr() : 'home.orderMushaf'.tr(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
