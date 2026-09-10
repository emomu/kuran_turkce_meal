import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/router/app_shell.dart';
import 'package:go_router/go_router.dart';

import 'helpers/localized_app.dart';

/// Alt sekme çubuğu: yerleşim ve seçim davranışı.
void main() async {
  await TestApp.ensureInitialized();

  // easy_localization durumunu statik tutar ve her test sonunda temizlenir;
  // tazelenmezse sonraki test boş bir ağaç çizer.
  setUp(TestApp.reset);

  /// Sekme çubuğunu gerçek yönlendirme kabuğuyla çizer.
  Future<void> pumpShell(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(navigationShell: shell),
          branches: [
            for (final path in [
              '/',
              '/ara',
              '/planlar',
              '/kayitlar',
              '/ayarlar',
            ])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (_, _) => const SizedBox.expand(),
                  ),
                ],
              ),
          ],
        ),
      ],
    );

    // Çeviri dosyaları diskten gerçek I/O ile okunur; sahte zamanlayıcı bunu
    // beklemez, bu yüzden ilk kare runAsync içinde çizilir.
    await tester.runAsync(() async {
      await tester.pumpWidget(ProviderScope(child: TestApp.wrapRouter(router)));
      await tester.pump();
    });
    await tester.pumpAndSettle();
  }

  testWidgets('beş sekme etiketleriyle çizilir', (tester) async {
    await pumpShell(tester);
    // Asistan sekmede değil; yüzen düğmeden açılıyor.
    for (final label in ['Oku', 'Ara', 'Planlar', 'Kayıtlar', 'Ayarlar']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('dokunma alanı Apple asgarisini karşılar', (tester) async {
    await pumpShell(tester);
    // 52pt yükseklikte ikon ve etiket sıkışıyordu.
    final size = tester.getSize(find.byType(GestureDetector).first);
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('ikon ve etiket dikeyde dengeli durur', (tester) async {
    await pumpShell(tester);

    final bar = tester.getRect(find.byType(GestureDetector).first);
    final icon = tester.getRect(find.byIcon(Icons.menu_book_rounded));
    final label = tester.getRect(find.text('Oku'));
    // Görsel denge yastığın kenarlarıyla ölçülür; ikonun kendi 22pt kutusu
    // içinde iç boşluğu var ve doğrudan ölçülürse yanıltır.
    final pill = tester.getRect(
      find
          .descendant(
            of: find.byType(GestureDetector).first,
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );

    // Üstteki ve alttaki nefes dengeli olmalı.
    //
    // Kutu kenarları TAM eşit değildir ve olmamalı: etiketin kutusunda altta
    // descender boşluğu var, yastıkta üstte iç dolgu. Kutular eşitlenirse
    // gözün gördüğü mürekkep yukarı kaymış görünür — ölçüldü, kutular
    // 10.5/10.5 iken mürekkep 16.5/14.0 çıkıyordu. Bu yüzden içerik
    // bilerek birkaç piksel yukarı çekiliyor; sınır ona göre gevşek.
    final topGap = pill.top - bar.top;
    final bottomGap = bar.bottom - label.bottom;
    expect(
      (topGap - bottomGap).abs(),
      lessThan(6),
      reason: 'üst $topGap / alt $bottomGap',
    );

    // İkon ile etiket birbirine değmemeli ama kopuk da olmamalı.
    final between = label.top - icon.bottom;
    expect(between, greaterThan(0));
    expect(between, lessThan(10));
  });

  testWidgets('seçili sekme vurgu yastığıyla işaretlenir', (tester) async {
    await pumpShell(tester);

    // Renk körlüğünde tek ipucu renk olmamalı; yastık da seçimi gösterir.
    final containers = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .toList();
    final filled = containers.where((c) {
      final d = c.decoration as BoxDecoration?;
      return d?.color != null && d!.color != Colors.transparent;
    });
    expect(filled.length, 1);
  });

  testWidgets('başka sekmeye geçilince seçim taşınır', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();

    // Seçili sekme dolu ikona geçer.
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
    // Önceki sekme ana hat ikonuna döner.
    expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
  });
}
