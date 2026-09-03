import 'package:flutter/material.dart';

/// Okuma deneyimini biçimlendiren kullanıcı tercihleri.
///
/// Tümü cihazda saklanır (SharedPreferences) — bunlar hesaba değil cihaza
/// ait ayarlardır; kullanıcı telefonunda küçük, tabletinde büyük punto
/// isteyebilir.
class ReaderPreferences {
  const ReaderPreferences({
    this.themeMode = ThemeMode.system,
    this.fontScale = 1.0,
    this.lineHeight = 1.7,
    this.showArabic = false,
    this.sortByRevelation = true,
    this.dailyAyahEnabled = true,
    this.dailyAyahHour = 8,
    this.dailyAyahMinute = 0,
  });

  final ThemeMode themeMode;

  /// Meal metninin punto çarpanı. Taban 17pt; 0.8–1.6 arasında ayarlanır.
  final double fontScale;

  /// Satır aralığı çarpanı. 1.4–2.2 arasında.
  final double lineHeight;

  /// Arapça orijinal metnin mealle birlikte gösterilip gösterilmeyeceği.
  final bool showArabic;

  /// Sure listesinin iniş sırasına göre sıralanıp sıralanmayacağı.
  final bool sortByRevelation;


  /// Günün ayeti bildirimi.
  final bool dailyAyahEnabled;
  final int dailyAyahHour;
  final int dailyAyahMinute;

  /// Meal metninin hesaplanmış punto değeri.
  double get translationFontSize => 17 * fontScale;

  /// Arapça metnin punto değeri. Arap hattı aynı puntoda Latin harflerden
  /// küçük göründüğü için bir buçuk kat büyütülür.
  double get arabicFontSize => 24 * fontScale;

  TimeOfDay get dailyAyahTime =>
      TimeOfDay(hour: dailyAyahHour, minute: dailyAyahMinute);

  ReaderPreferences copyWith({
    ThemeMode? themeMode,
    double? fontScale,
    double? lineHeight,
    bool? showArabic,
    bool? sortByRevelation,
    bool? dailyAyahEnabled,
    int? dailyAyahHour,
    int? dailyAyahMinute,
  }) => ReaderPreferences(
    themeMode: themeMode ?? this.themeMode,
    fontScale: fontScale ?? this.fontScale,
    lineHeight: lineHeight ?? this.lineHeight,
    showArabic: showArabic ?? this.showArabic,
    sortByRevelation: sortByRevelation ?? this.sortByRevelation,
    dailyAyahEnabled: dailyAyahEnabled ?? this.dailyAyahEnabled,
    dailyAyahHour: dailyAyahHour ?? this.dailyAyahHour,
    dailyAyahMinute: dailyAyahMinute ?? this.dailyAyahMinute,
  );
}
