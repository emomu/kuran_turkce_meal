import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/user_marks.dart';
import '../../../shared/widgets/pressable.dart';
import '../share/ayah_share.dart';

/// Bir ayete uzun basıldığında açılan eylem yaprağı.
///
/// Eylemler sıklığa göre sıralanmıştır: renk vurgusu en üstte çünkü en sık
/// kullanılan ve en görsel eylem; yıkıcı olmayan eylemler ortada; paylaşma
/// ve kopyalama altta.
class AyahActionsSheet extends StatelessWidget {
  const AyahActionsSheet({
    super.key,
    required this.ayah,
    required this.surahName,
    required this.mark,
    required this.onToggleBookmark,
    required this.onSetHighlight,
    required this.onEditNote,
    required this.onAnalyseRoots,
  });

  final Ayah ayah;
  final String surahName;
  final AyahMark? mark;
  final VoidCallback onToggleBookmark;
  final ValueChanged<int?> onSetHighlight;
  final VoidCallback onEditNote;

  /// Ayetin kelimelerini kök çözümlemesiyle açar.
  final VoidCallback onAnalyseRoots;

  /// Kopyalama için biçimlenmiş metin.
  String _shareText(BuildContext context) => 'actions.shareFormat'.tr(
    namedArgs: {
      'text': ayah.translationFor(context.locale.languageCode),
      'surah': surahName,
      'verse': ayah.numberLabel,
    },
  );

  /// Ayeti görsel kart olarak paylaşır.
  ///
  /// Yaprak kapatılmadan önce gereken her şey okunur: kapandıktan sonra
  /// `context` artık ağaçta değil ve tema, dil, konum bilgisi alınamaz.
  /// Çizim ise kök katmanda yapılır, o yüzden yaprağın kapanması çizimi
  /// etkilemez.
  Future<void> _shareCard(BuildContext context) async {
    final languageCode = context.locale.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.of(context);
    final rootContext = Navigator.of(context, rootNavigator: true).context;

    // iPad'de paylaşım yaprağı bir noktadan açılmalı; verilmezse sistem
    // uyarı verir ve yaprak ekranın ortasında belirir.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    Navigator.of(context).pop();

    final rendered = await AyahShare.card(
      context: rootContext,
      ayah: ayah,
      surahName: surahName,
      languageCode: languageCode,
      isDark: isDark,
      // Arapça metin varsa karta da girer. Okuma ekranındaki "Arapça
      // göster" tercihine bağlanmadı: orada kapalı tutmanın sebebi genelde
      // uzun listede akışı sadeleştirmek, oysa tek bir kartta orijinal
      // metin kartı zenginleştiriyor.
      includeArabic: ayah.arabic != null,
      origin: origin,
    );

    if (rendered) return;

    // Kart çizilemedi ve metin paylaşımına düşüldü. Kullanıcı ne
    // paylaştığını bilsin diye durum bildirilir.
    messenger.showSnackBar(
      SnackBar(
        content: Text('actions.shareCardFailed'.tr()),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBookmarked = mark?.isBookmarked ?? false;

    // Yatayda yaprak ekrana sığmayabilir; `AdaptiveSheet` yüksekliği
    // sınırlar ve gerekirse içeriği kaydırılabilir yapar.
    return AdaptiveSheet(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: horizontalSafeGutter(
            context,
          ).copyWith(top: Insets.xs, bottom: Insets.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hangi ayet üzerinde işlem yapıldığını gösteren başlık.
              Text(
                '$surahName · ${ayah.numberLabel}. ayet',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Insets.xs),
              Text(
                ayah.translationFor(context.locale.languageCode),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: Insets.md),

              _HighlightPicker(
                selected: mark?.highlightColor,
                onSelect: (color) {
                  onSetHighlight(color);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: Insets.md),

              _ActionRow(
                icon: isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                label: isBookmarked
                    ? 'actions.removeBookmark'.tr()
                    : 'actions.addBookmark'.tr(),
                isActive: isBookmarked,
                onTap: () {
                  onToggleBookmark();
                  Navigator.of(context).pop();
                },
              ),
              _ActionRow(
                icon: Icons.edit_note_rounded,
                label: (mark?.hasNote ?? false)
                    ? 'actions.editNote'.tr()
                    : 'actions.addNote'.tr(),
                isActive: mark?.hasNote ?? false,
                onTap: () {
                  Navigator.of(context).pop();
                  onEditNote();
                },
              ),
              // Kök analizi yalnızca Arapça metni olan ayetlerde anlamlıdır.
              if (ayah.arabic != null)
                _ActionRow(
                  icon: Icons.account_tree_outlined,
                  label: 'roots.title'.tr(),
                  onTap: () {
                    Navigator.of(context).pop();
                    onAnalyseRoots();
                  },
                ),
              _ActionRow(
                icon: Icons.ios_share_rounded,
                label: 'actions.share'.tr(),
                onTap: () {
                  Navigator.of(context).pop();
                  AyahShare.text(
                    ayah: ayah,
                    surahName: surahName,
                    languageCode: context.locale.languageCode,
                  );
                },
              ),
              // Görsel kart. Metin paylaşımının yerine değil yanına konuldu:
              // metin okunmak için, kart görülmek için — sohbette ve
              // hikâyede bir görsel düz metinden çok daha fazla duruyor.
              _ActionRow(
                icon: Icons.image_outlined,
                label: 'actions.shareCard'.tr(),
                onTap: () => _shareCard(context),
              ),
              _ActionRow(
                icon: Icons.copy_rounded,
                label: 'actions.copy'.tr(),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _shareText(context)));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('actions.copied'.tr()),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vurgu rengi seçici. Seçili renk halkayla belirtilir; "yok" seçeneği
/// üstü çizili daire olarak en sonda.
class _HighlightPicker extends StatelessWidget {
  const _HighlightPicker({required this.selected, required this.onSelect});

  final int? selected;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final color in AppColors.highlightPalette)
          _ColorDot(
            color: color,
            isSelected: selected == color.toARGB32(),
            onTap: () => onSelect(
              selected == color.toARGB32() ? null : color.toARGB32(),
            ),
          ),
        // Vurguyu kaldırma.
        Pressable(
          onTap: () => onSelect(null),
          scale: 0.9,
          hapticOnTap: true,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor, width: 1.5),
            ),
            child: Icon(
              Icons.format_color_reset_rounded,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      scale: 0.9,
      hapticOnTap: true,
      child: AnimatedContainer(
        duration: Motion.fast,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.onSurface
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: isSelected
            ? Icon(
                Icons.check_rounded,
                size: 18,
                color: Colors.black.withValues(alpha: 0.6),
              )
            : null,
      ),
    );
  }
}

/// Yapraktaki tek bir eylem satırı.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;

    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Padding(
        // Dokunma alanı en az 44pt yüksekliğinde tutulur (Apple HIG).
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        child: Row(
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(width: Insets.sm),
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
