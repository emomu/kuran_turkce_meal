import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';

/// İki tema arasındaki kontrast oranını hesaplar.
/// WCAG AA gövde metni için en az 4.5 ister.
double _contrastRatio(Color a, Color b) {
  double luminance(Color c) => c.computeLuminance();
  final l1 = luminance(a);
  final l2 = luminance(b);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tema erişilebilirliği', () {
    test('açık temada gövde metni WCAG AA kontrastını karşılar', () {
      final scheme = AppTheme.light.colorScheme;
      expect(
        _contrastRatio(scheme.onSurface, AppTheme.light.scaffoldBackgroundColor),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('koyu temada gövde metni WCAG AA kontrastını karşılar', () {
      final scheme = AppTheme.dark.colorScheme;
      expect(
        _contrastRatio(scheme.onSurface, AppTheme.dark.scaffoldBackgroundColor),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('vurgu rengi kendi zemininde okunabilir', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        expect(
          _contrastRatio(theme.colorScheme.primary, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(3.0),
          reason: '${theme.brightness} temasında vurgu rengi soluk kalıyor',
        );
      }
    });

    test('vurgu üstündeki metin okunabilir', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        expect(
          _contrastRatio(theme.colorScheme.onPrimary, theme.colorScheme.primary),
          greaterThanOrEqualTo(4.5),
          reason: '${theme.brightness} temasında buton metni okunmuyor',
        );
      }
    });
  });

  group('Tema yapısı', () {
    test('iki tema da aynı bileşenleri tanımlar', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        expect(theme.textTheme.bodyLarge, isNotNull);
        expect(theme.cardTheme.shape, isNotNull);
        expect(theme.bottomSheetTheme.backgroundColor, isNotNull);
      }
    });

    test('parlaklık değerleri doğru', () {
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.dark.brightness, Brightness.dark);
    });
  });
}
