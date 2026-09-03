

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';
import 'package:kuran_turkce_meal/data/models/reader_preferences.dart';
import 'package:kuran_turkce_meal/features/reader/widgets/ayah_tile.dart';

import 'helpers/localized_app.dart';
/// Bazı meallerde çevirmen ardışık ayetleri tek cümlede karşılar; bu ayetler
/// tek blokta birleştirilir ve rozet aralık gösterir.
const _range = Ayah(
  id: 1,
  surahNumber: 96,
  ayahNumber: 9,
  endAyahNumber: 10,
  translation: 'Namaz kıldığı zaman, bir kulu engelleyeni gördün mü',
  arabic: 'أَرَءَيۡتَ ٱلَّذِي يَنۡهَىٰ\nعَبۡدًا إِذَا صَلَّىٰ',
);

const _single = Ayah(
  id: 2,
  surahNumber: 96,
  ayahNumber: 1,
  translation: 'Yaratan Rabbinin adıyla oku',
);

/// Widget'ı çeviri bağlamıyla çizer ve yüklenmesini bekler.
Future<void> _pump(WidgetTester tester, Widget child) =>
    TestApp.pump(
      tester,
      SingleChildScrollView(child: child),
      theme: AppTheme.light,
    );

void main() async {
  await TestApp.ensureInitialized();

  group('Ayah aralık modeli', () {
    test('tekil ayette endAyahNumber kendisine eşitlenir', () {
      expect(_single.endAyahNumber, 1);
      expect(_single.isRange, isFalse);
      expect(_single.numberLabel, '1');
      expect(_single.reference, '96:1');
    });

    test('aralıkta etiket ve referans aralığı gösterir', () {
      expect(_range.isRange, isTrue);
      expect(_range.numberLabel, '9-10');
      expect(_range.reference, '96:9-10');
    });

    test('haritaya çevrilip geri okunduğunda aralık korunur', () {
      final restored = Ayah.fromMap(_range.toMap());
      expect(restored.ayahNumber, 9);
      expect(restored.endAyahNumber, 10);
      expect(restored.numberLabel, '9-10');
    });

    test('end_ayah_number eksikse tekil ayet varsayılır', () {
      final restored = Ayah.fromMap(const {
        'id': 3,
        'surah_number': 1,
        'ayah_number': 5,
        'translation': 'metin',
      });
      expect(restored.endAyahNumber, 5);
      expect(restored.isRange, isFalse);
    });
  });

  group('AyahTile aralık gösterimi', () {
    testWidgets('rozet aralığı yazar', (tester) async {
      await _pump(tester, AyahTile(
        ayah: _range,
        prefs: const ReaderPreferences(),
        mark: null,
        onTap: () {},
        onLongPress: () {},
      ));

      expect(find.text('9-10'), findsOneWidget);
      // Meal tek kez görünür — tekrar yok.
      expect(find.text(_range.translation), findsOneWidget);
    });

    testWidgets('tekil ayette sade numara yazar', (tester) async {
      await _pump(tester, AyahTile(
        ayah: _single,
        prefs: const ReaderPreferences(),
        mark: null,
        onTap: () {},
        onLongPress: () {},
      ));

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('aralıktaki tüm Arapça satırları gösterilir', (tester) async {
      await _pump(tester, AyahTile(
        ayah: _range,
        prefs: const ReaderPreferences(showArabic: true),
        mark: null,
        onTap: () {},
        onLongPress: () {},
      ));

      expect(find.text(_range.arabic!), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Arapça çizilen ayette blok boşluğu artar', (tester) async {
      Future<double> heightWith(Ayah ayah, bool showArabic) async {
        await _pump(tester, AyahTile(
          ayah: ayah,
          prefs: ReaderPreferences(showArabic: showArabic),
          mark: null,
          onTap: () {},
          onLongPress: () {},
        ));
        return tester.getSize(find.byType(AyahTile)).height;
      }

      expect(
        await heightWith(_range, true),
        greaterThan(await heightWith(_range, false)),
      );
    });

    testWidgets('Arapçası olmayan ayette ayar açık olsa da boşluk artmaz',
        (tester) async {
      // Boşluk artışı ayarın açık olmasına değil, Arapçanın gerçekten
      // çizilmesine bağlı olmalı; aksi halde Arapçası bulunmayan ayetler
      // sebepsiz yere aralanırdı.
      Future<double> heightWith(bool showArabic) async {
        await _pump(tester, AyahTile(
          ayah: _single,
          prefs: ReaderPreferences(showArabic: showArabic),
          mark: null,
          onTap: () {},
          onLongPress: () {},
        ));
        return tester.getSize(find.byType(AyahTile)).height;
      }

      expect(await heightWith(true), await heightWith(false));
    });
  });
}
