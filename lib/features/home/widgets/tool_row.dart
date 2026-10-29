import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';

/// Günün ayeti kartının eteğindeki araç satırı.
///
/// Kıble, kıssalar ve kök analizi kendi ekranlarında yaşar; burada yalnızca
/// kısa yolları durur. Ayrı bir kart olarak değil kartın içinde duruyorlar
/// çünkü ana ekranın dikey yığını zaten doluydu: kaldığın yer, günün ayeti,
/// bağış kartı ve liste başlığından sonra sure listesi ekranın dışına
/// taşıyordu.
///
/// Keşfet sekmesi de bu araçları barındırır; oradaki girişler kaldırılmadı.
/// Ana ekran kullanıcının en sık açtığı yer, buradaki satır tekrar değil
/// kısa yoldur.
class ToolRow extends StatelessWidget {
  const ToolRow({super.key});

  @override
  Widget build(BuildContext context) {
    const tools = [
      _Tool(
        icon: Icons.explore_outlined,
        labelKey: 'qibla.title',
        route: '/kible',
      ),
      _Tool(
        icon: Icons.auto_stories_outlined,
        labelKey: 'discover.prophetsTitle',
        route: '/kissalar',
      ),
      _Tool(
        icon: Icons.account_tree_outlined,
        labelKey: 'roots.title',
        route: '/kokler',
      ),
    ];

    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        children: [
          for (final tool in tools) ...[
            Expanded(child: _ToolButton(tool: tool)),
            // Araçlar arasına ince ayraç: üç dokunma alanı yan yana
            // olduğu için nerede bittiği görünsün.
            if (tool != tools.last)
              VerticalDivider(width: 1, color: theme.dividerColor),
          ],
        ],
      ),
    );
  }
}

/// Araç satırının kendi kart çerçevesindeki hali.
///
/// Günün ayeti yüklenemediğinde kullanılır: araçlar normalde o kartın
/// eteğinde durur, kart çizilmeyince kendi çerçevesine ihtiyaç duyarlar.
/// Aksi halde ekranda çerçevesiz, havada duran bir satır kalırdı.
class ToolCard extends StatelessWidget {
  const ToolCard({super.key});

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
      child: const ToolRow(),
    );
  }
}

/// Satırdaki tek bir aracın tanımı.
class _Tool {
  const _Tool({
    required this.icon,
    required this.labelKey,
    required this.route,
  });

  final IconData icon;
  final String labelKey;
  final String route;
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.tool});

  final _Tool tool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // InkWell kullanılır: kartın içindeki bir satır büyüyüp küçülmemeli,
    // dokunma geri bildirimi dalga olarak verilir.
    return InkWell(
      onTap: () => context.push(tool.route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tool.icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 3),
            Text(
              tool.labelKey.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
