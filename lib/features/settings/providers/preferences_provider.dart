import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/reader_preferences.dart';

/// Kullanıcı tercihlerini tutar ve değişiklikleri cihaza yazar.
///
/// Okuma sırasında punto/satır aralığı canlı değiştiği için bu notifier
/// arayüzün en sık dinlenen parçalarından biri. Yazma işlemleri arka planda
/// yapılır, arayüz beklemez.
class PreferencesNotifier extends StateNotifier<ReaderPreferences> {
  PreferencesNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static const _kThemeMode = 'theme_mode';
  static const _kFontScale = 'font_scale';
  static const _kLineHeight = 'line_height';
  static const _kShowArabic = 'show_arabic';
  static const _kSortByRevelation = 'sort_by_revelation';
  static const _kDailyAyahEnabled = 'daily_ayah_enabled';
  static const _kDailyAyahHour = 'daily_ayah_hour';
  static const _kDailyAyahMinute = 'daily_ayah_minute';
  static const _kReciterId = 'reciter_id';
  static const _kPlaybackSpeed = 'playback_speed';
  static const _kAutoScrollWithAudio = 'auto_scroll_with_audio';
  static const _kHighlightWords = 'highlight_words';

  static ReaderPreferences _read(SharedPreferences prefs) {
    return ReaderPreferences(
      themeMode: ThemeMode.values[
          prefs.getInt(_kThemeMode) ?? ThemeMode.system.index],
      fontScale: prefs.getDouble(_kFontScale) ?? 1.0,
      lineHeight: prefs.getDouble(_kLineHeight) ?? 1.7,
      showArabic: prefs.getBool(_kShowArabic) ?? true,
      sortByRevelation: prefs.getBool(_kSortByRevelation) ?? true,
      dailyAyahEnabled: prefs.getBool(_kDailyAyahEnabled) ?? true,
      dailyAyahHour: prefs.getInt(_kDailyAyahHour) ?? 8,
      dailyAyahMinute: prefs.getInt(_kDailyAyahMinute) ?? 0,
      reciterId: prefs.getString(_kReciterId),
      playbackSpeed: prefs.getDouble(_kPlaybackSpeed) ?? 1.0,
      autoScrollWithAudio: prefs.getBool(_kAutoScrollWithAudio) ?? true,
      highlightWords: prefs.getBool(_kHighlightWords) ?? true,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs.setInt(_kThemeMode, mode.index);
  }

  void setFontScale(double scale) {
    final clamped = scale.clamp(0.8, 1.6);
    state = state.copyWith(fontScale: clamped);
    _prefs.setDouble(_kFontScale, clamped);
  }

  void setLineHeight(double height) {
    final clamped = height.clamp(1.4, 2.2);
    state = state.copyWith(lineHeight: clamped);
    _prefs.setDouble(_kLineHeight, clamped);
  }

  void setShowArabic(bool value) {
    state = state.copyWith(showArabic: value);
    _prefs.setBool(_kShowArabic, value);
  }

  void setSortByRevelation(bool value) {
    state = state.copyWith(sortByRevelation: value);
    _prefs.setBool(_kSortByRevelation, value);
  }

  void setDailyAyahEnabled(bool value) {
    state = state.copyWith(dailyAyahEnabled: value);
    _prefs.setBool(_kDailyAyahEnabled, value);
  }

  void setDailyAyahTime(TimeOfDay time) {
    state = state.copyWith(
      dailyAyahHour: time.hour,
      dailyAyahMinute: time.minute,
    );
    _prefs
      ..setInt(_kDailyAyahHour, time.hour)
      ..setInt(_kDailyAyahMinute, time.minute);
  }

  /// Tilaveti okuyan kariyi değiştirir.
  ///
  /// Kari başına ayrı indirme yapıldığı için bu, indirilmiş seslerin
  /// kullanılabilirliğini de değiştirir: yeni karide daha önce indirilmiş sure
  /// yoksa kullanıcıdan yeniden indirmesi istenir. Eski karinin dosyaları
  /// silinmez — kullanıcı geri dönebilir.
  void setReciter(String reciterId) {
    state = state.copyWith(reciterId: reciterId);
    _prefs.setString(_kReciterId, reciterId);
  }

  void setPlaybackSpeed(double speed) {
    final clamped = speed.clamp(0.5, 2.0);
    state = state.copyWith(playbackSpeed: clamped);
    _prefs.setDouble(_kPlaybackSpeed, clamped);
  }

  void setAutoScrollWithAudio(bool value) {
    state = state.copyWith(autoScrollWithAudio: value);
    _prefs.setBool(_kAutoScrollWithAudio, value);
  }

  void setHighlightWords(bool value) {
    state = state.copyWith(highlightWords: value);
    _prefs.setBool(_kHighlightWords, value);
  }

  /// Okuma ayarlarını varsayılana döndürür. Tema ve bildirim tercihleri
  /// korunur — kullanıcı "yazıyı sıfırla" derken temasını kaybetmeyi beklemez.
  void resetReadingDefaults() {
    state = state.copyWith(
      fontScale: 1.0,
      lineHeight: 1.7,
      showArabic: true,
    );
    _prefs
      ..remove(_kFontScale)
      ..remove(_kLineHeight)
      ..remove(_kShowArabic);
  }
}

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, ReaderPreferences>(
  (ref) => PreferencesNotifier(ref.watch(sharedPreferencesProvider)),
);
