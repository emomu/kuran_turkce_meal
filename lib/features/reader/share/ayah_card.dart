import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Paylaşılabilir ayet kartı.
///
/// Uygulamanın metin paylaşımı zaten var; kart bunun yerine değil yanına
/// eklendi. Metin paylaşımı okunmak için, kart görülmek için: sohbette ve
/// hikâyede bir görsel, düz metinden çok daha fazla duruyor.
///
/// Kart ekranda gösterilmez — `AyahCardRenderer` tarafından görünmez bir
/// katmanda çizilip PNG'ye çevrilir. Bu yüzden burada duyarlı düzen yok:
/// boyut sabit ve tasarım o sabit boyuta göre kurulu.
class AyahCard extends StatelessWidget {
  const AyahCard({
    super.key,
    required this.text,
    required this.surahName,
    required this.verseLabel,
    required this.appName,
    this.arabic,
    this.isDark = false,
  });

  /// Meal metni.
  final String text;

  final String surahName;

  /// "255" ya da "255-257" gibi ayet numarası etiketi.
  final String verseLabel;

  /// Kartın altındaki uygulama adı. Görselin nereden geldiğini gösterir;
  /// paylaşılan kartın kaynağı belirsiz kalmamalı.
  final String appName;

  /// Arapça orijinal metin. Kullanıcı ayarlardan açtıysa karta da girer.
  final String? arabic;

  final bool isDark;

  /// Kartın kenar uzunluğu.
  ///
  /// Kare seçildi: Instagram, WhatsApp durumu ve X önizlemeleri kareyi
  /// kırpmadan gösteriyor. Dikey bir kart hikâyede iyi durur ama sohbette
  /// kırpılır; kare her ikisinde de bütün kalır.
  static const double size = 1080;

  Color get _background => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get _ink => isDark ? AppColors.darkInk : AppColors.lightInk;
  Color get _inkMuted => isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted;
  Color get _accent => isDark ? AppColors.accentDark : AppColors.accentLight;
  Color get _divider => isDark ? AppColors.darkDivider : AppColors.lightDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: _background,
      padding: const EdgeInsets.all(96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üstte ince bir vurgu çizgisi. Kartı bir "sayfa" gibi çerçeveler
          // ve boş üst boşluğun amaçsız görünmesini engeller.
          Container(width: 72, height: 3, color: _accent),

          const Spacer(),

          if (arabic != null) ...[
            // Arapça metin sağdan sola akar ve mealden görsel olarak
            // ayrılsın diye biraz daha soluk verilir.
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                arabic!,
                textAlign: TextAlign.right,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.reading(
                  fontSize: _arabicFontSize,
                  color: _inkMuted,
                  height: 1.9,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],

          Text(
            text,
            // Uzun ayetler karta sığmaz. Kırpmak yerine punto küçültülür
            // (bkz. _fontSize); yine de sığmayan çok uzun metinler sonda
            // üç noktayla kesilir. Kesmek, kartı okunmaz bir punto ile
            // doldurmaktan iyidir.
            maxLines: _maxLines,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.reading(
              fontSize: _fontSize,
              color: _ink,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 40),

          Container(width: double.infinity, height: 1, color: _divider),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: Text(
                  '$surahName $verseLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.ui(
                    fontSize: 30,
                    color: _accent,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                appName,
                style: AppTypography.ui(
                  fontSize: 24,
                  color: _inkMuted,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),

          const Spacer(),
        ],
      ),
    );
  }

  /// Meal metninin puntosu.
  ///
  /// Uzunluğa göre kademelendirilir: kısa bir ayet kartın ortasında küçücük
  /// durmamalı, uzun bir ayet de taşmamalı. Eşikler kart genişliğine göre
  /// deneyerek belirlendi.
  double get _fontSize {
    final length = text.length + (arabic?.length ?? 0) ~/ 2;
    if (length < 120) return 54;
    if (length < 240) return 46;
    if (length < 400) return 38;
    if (length < 600) return 32;
    return 28;
  }

  /// Arapça metnin puntosu. Arap hattı aynı puntoda Latin harflerden küçük
  /// göründüğü için büyütülür — okuma ekranındaki oranın aynısı.
  double get _arabicFontSize => _fontSize * 1.15;

  /// Metnin sığabileceği satır sayısı.
  ///
  /// Arapça metin gösteriliyorsa mealin payına düşen alan azalır.
  int get _maxLines => arabic == null ? 12 : 7;
}
