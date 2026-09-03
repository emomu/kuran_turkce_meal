import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:kuran_turkce_meal/features/bookmarks/view/bookmarks_screen.dart';
import 'package:kuran_turkce_meal/features/plans/providers/plans_provider.dart';
import 'package:kuran_turkce_meal/features/plans/view/plans_screen.dart';
import 'package:kuran_turkce_meal/features/settings/view/settings_screen.dart';
import 'package:kuran_turkce_meal/shared/widgets/responsive_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/localized_app.dart';

/// Ekranların yatayda gerçekten çizilebildiğinin denetimi.
///
/// Birim testleri dolgu hesabını doğrular ama asıl soru şudur: ekran yan
/// çevrildiğinde bir şey taşıyor mu? Yatayda yükseklik yarıya iner ve sabit
/// yükseklikli sütunlar sığmayabilir. Flutter taşma olduğunda çizim
/// sırasında hata üretir; bu testler o hatanın oluşmadığını doğrular.
///
/// Ayrıca aynı ekran dikeyde de çizilir — yatay için yapılan değişikliğin
/// dikey görünümü bozmadığı görülsün.
void main() async {
  await TestApp.ensureInitialized();

  // iPhone 13 yatay: 844x390. Dikeydekinin tam tersi.
  const landscape = Size(844, 390);
  const portrait = Size(390, 844);

  /// Ekranı verilen ölçüde çizer ve taşma olup olmadığını döndürür.
  Future<void> pumpAt(
    WidgetTester tester,
    Widget screen,
    Size size, {
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    // Yatayda çentik yanda kalır; gerçek cihaz koşulu bu.
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            ...overrides,
          ],
          child: TestApp.wrap(screen, theme: AppTheme.light),
        ),
      );
      await tester.pump();
    });
    await tester.pumpAndSettle();
  }

  group('Yatayda çizim', () {
    testWidgets('PlansScreen yatayda taşmadan çizilir', (tester) async {
      await pumpAt(
        tester,
        const PlansScreen(),
        landscape,
        overrides: [planProgressProvider.overrideWith((ref, id) async => 0)],
      );

      // Taşma olsaydı `pumpAndSettle` sırasında hata fırlatılırdı.
      expect(tester.takeException(), isNull);
      expect(find.text('Planlar'), findsOneWidget);
    });

    testWidgets('SettingsScreen yatayda taşmadan çizilir', (tester) async {
      await pumpAt(tester, const SettingsScreen(), landscape);

      expect(tester.takeException(), isNull);
      expect(find.text('Ayarlar'), findsOneWidget);
    });

    testWidgets('BookmarksScreen yatayda taşmadan çizilir', (tester) async {
      await pumpAt(
        tester,
        const BookmarksScreen(),
        landscape,
        overrides: [
          savedEntriesProvider.overrideWith((ref, tab) async => []),
        ],
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('Dikey görünüm korunur', () {
    testWidgets('PlansScreen dikeyde aynı içeriği gösterir', (tester) async {
      await pumpAt(
        tester,
        const PlansScreen(),
        portrait,
        overrides: [planProgressProvider.overrideWith((ref, id) async => 0)],
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Planlar'), findsOneWidget);
      expect(find.text('Otuz Günde Hatim'), findsOneWidget);
    });
  });

  group('İçerik genişliği', () {
    testWidgets('yatayda liste ekranın tamamına yayılmaz', (tester) async {
      await pumpAt(
        tester,
        const PlansScreen(),
        landscape,
        overrides: [planProgressProvider.overrideWith((ref, id) async => 0)],
      );

      // Başlık metni ortalanmış sütunun içinde kalmalı; ekranın sol
      // kenarından sütun payı kadar uzakta başlar.
      final titleBox = tester.getRect(find.text('Planlar'));
      final expectedSide = (landscape.width - ContentWidth.standard) / 2;

      expect(titleBox.left, greaterThanOrEqualTo(expectedSide));
    });
  });
}
