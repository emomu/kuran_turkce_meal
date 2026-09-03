import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';

/// Ekran genişliğine göre düzen kararları.
///
/// Uygulama yatay kullanımı da destekler. Yatayda ekran genişler ama okuma
/// metni genişlemez: satır uzadıkça göz satır sonundan bir sonraki satırın
/// başına dönmekte zorlanır. Tipografide uzun süredir bilinen aralık satır
/// başına 45–75 karakterdir; bunun üstünde okuma hızı ve süreklilik düşer.
///
/// Bu yüzden yatayda içerik ortalanır ve bir üst genişlik sınırına oturur;
/// artan alan kenarlarda boşluk olarak kalır. Dikeyde ise sınır zaten
/// telefon genişliğinin üstünde olduğu için hiçbir şey değişmez — dikey
/// görünüm bugünkü hâliyle korunur.
abstract final class Breakpoints {
  /// Bunun altındaki genişlikler "telefon dikey" kabul edilir.
  static const double compact = 600;

  /// Bunun üstü tablet/masaüstü genişliğidir.
  static const double expanded = 900;
}

/// İçerik için üst genişlik sınırları.
///
/// Okuma metni en dar sınırı alır: ayet metni uygulamanın en uzun soluklu
/// içeriği ve satır uzunluğuna en duyarlı olanı. Liste ve form ekranları
/// biraz daha geniş olabilir; oradaki satırlar zaten kısa.
abstract final class ContentWidth {
  /// Ayet/meal metni — konforlu satır uzunluğu.
  static const double reading = 680;

  /// Liste, form ve ayar ekranları.
  static const double standard = 840;
}

/// Ekranın yatay olup olmadığını söyler.
bool isLandscape(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width > size.height;
}

/// Ekran kenar boşluğu — geniş ekranlarda bir miktar artar.
///
/// Dar ekranda 20pt yeterli bir nefes payı; genişledikçe içerik kenara
/// yapışık durmasın diye boşluk da büyür.
double gutterFor(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= Breakpoints.expanded) return Insets.xl;
  if (width >= Breakpoints.compact) return Insets.lg;
  return Insets.screenGutter;
}

/// Yatayda çentik/ada kenarda kalır ve içeriği keser. `SafeArea` bunu
/// dikeyde hallediyor ama ekranlar yatay güvenli alanı okumuyordu; bu
/// yardımcı, kenar boşluğunu güvenli alan kadar artırır.
EdgeInsets horizontalSafeGutter(BuildContext context) {
  final padding = MediaQuery.paddingOf(context);
  final gutter = gutterFor(context);
  return EdgeInsets.only(
    left: gutter + padding.left,
    right: gutter + padding.right,
  );
}

/// İçeriği ortalayıp genişliğini sınırlayan sarmalayıcı.
///
/// Dikey telefonda ekran zaten sınırdan dar olduğu için bu widget hiçbir
/// şey değiştirmez; yatayda ise içeriği ortada tutar.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({
    super.key,
    required this.child,
    this.maxWidth = ContentWidth.standard,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Kaydırılabilir listeler için yatay dolgu hesabı.
///
/// Liste kendi kaydırma çubuğunu ekranın kenarında tutsun diye genişlik
/// sınırı dolguyla kurulur (listeyi `ConstrainedBox` ile daraltmak yerine).
/// Böylece yatayda içerik ortalanır ama kaydırma alanı tüm ekranı kaplar.
EdgeInsets centeredContentPadding(
  BuildContext context, {
  double maxWidth = ContentWidth.standard,
  double top = 0,
  double bottom = 0,
}) {
  final media = MediaQuery.of(context);
  final gutter = gutterFor(context);
  final available = media.size.width - media.padding.left - media.padding.right;
  // Sınırın üstünde kalan genişlik iki yana eşit dağıtılır.
  final overflow = available - maxWidth;
  final side = overflow > 0 ? overflow / 2 : 0.0;

  return EdgeInsets.only(
    left: gutter + media.padding.left + side,
    right: gutter + media.padding.right + side,
    top: top,
    bottom: bottom,
  );
}

/// Alt yapraklar (modal bottom sheet) için yatay uyum.
///
/// Yatayda ekran yüksekliği yarıya iner; sabit yükseklikli bir yaprak
/// taşar ve altındaki düğmeler erişilemez hale gelir. Bu sarmalayıcı
/// yaprağı kullanılabilir yüksekliğin bir oranıyla sınırlar ve içeriği
/// gerektiğinde kaydırılabilir yapar. Genişlikte de aynı okunabilirlik
/// kuralı geçerlidir: geniş ekranda yaprak ortada durur.
class AdaptiveSheet extends StatelessWidget {
  const AdaptiveSheet({
    super.key,
    required this.child,
    this.maxHeightFactor = 0.9,
  });

  final Widget child;

  /// Kullanılabilir yüksekliğin en fazla ne kadarını kaplayabileceği.
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Klavye açıkken kalan alan üzerinden hesaplanır; aksi halde yaprak
    // klavyenin altına uzanır.
    final available =
        media.size.height - media.viewInsets.bottom - media.padding.top;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: available * maxHeightFactor,
        maxWidth: ContentWidth.standard,
      ),
      child: SingleChildScrollView(
        // İçerik sığıyorsa kaydırma devreye girmez; sığmıyorsa (yatay,
        // küçük ekran, büyük sistem puntosu) kaydırılabilir olur.
        physics: const ClampingScrollPhysics(),
        child: child,
      ),
    );
  }
}
