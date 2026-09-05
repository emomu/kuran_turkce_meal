import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kuran_turkce_meal/core/router/app_router.dart';

/// Araçtan (ve bildirimden, derin bağlantıdan) açılan ekranlarda geri
/// davranışı.
///
/// Araç uygulamayı `go` ile açar; `go` gezinme yığınını sıfırlar, yani okuma
/// ekranı yığındaki tek sayfa olur. Düz bir `pop` orada ekranı boşaltıp
/// kullanıcıyı boş bir yüzeyde bırakıyordu — uygulamanın içindeydi ama
/// hiçbir yere gidemiyordu.
///
/// Buradaki testler o çıkmazın geri gelmediğini doğrular. Gerçek ekranlar
/// yerine aynı yönlendirici sözleşmesini kullanan iki sahne kurulur: sözü
/// edilen davranış [popOrHome] ile [canPopRoute] içinde yaşıyor ve ekranların
/// veri katmanını ayağa kaldırmadan sınanabiliyor.
void main() {
  /// Test yönlendiricisi: gerçek tablodaki gibi ana sayfa `/`, okuma ekranı
  /// da kabuk dışı bir kök.
  GoRouter buildRouter({required String initialLocation}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('ana sayfa'))),
        ),
        GoRoute(
          path: '/sure/:surahNumber',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('sure ${state.pathParameters['surahNumber']}'),
                  TextButton(
                    onPressed: () => popOrHome(context),
                    child: const Text('geri'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> pump(WidgetTester tester, GoRouter router) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  group('araçtan açılan ekranda geri', () {
    testWidgets('yığın boşken ana sayfaya döner, boş ekran bırakmaz', (
      tester,
    ) async {
      // Araca dokunulmuş gibi: uygulama doğrudan okuma ekranında açılır.
      final router = buildRouter(initialLocation: '/sure/9?ayet=93');
      await pump(tester, router);

      expect(find.text('sure 9'), findsOneWidget);

      await tester.tap(find.text('geri'));
      await tester.pumpAndSettle();

      // Eski davranışta burada hiçbir şey kalmıyordu.
      expect(find.text('ana sayfa'), findsOneWidget);
      expect(find.text('sure 9'), findsNothing);
    });

    testWidgets('uygulama içinden gelindiyse bir önceki ekrana döner', (
      tester,
    ) async {
      // Olağan akış: ana sayfadan okuma ekranına itilir.
      final router = buildRouter(initialLocation: '/');
      await pump(tester, router);

      router.push('/sure/2?ayet=255');
      await tester.pumpAndSettle();
      expect(find.text('sure 2'), findsOneWidget);

      await tester.tap(find.text('geri'));
      await tester.pumpAndSettle();

      expect(find.text('ana sayfa'), findsOneWidget);
    });
  });

  group('canPopRoute', () {
    testWidgets('araçtan gelindiğinde false döner', (tester) async {
      late BuildContext readerContext;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/sure/9',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const SizedBox.shrink(),
              ),
              GoRoute(
                path: '/sure/:surahNumber',
                builder: (context, state) {
                  readerContext = context;
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sistem geri jesti pop'lamamalı; PopScope devralıp ana sayfaya
      // götürmeli.
      expect(canPopRoute(readerContext), isFalse);
    });
  });

  group('yönlendirici olmayan bağlam', () {
    testWidgets('popOrHome tek başına çizilen ekranda patlamaz', (
      tester,
    ) async {
      // Ekranlar parça testlerinde ve önizlemede yönlendiricisiz de çizilir;
      // geri davranışı orada olağan Navigator akışına düşmeli.
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      expect(canPopRoute(ctx), isTrue);
      expect(() => popOrHome(ctx), returnsNormally);
    });
  });
}
