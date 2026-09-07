import 'package:easy_localization/easy_localization.dart'
    hide TextDirection;
import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/reader_preferences.dart';
import '../../../data/models/user_marks.dart';
import '../../../shared/widgets/pressable.dart';

/// Okuma akışındaki tek bir ayet.
///
/// Düzen kararları:
///  - Ayet numarası metnin soluna değil, üstüne küçük bir etiket olarak
///    konur. Sola konsaydı her satırda girinti gerekirdi ve uzun mealde
///    metin sütunu daralırdı.
///  - Vurgu rengi metnin arkasına düşük alfa ile uygulanır; metin rengi
///    değişmez, okunabilirlik korunur.
///  - Not varsa metnin altında ince bir şeritle belirtilir — kullanıcı
///    listeyi kaydırırken hangi ayete not aldığını görebilmeli.
class AyahTile extends StatelessWidget {
  const AyahTile({
    super.key,
    required this.ayah,
    required this.prefs,
    required this.mark,
    required this.onTap,
    required this.onLongPress,
    this.isFocused = false,
    this.isPlaying = false,
  });

  final Ayah ayah;
  final ReaderPreferences prefs;
  final AyahMark? mark;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// Aramadan veya bildirimden bu ayete gelindiğinde kısa süre vurgulanır.
  final bool isFocused;

  /// Tilavette şu an bu ayet okunuyor.
  ///
  /// Zemine çok hafif bir renk verilir, başka hiçbir işaret konmaz: tilavet
  /// boyunca her ayette sırayla belirecek bir gösterge, okuma akışının önüne
  /// geçmemeli.
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlight = mark?.highlightColor;
    final lang = context.locale.languageCode;

    // Arapça metin bu ayette gerçekten çizilecek mi. Ayarın açık olması
    // yetmez; ayetin Arapça metni de bulunmalı.
    final showsArabic = prefs.showArabic && ayah.arabic != null;

    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      scale: 0.99,
      child: AnimatedContainer(
        duration: Motion.slow,
        curve: Motion.standard,
        decoration: BoxDecoration(
          // Çalan ayetin zemini, arama vurgusundan daha hafif: tilavet
          // boyunca ekranda kalıcı olarak duracak, bu yüzden göz yormamalı.
          color: isFocused
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : isPlaying
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        // Arapça metin açıkken bloklar görsel olarak yükselir; ayetlerin
        // birbirine karışmaması için dikey boşluk artırılır.
        padding: EdgeInsets.symmetric(
          horizontal: Insets.xs,
          vertical: showsArabic ? Insets.lg : Insets.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AyahHeader(ayah: ayah, mark: mark),
            const SizedBox(height: Insets.xs),

            if (showsArabic) ...[
              // Arapça metin sağdan sola akar ve kendi punto ölçeğini kullanır.
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  ayah.arabic!,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: prefs.arabicFontSize,
                    height: 1.9,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: Insets.sm),
            ],

            _TranslationText(
              text: ayah.translationFor(lang),
              prefs: prefs,
              highlightColor: highlight,
            ),


            if (mark?.hasNote ?? false) ...[
              const SizedBox(height: Insets.sm),
              _NoteBlock(note: mark!.note!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ayet numarası ve işaret rozetleri.
class _AyahHeader extends StatelessWidget {
  const _AyahHeader({required this.ayah, required this.mark});

  final Ayah ayah;
  final AyahMark? mark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Ayet numarası rozeti. Boyutu punto ayarından bağımsızdır; metin
        // büyüdükçe rozet de büyüseydi düzen dengesizleşirdi.
        //
        // Birleşik meal bloklarında aralık gösterilir ("9-10"), bu yüzden
        // rozet daire değil hap biçimindedir ve içeriğe göre genişler.
        Container(
          constraints: const BoxConstraints(minWidth: 24),
          height: 24,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: ayah.isRange ? 7 : 0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: Text(
            ayah.numberLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        const Spacer(),
        if (mark?.isBookmarked ?? false)
          Icon(
            Icons.bookmark_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          ),
      ],
    );
  }
}

/// Meal metni. Vurgu rengi varsa metnin arkasına uygulanır.
class _TranslationText extends StatelessWidget {
  const _TranslationText({
    required this.text,
    required this.prefs,
    required this.highlightColor,
  });

  final String text;
  final ReaderPreferences prefs;
  final int? highlightColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final style = AppTypography.reading(
      fontSize: prefs.translationFontSize,
      color: theme.colorScheme.onSurface,
      height: prefs.lineHeight,
    );

    if (highlightColor == null) {
      return Text(text, style: style);
    }

    // Vurgu, metnin arkasına yerleşen bir zemin olarak çizilir. Satır
    // yüksekliği zaten geniş olduğu için ayrı bir dolgu gerekmez.
    return Container(
      decoration: BoxDecoration(
        color: Color(highlightColor!).withValues(
          alpha: theme.brightness == Brightness.dark ? 0.22 : 0.38,
        ),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.xs,
        vertical: Insets.xxs,
      ),
      child: Text(text, style: style),
    );
  }
}


/// Kullanıcının bu ayete aldığı not.
class _NoteBlock extends StatelessWidget {
  const _NoteBlock({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: Insets.sm),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
      child: Text(
        note,
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          height: 1.45,
        ),
      ),
    );
  }
}
