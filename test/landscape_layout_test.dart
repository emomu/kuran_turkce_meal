import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/theme/app_typography.dart';
import 'package:kuran_turkce_meal/shared/widgets/responsive_layout.dart';

/// Yatay (landscape) düzen denetimi.
///
/// Uygulama dört yönde de çalışır. Yatayda asıl risk satır uzunluğudur:
/// ekran genişledikçe metin de genişlerse satır başına düşen karakter sayısı
/// konforlu aralığın (45–75) çok üstüne çıkar ve okuma zorlaşır. Bu yüzden
/// metin genişliği bir sınıra oturur, kalan alan kenarlarda boşluk olur.
///
/// Aşağıdaki testler o sözleşmeyi doğrular — bozulursa yatayda ayet metni
/// ekranın bir ucundan diğerine yayılır.
void main() {
  /// Verilen ekran ölçüsü ve güvenli alanla dolguyu hesaplar.
  Future<EdgeInsets> paddingFor(
    WidgetTester tester, {
    required Size size,
    double maxWidth = ContentWidth.reading,
    EdgeInsets safeArea = EdgeInsets.zero,
  }) async {
    late EdgeInsets padding;

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size, padding: safeArea),
        child: Builder(
          builder: (context) {
            padding = centeredContentPadding(context, maxWidth: maxWidth);
            return const SizedBox();
          },
        ),
      ),
    );

    return padding;
  }

  // iPhone 13: dikeyde 390x844, yatayda 844x390.
  const portrait = Size(390, 844);
  const landscape = Size(844, 390);

  group('Okuma genişliği', () {
    testWidgets('dikey telefonda düzen değişmez', (tester) async {
      final padding = await paddingFor(tester, size: portrait);

      // 390pt genişlik sınırın (680) altında; dolgu ekran kenar boşluğunun
      // ta kendisi olmalı. Aksi halde dikey görünüm bu değişiklikten
      // etkilenmiş demektir.
      expect(padding.left, Insets.screenGutter);
      expect(padding.right, Insets.screenGutter);
    });

    testWidgets('yatayda metin sınırı aşmaz', (tester) async {
      final padding = await paddingFor(tester, size: landscape);

      final textWidth = landscape.width - padding.left - padding.right;
      expect(textWidth, lessThanOrEqualTo(ContentWidth.reading));
    });

    testWidgets('yatayda metin ortalanır', (tester) async {
      final padding = await paddingFor(tester, size: landscape);

      // Kalan alan iki yana eşit dağılmalı; biri diğerinden büyükse metin
      // ekranın bir yanına kaymış olur.
      expect(padding.left, closeTo(padding.right, 0.01));
    });

    testWidgets('çok geniş ekranda bile satır uzamaz', (tester) async {
      final padding = await paddingFor(
        tester,
        size: const Size(1600, 900),
      );

      final textWidth = 1600 - padding.left - padding.right;
      expect(textWidth, lessThanOrEqualTo(ContentWidth.reading));
    });
  });

  group('Yatay güvenli alan', () {
    testWidgets('çentik içeriği kesmez', (tester) async {
      // Yatayda çentik solda kalır; iPhone'da yaklaşık 47pt.
      const notch = EdgeInsets.only(left: 47, right: 47);

      final padding = await paddingFor(
        tester,
        size: landscape,
        safeArea: notch,
      );

      // İçerik en azından çentiğin dışında başlamalı.
      expect(padding.left, greaterThanOrEqualTo(notch.left));
      expect(padding.right, greaterThanOrEqualTo(notch.right));
    });

    testWidgets('güvenli alan yokken fazladan boşluk oluşmaz', (tester) async {
      final padding = await paddingFor(tester, size: portrait);

      expect(padding.left, Insets.screenGutter);
    });
  });

  group('Kenar boşluğu ölçeği', () {
    testWidgets('dar ekranda taban değer kullanılır', (tester) async {
      late double gutter;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: portrait),
          child: Builder(
            builder: (context) {
              gutter = gutterFor(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(gutter, Insets.screenGutter);
    });

    testWidgets('geniş ekranda boşluk artar', (tester) async {
      late double gutter;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: landscape),
          child: Builder(
            builder: (context) {
              gutter = gutterFor(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(gutter, greaterThan(Insets.screenGutter));
    });
  });

  group('Yön algısı', () {
    testWidgets('yatay ve dikey ayırt edilir', (tester) async {
      late bool landscapeSeen;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: landscape),
          child: Builder(
            builder: (context) {
              landscapeSeen = isLandscape(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(landscapeSeen, isTrue);
    });
  });
}
