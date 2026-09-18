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
    this.showArabic = true,
    this.sortByRevelation = true,
    this.dailyAyahEnabled = true,
    this.dailyAyahHour = 8,
    this.dailyAyahMinute = 0,
    this.reciterId,
    this.playbackSpeed = 1.0,
    this.autoScrollWithAudio = true,
    this.highlightWords = true,
  });

  final ThemeMode themeMode;

  /// Meal metninin punto çarpanı. Taban 17pt; 0.8–1.6 arasında ayarlanır.
  final double fontScale;

  /// Satır aralığı çarpanı. 1.4–2.2 arasında.
  final double lineHeight;

  /// Arapça orijinal metnin mealle birlikte gösterilip gösterilmeyeceği.
  ///
  /// Varsayılan açık: uygulama bir Kur'an uygulaması ve kullanıcıların çoğu
  /// orijinal metni görmeyi bekliyor. Kapalı başlatmak, özelliğin varlığını
  /// ayarlara girmeden fark edilemez kılıyordu.
  final bool showArabic;

  /// Sure listesinin iniş sırasına göre sıralanıp sıralanmayacağı.
  final bool sortByRevelation;


  /// Günün ayeti bildirimi.
  final bool dailyAyahEnabled;
  final int dailyAyahHour;
  final int dailyAyahMinute;

  /// Seçili karinin kimliği. Hiç seçilmemişse null; varsayılan kari kullanılır.
  ///
  /// Kari nesnesi değil kimliği saklanır: nesne uygulama sürümüyle değişebilir
  /// (adres güncellenir, kalite değişir) ama kimlik sabit kalır ve kullanıcının
  /// tercihi güncellemeden sağ çıkar.
  final String? reciterId;

  /// Tilavet oynatma hızı. 0.5–2.0 arası.
  ///
  /// Ezber çalışanlar yavaşlatır, tekrar dinleyenler hızlandırır. Varsayılan 1.0
  /// bırakıldı: tilavetin kendi tartımı vardır ve varsayılanı bozmak doğru
  /// değil.
  final double playbackSpeed;

  /// Ses çalarken listenin çalan ayeti takip edip etmeyeceği.
  final bool autoScrollWithAudio;

  /// Tilavette okunan kelimenin Arapça metinde vurgulanıp vurgulanmayacağı.
  ///
  /// Varsayılan açık: takip etmeyi kolaylaştıran asıl özellik bu. Kapatma
  /// seçeneği, vurgunun dikkatini dağıttığını söyleyenler için var — ve
  /// zamanlama verisi bulunmayan birkaç ayette vurgu zaten kendiliğinden
  /// devre dışı kalır.
  final bool highlightWords;

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
    String? reciterId,
    double? playbackSpeed,
    bool? autoScrollWithAudio,
    bool? highlightWords,
  }) => ReaderPreferences(
    themeMode: themeMode ?? this.themeMode,
    fontScale: fontScale ?? this.fontScale,
    lineHeight: lineHeight ?? this.lineHeight,
    showArabic: showArabic ?? this.showArabic,
    sortByRevelation: sortByRevelation ?? this.sortByRevelation,
    dailyAyahEnabled: dailyAyahEnabled ?? this.dailyAyahEnabled,
    dailyAyahHour: dailyAyahHour ?? this.dailyAyahHour,
    dailyAyahMinute: dailyAyahMinute ?? this.dailyAyahMinute,
    reciterId: reciterId ?? this.reciterId,
    playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    autoScrollWithAudio: autoScrollWithAudio ?? this.autoScrollWithAudio,
    highlightWords: highlightWords ?? this.highlightWords,
  );
}
