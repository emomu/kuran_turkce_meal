import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/pressable.dart';

/// Fihristi bölüme göre daraltan çip şeridi.
///
/// Izgaranın üstünde durur ve bölüm başlıklarının yerini alır. Sekiz bölüm
/// alt alta başlık olarak dizildiğinde ekranın yarısı başlıktı ve kullanıcı
/// "Ahiret"i görmek için beş bölüm kaydırmak zorundaydı; çip şeridi aynı
/// gezinmeyi tek dokunuşa indiriyor.
///
/// Seçim tek: iki bölümü birlikte görmek isteyen kullanıcı zaten "Tümü"ne
/// basar. Çoklu seçim, karşılığı olmayan bir karmaşıklık olurdu.
class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// Çip etiketleri. İlki "Tümü" olmalı; seçili olmadığında ona düşülür.
  final List<String> labels;

  /// Seçili çipin sırası. 0 "Tümü" demektir.
  final int selectedIndex;

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Şerit kenardan başlar ve kenarda biter: ilk çipin solunda boşluk
        // bırakmak onu hizadan düşürürdü, dolgu listeyi saran tarafta.
        padding: EdgeInsets.zero,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: Insets.xs),
        itemBuilder: (context, i) {
          final isSelected = i == selectedIndex;

          return Pressable(
            onTap: () => onSelected(i),
            borderRadius: BorderRadius.circular(Radii.pill),
            scale: 0.95,
            child: AnimatedContainer(
              duration: Motion.fast,
              curve: Motion.standard,
              padding: const EdgeInsets.symmetric(horizontal: Insets.sm + 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text(
                labels[i],
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
