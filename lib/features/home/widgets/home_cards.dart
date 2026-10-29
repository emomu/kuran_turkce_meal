import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/pressable.dart';
import '../providers/home_provider.dart';
import 'tool_row.dart';

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
            // Bütün künye tek satırda: sure adı ve kaçıncı ayette
            // kalındığı yan yana.
            //
            // Daha önce "KALDIĞIN YER" etiketi, sure adı ve ayet bilgisi
            // alt alta üç satırdı; kart ana ekranın en büyük öğesiydi ve
            // sure listesi ekranın dışına taşıyordu. Etiket kaldırıldı:
            // yeşil zemin, ilerleme çubuğu ve oynat düğmesi kartın ne
            // olduğunu zaten söylüyor, üstelik kart her zaman aynı yerde
            // duruyor.
            Row(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      // Kartın ne olduğunu söyleyen rozet.
                      //
                      // Üstte ayrı bir "KALDIĞIN YER" satırı vardı ve kart
                      // bir satır uzuyordu. Rozet aynı işi sure adının
                      // yanında görür: yeşil zemin ve oynat düğmesi tek
                      // başına "dinle" gibi okunabiliyordu, oysa kart
                      // okumaya götürür.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.22,
                          ),
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: Text(
                          'home.resumeBadge'.tr(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: Insets.xs),
                      Flexible(
                        child: Text(
                          lastRead.surah.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: Insets.xs),
                      // Ayet bilgisi sure adının yanında ve soluk: adı
                      // okumayı bölmeden, bakınca görülecek yerde.
                      Text(
                        '${lastRead.ayahNumber}/${lastRead.surah.ayahCount}',
                        maxLines: 1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.7,
                          ),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Insets.sm),
                // Devam etme eylemi. Kartın tamamı zaten dokunulabilir;
                // düğme görsel bir işaret, ayrı bir hedef değil.
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 20,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.xs),
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      // Kart iki bölümden oluşur ve her birinin kendi dokunma alanı
      // vardır: ayet metni sureye götürür, alttaki araçlar kendi
      // ekranlarına. Tek bir Pressable sarılsaydı araçlara dokunmak da
      // sureyi açardı.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pressable(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.lg),
            child: Padding(
              padding: const EdgeInsets.all(Insets.md),
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
                    // İki satır: üç satırken kart tek başına ekranın
                    // dörtte birini kaplıyordu ve sure listesi görünmüyordu.
                    // Kesilen ayet zaten dokunulunca tam açılır.
                    maxLines: 2,
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
          ),

          Divider(height: 1, color: theme.dividerColor),

          // Araçlar kartın eteğinde: ayrı bir blok olarak durmaları
          // ekranda bir kart daha demekti ve sure listesi büsbütün
          // aşağı kaçıyordu.
          const ToolRow(),
        ],
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
