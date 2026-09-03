import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../data/models/ayah.dart';
import '../../../shared/widgets/pressable.dart';

/// Bir ayete not yazma yaprağı.
///
/// Düzen kararları:
///  - Ayetin meali notun üstünde durur (tefsir yaprağındaki gibi): kullanıcı
///    hangi ayete yazdığını görmeden not alamamalı.
///  - Yazma alanı çerçevesizdir. Temanın odak çerçevesi ince alanlar için
///    tasarlandı; altı satırlık bir kutuyu sarınca arayüzün en baskın öğesi
///    hâline geliyor ve metnin önüne geçiyordu. Bunun yerine gömülü bir yüzey
///    kullanılır — alan zaten tek dokunulabilir öğe, çerçeveyle işaretlenmesi
///    gerekmiyor.
///  - Kaydet düğmesi metin boşken sönük durur; boş nota dokunmak sessizce
///    hiçbir şey yapmaktansa düğmenin devre dışı olduğunu göstermek yeğdir.
///  - Klavye açıldığında yaprak yukarı iter ([viewInsets] dolgusu).
class NoteEditorSheet extends StatefulWidget {
  const NoteEditorSheet({
    super.key,
    required this.ayah,
    required this.surahName,
    required this.initialNote,
    required this.onSave,
  });

  final Ayah ayah;
  final String surahName;
  final String? initialNote;
  final ValueChanged<String?> onSave;

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialNote,
  );
  late final FocusNode _focusNode = FocusNode();

  /// Kaydet düğmesinin etkin olup olmadığını izler.
  late bool _hasText = (widget.initialNote ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    // Yaprak açılır açılmaz klavye gelsin; kullanıcı ayrıca dokunmasın.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  void _onChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    // Boş metin notu silmek demektir; boş bir kayıt tutmanın anlamı yok.
    widget.onSave(text.isEmpty ? null : text);
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('actions.deleteNote'.tr()),
        content: Text('actions.deleteNoteConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'common.delete'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      widget.onSave(null);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hadNote = (widget.initialNote ?? '').trim().isNotEmpty;
    final lang = context.locale.languageCode;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      // Yatayda klavye açıkken kalan yükseklik çok azalır; yaprak
      // sınırlanır ve içerik kaydırılabilir olur.
      child: AdaptiveSheet(
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
                // Başlık satırı: hangi ayet, ne yapılıyor.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hadNote
                                ? 'actions.editNote'.tr()
                                : 'actions.addNote'.tr(),
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${widget.surahName} · '
                            '${widget.ayah.numberLabel}. ayet',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                    _SaveButton(enabled: _hasText, onTap: _save),
                  ],
                ),
                const SizedBox(height: Insets.md),

                // Ayetin meali — kullanıcı neye not aldığını görsün.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Insets.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Text(
                    widget.ayah.translationFor(lang),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.reading(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: Insets.md),

                // Yazma alanı. Çerçeve yerine gömülü yüzey; odak halkası bu
                // ölçekte gürültü yaratıyordu.
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.sm,
                    vertical: Insets.xs,
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 8,
                    minLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: AppTypography.reading(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                      height: 1.55,
                    ),
                    cursorColor: theme.colorScheme.primary,
                    decoration: InputDecoration(
                      hintText: 'actions.notePlaceholder'.tr(),
                      hintStyle: AppTypography.reading(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                        height: 1.55,
                      ),
                      // Temanın dolgulu/çerçeveli görünümü burada devre dışı;
                      // kabuk yukarıdaki Container tarafından çiziliyor.
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),

                if (hadNote) ...[
                  const SizedBox(height: Insets.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Pressable(
                      scale: 0.97,
                      onTap: _confirmDelete,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: Insets.xs,
                          horizontal: Insets.xxs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 17,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: Insets.xxs),
                            Text(
                              'actions.deleteNote'.tr(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kaydet düğmesi. Metin boşken sönük ve dokunulamaz.
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      scale: 0.95,
      hapticOnTap: true,
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: Motion.fast,
        opacity: enabled ? 1 : 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.xs,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: Text(
            'common.save'.tr(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
