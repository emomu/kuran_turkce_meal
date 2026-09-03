import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/notifications/daily_ayah_notifications.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets_bridge/home_widget_service.dart';
import 'core/widgets_bridge/home_widget_sync.dart';
import 'features/settings/providers/preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Çeviri dosyaları ilk kareden önce yüklenir; aksi halde uygulama bir an
  // çeviri anahtarlarını ham haliyle gösterirdi.
  await EasyLocalization.ensureInitialized();

  // Tercihler açılışta okunur ve sağlayıcıya enjekte edilir; böylece ilk kare
  // doğru tema ile çizilir ve uygulama açılırken tema atlaması olmaz.
  final prefs = await SharedPreferences.getInstance();

  // Bildirim altyapısı hazırlanır. İzin burada istenmez — kullanıcı ayarlardan
  // açtığında sorulur; açılışta izin istemek mağaza incelemelerinde de
  // eleştirilen bir davranış.
  final notifications = DailyAyahNotifications.instance;
  await notifications.init();

  // Bildirime dokunulduğunda ilgili ayete gidilir. Yönlendirici burada hazır
  // olduğu için geçiş doğrudan yapılabilir.
  notifications.onSelectRoute = appRouter.go;

  // Ana ekran araçlarının ortak veri alanı tanıtılır. Veri yazımı ilk
  // kareden sonra yapılır (bkz. QuranApp) — açılışı bekletmemek için.
  final homeWidgets = HomeWidgetService.instance;
  await homeWidgets.init();

  // Araca dokunularak açıldıysa hedef yol belirlenir. Bildirimle aynı
  // mantık: yönlendirici hazır olmadan gezinme yapılamaz.
  final widgetLaunchRoute = await homeWidgets.launchRoute();

  homeWidgets.listenForClicks(appRouter.go);

  // Uygulama dört yönde de çalışır. Yatayda satırların aşırı uzaması sorunu
  // yön kilidiyle değil, düzen tarafında çözülür: okuma metni ortalanır ve
  // konforlu bir satır genişliğine oturur (bkz. `shared/widgets/responsive_layout.dart`).
  // Yön kilidi ayrıca erişilebilirlik açısından da sorunlu — cihazını sabit
  // bir tutucuya yatay bağlayan kullanıcı uygulamayı hiç kullanamıyordu.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Sistem çubukları uygulamanın zeminiyle aynı renkte görünsün.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Uygulama bildirime dokunularak açıldıysa, ilk kare çizildikten sonra
  // hedefe gidilir; yönlendirici kurulmadan gezinme yapılamaz.
  final launchRoute = notifications.initialRoute ?? widgetLaunchRoute;
  if (launchRoute != null && launchRoute != '/') {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appRouter.go(launchRoute);
    });
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('tr'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('tr'),
      child: ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const QuranApp(),
      ),
    ),
  );
}

class QuranApp extends ConsumerStatefulWidget {
  const QuranApp({super.key});

  @override
  ConsumerState<QuranApp> createState() => _QuranAppState();
}

/// Ana ekran araçlarının verisi burada tazelenir.
///
/// İki an seçildi: ilk kare çizildikten sonra (açılışı bekletmeden) ve
/// uygulama öne geldiğinde. İkincisi önemli çünkü kullanıcı gece yarısını
/// uygulama açıkken geçirdiğinde günün ayeti değişir; öne gelişte tazelemek
/// bu durumu ek bir zamanlayıcı kurmadan yakalar.
class _QuranAppState extends ConsumerState<QuranApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWidgets());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncWidgets();
  }

  void _syncWidgets() {
    if (!mounted) return;
    ref.read(homeWidgetSyncProvider).sync(
          languageCode: context.locale.languageCode,
        );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(preferencesProvider.select((p) => p.themeMode));

    return MaterialApp.router(
      title: 'app.title'.tr(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,

      // Dil ve çeviri temsilcileri EasyLocalization'dan gelir.
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,

      builder: (context, child) {
        // Sistem yazı boyutu ayarı uygulamanın kendi punto ölçeğiyle
        // çarpışmasın diye üst sınır konur; kullanıcı çok büyük sistem
        // puntosu seçtiğinde arayüz düzeni bozulmaz, okuma metni ise
        // uygulama içi ayardan büyütülebilir.
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
