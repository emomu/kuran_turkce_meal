import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/data/repositories/root_repository.dart';
import 'package:kuran_turkce_meal/features/roots/view/root_search_screen.dart';
import 'package:kuran_turkce_meal/features/roots/widgets/root_highlight.dart';

import 'helpers/localized_app.dart';

/// Kök ekranlarının çizimi ve vurgulama davranışı.
void main() async {
  await TestApp.ensureInitialized();

  // TestApp.wrap zaten Scaffold sarıyor; ProviderScope kök olarak eklenir.
  Future<void> pump(WidgetTester tester, Widget child) =>
      TestApp.pump(tester, ProviderScope(child: child));

  // Kök verisi 4 MB'lık bir asset; testte gerçek I/O ile bir kez yüklenip
  // hazır depo olarak enjekte edilir. Aksi halde her ekran testi dosyayı
  // yeniden okur ve sahte zamanlayıcı bu beklemeyi çözemez.
  late RootRepository loadedRepo;

  setUpAll(() async {
    loadedRepo = RootRepository();
    await loadedRepo.ensureLoaded();
  });

  Future<void> pumpWithRoots(WidgetTester tester, Widget child) => TestApp.pump(
        tester,
        ProviderScope(
          overrides: [
            rootRepositoryProvider.overrideWithValue(loadedRepo),
          ],
          child: child,
        ),
      );

  group('Kök arama ekranı', () {
    testWidgets('açılışta yönlendirici boş durum gösterir', (tester) async {
      await pumpWithRoots(tester, const RootSearchScreen());

      expect(find.text('Kök ara'), findsWidgets);
      expect(
        find.text('Türkçe anlam, okunuş veya Arapça kök yazabilirsin'),
        findsOneWidget,
      );
    });

    testWidgets('harf filtresi katlanır ve açılır', (tester) async {
      await pumpWithRoots(tester, const RootSearchScreen());

      // Kapalıyken harfler görünmez.
      expect(find.text('re'), findsNothing);

      await tester.tap(find.text('Harf filtresi'));
      await tester.pumpAndSettle();

      // Açıldığında Türkçe okunuş etiketleri görünür.
      expect(find.text('re'), findsOneWidget);
      expect(find.text('elif'), findsOneWidget);
    });

    testWidgets('harf şeridi tek satır yüksekliğinde kalır', (tester) async {
      await pumpWithRoots(tester, const RootSearchScreen());

      final before = tester.getSize(find.byType(RootSearchScreen)).height;

      await tester.tap(find.text('Harf filtresi'));
      await tester.pumpAndSettle();

      // 29 harf ızgara olarak dizilseydi altı satır kaplar ve sonuç
      // listesini ekran dışına iterdi. Şerit tek satırda kaydırılır;
      // açıldığında eklenen yükseklik bir satırı aşmamalı.
      final strip = tester.getSize(
        find.ancestor(
          of: find.text('elif'),
          matching: find.byType(SingleChildScrollView),
        ).first,
      );
      expect(strip.height, lessThan(60));

      // Ekranın kendisi büyümez; şerit içeriden yer açar.
      expect(tester.getSize(find.byType(RootSearchScreen)).height, before);
    });

    testWidgets('yazınca sonuç listelenir', (tester) async {
      await pumpWithRoots(tester, const RootSearchScreen());

      await tester.enterText(find.byType(TextField), 'elçi');
      await tester.pumpAndSettle();

      expect(find.textContaining('elçi'), findsWidgets);
    });
  });

  group('Arapça vurgulama', () {
    testWidgets('yalnızca belirtilen kelime vurgulanır', (tester) async {
      await pump(
        tester,
        const HighlightedArabic(
          text: 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
          highlightIndexes: {1},
        ),
      );
      final widget = tester.widget<Text>(find.byType(Text));
      final spans = (widget.textSpan! as TextSpan).children!.cast<TextSpan>();

      // Kelimeler ve aralarındaki boşluklar dönüşümlü; 4 kelime + 3 boşluk.
      final words = [
        for (final s in spans)
          if (s.text != ' ') s,
      ];
      expect(words.length, 4);
      expect(words[1].style?.fontWeight, FontWeight.w600);
      expect(words[0].style?.fontWeight, isNot(FontWeight.w600));
    });
  });
}
