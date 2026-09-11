import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:kuran_turkce_meal/features/bookmarks/view/bookmarks_screen.dart';
import 'package:kuran_turkce_meal/features/discover/view/discover_screen.dart';
import 'package:kuran_turkce_meal/features/plans/providers/plans_provider.dart';
import 'package:kuran_turkce_meal/features/plans/view/plans_screen.dart';
import 'package:kuran_turkce_meal/features/settings/view/settings_screen.dart';
import 'package:kuran_turkce_meal/shared/widgets/responsive_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/localized_app.dart';

/// Tablet ölçülerinde çizim denetimi.
///
/// App Review incelemesi bir iPad Air 11" (M3) üzerinde yapıldı ve mevcut
/// testlerin hiçbiri o ölçüyü kapsamıyordu: yatay testleri 844x390 (telefon
/// yan) ve 1600x900 (geniş masaüstü) kullanıyor, aradaki tablet aralığı boş
/// kalıyordu.
///
/// Burada denetlenen iki şey var. Birincisi taşma: sabit yükseklikli sütunlar
/// ve ızgaralar bu ölçüde sığıyor mu. İkincisi — asıl mesele — içeriğin
/// ekranın tamamına yayılıp yayılmadığı. Telefon arayüzü gerilerek tablete
/// konduğunda uygulama "özensiz port" izlenimi verir; okuma genişliği sınırı
/// tam da bunun için var ve gerçekten işlediği görülmeli.
void main() async {
  await TestApp.ensureInitialized();

  // iPad Air 11" (M3) mantıksal ölçüleri. İnceleme bu cihazda yapıldı.
  const iPadPortrait = Size(820, 1180);
  const iPadLandscape = Size(1180, 820);

  Future<void> pumpAt(
    WidgetTester tester,
    Widget screen,
    Size size, {
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
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

  group('Tablette taşma yok', () {
    testWidgets('Keşfet dikeyde taşmadan çizilir', (tester) async {
      await pumpAt(tester, const DiscoverScreen(), iPadPortrait);
      expect(tester.takeException(), isNull);
      expect(find.text('Keşfet'), findsOneWidget);
    });

    testWidgets('Keşfet yatayda taşmadan çizilir', (tester) async {
      await pumpAt(tester, const DiscoverScreen(), iPadLandscape);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Planlar taşmadan çizilir', (tester) async {
      await pumpAt(
        tester,
        const PlansScreen(),
        iPadPortrait,
        overrides: [planProgressProvider.overrideWith((ref, id) async => 0)],
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Planlar'), findsOneWidget);
    });

    testWidgets('Ayarlar taşmadan çizilir', (tester) async {
      await pumpAt(tester, const SettingsScreen(), iPadPortrait);
      expect(tester.takeException(), isNull);
      expect(find.text('Ayarlar'), findsOneWidget);
    });

    testWidgets('Kayıtlar taşmadan çizilir', (tester) async {
      await pumpAt(
        tester,
        const BookmarksScreen(),
        iPadPortrait,
        overrides: [savedEntriesProvider.overrideWith((ref, tab) async => [])],
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('İçerik ekranın tamamına yayılmaz', () {
    /// Ekranda çizilen bir metnin genişliği okuma sınırını aşmamalı.
    ///
    /// Telefon arayüzünün gerilmiş hâli tam olarak bu sınavda görünür: satır
    /// 820pt boyunca uzarsa göz satır sonundan satır başına dönerken yerini
    /// kaybeder ve uygulama bir tablet uygulaması gibi durmaz.
    void expectWithinReadingWidth(WidgetTester tester, Finder finder) {
      final width = tester.getSize(finder).width;
      expect(
        width,
        lessThanOrEqualTo(ContentWidth.standard),
        reason: 'içerik ${width.toStringAsFixed(0)}pt genişledi; '
            'sınır ${ContentWidth.standard}pt',
      );
    }

    testWidgets('Planlar listesi sınırın içinde kalır', (tester) async {
      await pumpAt(
        tester,
        const PlansScreen(),
        iPadPortrait,
        overrides: [planProgressProvider.overrideWith((ref, id) async => 0)],
      );

      expectWithinReadingWidth(tester, find.text('Otuz Günde Hatim').first);
    });

    testWidgets('Ayarlar satırları sınırın içinde kalır', (tester) async {
      await pumpAt(tester, const SettingsScreen(), iPadPortrait);

      expectWithinReadingWidth(tester, find.text('Ayarlar').first);
    });

    testWidgets('Keşfet başlığı sınırın içinde kalır', (tester) async {
      await pumpAt(tester, const DiscoverScreen(), iPadPortrait);

      expectWithinReadingWidth(tester, find.text('Keşfet').first);
    });
  });

  group('Izgara tablette sütun sayısını artırır', () {
    testWidgets('Keşfet ızgarası telefondan daha çok sütun gösterir',
        (tester) async {
      // Izgara genişliğe göre sütun seçiyor: telefonda iki, tablette üç.
      // Sabit ikiyle kalsaydı kartlar avuç içi kadar genişler ve ızgara iki
      // dev bloğa dönüşürdü — "gerilmiş telefon arayüzü" izlenimi.
      await pumpAt(tester, const DiscoverScreen(), iPadPortrait);

      final grid = find.byType(SliverGrid);
      expect(grid, findsOneWidget);

      final delegate = tester.widget<SliverGrid>(grid).gridDelegate
          as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, greaterThan(2));
    });
  });
}
