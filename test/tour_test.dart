import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/features/onboarding/providers/tour_provider.dart';
import 'package:kuran_turkce_meal/features/onboarding/widgets/coach_mark.dart';
import 'package:kuran_turkce_meal/features/onboarding/widgets/tour_host.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/localized_app.dart';

/// Tanıtım turu denetimi.
///
/// Turun iki sözleşmesi var ve ikisi de bozulursa kullanıcıyı rahatsız eder:
///  - bir kez gösterilir, sonra bir daha çıkmaz (cihazda saklanır),
///  - hedefi ekranda olmayan adım gösterilmez.
///
/// Aşağıdaki testler ikisini de doğrular.
void main() async {
  await TestApp.ensureInitialized();
  setUp(TestApp.reset);

  /// Turu barındıran küçük bir test ekranı çizer.
  Future<ProviderContainer> pumpTour(
    WidgetTester tester, {
    required GlobalKey targetKey,
    Map<String, Object> initialPrefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TestApp.wrap(
            Scaffold(
              body: TourHost(
                tour: TourId.reader,
                steps: () => [
                  TourStep(
                    targetKey: targetKey,
                    title: 'Ayete basılı tutun',
                    body: 'Yer imi, not ve vurgu için.',
                  ),
                  const TourStep(
                    title: 'Sure sonunda çekin',
                    body: 'Sıradaki sure açılır.',
                  ),
                ],
                child: Center(
                  child: SizedBox(
                    key: targetKey,
                    width: 200,
                    height: 60,
                    child: const Text('1. Yaratan Rabbinin adıyla oku.'),
                  ),
                ),
              ),
            ),
            theme: AppTheme.light,
          ),
        ),
      );
      await tester.pump();
    });
    await tester.pumpAndSettle();

    return container;
  }

  group('İlk gösterim', () {
    testWidgets('tur daha önce izlenmediyse açılır', (tester) async {
      await pumpTour(tester, targetKey: GlobalKey());

      expect(find.text('Ayete basılı tutun'), findsOneWidget);
      expect(find.byType(CoachMarkOverlay), findsOneWidget);
    });

    testWidgets('izlenmiş tur bir daha açılmaz', (tester) async {
      await pumpTour(
        tester,
        targetKey: GlobalKey(),
        initialPrefs: {TourId.reader.storageKey: true},
      );

      expect(find.byType(CoachMarkOverlay), findsNothing);
      // Altındaki ekran normal çalışmaya devam eder.
      expect(find.textContaining('Yaratan Rabbinin'), findsOneWidget);
    });
  });

  group('Adımlar arası geçiş', () {
    testWidgets('devam tuşu sonraki adıma geçirir', (tester) async {
      await pumpTour(tester, targetKey: GlobalKey());

      expect(find.text('Ayete basılı tutun'), findsOneWidget);

      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();

      expect(find.text('Ayete basılı tutun'), findsNothing);
      expect(find.text('Sure sonunda çekin'), findsOneWidget);
    });

    testWidgets('son adımda "Anladım" görünür', (tester) async {
      await pumpTour(tester, targetKey: GlobalKey());

      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();

      expect(find.text('Anladım'), findsOneWidget);
      // Son adımda atlama seçeneği anlamsız; kaldırılır.
      expect(find.text('Atla'), findsNothing);
    });
  });

  group('Kapatma ve kalıcılık', () {
    testWidgets('atlanınca katman kapanır', (tester) async {
      await pumpTour(tester, targetKey: GlobalKey());

      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();

      expect(find.byType(CoachMarkOverlay), findsNothing);
    });

    testWidgets('atlanan tur görüldü olarak kaydedilir', (tester) async {
      final container = await pumpTour(tester, targetKey: GlobalKey());

      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();

      // Cihaza yazıldığı için uygulama yeniden açıldığında da çıkmaz.
      expect(container.read(tourProvider), contains(TourId.reader));
    });

    testWidgets('bitirilen tur görüldü olarak kaydedilir', (tester) async {
      final container = await pumpTour(tester, targetKey: GlobalKey());

      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anladım'));
      await tester.pumpAndSettle();

      expect(container.read(tourProvider), contains(TourId.reader));
      expect(find.byType(CoachMarkOverlay), findsNothing);
    });
  });

  group('Ayarlardan sıfırlama', () {
    testWidgets('sıfırlanınca tur yeniden gösterilir', (tester) async {
      final container = await pumpTour(
        tester,
        targetKey: GlobalKey(),
        initialPrefs: {TourId.reader.storageKey: true},
      );

      expect(find.byType(CoachMarkOverlay), findsNothing);

      container.read(tourProvider.notifier).resetAll();
      await tester.pumpAndSettle();

      expect(find.byType(CoachMarkOverlay), findsOneWidget);
    });
  });

  group('Hedefin sonradan yer değiştirmesi', () {
    testWidgets('delik yeni konuma taşınır', (tester) async {
      // Gerçek cihazda yazı tipleri ağdan yüklenir ve yüklendiğinde metin
      // yeniden yerleşir — işaret edilen ayet aşağı kayar. Delik `build`
      // sırasında ölçülürse eski yerde açılı kalır ve kullanıcı ayetin
      // yanında boş bir kutu görür.
      final targetKey = GlobalKey();
      final rebuild = ValueNotifier<double>(0);
      addTearDown(rebuild.dispose);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.runAsync(() async {
        await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: TestApp.wrap(
            Scaffold(
              body: TourHost(
                tour: TourId.reader,
                steps: () => [
                  TourStep(
                    targetKey: targetKey,
                    title: 'Ayete basılı tutun',
                    body: 'Yer imi, not ve vurgu için.',
                  ),
                ],
                child: ValueListenableBuilder<double>(
                  valueListenable: rebuild,
                  builder: (context, offset, _) => Column(
                    children: [
                      // Üstteki boşluk sonradan büyür; hedef aşağı kayar.
                      SizedBox(height: offset),
                      SizedBox(
                        key: targetKey,
                        width: 200,
                        height: 60,
                        child: const Text('1. Yaratan Rabbinin adıyla oku.'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            theme: AppTheme.light,
          ),
        ),
        );
        await tester.pump();
      });
      await tester.pumpAndSettle();

      final before = tester.getRect(
        find.text('1. Yaratan Rabbinin adıyla oku.'),
      );

      // Yerleşim değişir (yazı tipi yüklendi, liste konumlandı).
      rebuild.value = 120;
      await tester.pumpAndSettle();

      final after = tester.getRect(
        find.text('1. Yaratan Rabbinin adıyla oku.'),
      );
      expect(after.top, greaterThan(before.top), reason: 'hedef kaymalıydı');

      // Deliğin çizildiği kare — boyama anında ölçülür, bu yüzden ekranda
      // gerçekten görünen deliğin konumu budur.

      final painters = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(CoachMarkOverlay),
              matching: find.byType(CustomPaint),
            ),
          )
          .where((p) => p.painter.runtimeType.toString() == '_SpotlightPainter');
      final drawn = (painters.single.painter as dynamic).target as Rect?;

      expect(drawn, isNotNull);
      expect(
        drawn!.top,
        closeTo(after.top, 8),
        reason: 'delik eski konumda kalmış: $drawn, hedef: $after',
      );
    });
  });

  group('Baloncuk yerleşimi', () {
    /// Verilen hedef konumuyla turu çizer ve baloncuğun karesini döndürür.
    Future<({Rect bubble, Rect? target, Size screen})> layoutWith(
      WidgetTester tester, {
      required Alignment targetAlignment,
      GlobalKey? targetKey,
    }) async {
      final key = targetKey ?? GlobalKey();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: TestApp.wrap(
              TourHost(
                tour: TourId.reader,
                steps: () => [
                  TourStep(
                    targetKey: key,
                    title: 'Ayete basılı tutun',
                    body: 'Yer imi, not, vurgu, paylaşma ve kök analizi '
                        'için ayete uzun basmanız yeterli.',
                  ),
                ],
                child: Align(
                  alignment: targetAlignment,
                  child: SizedBox(
                    key: key,
                    width: 44,
                    height: 44,
                    child: const Text('hedef'),
                  ),
                ),
              ),
              theme: AppTheme.light,
            ),
          ),
        );
        await tester.pump();
      });
      await tester.pumpAndSettle();

      return (
        bubble: tester.getRect(find.text('Ayete basılı tutun')),
        target: tester.getRect(find.byKey(key)),
        screen: const Size(390, 844),
      );
    }

    testWidgets('hedef tepedeyken baloncuk altına iner', (tester) async {
      final r = await layoutWith(tester, targetAlignment: Alignment.topCenter);

      // Baloncuk hedefin üstünü örtmemeli.
      expect(r.bubble.top, greaterThan(r.target!.bottom),
          reason: 'baloncuk hedefi örtüyor: ${r.bubble} vs ${r.target}');
    });

    testWidgets('hedef dipteyken baloncuk üstüne çıkar', (tester) async {
      final r = await layoutWith(
        tester,
        targetAlignment: Alignment.bottomCenter,
      );

      expect(r.bubble.bottom, lessThan(r.target!.top),
          reason: 'baloncuk hedefi örtüyor: ${r.bubble} vs ${r.target}');
    });

    testWidgets('baloncuk her durumda ekran içinde kalır', (tester) async {
      for (final alignment in [
        Alignment.topCenter,
        Alignment.center,
        Alignment.bottomCenter,
      ]) {
        final r = await layoutWith(tester, targetAlignment: alignment);

        expect(r.bubble.top, greaterThanOrEqualTo(0),
            reason: '$alignment: baloncuk ekranın üstüne taşıyor');
        expect(r.bubble.bottom, lessThanOrEqualTo(r.screen.height),
            reason: '$alignment: baloncuk ekranın altına taşıyor');
      }
    });
  });

  group('Hedefsiz adım', () {
    testWidgets('baloncuk ortada durur, tepeye yapışmaz', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: TestApp.wrap(
              TourHost(
                tour: TourId.reader,
                steps: () => const [
                  TourStep(
                    title: 'Sure bitince durmayın',
                    body: 'Sure sonunda kaydırmayı sürdürün ya da karta '
                        'dokunun; sıradaki sure listeye dönmeden açılır.',
                  ),
                ],
                child: const SizedBox.expand(),
              ),
              theme: AppTheme.light,
            ),
          ),
        );
        await tester.pump();
      });
      await tester.pumpAndSettle();

      final bubble = tester.getRect(find.text('Sure bitince durmayın'));

      // Hedefsiz adımda baloncuk ekranın ortasında olmalı. `Stack`
      // yayılmadığında sol üste hizalanıyor ve saatin/çentiğin altına
      // yapışıyordu — başlık durum çubuğuyla üst üste biniyordu.
      expect(bubble.top, greaterThan(200),
          reason: 'baloncuk tepeye yapışmış: $bubble');
      expect(bubble.center.dy, closeTo(844 / 2, 140),
          reason: 'baloncuk ortada değil: $bubble');
    });
  });

  group('Tercih deposu', () {
    test('görüldü işareti tüm turlar için ayrı tutulur', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = TourNotifier(prefs);

      notifier.markSeen(TourId.reader);

      expect(notifier.hasSeen(TourId.reader), isTrue);
      // Bir turu görmek diğerini kapatmamalı; her ekran kendi ipucunu verir.
      expect(notifier.hasSeen(TourId.home), isFalse);
    });

    test('sıfırlama tüm turları geri getirir', () async {
      SharedPreferences.setMockInitialValues({
        TourId.home.storageKey: true,
        TourId.reader.storageKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = TourNotifier(prefs);

      expect(notifier.state, hasLength(2));

      notifier.resetAll();

      expect(notifier.state, isEmpty);
      expect(prefs.getBool(TourId.reader.storageKey), isNull);
    });
  });
}
