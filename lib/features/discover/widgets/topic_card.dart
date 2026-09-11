import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/topic.dart';
import '../../../shared/widgets/pressable.dart';

/// Fihrist ızgarasındaki konu kartı.
///
/// Kart, düz liste satırının yerini aldı. Elli altı konu aynı gri satırda
/// dizildiğinde göz tutunacak yer bulamıyor ve liste bir "içindekiler"
/// sayfasına dönüşüyordu; fihrist ise gezilecek bir yer olmalı.
///
/// KATMANLAR
/// ---------
/// Altta konunun görseli, üstünde bölüm renginde bir perde, en üstte metin.
/// Perde iki iş yapıyor: görseller ayrı ayrı üretildiği için tonları
/// tutmuyor ve perde onları tek bir sisteme bağlıyor; ayrıca metnin
/// üzerindeki zemini öngörülebilir kılıyor — perdesiz bir kartta açık
/// renkli bir görselin üstünde beyaz başlık kayboluyordu.
///
/// Renk bölümden gelir, konudan değil. Aynı bölümün konuları aynı rengi
/// paylaşır: kullanıcı "Ahiret" kartlarını okumadan, mor tonundan tanır.
class TopicCard extends StatelessWidget {
  const TopicCard({super.key, required this.topic, required this.onTap});

  final Topic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.locale.languageCode;
    final isDark = theme.brightness == Brightness.dark;
    final color = AppColors.topicColor(topic.categoryId, isDark: isDark);

    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Görsel kartı doldurur; kare üretildiği için karttan taşan
            // kısım kırpılır. Hizalama sağa verildi: metin solda duruyor ve
            // görselin asıl içeriği sağda görünür kalmalı.
            Image.asset(
              'assets/images/topics/${topic.id}.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              // Görsel eksikse kart düz renge düşer ve okunur kalır. Bir
              // dosya adı hatası yüzünden kırmızı hata kutusu göstermek,
              // fihristin tamamını kullanılmaz hâle getirirdi.
              errorBuilder: (_, _, _) => ColoredBox(color: color),
            ),

            // Bölüm perdesi: görselleri tek palete bağlar.
            ColoredBox(color: color.withValues(alpha: 0.62)),

            // Metnin arkasını koyulaştıran gradyan. Soldan sağa açılır,
            // çünkü başlık ve sayaç solda hizalı.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(Insets.sm + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    topic.nameFor(lang),
                    style: theme.textTheme.titleSmall?.copyWith(
                      // Renkli zeminde tema mürekkebi yerine sabit açık ton:
                      // kartlar açık temada da koyu zeminli ve oradaki koyu
                      // mürekkep okunmuyordu.
                      color: Colors.white,
                      height: 1.25,
                      shadows: const [
                        Shadow(blurRadius: 8, color: Colors.black54),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    'discover.ayahCount'.tr(args: ['${topic.ayahCount}']),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 0,
                      shadows: const [
                        Shadow(blurRadius: 6, color: Colors.black45),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
