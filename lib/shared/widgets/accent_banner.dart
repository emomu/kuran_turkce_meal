import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import 'pressable.dart';

/// Ayarların en üstündeki renkli davet kartı.
///
/// Destek ve puan kartları aynı biçimi paylaşır, yalnızca rengi ve metni
/// farklıdır. Ayarlar listesindeki nötr gri grupların arasında ilk göze
/// çarpan öğeler olsunlar diye vurgu rengiyle dolu bir yüzey kullanırlar.
class AccentBanner extends StatelessWidget {
  const AccentBanner({
    super.key,
    required this.accent,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          // Düz renk yerine çok hafif bir geçiş: yüzeye derinlik verir ama
          // metnin kontrastını bozacak kadar koyulaşmaz.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.14),
              accent.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(
            color: accent.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 21, color: accent),
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Insets.xs),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: accent.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
