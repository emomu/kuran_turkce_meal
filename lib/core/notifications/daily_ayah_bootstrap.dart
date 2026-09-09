import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/preferences_provider.dart';
import '../providers/app_providers.dart';
import 'daily_ayah_notifications.dart';

/// İznin daha önce istenip istenmediği. Bir kez sorulur, cevabı ne olursa
/// olsun bir daha açılışta sorulmaz.
const _kPermissionAsked = 'daily_ayah_permission_asked';

/// Günün ayeti hatırlatmasını açılışta yeniden kurar.
///
/// Bu olmadan bildirim, yalnızca kullanıcı ayarlardan anahtarı elle açtığı
/// anda planlanıyordu — ve tercih varsayılan olarak açık geldiği için
/// kullanıcıların çoğu anahtara hiç dokunmuyor. Sonuç: ayarlarda "Bildirim:
/// açık" yazıyor ama planlanmış hiçbir kayıt yok, izin de hiç istenmemiş.
///
/// Açılışta tazelemek ayrıca üç durumu daha toparlar:
/// - Telefon yeniden başlatıldığında düşen kayıtlar geri kurulur.
/// - Kullanıcı izni sistem ayarlarından geri aldıysa tercih de kapatılır,
///   böylece arayüz çalışmayan bir anahtar göstermez.
/// - Uygulama dili değiştiyse bildirim metni yeni dille yeniden yazılır.
///
/// Uygulama açık değilken bir şey yapılamaz; bu yüzden "her gün düşen"
/// kaydın kendisi `matchDateTimeComponents` ile sistemde tekrarlıyor, bu
/// fonksiyon yalnızca kaydın sağlığını doğruluyor.
Future<void> refreshDailyAyahNotification(WidgetRef ref) async {
  final prefs = ref.read(preferencesProvider);
  final notifications = DailyAyahNotifications.instance;

  if (!prefs.dailyAyahEnabled) {
    // Tercih kapalıysa artık kayıt da kalmamalı. Kullanıcı ayarlardan
    // kapattığında zaten iptal ediliyor; bu, o çağrının bir sebeple
    // yapılamadığı hallere karşı ikinci bir güvence.
    await notifications.cancel();
    return;
  }

  var granted = await notifications.hasPermission();

  // İlk açılışta izin bir kez istenir.
  //
  // Tercih varsayılan olarak açık geliyor; kullanıcı anahtara hiç
  // dokunmadığı için izin de hiç istenmiyor ve "açık" görünen bildirim hiç
  // düşmüyordu. İstek yalnızca bir kez yapılır: reddeden kullanıcıya her
  // açılışta pencere göstermek rahatsız edici olur ve iOS zaten ikinci
  // isteği kendiliğinden yutar.
  final prefsStore = ref.read(sharedPreferencesProvider);
  if (!granted && !(prefsStore.getBool(_kPermissionAsked) ?? false)) {
    await prefsStore.setBool(_kPermissionAsked, true);
    granted = await notifications.requestPermission();
  }

  if (!granted) {
    // İzin yok: tercih açık kalırsa kullanıcı hiç düşmeyecek bir bildirimi
    // açık sanır. Anahtarı kapatmak, ayarlar ekranını gerçeğe döndürür ve
    // kullanıcı yeniden açtığında izin penceresi çıkar.
    ref.read(preferencesProvider.notifier).setDailyAyahEnabled(false);
    await notifications.cancel();
    return;
  }

  final time = prefs.dailyAyahTime;
  await notifications.schedule(
    hour: time.hour,
    minute: time.minute,
    title: 'settings.dailyAyahTitle'.tr(),
    body: 'settings.dailyAyahBody'.tr(),
  );

}
