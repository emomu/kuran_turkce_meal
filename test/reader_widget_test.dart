

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';
import 'package:kuran_turkce_meal/data/models/reader_preferences.dart';
import 'package:kuran_turkce_meal/data/models/user_marks.dart';
import 'package:kuran_turkce_meal/features/reader/widgets/ayah_tile.dart';

import 'helpers/localized_app.dart';
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

const _ayah = Ayah(
  id: 1,
  surahNumber: 96,
  ayahNumber: 1,
  translation: 'Yaratan Rabbinin adıyla oku.',
  tafsir: 'Bu ayet ilk inen ayettir.',
);

void main() async {
  await TestApp.ensureInitialized();

  group('AyahTile', () {
    testWidgets('meal metnini ve ayet numarasını gösterir', (tester) async {
      await _pump(tester, AyahTile(
        ayah: _ayah,
        prefs: const ReaderPreferences(),
        mark: null,
        onTap: () {},
        onLongPress: () {},
      ));

      expect(find.text('Yaratan Rabbinin adıyla oku.'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('yer imi rozetini yalnızca işaretliyken çizer', (tester) async {
      await _pump(tester, AyahTile(
        ayah: _ayah,
        prefs: const ReaderPreferences(),
        mark: null,
        onTap: () {},
        onLongPress: () {},
      ));
      expect(find.byIcon(Icons.bookmark_rounded), findsNothing);

      await _pump(tester, AyahTile(
        ayah: _ayah,
        prefs: const ReaderPreferences(),
        mark: AyahMark(
          ayahId: 1,
          isBookmarked: true,
          updatedAt: DateTime(2026),
        ),
        onTap: () {},
        onLongPress: () {},
      ));
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });


    testWidgets('not varsa metnin altında gösterilir', (tester) async {
      await _pump(tester, AyahTile(
        ayah: _ayah,
        prefs: const ReaderPreferences(),
        mark: AyahMark(
          ayahId: 1,
          note: 'Üzerine düşünülecek.',
          updatedAt: DateTime(2026),
        ),
        onTap: () {},
        onLongPress: () {},
      ));
      expect(find.text('Üzerine düşünülecek.'), findsOneWidget);
    });

    testWidgets('punto ayarı meal metnine uygulanır', (tester) async {
      await _pump(tester, AyahTile(
        ayah: _ayah,
        prefs: const ReaderPreferences(fontScale: 1.6),
        mark: null,
        onTap: () {},
        onLongPress: () {},
      ));

      final text = tester.widget<Text>(
        find.text('Yaratan Rabbinin adıyla oku.'),
      );
      expect(text.style?.fontSize, closeTo(17 * 1.6, 0.01));
    });

    testWidgets('uzun basış geri çağrısı tetiklenir', (tester) async {
      var longPressed = false;
      await _pump(tester, AyahTile(
        ayah: _ayah,
        prefs: const ReaderPreferences(),
        mark: null,
        onTap: () {},
        onLongPress: () => longPressed = true,
      ));

      await tester.longPress(find.text('Yaratan Rabbinin adıyla oku.'));
      expect(longPressed, isTrue);
    });

    testWidgets('koyu temada da taşma olmadan çizilir', (tester) async {
      await _pump(tester, AyahTile(
          ayah: _ayah,
          prefs: const ReaderPreferences(fontScale: 1.6),
          mark: AyahMark(
            ayahId: 1,
            isBookmarked: true,
            highlightColor: 0xFFF5D77E,
            note: 'Not',
            updatedAt: DateTime(2026),
          ),
          onTap: () {},
          onLongPress: () {},
        ),
        brightness: Brightness.dark,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
