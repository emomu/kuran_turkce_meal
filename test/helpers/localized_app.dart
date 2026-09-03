import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget testleri için ortak kurulum.
///
/// Arayüz `easy_localization` kullandığı için widget'lar `context.locale` ve
/// `.tr()` çağırır; bunlar `EasyLocalization` sarmalayıcısı olmadan çalışmaz.
/// Bu yardımcı, testin çevirileri gerçek dosyalardan yüklemesini sağlar.
abstract final class TestApp {
  /// Çeviri altyapısını başlatır.
  ///
  /// `main()` başında bir kez çağrılır; ayrıca her testten önce yeniden
  /// çalıştırılması gerekir çünkü `easy_localization` durumunu statik olarak
  /// tutar ve bir test bittiğinde temizlenir — sonraki test boş bir ağaç
  /// çizerdi.
  static Future<void> ensureInitialized() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // `easy_localization` seçili dili SharedPreferences'ta saklar; test
    // ortamında eklenti bulunmadığı için sahte bir depo verilir.
    SharedPreferences.setMockInitialValues({});

    await EasyLocalization.ensureInitialized();
  }

  /// Her testten önce çeviri altyapısını tazeler.
  ///
  /// Test dosyasının `main()` gövdesinde `setUp(TestApp.reset)` olarak
  /// kullanılır.
  static Future<void> reset() => ensureInitialized();

  /// [child]'ı çeviri ve tema bağlamıyla sarmalar.
  ///
  /// [locale] ile dil seçilir; iki dilin de doğru çevrildiğini sınamak için
  /// aynı widget iki dille çizilebilir.
  /// Aynı test dosyasındaki ardışık çizimleri birbirinden ayırmak için sayaç.
  ///
  /// [EasyLocalization] durumunu widget ağacında tutar; anahtar verilmezse
  /// Flutter aynı öğeyi yeniden kullanır ve ikinci `pumpWidget` çağrısında
  /// alt ağaç güncellenmeden kalır.
  static int _instance = 0;

  static Widget wrap(
    Widget child, {
    ThemeData? theme,
    Locale locale = const Locale('tr'),
  }) {
    return EasyLocalization(
      key: ValueKey('test-localization-${_instance++}'),
      supportedLocales: const [Locale('tr'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('tr'),
      startLocale: locale,
      child: Builder(
        builder: (context) => MaterialApp(
          theme: theme,
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(body: child),
        ),
      ),
    );
  }

  /// Yönlendirici kullanan ekranlar için sarmalayıcı.
  ///
  /// [wrap] sabit bir `home` verir; sekme kabuğu gibi gerçek yönlendirme
  /// gerektiren ekranlar `MaterialApp.router` ister.
  static Widget wrapRouter(
    RouterConfig<Object> router, {
    ThemeData? theme,
    Locale locale = const Locale('tr'),
  }) {
    return EasyLocalization(
      key: ValueKey('test-localization-${_instance++}'),
      supportedLocales: const [Locale('tr'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('tr'),
      startLocale: locale,
      child: Builder(
        builder: (context) => MaterialApp.router(
          theme: theme,
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          routerConfig: router,
        ),
      ),
    );
  }

  /// Widget'ı çizer ve çevirilerin yüklenmesini bekler.
  ///
  /// Çeviri dosyaları diskten gerçek asenkron I/O ile okunur; `pumpAndSettle`
  /// tek başına yetmez çünkü test ortamı sahte bir zamanlayıcı kullanır ve
  /// gerçek dosya okumasını beklemez. [WidgetTester.runAsync] bu süre boyunca
  /// gerçek olay döngüsünü çalıştırır.
  static Future<void> pump(
    WidgetTester tester,
    Widget child, {
    ThemeData? theme,
    Locale locale = const Locale('tr'),
  }) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(wrap(child, theme: theme, locale: locale));
      await tester.pump();
    });
    await tester.pumpAndSettle();
  }
}
