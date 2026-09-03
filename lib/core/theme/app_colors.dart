import 'package:flutter/material.dart';

/// Uygulamanın renk paleti.
///
/// Palet, mürekkep ve kâğıt metaforu üzerine kurulu: sıcak, hafif kırık bir
/// beyaz zemin ve tam siyah olmayan bir mürekkep rengi. Saf beyaz (#FFFFFF) ve
/// saf siyah (#000000) uzun okuma seanslarında göz yorar; kırık tonlar hem
/// daha az kontrast şoku verir hem de basılı mushaf hissini korur.
///
/// Vurgu rengi, geleneksel tezhip yeşilinden türetilmiş sakin bir tondur.
/// Doygunluğu bilerek düşük tutulmuştur — metin ekranda tek başına kalmalı,
/// arayüz kendini hatırlatmamalıdır.
abstract final class AppColors {
  // ---------------------------------------------------------------- Light

  /// Ana zemin. Hafif sıcak bir kırık beyaz.
  static const lightBackground = Color(0xFFFAF9F6);

  /// Kart ve yükseltilmiş yüzeyler. Zeminden bir tık daha açık.
  static const lightSurface = Color(0xFFFFFEFB);

  /// Sekme çubuğu, arama alanı gibi gömülü yüzeyler.
  static const lightSurfaceSunken = Color(0xFFF1EFEA);

  /// Ana metin rengi. Tam siyah değil, sıcak koyu gri.
  static const lightInk = Color(0xFF1C1B18);

  /// İkincil metin: ayet numarası, sure alt bilgisi, tarih.
  static const lightInkMuted = Color(0xFF6B6862);

  /// Üçüncül metin: ipuçları, devre dışı durumlar.
  static const lightInkFaint = Color(0xFF9C9891);

  /// Ayırıcı çizgiler. Neredeyse görünmez olmalı.
  static const lightDivider = Color(0xFFE6E3DC);

  // ----------------------------------------------------------------- Dark

  /// Ana zemin. Mavi tonlu değil, nötr-sıcak koyu.
  static const darkBackground = Color(0xFF14130F);

  /// Kart ve yükseltilmiş yüzeyler.
  static const darkSurface = Color(0xFF1D1C18);

  /// Gömülü yüzeyler.
  static const darkSurfaceSunken = Color(0xFF262420);

  /// Ana metin. Saf beyaz değil — koyu zeminde parlama yapmasın.
  static const darkInk = Color(0xFFEDEAE3);

  static const darkInkMuted = Color(0xFF9A968D);

  static const darkInkFaint = Color(0xFF6A665E);

  static const darkDivider = Color(0xFF2E2C27);

  // ----------------------------------------------------------------- Accent

  /// Vurgu rengi — açık tema. Sakin, düşük doygunluklu yeşil.
  static const accentLight = Color(0xFF3F6B54);

  /// Vurgu rengi — koyu tema. Koyu zeminde okunabilirlik için açılmış.
  static const accentDark = Color(0xFF7FB394);

  /// Ayet vurgulama renkleri. Kullanıcı bir ayeti işaretlediğinde kullanılır.
  /// Düşük alfa ile metnin üstüne bindirilir, metni bastırmaz.
  static const highlightYellow = Color(0xFFF5D77E);
  static const highlightGreen = Color(0xFF9FD4AE);
  static const highlightBlue = Color(0xFF9EC4E8);
  static const highlightPink = Color(0xFFE8A9BC);
  static const highlightPurple = Color(0xFFC0AEE0);

  static const highlightPalette = <Color>[
    highlightYellow,
    highlightGreen,
    highlightBlue,
    highlightPink,
    highlightPurple,
  ];
}
