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

  // ------------------------------------------------------------ Fihrist

  /// Fihrist bölümlerinin renkleri.
  ///
  /// Kartlar renkle ayrışır çünkü fihrist gezilen bir yer: kullanıcı aradığı
  /// bölümü okumadan, rengiyle tanır. Düz bir liste bunu veremiyordu — elli
  /// altı satır aynı griydi ve göz tutunacak yer bulamıyordu.
  ///
  /// Renkler paletin kendi mantığında kaldı: düşük doygunluk, kırık tonlar.
  /// Doygun renkler ("bible app yeşili") bu uygulamada yabancı durur ve
  /// mürekkep-kâğıt hissini bozardı. Ayrım için doygunluk değil ton farkı
  /// kullanılıyor.
  ///
  /// Her bölümün iki tonu var: koyu temada zemin daha koyu olmalı, yoksa
  /// kart metni okunmaz hâle gelir.
  static const topicLight = <String, Color>{
    'inanc': Color(0xFF4A6B7C),
    'ibadet': Color(0xFF3F6B54),
    'ahlak': Color(0xFF7C6545),
    'iliskiler': Color(0xFF8A5A5F),
    'hukuk': Color(0xFF5A5A78),
    'ahiret': Color(0xFF6B4F6B),
    'kainat': Color(0xFF4A7068),
    'haller': Color(0xFF7A6A52),
  };

  static const topicDark = <String, Color>{
    'inanc': Color(0xFF2E4551),
    'ibadet': Color(0xFF2A4638),
    'ahlak': Color(0xFF52432E),
    'iliskiler': Color(0xFF5C3C3F),
    'hukuk': Color(0xFF3C3C50),
    'ahiret': Color(0xFF473547),
    'kainat': Color(0xFF2F4945),
    'haller': Color(0xFF514637),
  };

  /// Bir bölümün kart rengi. Tanımsız bölüm nötr yüzeye düşer.
  static Color topicColor(String categoryId, {required bool isDark}) {
    final map = isDark ? topicDark : topicLight;
    return map[categoryId] ?? (isDark ? darkSurfaceSunken : lightSurfaceSunken);
  }
}
