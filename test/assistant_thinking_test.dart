import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/features/assistant/view/widgets/assistant_thinking_indicator.dart';

import 'helpers/localized_app.dart';

/// Düşünme göstergesinin davranışı.
///
/// Gösterge bir süsleme değil: kullanıcıya asistanın çalıştığını ve neyi
/// yaptığını söyler. Etiketin aşamaya göre değişmesi ve sayacın ancak
/// gerçek bir bekleyişte belirmesi bu yüzden denetleniyor.
void main() {
  setUp(TestApp.reset);

  /// Göstergeyi çizer.
  ///
  /// İki aşama: çeviriler gerçek dosya I/O ile yüklenir (`runAsync`),
  /// sonra aynı ağaç sahte saat altında yeniden çizilir. Süre parıltının
  /// ticker'ından okunduğu için ikinci aşama şart — `runAsync` içinde
  /// kalan bir ticker test saatiyle ilerlemez.
  ///
  /// `pumpAndSettle` kullanılmaz: parıltı sonsuz döner, ağaç durulmaz.
  Future<void> show(WidgetTester tester) async {
    final tree = TestApp.wrap(const AssistantThinkingIndicator());

    await tester.runAsync(() async {
      await tester.pumpWidget(tree);
      await tester.pump();
    });
    await tester.pumpWidget(tree);
    await tester.pump();
  }

  /// Sonsuz animasyonu söker; testin bitebilmesi için gerekli.
  Future<void> stop(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('ilk anda düşünme etiketi görünür', (tester) async {
    await show(tester);
    expect(find.text('Düşünülüyor'), findsOneWidget);
    await stop(tester);
  });

  testWidgets('sayaç ilk saniyede gösterilmez', (tester) async {
    // Yerel arama çoğu kez bir saniyeden kısa sürer; sayaç o an belirirse
    // olmayan bir bekleyişi varmış gibi gösterirdi.
    await show(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
    );
    await stop(tester);
  });

  testWidgets('bekleyiş uzayınca sayaç belirir', (tester) async {
    await show(tester);
    await tester.pump(const Duration(milliseconds: 1200));

    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      1,
    );
    expect(find.textContaining('s'), findsWidgets);
    await stop(tester);
  });

  testWidgets('etiket aşamaya göre değişir', (tester) async {
    await show(tester);

    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('Mealde aranıyor'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Cevap hazırlanıyor'), findsOneWidget);

    await stop(tester);
  });

  testWidgets('metin parıltıyla çizilir', (tester) async {
    // Parıltı bir gradyan maskesiyle yapılıyor; kaldırılırsa gösterge
    // sessizce düz metne döner ve kimse fark etmez.
    await show(tester);
    expect(find.byType(ShaderMask), findsOneWidget);
    await stop(tester);
  });

  testWidgets('karanlık temada da okunur kalır', (tester) async {
    // Parıltı ve taban renk temadan geliyor; karanlıkta sabit bir renge
    // düşerse metin ya kaybolur ya göz alır.
    final tree = TestApp.wrap(
      const AssistantThinkingIndicator(),
      theme: ThemeData.dark(),
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(tree);
      await tester.pump();
    });
    await tester.pumpWidget(tree);
    await tester.pump();

    final text = tester.widget<Text>(find.text('Düşünülüyor'));
    final color = text.style?.color;
    expect(color, isNotNull);

    // Karanlık temanın gövde rengi açık olmalı; koyu kalırsa okunmaz.
    expect(color!.computeLuminance(), greaterThan(0.3));

    await stop(tester);
  });
}
