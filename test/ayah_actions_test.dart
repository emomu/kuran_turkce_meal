

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/theme/app_colors.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';
import 'package:kuran_turkce_meal/data/models/user_marks.dart';
import 'package:kuran_turkce_meal/features/reader/widgets/ayah_actions_sheet.dart';

import 'helpers/localized_app.dart';
const _ayah = Ayah(
  id: 1,
  surahNumber: 96,
  ayahNumber: 1,
  translation: 'Yaratan Rabbinin adıyla oku.',
  tafsir: 'İlk inen ayet.',
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

  group('AyahActionsSheet', () {
    testWidgets('yer imi yokken "ekle", varken "kaldır" yazar', (tester) async {
      await _pump(tester, AyahActionsSheet(
        ayah: _ayah,
        surahName: 'Alak',
        mark: null,
        onToggleBookmark: () {},
        onSetHighlight: (_) {},
        onEditNote: () {},
        onAnalyseRoots: () {},
      ));
      expect(find.text('Yer imi ekle'), findsOneWidget);

      await _pump(tester, AyahActionsSheet(
        ayah: _ayah,
        surahName: 'Alak',
        mark: AyahMark(
          ayahId: 1,
          isBookmarked: true,
          updatedAt: DateTime(2026),
        ),
        onToggleBookmark: () {},
        onSetHighlight: (_) {},
        onEditNote: () {},
        onAnalyseRoots: () {},
      ));
      expect(find.text('Yer imini kaldır'), findsOneWidget);
    });

    testWidgets('not yokken "ekle", varken "düzenle" yazar', (tester) async {
      await _pump(tester, AyahActionsSheet(
        ayah: _ayah,
        surahName: 'Alak',
        mark: AyahMark(ayahId: 1, note: 'Notum', updatedAt: DateTime(2026)),
        onToggleBookmark: () {},
        onSetHighlight: (_) {},
        onEditNote: () {},
        onAnalyseRoots: () {},
      ));
      expect(find.text('Notu düzenle'), findsOneWidget);
    });


    testWidgets('renk seçimi seçili rengi geri bildirir', (tester) async {
      int? picked;
      var called = false;

      await _pump(tester, AyahActionsSheet(
              ayah: _ayah,
              surahName: 'Alak',
              mark: null,
              onToggleBookmark: () {},
              onSetHighlight: (c) {
                picked = c;
                called = true;
              },
              onEditNote: () {},
        onAnalyseRoots: () {},
            ));

      // İlk renk noktasına dokun.
      final dots = find.byType(GestureDetector);
      await tester.tap(dots.at(0), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(picked, AppColors.highlightYellow.toARGB32());
    });

    testWidgets('seçili renge tekrar dokunmak vurguyu kaldırır',
        (tester) async {
      int? picked = -1;

      await _pump(tester, AyahActionsSheet(
        ayah: _ayah,
        surahName: 'Alak',
        mark: AyahMark(
          ayahId: 1,
          highlightColor: AppColors.highlightYellow.toARGB32(),
          updatedAt: DateTime(2026),
        ),
        onToggleBookmark: () {},
        onSetHighlight: (c) => picked = c,
        onEditNote: () {},
        onAnalyseRoots: () {},
      ));

      await tester.tap(find.byType(GestureDetector).at(0), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(picked, isNull, reason: 'Aynı renge dokununca vurgu kalkmalı');
    });
  });
}
