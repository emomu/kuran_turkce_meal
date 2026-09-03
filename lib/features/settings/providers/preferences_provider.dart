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

  static ReaderPreferences _read(SharedPreferences prefs) {
    return ReaderPreferences(
      themeMode: ThemeMode.values[
          prefs.getInt(_kThemeMode) ?? ThemeMode.system.index],
      fontScale: prefs.getDouble(_kFontScale) ?? 1.0,
      lineHeight: prefs.getDouble(_kLineHeight) ?? 1.7,
      showArabic: prefs.getBool(_kShowArabic) ?? false,
      sortByRevelation: prefs.getBool(_kSortByRevelation) ?? true,
      dailyAyahEnabled: prefs.getBool(_kDailyAyahEnabled) ?? true,
      dailyAyahHour: prefs.getInt(_kDailyAyahHour) ?? 8,
      dailyAyahMinute: prefs.getInt(_kDailyAyahMinute) ?? 0,
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

  /// Okuma ayarlarını varsayılana döndürür. Tema ve bildirim tercihleri
  /// korunur — kullanıcı "yazıyı sıfırla" derken temasını kaybetmeyi beklemez.
  void resetReadingDefaults() {
    state = state.copyWith(
      fontScale: 1.0,
      lineHeight: 1.7,
      showArabic: false,
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
