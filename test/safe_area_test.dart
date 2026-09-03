import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/router/app_shell.dart';
import 'package:kuran_turkce_meal/shared/widgets/tab_bar_inset.dart';

/// Sistem paneliyle çakışma denetimi.
///
/// iOS 26'da sekme çubuğu camdır ve gövde onun altına uzatılır
/// (`extendBody`), yani kaydırılan listenin son öğesi çubuğun arkasına
/// girebilir. Android ve eski iOS'ta gövde çubuğun üstünde biter.
///
/// `Scaffold` bu farkı gövdeye verdiği alt dolguya zaten yansıtır; ekranlar
/// o değeri okur. Aşağıdaki testler o sözleşmenin bozulmadığını doğrular —
/// bozulursa ya içerik çubuğun altında kalır ya da altta ölü boşluk oluşur.
void main() {
  Future<double> insetIn(
    WidgetTester tester, {
    required bool extendBody,
    double safeAreaBottom = 34,
  }) async {
    late double inset;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            padding: EdgeInsets.only(bottom: safeAreaBottom),
          ),
          child: Scaffold(
            extendBody: extendBody,
            bottomNavigationBar: const SizedBox(height: AppShell.barHeight),
            body: Builder(
              builder: (context) {
                inset = bottomInsetFor(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    return inset;
  }

  group('Sekme çubuğu alt boşluğu', () {
    testWidgets('cam modda içerik çubuğun altında kalmaz', (tester) async {
      final inset = await insetIn(tester, extendBody: true);

      // Gövde çubuğun altına uzatıldığı için boşluk en az çubuk kadar
      // olmalı; aksi halde son ayet camın arkasında kalırdı.
      expect(inset, greaterThanOrEqualTo(AppShell.barHeight));
    });

    testWidgets('düz modda altta ölü boşluk oluşmaz', (tester) async {
      final inset = await insetIn(tester, extendBody: false);

      // Scaffold gövdeyi zaten çubuğun üstünde bitirir; buraya çubuk
      // yüksekliği eklemek ekranın altında boş bir şerit bırakırdı.
      expect(inset, lessThan(AppShell.barHeight));
    });

    testWidgets('jest çubuğu olmayan cihazda da çubuk payı korunur',
        (tester) async {
      final inset = await insetIn(
        tester,
        extendBody: true,
        safeAreaBottom: 0,
      );

      expect(inset, greaterThanOrEqualTo(AppShell.barHeight));
    });

    testWidgets('kabuk dışında ekranın kendi güvenli alanı kullanılır',
        (tester) async {
      late double inset;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: 34),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                inset = bottomInsetFor(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Okuma ekranı gibi kabuk dışı ekranlarda çubuk yoktur; yalnızca
      // jest çubuğu payı kalır.
      expect(inset, 34);
    });
  });

  test('sekme çubuğu dokunma hedefi erişilebilirlik alt sınırının üstünde', () {
    // Apple 44pt, Material 48dp ister; çubuk bundan alçalmamalı.
    expect(AppShell.barHeight, greaterThanOrEqualTo(48));
  });
}
