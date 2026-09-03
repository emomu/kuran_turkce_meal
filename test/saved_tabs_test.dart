import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:kuran_turkce_meal/features/bookmarks/view/bookmarks_screen.dart';

import 'helpers/localized_app.dart';

/// Kayıtlar sekmesindeki segment kontrolü.
///
/// Seçim, sekmeler arasında kayan tek bir göstergeyle belirtilir. Her segment
/// kendi rengini ayrı canlandırsaydı seçim bir yerde sönüp başka yerde yanar,
/// hareketin nereden nereye gittiği kaybolurdu.
void main() async {
  await TestApp.ensureInitialized();

  setUp(TestApp.reset);

  /// Ekranı boş kayıt listesiyle çizer.
  ///
  /// Test animasyonu sınıyor, veriyi değil; sağlayıcı geçilmezse ekran
  /// veritabanını bekleyip sonsuz yükleme göstergesinde kalır.
  Future<void> pumpScreen(WidgetTester tester) => TestApp.pump(
        tester,
        ProviderScope(
          overrides: [
            for (final tab in SavedTab.values)
              savedEntriesProvider(tab).overrideWith((ref) async => const []),
          ],
          child: const BookmarksScreen(),
        ),
      );

  testWidgets('üç sekme de görünür', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Yer imleri'), findsOneWidget);
    expect(find.text('Notlar'), findsOneWidget);
    expect(find.text('Vurgular'), findsOneWidget);
  });

  testWidgets('seçim göstergesi tek ve kayan bir yüzeydir', (tester) async {
    await pumpScreen(tester);

    // Üç ayrı renkli kutu değil, konumu değişen tek gösterge olmalı.
    expect(find.byType(AnimatedAlign), findsOneWidget);
  });

  testWidgets('sekme değişince gösterge konumu kayar', (tester) async {
    await pumpScreen(tester);

    Alignment alignmentOf() => tester
        .widget<AnimatedAlign>(find.byType(AnimatedAlign))
        .alignment as Alignment;

    // İlk sekme seçili: gösterge solda.
    expect(alignmentOf().x, -1);

    await tester.tap(find.text('Vurgular'));
    await tester.pumpAndSettle();

    // Son sekme seçili: gösterge sağda.
    expect(alignmentOf().x, 1);

    await tester.tap(find.text('Notlar'));
    await tester.pumpAndSettle();

    // Ortadaki sekme: gösterge ortada.
    expect(alignmentOf().x, 0);
  });

  testWidgets('etiket rengi göstergeyle aynı sürede değişir', (tester) async {
    await pumpScreen(tester);

    // İki hareket tek hareket gibi okunmalı; süreler ayrışırsa metin
    // göstergeden önce ya da sonra değişip kopukluk yaratır.
    final indicator =
        tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
    final label = tester.widget<AnimatedDefaultTextStyle>(
      find
          .ancestor(
            of: find.text('Notlar'),
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .first,
    );

    expect(label.duration, indicator.duration);
  });

  testWidgets('içerik sekme değişiminde yumuşak geçer', (tester) async {
    await pumpScreen(tester);

    // Ani zıplama yerine solma; liste yüksekliği sekmeler arasında değişiyor.
    expect(find.byType(AnimatedSwitcher), findsWidgets);
  });

  testWidgets('seçili sekmeye tekrar dokunmak durumu değiştirmez',
      (tester) async {
    await pumpScreen(tester);

    Alignment alignmentOf() => tester
        .widget<AnimatedAlign>(find.byType(AnimatedAlign))
        .alignment as Alignment;

    final before = alignmentOf();
    await tester.tap(find.text('Yer imleri'));
    await tester.pumpAndSettle();
    expect(alignmentOf(), before);
  });
}
