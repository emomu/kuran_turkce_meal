import 'package:flutter/material.dart';

/// Tipografik ölçek.
///
/// İki aile kullanılır:
///  - Arayüz metni (başlık, buton, etiket) için geometrik-humanist bir sans.
///  - Ayet metni için tırnaklı (serif) bir yüz. Uzun okuma seanslarında
///    serif satır takibini kolaylaştırır ve mushaf/kitap hissini korur.
///
/// Ölçek 1.200 (minor third) oranına yakın tutulmuştur; bu oran ekranda
/// hiyerarşiyi kurmaya yeter ama başlıkları abartmaz.
abstract final class AppTypography {
  /// Aile adları pubspec.yaml'daki `fonts:` tanımlarıyla birebir eşleşir.
  /// Fontlar uygulamayla paketlendiği için çalışma anında indirilmez;
  /// uygulama çevrimdışıyken de doğru yüzle açılır.
  static const String _serif = 'SourceSerif4';
  static const String _sans = 'Inter';

  /// Kur'an metninin yüzü: Kral Fahd Kur'an Basım Kompleksi'nin resmi
  /// mushaf hattı.
  ///
  /// Font metindeki yuvarlak tenvinleri (U+08F0–08F2) taşımıyordu; 2010
  /// yapımı, o işaretler Unicode'a 2012'de eklendi. Metin bu yüzden
  /// `tool/normalize_tanween.py` ile standart tenvinlere çevrildi ve font
  /// artık metni eksiksiz kapsıyor.
  static const String _arabic = 'UthmanicHafs';

  /// Mushaf yüzünün punto çarpanı.
  ///
  /// Her font aynı punto değerinde aynı büyüklükte çizilmez; harflerin
  /// birim kareye göre oranı fonttan fonta değişir. Bu yüzün oranı 1.76,
  /// bir önceki yüzünki 2.45'ti — çarpansız metin belirgin biçimde küçük
  /// kalır ve koyu zeminde silikleşir.
  ///
  /// Kullanıcının punto tercihinin yerine geçmez, onunla çarpılır:
  /// ayarlardaki ölçek anlamını korur.
  static const double _arabicScale = 1.46;

  /// Arapça ayet metni için mushaf yüzü.
  ///
  /// Latin yüzleri Arapça glif taşımadığından metin eskiden sistem fontuna
  /// düşüyordu (iOS'ta Geeza Pro, Android'de Noto Naskh). Bunlar mushaf
  /// dizgisi için tasarlanmadığından harekeler harfe doğru oturmuyor ve
  /// uzun ayetlerde okunurluk düşüyordu.
  ///
  /// [height] varsayılanı Latin metninden yüksek: Arapça harekeler harfin
  /// altına ve üstüne taşar, dar satır aralığında birbirine değerler.
  static TextStyle arabic({
    required double fontSize,
    required Color color,
    double height = 1.9,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: _arabic,
      fontSize: fontSize * _arabicScale,
      color: color,
      height: height,
      fontWeight: weight,
      letterSpacing: 0,
    );
  }

  /// Ayet metni için okuma yüzü.
  static TextStyle reading({
    required double fontSize,
    required Color color,
    required double height,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: _serif,
      fontSize: fontSize,
      color: color,
      height: height,
      fontWeight: weight,
      letterSpacing: 0,
    );
  }

  /// Arayüz metni.
  static TextStyle ui({
    required double fontSize,
    required Color color,
    FontWeight weight = FontWeight.w400,
    double? height,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: _sans,
      fontSize: fontSize,
      color: color,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Tema için tam TextTheme üretir.
  static TextTheme textTheme(Color ink, Color inkMuted) {
    return TextTheme(
      // Büyük ekran başlıkları — "Kur'an", "Ayarlar" gibi.
      displaySmall: ui(
        fontSize: 32,
        color: ink,
        weight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.15,
      ),
      // Bölüm başlıkları.
      headlineMedium: ui(
        fontSize: 24,
        color: ink,
        weight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.2,
      ),
      headlineSmall: ui(
        fontSize: 20,
        color: ink,
        weight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.25,
      ),
      // Kart başlıkları — sure adı gibi.
      titleMedium: ui(
        fontSize: 17,
        color: ink,
        weight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      titleSmall: ui(
        fontSize: 15,
        color: ink,
        weight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.3,
      ),
      // Gövde metni.
      bodyLarge: ui(fontSize: 17, color: ink, height: 1.45),
      bodyMedium: ui(fontSize: 15, color: ink, height: 1.45),
      bodySmall: ui(fontSize: 13, color: inkMuted, height: 1.4),
      // Etiketler — ayet numarası, rozet, sekme.
      labelLarge: ui(
        fontSize: 15,
        color: ink,
        weight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      labelMedium: ui(
        fontSize: 13,
        color: inkMuted,
        weight: FontWeight.w500,
      ),
      labelSmall: ui(
        fontSize: 11,
        color: inkMuted,
        weight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
    );
  }
}

/// Boşluk ölçeği. 4pt taban ızgarası.
///
/// Apple'ın HIG'i 8pt ızgara önerir; 4pt taban, ikonlar ve küçük rozetler için
/// yarım adım verir ama düzenin ana ritmi 8/16/24 üzerinden kurulur.
abstract final class Insets {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Ekran kenar boşluğu. iPhone 13 (390pt genişlik) baz alınmıştır.
  static const double screenGutter = 20;
}

/// Köşe yarıçapları. Apple'ın "continuous corner" hissine yakın,
/// yüzey boyutuyla orantılı bir ölçek.
abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}

/// Hareket süreleri ve eğrileri.
///
/// Apple tasarım dilinde animasyon hızlı ve amaçlıdır; dikkat çekmez, yönlendirir.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  /// Standart giriş/çıkış eğrisi.
  static const Curve standard = Curves.easeOutCubic;

  /// Yüzey büyürken/küçülürken — hafif yaylanma, taşma yok.
  static const Curve emphasized = Curves.easeOutQuart;
}
