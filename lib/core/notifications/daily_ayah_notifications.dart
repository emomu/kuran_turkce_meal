import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Günün ayeti hatırlatması.
///
/// Bildirim tamamen cihazda planlanır — sunucu, hesap ya da ağ erişimi yok.
/// Uygulamanın geri kalanı gibi bu da çevrimdışı çalışır: her gün seçilen
/// saatte yerel bir bildirim düşer.
///
/// Planlama `matchDateTimeComponents: time` ile yapılır; tek bir kayıt her
/// gün aynı saatte tekrarlar, uygulamanın arka planda uyanmasına gerek
/// kalmaz. Kullanıcı saati değiştirdiğinde kayıt iptal edilip yeniden
/// kurulur.
class DailyAyahNotifications {
  DailyAyahNotifications._();

  static final instance = DailyAyahNotifications._();

  static const _channelId = 'daily_ayah';
  static const _notificationId = 1001;

  final _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Bildirime dokunularak açıldıysa gidilecek yol. `main()` ilk kareden
  /// önce bunu okur; yönlendirici hazır olmadan gezinme yapılamaz.
  String? initialRoute;

  /// Uygulama açıkken bildirime dokunulduğunda çağrılır. Yönlendirici
  /// kurulduktan sonra `main()` tarafından atanır.
  void Function(String route)? onSelectRoute;

  /// Eklentiyi ve saat dilimi veritabanını hazırlar.
  ///
  /// Testlerde ve masaüstünde platform kanalı bulunmadığı için tüm çağrılar
  /// sessizce yutulur; bildirim ikincil bir özellik, açılışı engellememeli.
  Future<void> init() async {
    if (_initialized) return;
    if (!_supported) return;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.local);

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // İzin açılışta değil, kullanıcı bildirimi açtığında istenir.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );

      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload == null || payload.isEmpty) return;
          onSelectRoute?.call(payload);
        },
      );

      // Uygulama kapalıyken bildirime dokunulmuşsa, açılış yolu buradan gelir.
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        final payload = launch?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) initialRoute = payload;
      }

      _initialized = true;
    } catch (error, stack) {
      debugPrint('Bildirim başlatılamadı: $error\n$stack');
    }
  }

  /// Bildirim iznini ister. Kullanıcı anahtarı açtığında çağrılır.
  ///
  /// Dönen değer izin verilip verilmediğidir; reddedilirse ayar açık
  /// bırakılmaz, böylece kullanıcı çalışmayan bir anahtar görmez.
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    await init();
    if (!_initialized) return false;

    try {
      if (Platform.isIOS) {
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      }

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return false;

      // Android 13+ çalışma anında izin ister; öncesinde izin zaten verilidir.
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    } catch (error) {
      debugPrint('Bildirim izni alınamadı: $error');
      return false;
    }
  }

  /// Her gün [hour]:[minute] saatinde tekrarlayan hatırlatmayı kurar.
  Future<void> schedule({
    required int hour,
    required int minute,
    required String title,
    required String body,
    String payload = '/',
  }) async {
    if (!_supported) return;
    await init();
    if (!_initialized) return;

    try {
      await cancel();

      await _plugin.zonedSchedule(
        id: _notificationId,
        title: title,
        body: body,
        scheduledDate: _nextInstanceOf(hour, minute),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Günün ayeti',
            channelDescription:
                'Her gün seçtiğiniz saatte bir ayet hatırlatması',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // Kesin zamanlama pil kısıtlarından etkilenmesin diye inexact
        // kullanılır; hatırlatma için dakika hassasiyeti gerekmez ve
        // Android'in SCHEDULE_EXACT_ALARM iznine ihtiyaç kalmaz.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (error) {
      debugPrint('Bildirim planlanamadı: $error');
    }
  }

  Future<void> cancel() async {
    if (!_supported) return;
    try {
      await _plugin.cancel(id: _notificationId);
    } catch (error) {
      debugPrint('Bildirim iptal edilemedi: $error');
    }
  }

  /// Verilen saatin bugünkü ya da yarınki en yakın örneği.
  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Yalnızca mobil platformlarda anlamlı; testler ve masaüstü atlanır.
  static bool get _supported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }
}
