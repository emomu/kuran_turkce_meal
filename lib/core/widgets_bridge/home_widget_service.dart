import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../router/app_router.dart';
import 'home_widget_data.dart';
import 'home_widget_keys.dart';

/// Ana ekran araçlarına veri yazan katman.
///
/// Araçlar Flutter motorunu çalıştırmaz: uygulama verileri düz anahtar-değer
/// olarak ortak depoya yazar (Android'de SharedPreferences, iOS'ta App Group
/// UserDefaults), native taraf da yalnızca bunu okuyup çizer. Bunun iki
/// getirisi var — araç anında görünür ve arka planda pil harcamaz.
///
/// Bu yüzden veri "yazılıp bırakılır": uygulama bir daha hiç açılmasa bile
/// araç son yazılan içeriği göstermeye devam eder. Günün ayeti için bu
/// yetersiz kalırdı (ertesi gün bayat içerik kalırdı), bu yüzden araç
/// tarafında gün numarası karşılaştırması yapılır ve gerekirse araç kendi
/// yedek metnini gösterir.
///
/// Bildirim katmanı gibi burada da tüm çağrılar sessizce yutulur: araç
/// ikincil bir özellik, hata vermesi uygulamanın akışını bozmamalı.
class HomeWidgetService {
  HomeWidgetService._();

  static final instance = HomeWidgetService._();

  bool _initialized = false;

  /// Ortak veri alanını tanıtır. iOS'ta App Group olmadan yazılan veri
  /// araçlara ulaşmaz; Android'de bu çağrı zararsızdır.
  Future<void> init() async {
    if (_initialized || !_supported) return;
    try {
      await HomeWidget.setAppGroupId(HomeWidgetKeys.iosAppGroupId);
      _initialized = true;
    } catch (error) {
      debugPrint('Araç veri alanı tanıtılamadı: $error');
    }
  }

  /// Üç aracın verisini birden yazar ve yenilenmelerini ister.
  ///
  /// Tek tek yazmak yerine toplu yazılır çünkü veriler aynı kaynaklardan
  /// (son okuma, aktif plan, günün ayeti) türüyor ve hepsi aynı anda
  /// tazeleniyor; ayrı ayrı tetiklemek araçların birbirinden farklı anlarda
  /// güncellenmesine, dolayısıyla ana ekranda tutarsız görünmesine yol açardı.
  Future<void> update(HomeWidgetPayload payload) async {
    if (!_supported) return;
    await init();
    if (!_initialized) return;

    try {
      await Future.wait([
        for (final entry in payload.toMap().entries)
          HomeWidget.saveWidgetData(entry.key, entry.value),
      ]);

      await Future.wait([
        _refresh(
          android: HomeWidgetKeys.androidDailyAyahProvider,
          ios: HomeWidgetKeys.iosDailyAyahKind,
        ),
        _refresh(
          android: HomeWidgetKeys.androidContinueProvider,
          ios: HomeWidgetKeys.iosContinueKind,
        ),
        _refresh(
          android: HomeWidgetKeys.androidStreakProvider,
          ios: HomeWidgetKeys.iosStreakKind,
        ),
      ]);
    } catch (error) {
      debugPrint('Araç verisi yazılamadı: $error');
    }
  }

  Future<void> _refresh({
    required String android,
    required String ios,
  }) async {
    try {
      await HomeWidget.updateWidget(
        androidName: android,
        iOSName: ios,
        qualifiedAndroidName:
            '${HomeWidgetPayload.androidPackage}.widgets.$android',
      );
    } catch (error) {
      debugPrint('Araç yenilenemedi ($android): $error');
    }
  }

  /// Araca dokunularak açıldıysa gidilecek yol.
  ///
  /// Araçlar uygulamayı `homeWidget://` şemasıyla açar; yolun kendisi
  /// bağlantının host+path kısmında taşınır.
  Future<String?> launchRoute() async {
    if (!_supported) return null;
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      return routeFromUri(uri);
    } catch (error) {
      debugPrint('Araç açılış yolu okunamadı: $error');
      return null;
    }
  }

  /// Uygulama açıkken araca dokunulduğunda tetiklenir.
  void listenForClicks(void Function(String route) onRoute) {
    if (!_supported) return;
    try {
      HomeWidget.widgetClicked.listen((uri) {
        final route = routeFromUri(uri);
        if (route != null) onRoute(route);
      });
    } catch (error) {
      debugPrint('Araç dokunuşları dinlenemedi: $error');
    }
  }

  /// `homeWidget://sure/2?ayet=255` biçimindeki bağlantıyı uygulama içi
  /// yola çevirir.
  ///
  /// Çeviri yönlendiricideki [widgetRouteOf] ile paylaşılır: aynı bağlantı
  /// iki ayrı yoldan gelebiliyor (eklentinin kendi akışı ve işletim
  /// sisteminin derin bağlantı akışı) ve ikisinin farklı ayrıştırması
  /// birinde çalışıp diğerinde bozulan bir davranış üretirdi.
  ///
  /// Şemasız bağlantılar da kabul edilir: eklenti bazı durumlarda yolu
  /// şemayı sıyırarak veriyor.
  @visibleForTesting
  static String? routeFromUri(Uri? uri) {
    if (uri == null) return null;

    final route = widgetRouteOf(uri);
    if (route != null) return route;

    // Şema yoksa bağlantının kendisi zaten uygulama içi yoldur.
    if (uri.scheme.isNotEmpty) return null;

    final path = uri.path;
    if (path.isEmpty || path == '/') return '/';

    return uri.query.isEmpty ? path : '$path?${uri.query}';
  }

  /// Araçlar yalnızca mobilde var; masaüstü ve testlerde atlanır.
  static bool get _supported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}
