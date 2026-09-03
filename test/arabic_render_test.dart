

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';
import 'package:kuran_turkce_meal/data/models/reader_preferences.dart';
import 'package:kuran_turkce_meal/features/reader/widgets/ayah_tile.dart';

import 'helpers/localized_app.dart';
/// Gerçek Uthmani metniyle Arapça gösterimini sınar.
const _ayah = Ayah(
  id: 1,
  surahNumber: 96,
  ayahNumber: 1,
  translation: 'Yaratan Rabbinin adıyla oku',
  arabic: 'ٱقۡرَأۡ بِٱسۡمِ رَبِّكَ ٱلَّذِي خَلَقَ',
);

/// Widget'ı çeviri bağlamıyla çizer ve yüklenmesini bekler.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
}) =>
    TestApp.pump(
      tester,
      SingleChildScrollView(child: child),
      theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
    );

void main() async {
  await TestApp.ensureInitialized();

  group('Arapça metin', () {
    testWidgets('ayar kapalıyken gösterilmez', (tester) async {
      await _pump(tester, AyahTile(
        ayah: _ayah,
        prefs: const ReaderPreferences(showArabic: false),
        mark: null,
        onTap: () {},
        onLongPress: () {},
      ));

      expect(find.text(_ayah.arabic!), findsNothing);
      expect(find.text(_ayah.translation), findsOneWidget);
    });

    testWidgets('ayar açıkken mealin üstünde gösterilir', (tester) async {
      await _pump(tester, AyahTile(
        ayah: _ayah,
        prefs: const ReaderPreferences(showArabic: true),
        mark: null,
        onTap: () {},
        onLongPress: () {},
      ));

      expect(find.text(_ayah.arabic!), findsOneWidget);

      // Arapça metin mealin üstünde konumlanmalı.
      final arabicY = tester.getTopLeft(find.text(_ayah.arabic!)).dy;
      final translationY =
          tester.getTopLeft(find.text(_ayah.translation)).dy;
      expect(arabicY, lessThan(translationY));
    });

    testWidgets('sağdan sola yönde çizilir', (tester) async {
      await _pump(tester, AyahTile(
        ayah: _ayah,
        prefs: const ReaderPreferences(showArabic: true),
        mark: null,
        onTap: () {},
        onLongPress: () {},
      ));

      final text = tester.widget<Text>(find.text(_ayah.arabic!));
      expect(text.textDirection, TextDirection.rtl);
      expect(text.textAlign, TextAlign.right);
    });

    testWidgets('Arapça punto meal puntosundan büyük', (tester) async {
      const prefs = ReaderPreferences(showArabic: true);
      await _pump(tester, AyahTile(
        ayah: _ayah,
        prefs: prefs,
        mark: null,
        onTap: () {},
        onLongPress: () {},
      ));

      final arabic = tester.widget<Text>(find.text(_ayah.arabic!));
      final translation = tester.widget<Text>(find.text(_ayah.translation));

      // Arap hattı aynı puntoda Latin harflerden küçük göründüğü için
      // bilerek büyütülür.
      expect(arabic.style!.fontSize, greaterThan(translation.style!.fontSize!));
      expect(arabic.style!.fontSize, prefs.arabicFontSize);
    });

    testWidgets('punto ölçeği Arapçaya da uygulanır', (tester) async {
      await _pump(tester, AyahTile(
        ayah: _ayah,
        prefs: const ReaderPreferences(showArabic: true, fontScale: 1.6),
        mark: null,
        onTap: () {},
        onLongPress: () {},
      ));

      final arabic = tester.widget<Text>(find.text(_ayah.arabic!));
      expect(arabic.style!.fontSize, closeTo(24 * 1.6, 0.01));
    });

    testWidgets('Arapçası olmayan ayette ayar açık olsa da taşma olmaz',
        (tester) async {
      const noArabic = Ayah(
        id: 2,
        surahNumber: 96,
        ayahNumber: 2,
        translation: 'Meal metni.',
      );

      await _pump(tester, AyahTile(
        ayah: noArabic,
        prefs: const ReaderPreferences(showArabic: true),
        mark: null,
        onTap: () {},
        onLongPress: () {},
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Meal metni.'), findsOneWidget);
    });

    testWidgets('koyu temada da sorunsuz çizilir', (tester) async {
      await _pump(tester, AyahTile(
          ayah: _ayah,
          prefs: const ReaderPreferences(showArabic: true, fontScale: 1.6),
          mark: null,
          onTap: () {},
          onLongPress: () {},
        ),
        brightness: Brightness.dark,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
