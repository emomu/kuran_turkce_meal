import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kuran_turkce_meal/core/providers/app_providers.dart';
import 'package:kuran_turkce_meal/core/router/app_router.dart';
import 'package:kuran_turkce_meal/features/reader/view/reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Araçtan gelen bağlantının doğru ekrana götürmesi.
///
/// Bu yol widget testinde tam doğrulanamıyor: yönlendiricinin gerçekten o
/// ekranı kurduğunu görmek için uygulamanın kendi yönlendirici örneğini
/// çalıştırmak gerekiyor.
///
/// Doğrulanan hata gerçekti: Android manifest'te `homeWidget` yazılı olsa
/// da şemayı küçülterek iletiyor, karşılaştırma ise büyük/küçük harfe
/// duyarlıydı. Sonuç: araca dokunan kullanıcı ayete gitmek yerine
/// "Sayfa bulunamadı: homewidget://sure/9?ayet=93" ekranını görüyordu.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await EasyLocalization.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('araç bağlantısı okuma ekranını açar', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('tr'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('tr'),
        // Ekranlar sağlayıcıları izliyor; kapsam olmadan çizilemezler.
        child: ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: Builder(
            builder: (context) => MaterialApp.router(
              routerConfig: appRouter,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Android'in ilettiği biçim: şema küçük harfli.
    appRouter.go('homewidget://sure/9?ayet=93');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Hata ekranı yerine okuma ekranı açılmalı.
    expect(find.textContaining('Sayfa bulunamadı'), findsNothing);
    expect(find.byType(ReaderScreen), findsOneWidget);

    final reader = tester.widget<ReaderScreen>(find.byType(ReaderScreen));
    expect(reader.surahNumber, 9);
    // Ayet numarası sorgu parametresinde taşınıyor; düşerse araç sureyi
    // açar ama ayete konumlanmaz.
    expect(reader.initialAyah, 93);
  });
}
