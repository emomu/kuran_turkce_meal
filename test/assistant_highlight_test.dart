import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';
import 'package:kuran_turkce_meal/features/assistant/data/assistant_intent.dart';
import 'package:kuran_turkce_meal/features/assistant/view/widgets/assistant_ayah_card.dart';

/// Eşleşen kelimenin ayet metninde vurgulanması.
///
/// Vurgu bir süs değil: kullanıcı sonucun neden geldiğini görmeli.
/// Asistanın seçimi böyle denetlenebilir olur.
void main() {
  const ayah = Ayah(
    id: 1,
    surahNumber: 2,
    ayahNumber: 153,
    translation: 'Ey iman edenler! Sabır ve namazla yardım isteyin. '
        'Şüphesiz Allah sabredenlerle beraberdir.',
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    List<String> terms = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                body: AssistantAyahCard(
                  answer: const AnswerAyah(ayah: ayah, surahName: 'Bakara'),
                  languageCode: 'tr',
                  highlightTerms: terms,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Karttaki meal metnini taşıyan span ağacını verir.
  InlineSpan? translationSpan(WidgetTester tester) {
    final texts = tester.widgetList<Text>(find.byType(Text));
    for (final t in texts) {
      final span = t.textSpan;
      if (span == null) continue;
      if (span.toPlainText().startsWith('Ey iman')) return span;
    }
    return null;
  }

  testWidgets('terim verilmezse metin düz çizilir', (tester) async {
    await pumpCard(tester);

    // Vurgu yoksa Text.rich kullanılmaz; düz metin bulunur.
    expect(find.text(ayah.translation), findsOneWidget);
  });

  testWidgets('eşleşen kelime kalın çizilir', (tester) async {
    await pumpCard(tester, terms: ['sabır']);

    final span = translationSpan(tester);
    expect(span, isNotNull);

    // Metnin tamamı korunmalı: vurgu hiçbir harfi düşürmemeli.
    expect(span!.toPlainText(), ayah.translation);

    final bold = <String>[];
    span.visitChildren((child) {
      if (child is TextSpan &&
          child.style?.fontWeight == FontWeight.w700 &&
          child.text != null) {
        bold.add(child.text!);
      }
      return true;
    });

    expect(bold, isNotEmpty);
    expect(bold.first.toLowerCase(), 'sabır');
  });

  testWidgets('ekli biçim de vurgulanır', (tester) async {
    // "sabr" terimi "sabredenlerle" içinde geçer; önek eşleşmesi
    // Türkçe'de gereklidir.
    await pumpCard(tester, terms: ['sabred']);

    final span = translationSpan(tester);
    expect(span!.toPlainText(), ayah.translation);

    var foundBold = false;
    span.visitChildren((child) {
      if (child is TextSpan && child.style?.fontWeight == FontWeight.w700) {
        foundBold = true;
      }
      return true;
    });
    expect(foundBold, isTrue);
  });

  testWidgets('eşleşmeyen terim metni bozmaz', (tester) async {
    await pumpCard(tester, terms: ['kelebek']);

    // Eşleşme yoksa metin olduğu gibi kalır.
    expect(find.text(ayah.translation), findsOneWidget);
  });

  testWidgets('birden fazla terim vurgulanır', (tester) async {
    await pumpCard(tester, terms: ['sabır', 'namaz']);

    final span = translationSpan(tester);
    expect(span!.toPlainText(), ayah.translation);

    final bold = <String>[];
    span.visitChildren((child) {
      if (child is TextSpan &&
          child.style?.fontWeight == FontWeight.w700 &&
          child.text != null) {
        bold.add(child.text!.toLowerCase());
      }
      return true;
    });

    expect(bold, containsAll(['sabır', 'namaz']));
  });
}
