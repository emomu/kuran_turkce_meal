import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/features/onboarding/providers/tour_provider.dart';
import 'package:kuran_turkce_meal/features/onboarding/widgets/coach_mark.dart';
import 'package:kuran_turkce_meal/features/plans/providers/plans_provider.dart';
import 'package:kuran_turkce_meal/features/plans/view/plans_screen.dart';
import 'package:kuran_turkce_meal/data/repositories/root_repository.dart';
import 'package:kuran_turkce_meal/features/roots/view/root_detail_screen.dart';
import 'package:kuran_turkce_meal/features/search/view/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/localized_app.dart';

/// Arama ve Planlar ekranlarındaki tanıtım turları.
///
/// Her turun iki sözleşmesi var: ilk açılışta görünmesi ve bir kez
/// izlendikten sonra bir daha çıkmaması. İkincisi bozulursa kullanıcı her
/// sekmeye dokunuşunda aynı ipucunu görür — tanıtım rahatsızlığa dönüşür.
void main() async {
  await TestApp.ensureInitialized();
  setUp(TestApp.reset);

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Map<String, Object> initialPrefs = const {},
    List<Override> overrides = const [],
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
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

  group('Arama ekranı turu', () {
    testWidgets('ilk açılışta arama ipucu gösterilir', (tester) async {
      await pumpScreen(tester, const SearchScreen());

      expect(find.byType(CoachMarkOverlay), findsOneWidget);
      expect(find.text('Meal ve tefsirde arayın'), findsOneWidget);
    });

    testWidgets('ikinci adım Türkçe karakterleri anlatır', (tester) async {
      await pumpScreen(tester, const SearchScreen());

      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();

      expect(find.text('Türkçe karakter derdi yok'), findsOneWidget);
      expect(find.text('Anladım'), findsOneWidget);
    });

    testWidgets('izlendikten sonra arama alanı kullanılabilir',
        (tester) async {
      await pumpScreen(tester, const SearchScreen());

      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();

      expect(find.byType(CoachMarkOverlay), findsNothing);
      // Katman kapandıktan sonra alana gerçekten yazılabilmeli.
      await tester.enterText(find.byType(TextField), 'adalet');
      await tester.pump();
      expect(find.text('adalet'), findsOneWidget);
    });

    testWidgets('daha önce izlendiyse hiç açılmaz', (tester) async {
      await pumpScreen(
        tester,
        const SearchScreen(),
        initialPrefs: {TourId.search.storageKey: true},
      );

      expect(find.byType(CoachMarkOverlay), findsNothing);
    });
  });

  group('Planlar ekranı turu', () {
    final planOverrides = [
      planProgressProvider.overrideWith((ref, id) async => 0),
    ];

    testWidgets('ilk açılışta plan ipucu gösterilir', (tester) async {
      await pumpScreen(
        tester,
        const PlansScreen(),
        overrides: planOverrides,
      );

      expect(find.byType(CoachMarkOverlay), findsOneWidget);
      expect(find.text('Kendi temponuzu seçin'), findsOneWidget);
    });

    testWidgets('üç adım sırayla gezilir', (tester) async {
      await pumpScreen(
        tester,
        const PlansScreen(),
        overrides: planOverrides,
      );

      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      expect(find.text('İki farklı sıra'), findsOneWidget);

      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      expect(find.text('İlerlemeniz kaydedilir'), findsOneWidget);

      await tester.tap(find.text('Anladım'));
      await tester.pumpAndSettle();
      expect(find.byType(CoachMarkOverlay), findsNothing);
    });

    testWidgets('tur kapanınca plan kartları görünür kalır', (tester) async {
      await pumpScreen(
        tester,
        const PlansScreen(),
        overrides: planOverrides,
      );

      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();

      expect(find.text('Bir Yılda Kronolojik'), findsOneWidget);
      expect(find.text('Otuz Günde Hatim'), findsOneWidget);
    });

    testWidgets('daha önce izlendiyse hiç açılmaz', (tester) async {
      await pumpScreen(
        tester,
        const PlansScreen(),
        initialPrefs: {TourId.plans.storageKey: true},
        overrides: planOverrides,
      );

      expect(find.byType(CoachMarkOverlay), findsNothing);
      expect(find.text('Planlar'), findsOneWidget);
    });
  });

  group('Kök analizi turu', () {
    // Kök verisi 4 MB'lık bir asset; bir kez yüklenip depo olarak verilir.
    late RootRepository loadedRepo;

    setUpAll(() async {
      loadedRepo = RootRepository();
      await loadedRepo.ensureLoaded();
    });

    Future<void> pumpRoot(
      WidgetTester tester, {
      Map<String, Object> initialPrefs = const {},
    }) =>
        pumpScreen(
          tester,
          // خلق — ekran görüntüsündeki kök; 261 yerde geçiyor.
          const RootDetailScreen(rootArabic: 'خلق'),
          initialPrefs: initialPrefs,
          overrides: [rootRepositoryProvider.overrideWithValue(loadedRepo)],
        );

    testWidgets('ilk açılışta kök ipucu gösterilir', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpRoot(tester);

      expect(find.byType(CoachMarkOverlay), findsOneWidget);
      expect(find.text('Kelimenin kökü'), findsOneWidget);
    });

    testWidgets('karartma üst çubuğu da örter', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpRoot(tester);

      // Karartma ekranın tamamını kaplamalı. `TourHost` `Scaffold`'un
      // `body`'sine sarılı olduğu için katman ekranın kendi ağacında
      // çizilseydi yalnızca gövdeyi kaplar, `AppBar` aydınlık kalırdı —
      // üst çubuktaki arama simgesini işaret eden adımda delik açılamazdı.
      final scrim = tester.getRect(find.byType(CoachMarkOverlay));
      final appBar = tester.getRect(find.byType(AppBar));

      expect(scrim.top, lessThanOrEqualTo(appBar.top),
          reason: 'karartma üst çubuğun altından başlıyor');
      expect(scrim.bottom, greaterThanOrEqualTo(appBar.bottom));
      expect(scrim.height, tester.view.physicalSize.height,
          reason: 'karartma ekranın tamamını kaplamalı');
    });

    testWidgets('üç adım sırayla gezilir', (tester) async {
      await pumpRoot(tester);

      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      expect(find.text('Kökün geçtiği her yer'), findsOneWidget);

      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      expect(find.text('Başka kök arayın'), findsOneWidget);

      await tester.tap(find.text('Anladım'));
      await tester.pumpAndSettle();
      expect(find.byType(CoachMarkOverlay), findsNothing);
    });

    testWidgets('tur kapanınca kök ve geçişler görünür kalır',
        (tester) async {
      await pumpRoot(tester);

      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();

      expect(find.text('خلق'), findsWidgets);
      expect(find.text('GEÇTİĞİ AYETLER'), findsOneWidget);
    });

    testWidgets('daha önce izlendiyse hiç açılmaz', (tester) async {
      await pumpRoot(tester, initialPrefs: {TourId.roots.storageKey: true});

      expect(find.byType(CoachMarkOverlay), findsNothing);
    });
  });

  group('Turlar birbirinden bağımsız', () {
    testWidgets('arama turunu izlemek planlar turunu kapatmaz',
        (tester) async {
      await pumpScreen(
        tester,
        const PlansScreen(),
        initialPrefs: {TourId.search.storageKey: true},
        overrides: [planProgressProvider.overrideWith((ref, id) async => 0)],
      );

      // Arama turu izlenmiş olsa da planlar turu hâlâ gösterilmeli.
      expect(find.byType(CoachMarkOverlay), findsOneWidget);
      expect(find.text('Kendi temponuzu seçin'), findsOneWidget);
    });
  });

  group('Tercih deposu yokken', () {
    testWidgets('ekran tur olmadan da açılır', (tester) async {
      // Tercih deposu kurulmamış bir ağaç (tekil widget testi, önizleme
      // aracı). Tanıtım uğruna ekran çökmemeli.
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: SizedBox()),
          ),
        );
        await tester.pump();
      });

      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            child: TestApp.wrap(const PlansScreen(), theme: AppTheme.light),
          ),
        );
        await tester.pump();
      });
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CoachMarkOverlay), findsNothing);
      expect(find.text('Planlar'), findsOneWidget);
    });
  });

  group('Gizli sekme', () {
    /// Sekme kabuğunun davranışını taklit eder.
    ///
    /// Sekmeler `IndexedStack` ile tutulur: seçili olmayan ekran çizilmez
    /// ama ağaçta canlı kalır. Tur bu farkı gözetmezse, görünmeyen bir
    /// ekranın ipucu açılıp öndeki ekranın üstünde belirir.
    Future<void> pumpTabs(WidgetTester tester, {required int index}) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: TestApp.wrap(
              // Gerçek kabuk gibi: her dalın kendi `Navigator`'ı, dolayısıyla
              // kendi `Overlay`'i var. Tek ortak katman kullanılsaydı bu
              // ayrım kaybolur ve test asıl hatayı ölçemezdi.
              IndexedStack(
                index: index,
                children: [
                  Navigator(
                    onGenerateRoute: (_) => MaterialPageRoute<void>(
                      builder: (_) => const SearchScreen(),
                    ),
                  ),
                  Navigator(
                    onGenerateRoute: (_) => MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        body: Center(child: Text('ayarlar')),
                      ),
                    ),
                  ),
                ],
              ),
              theme: AppTheme.light,
            ),
          ),
        );
        await tester.pump();
      });
      await tester.pumpAndSettle();
    }

    testWidgets('görünmeyen sekmenin turu açılmaz', (tester) async {
      // İkinci sekme seçili: arama ekranı ağaçta ama görünmüyor.
      await pumpTabs(tester, index: 1);

      expect(find.text('ayarlar'), findsOneWidget);
      expect(find.byType(CoachMarkOverlay), findsNothing,
          reason: 'gizli sekmenin turu öndeki ekranın üstünde belirdi');
      expect(find.text('Meal ve tefsirde arayın'), findsNothing);
    });

    testWidgets('sekme öne gelince turu açılır', (tester) async {
      // Aynı ekran seçili olduğunda tur normal şekilde çalışmalı;
      // görünürlük kontrolü turu büsbütün kapatmamalı.
      await pumpTabs(tester, index: 0);

      expect(find.byType(CoachMarkOverlay), findsOneWidget);
      expect(find.text('Meal ve tefsirde arayın'), findsOneWidget);
    });
  });
}
