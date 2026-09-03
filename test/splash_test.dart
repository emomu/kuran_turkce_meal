import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/features/splash/view/splash_screen.dart';
import 'package:lottie/lottie.dart';

import 'helpers/localized_app.dart';

/// Açılışın ekranda kalma süresi — widget'takiyle aynı olmalı.
const _splashDuration = Duration(seconds: 5);

/// Açılış ekranı: içerik kuralları, tema uyumu ve geçiş.
void main() async {
  await TestApp.ensureInitialized();

  setUp(TestApp.reset);

  /// Açılış ekranını gerçek yönlendiriciyle çizer ve hedefe gidip
  /// gitmediğini gözlemleyebilmek için basit bir ana sayfa verir.
  Future<GoRouter> pumpSplash(
    WidgetTester tester, {
    required ThemeData theme,
  }) async {
    final router = GoRouter(
      initialLocation: '/acilis',
      routes: [
        GoRoute(
          path: '/acilis',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('ana sayfa')),
        ),
      ],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(TestApp.wrapRouter(router, theme: theme));
      await tester.pump();
    });

    return router;
  }

  group('içerik', () {
    testWidgets('ekranda hiç yazı yok', (tester) async {
      await pumpSplash(tester, theme: AppTheme.light);

      // Açılışta tipografi bilinçli olarak yok — marka adı da dahil.
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('ilerleme göstergesi yok', (tester) async {
      await pumpSplash(tester, theme: AppTheme.light);

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ProgressIndicator), findsNothing);
    });

    testWidgets('yalnızca Lottie animasyonu çizilir', (tester) async {
      await pumpSplash(tester, theme: AppTheme.light);

      expect(find.byType(LottieBuilder), findsOneWidget);
    });
  });

  group('tema', () {
    testWidgets('açık temada zemin açık tema rengini alır', (tester) async {
      await pumpSplash(tester, theme: AppTheme.light);

      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(SplashScreen),
          matching: find.byType(Scaffold),
        ),
      );
      expect(scaffold.backgroundColor, AppTheme.light.scaffoldBackgroundColor);
    });

    testWidgets('koyu temada zemin koyu tema rengini alır', (tester) async {
      await pumpSplash(tester, theme: AppTheme.dark);

      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(SplashScreen),
          matching: find.byType(Scaffold),
        ),
      );
      expect(scaffold.backgroundColor, AppTheme.dark.scaffoldBackgroundColor);
    });
  });

  group('geçiş', () {
    testWidgets('bekleme süresi dolunca hedefe gider', (tester) async {
      final router = await pumpSplash(tester, theme: AppTheme.light);

      // Animasyon dosyası asenkron çözülür; gerçek olay döngüsü olmadan
      // denetleyici hiç başlamaz.
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      });

      // Bekleme zamanlayıcısı animasyon yüklendiğinde, yani `runAsync`
      // içindeki gerçek zamanda kurulur; sahte saati ilerletmek onu
      // tetiklemez. Bu yüzden süre yine gerçek zamanda beklenir.
      //
      // `pumpAndSettle` de kullanılamaz: döngüdeki animasyon kare üretmeyi
      // hiç bırakmadığı için zaman aşımına uğrar.
      await tester.runAsync(() async {
        await Future<void>.delayed(_splashDuration + const Duration(seconds: 1));
      });
      // Bir kare geçişi işler, ikincisi yeni ekranı çizer.
      await tester.pump();
      await tester.pump();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/',
      );
      expect(find.text('ana sayfa'), findsOneWidget);
    });

    testWidgets('animasyon süre dolmadan durmaz', (tester) async {
      final router = await pumpSplash(tester, theme: AppTheme.light);

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      });

      // Açılış 5 sn tutuluyor; 2. saniyede hâlâ ekranda olmalı. Animasyon
      // tek sefer oynayıp donsaydı ya da süre kısaltılsaydı burada çoktan
      // geçmiş olurdu.
      //
      // `runAsync` gerçek zamanı ilerlettiği için sınır değerine yakın
      // beklemek kırılgan olurdu — bu yüzden süreyle aramızda pay bırakılır.
      await tester.pump(const Duration(seconds: 2));

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/acilis',
      );
      expect(find.byType(LottieBuilder), findsOneWidget);
    });
  });

  group('animasyon dosyası', () {
    testWidgets('gerçek Lottie ayrıştırıcısı dosyayı okuyabiliyor',
        (tester) async {
      // Belgenin şemaya uygun görünmesi yetmez: dosya elle üretildiği için
      // ayrıştırıcının kabul ettiğini doğrudan sınamak gerekiyor. Aksi halde
      // ekranda sessizce hiçbir şey çizilmez — `errorBuilder` devreye girer
      // ve kullanıcı boş bir açılış görür.
      Object? error;
      LottieComposition? composition;

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Lottie.asset(
              'assets/lottie/splash_moon_star.json',
              onLoaded: (c) => composition = c,
              errorBuilder: (context, e, stack) {
                error = e;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 800));
        await tester.pump();
      });

      expect(error, isNull, reason: 'animasyon ayrıştırılamadı: $error');
      expect(composition, isNotNull, reason: 'animasyon yüklenmedi');
      expect(composition!.duration, _splashDuration);
    });

    test('geçerli Lottie belgesi ve makul süre', () {
      final file = File('assets/lottie/splash_moon_star.json');
      expect(file.existsSync(), isTrue,
          reason: 'animasyon varlığı pakete eklenmiş olmalı');

      final doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      // Lottie'nin zorunlu alanları.
      for (final key in ['v', 'fr', 'ip', 'op', 'w', 'h', 'layers']) {
        expect(doc.containsKey(key), isTrue, reason: '$key alanı eksik');
      }

      final layers = doc['layers'] as List;
      expect(layers, isNotEmpty);

      // Açılış animasyonu kullanıcıyı bekletmemeli.
      final seconds = (doc['op'] as num) / (doc['fr'] as num);
      expect(seconds, closeTo(5.0, 0.01),
          reason: 'açılış animasyonu 5 sn olmalı');
    });

    test('kompozisyon baştan sona kesintisiz döner', () {
      final doc = jsonDecode(
        File('assets/lottie/splash_moon_star.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      final layers = (doc['layers'] as List).cast<Map<String, dynamic>>();
      final orbit = layers.firstWhere((l) => l['nm'] == 'Orbit');

      // Yörünge katmanı tam tur atmalı; eksik tur başa sarmada sıçrama yapar.
      final rot = (orbit['ks'] as Map)['r'] as Map<String, dynamic>;
      expect(rot['a'], 1, reason: 'yörünge dönüşü animasyonlu olmalı');

      final keys = (rot['k'] as List).cast<Map<String, dynamic>>();
      expect((keys.first['s'] as List).first, 0);
      expect((keys.last['s'] as List).first, 360);
      expect(keys.last['t'], doc['op'],
          reason: 'dönüş kompozisyonun sonuna kadar sürmeli');

      // Serpinti ve halka yörüngeye bağlı olmalı — dönüşü onlar taşıyor.
      final orbiting = layers.where((l) => l['parent'] == orbit['ind']);
      expect(orbiting.length, greaterThanOrEqualTo(6));
    });

    test('ay ve yıldız dik kalır', () {
      final doc = jsonDecode(
        File('assets/lottie/splash_moon_star.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      final layers = (doc['layers'] as List).cast<Map<String, dynamic>>();

      // Hilal ve yıldız devrilirse yıldız hilalin boşluğundan çıkar ve
      // ay-yıldız formu bozulur; dönüş yalnızca yörüngede olmalı.
      for (final name in ['Crescent', 'Star']) {
        final layer = layers.firstWhere((l) => l['nm'] == name);
        final rot = (layer['ks'] as Map)['r'] as Map<String, dynamic>;
        final keys = (rot['k'] as List).cast<Map<String, dynamic>>();
        for (final k in keys) {
          final deg = ((k['s'] as List).first as num).abs();
          expect(deg, lessThanOrEqualTo(60),
              reason: '$name katmanı devriliyor ($deg°)');
        }
        expect(layer['parent'], isNull,
            reason: '$name yörüngeye bağlanmamalı');
      }
    });

    test('animasyonda metin katmanı yok', () {
      final doc = jsonDecode(
        File('assets/lottie/splash_moon_star.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      // Lottie'de metin katmanının türü 5'tir; ekranda yazı olmamalı.
      final textLayers =
          (doc['layers'] as List).where((l) => (l as Map)['ty'] == 5);
      expect(textLayers, isEmpty);
    });

    test('animasyon varlığı pubspec ile paketlenir', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('assets/lottie/'));
    });
  });
}
