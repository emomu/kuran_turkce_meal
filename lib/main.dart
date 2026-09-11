import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/notifications/daily_ayah_bootstrap.dart';
import 'core/notifications/daily_ayah_notifications.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets_bridge/home_widget_service.dart';
import 'core/widgets_bridge/home_widget_sync.dart';
import 'features/donate/providers/donation_provider.dart';
import 'features/donate/providers/donation_reminder.dart';
import 'features/settings/providers/preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Çeviri dosyaları ilk kareden önce yüklenir; aksi halde uygulama bir an
  // çeviri anahtarlarını ham haliyle gösterirdi.
  await EasyLocalization.ensureInitialized();

  // Tilavetin arka planda sürmesi ve kilit ekranından yönetilebilmesi için
  // ses servisi kurulur. Kurulum ses çalınmasa da yapılır: servis ancak
  // uygulama açılışında tanıtılabilir, ilk çalma anında kurulamaz.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.kuran.meal.audio',
    androidNotificationChannelName: 'Tilavet',
    // Bildirim, ses duraklatıldığında da durur: kullanıcı okumaya döndüğünde
    // bildirim çubuğunda asılı kalan bir denetim istemez.
    androidStopForegroundOnPause: true,
  );

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWidgets();
      // Hataları uygulamayı ilgilendirmez; servislerin içinde yutulur.
      unawaited(_registerOpen());
    });
  }

  /// Açılışta yapılan hafif işler: bildirim kaydını tazelemek, bağış
  /// sayacını artırmak ve gerekiyorsa bağış hatırlatmasını planlamak.
  ///
  /// İlk kareden sonra çalışır — hiçbiri açılışı bekletmeye değmez ve
  /// hiçbiri kullanıcının o anda gördüğü ekranı etkilemez.
  ///
  /// Sıra önemli: bağış hatırlatması günün ayeti bildiriminin açık olmasına
  /// bakıyor ve [refreshDailyAyahNotification] izin yoksa o tercihi
  /// kapatabiliyor. Önce bildirim tazelenmezse, bağış hatırlatması izni
  /// olmayan bir cihazda planlanmış sayılır ve bir yıl boyunca tekrar
  /// denenmezdi.
  Future<void> _registerOpen() async {
    if (!mounted) return;
    ref.read(donationProvider.notifier).registerAppOpen();

    await refreshDailyAyahNotification(ref);
    if (!mounted) return;
    await maybeScheduleDonationReminder(ref);
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
          // Boşluğa dokununca klavye kapanır — uygulamanın her ekranında.
          //
          // iOS'ta klavyeyi kapatmanın yerleşik bir yolu yok: Android'in
          // geri tuşu gibi bir çıkış bulunmadığı için kullanıcı bir alana
          // yazdıktan sonra klavyeyle baş başa kalır ve içeriğin yarısı
          // örtülü durur.
          //
          // `TapRegion` burada işe yaramaz: `onTapOutside` kendi sınırının
          // dışına dokunulunca ateşlenir ve bu widget ağacın en dışında
          // olduğu için "dışarısı" diye bir yer kalmaz. `Listener` ise
          // dokunuşu görür ama tüketmez — altındaki düğmeler, listeler ve
          // kaydırmalar dokunuşu almaya devam eder.
          child: Builder(
            builder: (context) => Listener(
              key: _keyboardDismissKey,
              onPointerDown: (event) {
                // Klavye kapalıyken hiçbir şey yapılmaz: düğme ya da
                // kaydırma odağını düşürmek erişilebilirlik gezinmesini
                // bozardı. Ölçü dokunma anında okunur; builder'ın yakaladığı
                // değer o an güncel olmayabilir.
                if (MediaQuery.viewInsetsOf(context).bottom <= 0) return;

                // Dokunulan yerde tıklanabilir bir şey varsa klavye kapanmaz.
                //
                // Bu katman bütün ekranı dinliyor ve dokunuşu tüketmiyor;
                // dolayısıyla bir düğmeye basıldığında hem düğme çalışıyor
                // hem klavye kapanıyordu. Arama ekranındaki öneri şeridi
                // bunu görünür kıldı: bir öneriye basmak metni kutuya
                // yazıyor ama aynı anda klavyeyi kapatıyordu — kullanıcı
                // yazmaya devam edemiyordu.
                final self = _keyboardDismissKey.currentContext
                    ?.findRenderObject();
                if (keyboardDismissHitsInteractive(event.position, self)) {
                  return;
                }

                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: child!,
            ),
          ),
        );
      },
    );
  }
}

/// Klavyeyi kapatan dinleyicinin kimliği.
///
/// İsabet denetimi kendi katmanını atlayabilsin diye tutuluyor.
final _keyboardDismissKey = GlobalKey();

/// Verilen ekran noktasında dokunuşa yanıt veren bir widget var mı.
///
/// Klavyeyi kapatan genel dinleyici bunu sorar: boşluğa dokunulduysa klavye
/// kapanır, bir düğmeye ya da metin alanına dokunulduysa dokunulmaz.
///
/// Sınanabilmesi için dışa açık; uygulama kodunda yalnızca o dinleyici
/// çağırır (bkz. test/keyboard_dismiss_test.dart).
///
/// `hitTest` o noktadaki render nesnelerini en üstten en alta sıralar;
/// aralarında bir `RenderPointerListener` ya da `RenderSemanticsGestureHandler`
/// varsa orada tıklanabilir bir şey vardır. Metin alanının kendisi de bu
/// denetimden geçer — zaten ona dokunulduğunda klavyenin kapanmaması doğru.
bool keyboardDismissHitsInteractive(
  Offset position,
  RenderObject? self,
) {
  // Kök `RenderView`'dır, `RenderBox` değil: doğrudan `RenderBox` beklemek
  // denetimi sessizce devre dışı bırakıyordu (her zaman false dönüyordu).
  // `RenderView.hitTest` doğru giriş noktası.
  final root = WidgetsBinding.instance.rootElement?.renderObject;
  if (root is! RenderView) return false;

  final result = HitTestResult();
  root.hitTest(result, position: position);

  for (final entry in result.path) {
    final target = entry.target;
    // Dinleyicinin kendisi sayılmaz: bütün ekranı kapladığı için her
    // dokunuşta isabet alır ve sayılsaydı klavye hiçbir zaman kapanmazdı.
    if (identical(target, self)) continue;

    // Kaydırılabilir alanlar atlanır. `Scrollable` kendi jest tanıyıcısı
    // için bir `RenderSemanticsGestureHandler` üretiyor ve bu, listenin boş
    // yerinde de isabet alıyor. Ayırt edilmeseydi kaydırılabilir her ekranda
    // klavye kapanmazdı — Keşfet'te tam olarak bu oluyordu: liste boşken
    // altındaki boşluğa dokunmak hiçbir şey yapmıyordu.
    //
    // Ölçüt, tanıyıcının dokunmaya yanıt verip vermediği: bir düğme `onTap`
    // taşır, kaydırma yalnızca sürüklemeyi dinler.
    if (target is RenderSemanticsGestureHandler) {
      if (target.onTap != null || target.onLongPress != null) return true;
      continue;
    }

    // `InkWell`/`ElevatedButton` gibi Material düğmeleri bunu üretir.
    //
    // `RenderPointerListener`'a bakılmaz: `MaterialApp` fare imleci için
    // ekranın tamamını kaplayan bir tane koyuyor ve boş alanda da isabet
    // alıyor. Ona bakılsaydı klavye hiçbir yerde kapanmazdı — denetimin
    // tamamı sessizce işlevsiz kalırdı.
    if (target is RenderMouseRegion) {
      return true;
    }
  }
  return false;
}
