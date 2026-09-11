import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/pressable.dart';

/// Keşfet ekranının üstündeki giriş kartı.
///
/// Konu kartlarından ayrı bir yüzeyde durur ve bu bilinçli: ızgaradaki
/// kartlar aynı türden şeyleri (konular) gösterir, bunlar ise uygulamanın
/// ayrı bölümlerine açılır. Aynı görünselerdi kullanıcı "Kökler"i bir konu
/// sanırdı — renk yerine nötr yüzey kullanılmasının sebebi bu.
///
/// DÜZEN
/// -----
/// Sayı en büyük öğe. Kart bir kapıdan ibaret değil, arkasında ne kadar şey
/// olduğunu da söylüyor: "25 peygamber" bilgisi kullanıcının oraya girip
/// girmeme kararını başlıktan daha çok etkiliyor.
///
/// Üç satır: ikon + ad, sayı, açıklama. Önceki iki satırlık düzende ad ve
/// açıklama yan yana sığmıyor ve ikisi de üç noktayla kesiliyordu.
class DiscoverEntryCard extends StatelessWidget {
  const DiscoverEntryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.count,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;

  /// Bölümün adı. Tek satırda sığacak kadar kısa olmalı ("Kıssalar").
  final String title;

  /// Kartın taşıdığı sayı ("25 peygamber").
  ///
  /// Boş verilebilir: veri yüklenene kadar boştur ve o aralıkta kart
  /// yüksekliği değişmesin diye satır yine de çizilir.
  final String count;

  /// Tek satırlık açıklama ("İniş sırasına göre").
  final String hint;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: Container(
        padding: const EdgeInsets.all(Insets.sm + 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 17, color: theme.colorScheme.primary),
                const SizedBox(width: Insets.xxs + 2),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.xs),
            // Sayı kartın ağırlık merkezi. Yükseklik sıkılaştırıldı: varsayılan
            // satır aralığı bu boyutta üstte ve altta ölü boşluk bırakıyor.
            Text(
              count,
              style: theme.textTheme.titleMedium?.copyWith(height: 1.1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
