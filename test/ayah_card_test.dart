import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/features/reader/share/ayah_card.dart';

import 'helpers/localized_app.dart';

/// Paylaşılabilir ayet kartı.
///
/// Kart ekranda gösterilmez, görsele çevrilir; bu yüzden testler görünümü
/// değil kartın içeriğini ve ölçü kararlarını doğrular. Görsele çevirmenin
/// kendisi raster hattı gerektiriyor ve widget testlerinde çalışmıyor —
/// o yol cihazda doğrulanır (bkz. AyahCardRenderer).
void main() {
  setUp(TestApp.reset);

  /// Kartı ölçüp çizer. Kart 1080 piksel; test ekranı ondan küçük olduğu
  /// için taşma uyarısı vermesin diye ölçek küçültülür.
  Future<void> pumpCard(WidgetTester tester, AyahCard card) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: card)),
      ),
    );
  }

  testWidgets('meal, sure adı ve ayet numarası kartta görünür', (tester) async {
    await pumpCard(
      tester,
      const AyahCard(
        text: 'Rabbimiz! Bize dünyada da iyilik ver.',
        surahName: 'Bakara',
        verseLabel: '201',
        appName: "Kur'an",
      ),
    );

    expect(find.text('Rabbimiz! Bize dünyada da iyilik ver.'), findsOneWidget);
    expect(find.text('Bakara 201'), findsOneWidget);
    // Kartın kaynağı belirsiz kalmamalı; paylaşılan görsel nereden geldiğini
    // kendisi söylemeli.
    expect(find.text("Kur'an"), findsOneWidget);
  });

  testWidgets('Arapça metin verilmezse gösterilmez', (tester) async {
    await pumpCard(
      tester,
      const AyahCard(
        text: 'Meal',
        surahName: 'Fâtiha',
        verseLabel: '1',
        appName: "Kur'an",
      ),
    );

    expect(find.byType(Directionality), findsWidgets);
    // Arapça bloğu RTL yönünde çizilir; verilmediğinde hiç kurulmamalı.
    final rtl = tester.widgetList<Directionality>(find.byType(Directionality));
    expect(rtl.any((d) => d.textDirection == TextDirection.rtl), isFalse);
  });

  testWidgets('Arapça metin verilirse sağdan sola çizilir', (tester) async {
    await pumpCard(
      tester,
      const AyahCard(
        text: 'Meal',
        surahName: 'Fâtiha',
        verseLabel: '1',
        appName: "Kur'an",
        arabic: 'بِسْمِ اللَّهِ',
      ),
    );

    final rtl = tester.widgetList<Directionality>(find.byType(Directionality));
    expect(rtl.any((d) => d.textDirection == TextDirection.rtl), isTrue);
  });

  group('punto ölçeklemesi', () {
    /// Kart sabit boyutlu; metin uzadıkça punto küçülmeli, yoksa uzun
    /// ayetler karttan taşar ve kırpılır.
    double fontSizeOf(WidgetTester tester, String text) {
      final widget = tester.widget<Text>(find.text(text));
      return widget.style!.fontSize!;
    }

    testWidgets('uzun ayet kısa ayetten küçük puntoyla çizilir',
        (tester) async {
      const kisa = 'Kısa bir ayet.';
      await pumpCard(
        tester,
        const AyahCard(
          text: kisa,
          surahName: 'Fâtiha',
          verseLabel: '1',
          appName: "Kur'an",
        ),
      );
      final kisaPunto = fontSizeOf(tester, kisa);

      final uzun = 'Uzun bir ayet metni. ' * 40;
      await pumpCard(
        tester,
        AyahCard(
          text: uzun,
          surahName: 'Bakara',
          verseLabel: '282',
          appName: "Kur'an",
        ),
      );
      final uzunPunto = fontSizeOf(tester, uzun);

      expect(uzunPunto, lessThan(kisaPunto));
    });
  });

  testWidgets('koyu ve açık tema farklı zemin kullanır', (tester) async {
    Color backgroundOf(WidgetTester tester) {
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      return container.color!;
    }

    await pumpCard(
      tester,
      const AyahCard(
        text: 'Meal',
        surahName: 'Fâtiha',
        verseLabel: '1',
        appName: "Kur'an",
      ),
    );
    final acik = backgroundOf(tester);

    await pumpCard(
      tester,
      const AyahCard(
        text: 'Meal',
        surahName: 'Fâtiha',
        verseLabel: '1',
        appName: "Kur'an",
        isDark: true,
      ),
    );
    final koyu = backgroundOf(tester);

    expect(acik, isNot(koyu));
  });
}
